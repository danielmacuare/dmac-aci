
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
| **VRF** | Prod_VRF | `Tenants > DMAC > Networking > VRFs` | Production VRF to hold the routing table. |
| **Bridge Domain** | WebSrv_BD | `Tenants > DMAC > Networking > Bridge Domains` | GW: **10.10.10.1/24**. Unicast Routing & ARP Flooding: True. Advertised Externally: True. GARP detection: True. |
| **Bridge Domain** | AppSrv_BD | `Tenants > DMAC > Networking > Bridge Domains` | GW: **10.10.20.1/24**. Unicast Routing & ARP Flooding: True. Advertised Externally: True. GARP detection: True. |
| **Bridge Domain** | DbSrv_BD | `Tenants > DMAC > Networking > Bridge Domains` | GW: **10.10.30.1/24**. Unicast Routing & ARP Flooding: True. Advertised Externally: True. GARP detection: True. |
| **Application Profile** | Web_AP | `Tenants > DMAC > Application Profiles` | Logical folder organizing the Web, App, and DB EPGs. |
| **Application EPG** | WebSrv_EPG | `Tenants > DMAC > Application Profiles > Web_AP > Application EPGs` | Intra-EPG Isolation: Unenforced. Static Path: Pod-1/Node-101/eth1/31 (VLAN 31). |
| **Application EPG** | AppSrv_EPG | `Tenants > DMAC > Application Profiles > Web_AP > Application EPGs` | Intra-EPG Isolation: Unenforced. Static Path: Pod-1/Node-101/eth1/32 (VLAN 32). |
| **Application EPG** | DbSrv_EPG | `Tenants > DMAC > Application Profiles > Web_AP > Application EPGs` | Intra-EPG Isolation: Unenforced. Static Path: Pod-1/Node-101/eth1/33 (VLAN 33). |
| **Filter** | web_FILT | `Tenants > DMAC > Contracts > Filters` | Web Ports: HTTP (TCP 80), HTTPS (TCP 443), HTTP Alt (TCP 8080). |
| **Filter** | dbs_FILT | `Tenants > DMAC > Contracts > Filters` | Database Ports: MySQL (TCP 3306), Postgres (TCP 5432), Mongo (TCP 27017). |
| **Filter** | apps_FILT | `Tenants > DMAC > Contracts > Filters` | Backend App Ports: TCP 3000, 8000, 8080. |
| **Contract** | WebSrv_to_AppSrv_CT | `Tenants > DMAC > Contracts > Standard` | Scope: App Profile. Subject: Consumer_to_provider. Reverse Filter Ports & Both Directions: True. |
| **Contract** | internal2web_CT | `Tenants > DMAC > Contracts > Standard` | Scope: App Profile. Subject: web2App_SBJ. Reverse Filter Ports & Both Directions: True. |
| **EPG Contract Assoc.** | *Varies* | `Tenants > DMAC > App Profiles > Web_AP > App EPGs > [EPG] > Contracts` | `web2App_CT` -> Provider: AppSrv_EPG, Consumer: WebSrv_EPG. |
