# ACI Terraform Deployment Guide

This repository contains Terraform configurations for deploying ACI infrastructure.

## Workflows

We will cover the following workflows:

- Inter-EPG Traffic between ESXi Hosts (Prod VRF) and Network Services (Shared VRF)
- Receive and advertise routes between the ACI Fabric and NSX-T using L3OUT constructs

## Assumptions

- Node Policies and Fabric Policies are already configured

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

- [x] Bind EPG to Domain (Pushes VLANs to the switch)
- [x] Bind EPGs to VPC Static Paths

## Docs

- [How It Works](docs/how-it-works.md)
- [Fabric Object Names](docs/fabric-object-names.md)
