# DMAC ACI Fabric Design

## Overview

This document describes the full Cisco ACI fabric design for the DMAC Production environment, derived entirely from the Terraform code in this repository. It covers the physical topology, access policies, tenant policies, and how a packet travels from a server NIC to an EPG.

The configuration is split across two independent Terraform workspaces:

| Workspace | Path | Responsibility |
| :--- | :--- | :--- |
| Access Policies | `tform/tenants/prod/access-pols/` | Physical fabric: ports, VLANs, domains, interface policies |
| Tenant Policies | `tform/tenants/prod/tenant-pols/` | Logical network: tenant, VRFs, BDs, EPGs, contracts |

---

## Physical Topology

Three ESXi hosts are dual-homed to two ACI leaf switches via vPC (Virtual Port Channel). Each host uses LACP active mode, matching the `LACP_Enable` policy on the ACI side.

```
                  Leaf 101              Leaf 102
                ┌─────────┐           ┌─────────┐
                │         │           │         │
         Eth1/31│         │   vPC     │         │Eth1/31
  esxi-lab-01 ══╪═════════╪═══════════╪═════════╪══ esxi-lab-01
                │         │           │         │
         Eth1/32│         │   vPC     │         │Eth1/32
  esxi-lab-02 ══╪═════════╪═══════════╪═════════╪══ esxi-lab-02
                │         │           │         │
         Eth1/33│         │   vPC     │         │Eth1/33
  esxi-lab-03 ══╪═════════╪═══════════╪═════════╪══ esxi-lab-03
                └─────────┘           └─────────┘
                  Node 101              Node 102
```

Each vPC bundle is managed by a dedicated Interface Policy Group:

| Host | vPC Policy Group | Leaf Port | Speed | LACP |
| :--- | :--- | :--- | :--- | :--- |
| esxi-lab-01 | `ESXILab01_VPC` | Eth1/31 | 10G | Active |
| esxi-lab-02 | `ESXILab02_VPC` | Eth1/32 | 10G | Active |
| esxi-lab-03 | `ESXILab03_VPC` | Eth1/33 | 10G | Active |

---

## Access Policies (`access-pols/`)

Access policies define how the physical fabric behaves — what VLANs are allowed, how ports are configured, and which physical domain governs the infrastructure. These are fabric-wide and have no knowledge of tenants or applications.

### VLAN Pool

```
DmacProd_StaticVLPool  →  VLANs 400–500  (static allocation, role: external)
```

A static pool means VLANs are only assigned where explicitly configured — no dynamic allocation. The range 400–500 provides 101 VLANs for production workloads.

### Physical Domain → AAEP → Interface Policy Groups

This is the core binding chain in ACI access policies:

```
DmacProd_StaticVLPool (VLANs 400-500)
        │
        ▼
DMACProd_PhysDom  (Physical Domain)
        │
        ▼
DMACProd_AAEP  (Attachable Access Entity Profile)
        │
        ├──► ESXILab01_VPC  (vPC Policy Group)
        ├──► ESXILab02_VPC  (vPC Policy Group)
        └──► ESXILab03_VPC  (vPC Policy Group)
```

- The **Physical Domain** declares which VLAN pool is valid for physical ports.
- The **AAEP** is the "glue" — it binds the Physical Domain to the Interface Policy Groups, making the VLAN pool available on the actual ports.

### Interface Policies

Each vPC Interface Policy Group bundles five policies:

| Policy | Name | Setting |
| :--- | :--- | :--- |
| CDP | `CDP_Enable` | Enabled |
| LLDP | `LLDP_Enable` | TX + RX enabled |
| LACP | `LACP_Enable` | Mode: **Active** |
| Link Level | `10G_SPEED` | Speed: 10G |
| AAEP | `DMACProd_AAEP` | Binds domain to port |

### Interface Profile and Switch Profile

The Interface Profile (`Leaf101_102_IP`) maps physical port numbers to their vPC Policy Groups:

| Port Selector | Port | vPC Policy Group |
| :--- | :--- | :--- |
| `eth1_31` | Eth1/31 | `ESXILab01_VPC` |
| `eth1_32` | Eth1/32 | `ESXILab02_VPC` |
| `eth1_33` | Eth1/33 | `ESXILab03_VPC` |

