# Naming Conventions

This doc will be used as a reference for naming conventions in this repository. It will be based on a doc published by Cisco but with some small modifications for our use case.

Source: <https://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/application-centric-infrastructure/aci-guide-naming-convention-best-practices.pdf>

## General Rules

- Delimiter = Underscore `_`
- Capitalize Separate Words
  - Example: - Leaf201_SwProf or lf201_SwProf
  - Example: - TenantX_VlanPoolStatic

## Fabric Devices

- Leaf-Spine Numbering
  - Spines: 100 - 199
  - Pod1Leafs: 200 - 299
  - Pod2Leafs: 300 - 399

## Access Policies

- VLAN Pool (D)
  - GUI: Fabric > Access Policies > Pools > Vlan Pools
  - Example: DmacProd_StaticVLPool
  - Description: DMAC VLAN Pool for Production

- AAEP (Attachable Access Entity Profiles)
  - Example: ProdPorts_AAEP
  - Description: Prod Ports AAEP
  - Physcial Domains
    - Examples: Prod_PHYDOM

## Tenant Policies

- Tenants
  - When using VMM Domains: “Tenant | Application Profile | EPG” name will be displayed in Vcenter as portgroup names.
  - Customer Name: Enterprise
  - Tenant Name: EntProd; EntTest; EntDev
- Application Profiles
  - Examples: Web_AP, Db_AP,
- EPG
  - Examples:
    - Grouping(s): Web, Vlan 101, Management, PXE
    - EPG Name(s): Web_EPG, Vl101_EPG, Mgmt_EPG
- VRF
  - Examples: Prod_VRF, Dev_VRF
- Bridge Domain
  - Examples: Web_BD, Vl101_BD, Mgmt_BD, PXE_BD
- Contracts
  - Examples: http_CT, https_CT, mysql_CT
- Filters
  - Examples: web_FILT , icmp_FILT, dbs_FILT
  - Entries
    - web_FILT
      - httpTcp80
      - httpsTcp443
      - httpTcp8080
    - dbs_FILT
      - mysqlTcp3306
      - postgresTcp5432
      - mongoTcp27017
