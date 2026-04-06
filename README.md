# ACI Terraform Deployment Guide

This repository contains Terraform configurations for deploying ACI infrastructure.

## Build Steps

### Phase 1 (Access Policies)

- Goal: I want to configure some physical ports on a switch to be ready to accept traffic. The SVIs (Distributed Anycast Gateways will be configured in the ACI side).

- Vlan Pool
- Physical Domain
- AAEP (Attachable Access Entity Profile)
- Interface Policy Group
- Interface Profile
- Switch Profile (Leaf101_SP)
  - (Once per switch)
  - Per each vPC (Virtual Port Channel)
- Output: The physical ports on Leaf 101 are now awake, configured, and legally allowed to carry VLANs 31-40. But they are waiting for a Tenant to actually use them.

### Phase 2 (Tenant Policies)

#### 2.1 - Network Constructs

- Tenant
- VRF
- Bridge Domains

#### 2.2 - Map Apps to Ports

- Application Profile
- EPGs
- Domain Binding (EPGs to Physical Domains)
- Static Ports

#### 2.3 - Security

- Filters
- Contracts
- Contract Association (Associate to Provider and Consumer EPGs)