The Switch Profile (`Leaf101_102_SP`) binds this Interface Profile to the physical switches via a Leaf Selector covering **nodes 101 and 102**. Because both leaves share one Interface Profile, the same port configuration is applied symmetrically to both — which is required for vPC.

---

## Tenant Policies (`tenant-pols/`)

Tenant policies define the logical network inside the `DMACProd` tenant. This layer is entirely decoupled from the physical fabric — it has no knowledge of leaf node IDs or port numbers.

### Tenant: `DMACProd`

All resources below live inside this tenant, which is the top-level isolation boundary in ACI.

### VRFs

Five VRFs are defined, all with policy enforcement **enforced** (contracts are required for inter-EPG communication):

| VRF | Purpose |
| :--- | :--- |
| `Prod_VRF` | Production compute workloads |
| `Shared_VRF` | Shared network services (DNS, DHCP) accessible across VRFs |
| `Storage_VRF` | Isolated storage traffic |
| `PCI_VRF` | Reserved for PCI-scoped workloads |
| `External_VRF` | Reserved for future L3Out (external routing) |

### Bridge Domains and Subnets

Each Bridge Domain is a Layer 2 boundary with an embedded Layer 3 gateway. ACI acts as the default gateway for each subnet.

| Bridge Domain | VRF | Gateway | Subnet Scope | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `NetServices_BD` | `Shared_VRF` | `10.20.0.1/24` | shared, public | Route leaking enabled. Accessible from other VRFs via shared scope. |
| `Compute01_BD` | `Prod_VRF` | `10.10.0.1/24` | public, shared | Compute tier 1. Routed externally via L3Out. |
| `Compute02_BD` | `Prod_VRF` | `10.10.1.1/24` | public, shared | Compute tier 2. Routed externally via L3Out. |
| `Storage_BD` | `Storage_VRF` | `10.30.0.1/24` | private, shared | Storage traffic. Private scope prevents L3Out advertisement. |

All Bridge Domains have **unicast routing** and **ARP flooding** enabled.

### Application Profiles and EPGs

EPGs are the fundamental policy units — traffic is classified into an EPG and policy is applied based on EPG membership.

```
DMACProd (Tenant)
├── NetServices_AP
│     └── NetServices_EPG  →  NetServices_BD  (10.20.0.0/24, Shared_VRF)
└── Compute_AP
      ├── Compute01_EPG    →  Compute01_BD    (10.10.0.0/24, Prod_VRF)
      └── Compute02_EPG    →  Compute02_BD    (10.10.1.0/24, Prod_VRF)
```

Note: `Storage_BD` exists but has no EPG yet — it is reserved for future use.

### Contracts, Filters, and Policy Enforcement

ACI uses a whitelist model — all inter-EPG traffic is **denied by default**. Contracts explicitly permit traffic between EPGs.

#### Filters

| Filter | Protocol | Port(s) | Purpose |
| :--- | :--- | :--- | :--- |
| `DNS_Filter` | UDP | 53 | DNS queries |
| `DNS_Filter` | TCP | 53 | DNS zone transfers / large responses |
| `DHCP_Filter` | UDP (IPv4) | 67 | DHCP server |
| `DHCP_Filter` | UDP (IPv6) | 546 | DHCPv6 client |
| `DHCP_Filter` | UDP (IPv6) | 547 | DHCPv6 server |

#### Contract: `NetworkServices_Contract`

Scope: **tenant** — this allows the contract to span across VRFs (Prod_VRF → Shared_VRF), enabling route leaking so compute workloads can reach shared services.

| Subject | Filter | Action |
| :--- | :--- | :--- |
| `NetworkServices_Subject` | `DNS_Filter` | Permit |
| `NetworkServices_Subject` | `DHCP_Filter` | Permit + **Log** |

#### EPG Roles

| EPG | Role | Meaning |
| :--- | :--- | :--- |
| `NetServices_EPG` | **Provider** | Offers DNS and DHCP services |
| `Compute01_EPG` | **Consumer** | Requests DNS and DHCP from NetServices |
| `Compute02_EPG` | **Consumer** | Requests DNS and DHCP from NetServices |

### EPG-to-Domain Bindings

Before an EPG can use physical ports, it must be bound to the Physical Domain. The data source in `sources.tf` looks up `DMACProd_PhysDom` from the `access-pols` workspace at plan time.

