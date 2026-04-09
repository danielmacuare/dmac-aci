# ACI Terraform Deployment Guide

This repository contains Terraform configurations for deploying ACI infrastructure.

## Workflows

We will cover the following workflows:

- Inter-EPG Traffic between ESXi Hosts (Prod VRF) and Network Services (Shared VRF)
- Receive and advertise routes between the ACI Fabric and NSX-T using L3OUT constructs
- If time allows:
  - Policies using ESG instead of EPGs
  - Dynamic Policies using Tags instead of manually defining the EPGs in the contracts

## Assumptions

- Node Policies and Fabric Policies are already configured
- RR Policies are already configured to distribute routes to all the Leaves. Spines shoulb be configured as RR to distribute routes to all the Leaves.

## Build Steps

### Phase 0 - Pre-Requisites

1 - To test this ACI Fabric deployment using terraform, we will use the always-on sandbox environment provided by Cisco.

To book the sandbox visit: <https://devnetsandbox.cisco.com/DevNet/catalog/ACI-Simulator-Always-On_aci-simulator-always-on>

Creds are configured in each terraform folder using the following file:

- Filename: `secrets.auto.tfvars`

```terraform
user = {
    username = "admin"
    password = "MYPASSWORD"
    url = "https://sandboxapicdc.cisco.com"
}
```

2 - Install terraform

### Phase 1 (Access Policies)

[Access Policies](tform/tenants/prod/access-pols/main.tf)

![Access Policies](resources/1-Access%20Policies.png)

- [x] Vlan Pool
- [x] Physical Domain
  - Bind VLAN Pool to Physical Domain
- [x] AAEP (Attachable Access Entity Profile)
  - Bind AAEP to Physical Domain
- [x] Interface Policy Group (Port Channels)
  - VPC Interface
  - Enable CDP, LLDP, LACP and 10G Speed Policies for the Policy Group
  - 1 Policy Group per each vPC Port
    - ESXILab01_VPC (Done)
    - ESXILab02_VPC (Done)
    - ESXILab03_VPC (Done)
- [x] Interface Profiles (Pick the Switch Ports) - One for the 2 Leaves
  - [x] Port Selectors (One per interface)
  - You need to use `aci_access_port_selector`
  - Here you will select the Eth-1/31 port and will associate it to esxilab01 vPC Policy Group
  - Here you will select the Eth-1/32 port and will associate it to esxilab02 vPC Policy Group
  - Here you will select the Eth-1/33 port and will associate it to esxilab03 vPC Policy Group
- [x] Switch Profile
  - [x] Create a switch Profile (Only need one Profile for the 2 Leaves - vPC)
  - [x] Create Interface Port Selector
  - [x] Associate a Block that targets Leaf 101-102

### Phase 2 (Tenant Policies)

[Tenant Policies](tform/tenants/prod/tenant-pols/main.tf)

![Tenant Policies](resources/2-Tenant%20Policies.png)

- [x] Tenant
- [x] VRF
- [x] Bridge Domains
- [x] Application Profiles (Like Organizational Folders) to group similar EPGs.
- [x] EPGs
- [x] Filters
- [x] Contracts and Contract Subjects
- [x] Bind Contracts, Contracts Subjects and Filters
- [x] Associate Contract with Consumer and Provider EPGs

### Phase 3 (Bind Physical + Logical Layer)

![Physical Topology](resources/3-Physical%20Topology.png)

- Bind EPG to Domain (Pushes VLANs to the switch)
- Bind EPGs to VPC Static Paths

### Phase 4 L3 OUT

#### DATA

- ACI: 10.60.10.1/29 (VLAN 405) - Eth1/45 - Leaf101 - ASN 65001 - Router ID: 1.1.1.101
- ACI: 10.60.10.3/29 (VLAN 405) - Eth1/46 - Leaf102 - ASN 65001 - Router ID: 1.1.1.102
- NSX - Node 1: 10.60.10.2/29 (VLAN 405) - ASN 65002
- NSX - Node 2: 10.60.10.4/29 (VLAN 405) - ASN 65003

#### Access Policies (Physical Side)

- Create VLAN Pool - VLAN 405 - Already exists: (D)
- Create L3 Domain (External Routed Domain): DmacProdNSX_L3Domain (D)
- Create AAEP:  NSXT_AAEP (D)
- Create interface profile: Which interface I want to configure and how? (D)
  - Interface/Port Selector and blocks:
    - Et-1/45 ACI Side
    - Et-1/46 ACI Side
  - Access Port Policy Group
    - SPEED10G
    - CDP
    - AAEP
- Assign Interface Profile to the Switch Profile (Already done)

#### L3OUT and L3OUT EPG (Logical Config)

- We create the L3OUT (D)
  - Bind it to the Prod_VRF
  - Attach it to the NSXT_L3Domain
    - We enable BGP
- Assign L3OUT to Border Leaf (D)
  - Logical Node Profile (Assign it to Leaves, enable Loopbacks and configure Router ID)
- Define SVIs on the Leaves Ports (D)
  - Interface Profile
  - Path Attachment
- Define BGP Connectivity Profile (D)
  - Remote ASN
  - Remote IP
- Define external EPG (D)
  - Define EPG
  - Add L3 Subnets to the EPG
    - On
    - **shared-rtctrl** **(Shared Route Control Subnet):** This indicates that the network learned from the outside (in your case, NSX-T), can be leaked to other VRF instances, assuming they have a contract with this external EPG.
    - **shared-security** **(Shared Security Import Subnet):** This defines which subnets learned from a shared VRF belong to this external EPG so that cross-VRF contract filtering can be applied properly.I
- Create contracts to allow internal to external and the other way around
  - Create contract and filters
    - scope = "tenant" because we want to leak these routes into the Shared VRF.
    - Filters: 80, 443, 3306 and ICMP Ping
  - Bind the contract to the external EPG (Provider)
  - Bind the contract to the Compute EPGs (Consumers)

## Docs

- [How It Works](docs/how-it-works.md)
- [Fabric Object Names](docs/fabric-object-names.md)

## TO Improve

- [ ] Split main.tf files in manageable files with logical groupings
