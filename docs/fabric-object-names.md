
### DMAC Organization - ACI Configuration MOP (Method of Procedure)

### Access Policies

| Object | Object Name | GUI Location | Notes |
| :--- | :--- | :--- | :--- |
| **VLAN Pool** | DmacProd_StaticVLPool | `Fabric > Access Policies > Pools > VLAN` | Static allocation for range **400 - 500**. Role: External. |
| **Physical Domain** | DMACProd_PhysDom | `Fabric > Access Policies > Physical and External Domains > Physical Domains` | Bound to `DmacProd_StaticVLPool`. |
| **AAEP** | DMACProd_AAEP | `Fabric > Access Policies > Policies > Global > Attachable Access Entity Profiles` | Binds `DMACProd_PhysDom` to physical port configurations. |
| **CDP Policy** | CDP_Enable | `Fabric > Access Policies > Policies > Interface > CDP Interface` | CDP enabled. |
| **LLDP Policy** | LLDP_Enable | `Fabric > Access Policies > Policies > Interface > LLDP Interface` | LLDP transmit and receive enabled. |
| **LACP Policy** | LACP_Enable | `Fabric > Access Policies > Policies > Interface > Port Channel` | LACP mode: Active. Used for vPC bundles. |
| **Link Level Policy** | 10G_SPEED | `Fabric > Access Policies > Policies > Interface > Link Level` | Speed: 10G. |
| **Interface Policy Group** | ESXILab01_VPC | `Fabric > Access Policies > Interfaces > Leaf Interfaces > Policy Groups > VPC Interface` | vPC bundle for esxi-lab-01. Binds CDP, LLDP, LACP, 10G, and `DMACProd_AAEP`. Port: Eth1/31. |
| **Interface Policy Group** | ESXILab02_VPC | `Fabric > Access Policies > Interfaces > Leaf Interfaces > Policy Groups > VPC Interface` | vPC bundle for esxi-lab-02. Binds CDP, LLDP, LACP, 10G, and `DMACProd_AAEP`. Port: Eth1/32. |
| **Interface Policy Group** | ESXILab03_VPC | `Fabric > Access Policies > Interfaces > Leaf Interfaces > Policy Groups > VPC Interface` | vPC bundle for esxi-lab-03. Binds CDP, LLDP, LACP, 10G, and `DMACProd_AAEP`. Port: Eth1/33. |
| **Interface Profile** | Leaf101_102_IP | `Fabric > Access Policies > Interfaces > Leaf Interfaces > Profiles` | Port selectors: Eth1/31 (ESXILab01), Eth1/32 (ESXILab02), Eth1/33 (ESXILab03). Shared by Leaf 101 and 102. |
| **Switch Profile** | Leaf101_102_SP | `Fabric > Access Policies > Switches > Leaf Switches > Profiles` | Binds `Leaf101_102_IP`. Leaf selector `Leaf101_102_Selector` covers nodes 101–102. |

## Tenant Policies

| Object | Object Name | GUI Location | Notes |
| :--- | :--- | :--- | :--- |
| **Tenant** | DMACProd | `Tenants > Add Tenant` | Top-level logical container for the DMAC Organization Prod. |
| **VRF** | PCI_VRF | `Tenants > DMACProd > Networking > VRFs` | Policy enforcement: enforced. |
| **VRF** | Shared_VRF | `Tenants > DMACProd > Networking > VRFs` | Policy enforcement: enforced. |
| **VRF** | Prod_VRF | `Tenants > DMACProd > Networking > VRFs` | Policy enforcement: enforced. |
| **VRF** | Storage_VRF | `Tenants > DMACProd > Networking > VRFs` | Policy enforcement: enforced. |
| **VRF** | External_VRF | `Tenants > DMACProd > Networking > VRFs` | Policy enforcement: enforced. Reserved for future L3Out. |
| **Bridge Domain** | NetServices_BD | `Tenants > DMACProd > Networking > Bridge Domains` | VRF: `Shared_VRF`. GW: **10.20.0.1/24**. Unicast Routing: yes. ARP Flooding: yes. Subnet scope: shared, public. |
| **Bridge Domain** | Compute01_BD | `Tenants > DMACProd > Networking > Bridge Domains` | VRF: `Prod_VRF`. GW: **10.10.0.1/24**. Unicast Routing: yes. ARP Flooding: yes. Subnet scope: public. |
| **Bridge Domain** | Compute02_BD | `Tenants > DMACProd > Networking > Bridge Domains` | VRF: `Prod_VRF`. GW: **10.10.1.1/24**. Unicast Routing: yes. ARP Flooding: yes. Subnet scope: public. |
| **Bridge Domain** | Storage_BD | `Tenants > DMACProd > Networking > Bridge Domains` | VRF: `Storage_VRF`. GW: **10.30.0.1/24**. Unicast Routing: yes. ARP Flooding: yes. Subnet scope: private. |