All three EPGs are bound to `DMACProd_PhysDom` with `instr_imedcy = immediate`, meaning ACI programmes the policies on the leaf as soon as the binding is applied — without waiting for a host to be discovered on the port.

### Static Path Bindings

Static path bindings are the final link between the logical EPGs and the physical vPC ports. They specify which VLAN encapsulation is used on each bundle.

| EPG | vPC Bundle | VLAN | Mode |
| :--- | :--- | :--- | :--- |
| `Compute01_EPG` | `ESXILab01_VPC` (Eth1/31) | **401** | regular (802.1Q tagged) |
| `Compute02_EPG` | `ESXILab02_VPC` (Eth1/32) | **402** | regular (802.1Q tagged) |
| `NetServices_EPG` | `ESXILab03_VPC` (Eth1/33) | **403** | regular (802.1Q tagged) |

---

## End-to-End: How a Packet Gets Classified

The journey of a frame from an ESXi VM NIC to an ACI EPG:

```
1. VM sends a frame tagged with VLAN 401
        │
        ▼
2. ESXi vmnic → vDS port group "Compute01_PG" (VLAN 401)
        │
        ▼
3. Frame leaves the ESXi physical NIC over the LACP bond
        │
        ▼
4. ACI Leaf 101 or 102 receives the frame on Eth1/31
   - The port is mapped to ESXILab01_VPC via the Interface Profile
   - The AAEP links ESXILab01_VPC to DMACProd_PhysDom
   - The Static Path Binding maps VLAN 401 on ESXILab01_VPC → Compute01_EPG
        │
        ▼
5. Frame is classified into Compute01_EPG (Compute01_BD, Prod_VRF)
        │
        ▼
6. Policy enforcement: destination EPG checked against contracts
   - If destination is NetServices_EPG: NetworkServices_Contract checked → DNS/DHCP permitted
   - If destination is another Compute EPG: no contract → denied
        │
        ▼
7. Frame forwarded to destination leaf and delivered
```

---

## Full Dependency Chain

```
access-pols workspace
─────────────────────────────────────────────────────
DmacProd_StaticVLPool (VLANs 400-500)
  └── DMACProd_PhysDom
        └── DMACProd_AAEP
              └── ESXILab01/02/03_VPC ◄── CDP_Enable
                        │               ◄── LLDP_Enable
                        │               ◄── LACP_Enable (active)
                        │               ◄── 10G_SPEED
                        │
              Leaf101_102_IP (Interface Profile)
                ├── eth1_31 ──► ESXILab01_VPC
                ├── eth1_32 ──► ESXILab02_VPC
                └── eth1_33 ──► ESXILab03_VPC
                        │
              Leaf101_102_SP (Switch Profile)
                └── Leaf101_102_Selector (nodes 101-102)


tenant-pols workspace
─────────────────────────────────────────────────────
DMACProd (Tenant)
  ├── PCI_VRF / Shared_VRF / Prod_VRF / Storage_VRF / External_VRF
  │
  ├── NetServices_BD (Shared_VRF, 10.20.0.1/24)
  │     └── NetServices_EPG ──► DMACProd_PhysDom (data source)
  │               │              Static path: ESXILab03_VPC, VLAN 403
  │               └── provides: NetworkServices_Contract
  │
  ├── Compute01_BD (Prod_VRF, 10.10.0.1/24)
  │     └── Compute01_EPG ──► DMACProd_PhysDom (data source)
  │               │             Static path: ESXILab01_VPC, VLAN 401
  │               └── consumes: NetworkServices_Contract
  │
  ├── Compute02_BD (Prod_VRF, 10.10.1.1/24)
  │     └── Compute02_EPG ──► DMACProd_PhysDom (data source)
  │               │             Static path: ESXILab02_VPC, VLAN 402
  │               └── consumes: NetworkServices_Contract
  │
  └── Storage_BD (Storage_VRF, 10.30.0.1/24)
        └── (no EPG yet)


NetworkServices_Contract (scope: tenant)
  └── NetworkServices_Subject
        ├── DNS_Filter  → permit (UDP/TCP 53)
        └── DHCP_Filter → permit + log (UDP 67, 546, 547)
```
