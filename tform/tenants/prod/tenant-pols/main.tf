################################################################
#Tenants
################################################################

resource "aci_tenant" "dmacprod_tenant" {
  name        = "DMACProd"
  description = "${var.tform_managed} - DMACProd Tenant"
}
################################################################
# VRFs Defintion
################################################################

resource "aci_vrf" "dmacprod_vrf_pci" {
  parent_dn                       = aci_tenant.dmacprod_tenant.id
  name                            = "PCI_VRF"
  description                     = "${var.tform_managed} - PCI VRF"
  policy_control_enforcement_mode = "enforced"
}

resource "aci_vrf" "dmacprod_vrf_shared" {
  parent_dn                       = aci_tenant.dmacprod_tenant.id
  name                            = "Shared_VRF"
  description                     = "${var.tform_managed} - Shared VRF"
  policy_control_enforcement_mode = "enforced"
}

resource "aci_vrf" "dmacprod_vrf" {
  parent_dn                       = aci_tenant.dmacprod_tenant.id
  name                            = "Prod_VRF"
  description                     = "${var.tform_managed} - Prod VRF"
  policy_control_enforcement_mode = "enforced"
}

resource "aci_vrf" "dmacprod_vrf_storage" {
  parent_dn                       = aci_tenant.dmacprod_tenant.id
  name                            = "Storage_VRF"
  description                     = "${var.tform_managed} - Storage VRF"
  policy_control_enforcement_mode = "enforced"
}


resource "aci_vrf" "dmacprod_vrf_external" {
  parent_dn                       = aci_tenant.dmacprod_tenant.id
  name                            = "External_VRF"
  description                     = "${var.tform_managed} - External VRF"
  policy_control_enforcement_mode = "enforced"
}

################################################################
# Bridge Domains and Subnets
################################################################

# Shared Network Services Bridge Domain and Subnet
resource "aci_bridge_domain" "bd_netservices" {
  parent_dn       = aci_tenant.dmacprod_tenant.id
  name            = "NetServices_BD"
  description     = "${var.tform_managed} - Shared Network Services Bridge Domain"
  unicast_routing = "yes"
  arp_flooding    = "yes"

  relation_to_vrf = {
    vrf_name = aci_vrf.dmacprod_vrf_shared.name
  }
}

resource "aci_subnet" "sub_netservices" {
  parent_dn = aci_bridge_domain.bd_netservices.id
  ip        = "10.20.0.1/24"
  description = "${var.tform_managed} - Gateway for Shared Network Services"
  # shared=route leaking + public=L3Out advertisement
  scope     = ["shared", "public"]
}


# App Compute 01 Bridge Domain and Subnet
resource "aci_bridge_domain" "bd_compute01" {
  parent_dn       = aci_tenant.dmacprod_tenant.id
  name            = "Compute01_BD"
  description     = "${var.tform_managed} - Compute 01 Bridge Domain"
  unicast_routing = "yes"
  arp_flooding    = "yes"

  relation_to_vrf = {
    vrf_name = aci_vrf.dmacprod_vrf.name
  }
}

resource "aci_subnet" "sub_compute01" {
  parent_dn   = aci_bridge_domain.bd_compute01.id
  ip          = "10.10.0.1/24"
  description = "${var.tform_managed} - Gateway for Compute 01"
  scope       = ["public"]
}

# App Compute 02 Bridge Domain and Subnet
resource "aci_bridge_domain" "bd_compute02" {
  parent_dn       = aci_tenant.dmacprod_tenant.id
  name            = "Compute02_BD"
  description     = "${var.tform_managed} - Compute 02 Bridge Domain"
  unicast_routing = "yes"
  arp_flooding    = "yes"

  relation_to_vrf = {
    vrf_name = aci_vrf.dmacprod_vrf.name
  }
}

resource "aci_subnet" "sub_compute02" {
  parent_dn   = aci_bridge_domain.bd_compute02.id
  ip          = "10.10.1.1/24"
  description = "${var.tform_managed} - Gateway for Compute 02"
  scope       = ["public"]
}


# Storage Bridge Domain and Subnet
resource "aci_bridge_domain" "bd_storage" {
  parent_dn       = aci_tenant.dmacprod_tenant.id
  name            = "Storage_BD"
  description     = "${var.tform_managed} - Storage Bridge Domain"
  unicast_routing = "yes"
  arp_flooding    = "yes"

  relation_to_vrf = {
    vrf_name = aci_vrf.dmacprod_vrf_storage.name
  }
}

resource "aci_subnet" "sub_storage" {
  parent_dn   = aci_bridge_domain.bd_storage.id
  ip          = "10.30.0.1/24"
  description = "${var.tform_managed} - Gateway for Storage Traffic"
  scope       = ["private"]
}

################################################################
# App Profiles
################################################################

resource "aci_application_profile" "ap_netservices" {
  parent_dn   = aci_tenant.dmacprod_tenant.id
  name        = "NetServices_AP"
  description = "${var.tform_managed} - Shared Services Application Profile"
}

resource "aci_application_profile" "ap_compute" {
  parent_dn   = aci_tenant.dmacprod_tenant.id
  name        = "Compute_AP"
  description = "${var.tform_managed} - Compute Application Profile"
}


################################################################
# EPGs
################################################################

resource "aci_application_epg" "epg_netservices" {
  parent_dn   = aci_application_profile.ap_netservices.id
  name        = "NetServices_EPG"
  description = "${var.tform_managed} - Net Services EPG"

  relation_to_bridge_domain = {
    bridge_domain_name = aci_bridge_domain.bd_netservices.name
  }
}

resource "aci_application_epg" "epg_compute01" {
  parent_dn   = aci_application_profile.ap_compute.id
  name        = "Compute01_EPG"
  description = "${var.tform_managed} - Compute01 EPG"

  relation_to_bridge_domain = {
    bridge_domain_name = aci_bridge_domain.bd_compute01.name
  }
}

resource "aci_application_epg" "epg_compute02" {
  parent_dn   = aci_application_profile.ap_compute.id
  name        = "Compute02_EPG"
  description = "${var.tform_managed} - Compute02 EPG"

  relation_to_bridge_domain = {
    bridge_domain_name = aci_bridge_domain.bd_compute02.name
  }
}

################################################################
# Filters and Filter Entries
################################################################
# DNS
resource "aci_filter" "filter_dns" {
  tenant_dn   = aci_tenant.dmacprod_tenant.id
  name        = "DNS_Filter"
  description = "${var.tform_managed} - DNS Filter"
}

resource "aci_filter_entry" "dns_udp_53" {
  filter_dn   = aci_filter.filter_dns.id
  name        = "udp_53"
  ether_t     = "ip"
  prot        = "udp"
  d_from_port = "53"
  d_to_port   = "53"
}

resource "aci_filter_entry" "dns_tcp_53" {
  filter_dn   = aci_filter.filter_dns.id
  name        = "tcp_53"
  ether_t     = "ip"
  prot        = "tcp"
  d_from_port = "53"
  d_to_port   = "53"
}

# DHCP
resource "aci_filter" "filter_dhcp" {
  tenant_dn   = aci_tenant.dmacprod_tenant.id
  name        = "DHCP_Filter"
  description = "${var.tform_managed} - Allow DHCP Traffic"
}

resource "aci_filter_entry" "dhcp_udp_67" {
  filter_dn   = aci_filter.filter_dhcp.id
  name        = "udp_67"
  # ether_t "ip" covers standard IPv4 routing
  ether_t     = "ip" 
  prot        = "udp"
  d_from_port = "67"
  d_to_port   = "67"
}

resource "aci_filter_entry" "dhcpv6_udp_546" {
  filter_dn   = aci_filter.filter_dhcp.id
  name        = "udp_546"
  ether_t     = "ipv6" 
  prot        = "udp"
  d_from_port = "546"
  d_to_port   = "546"
}

# IPv6 Server (UDP 547)
resource "aci_filter_entry" "dhcpv6_udp_547" {
  filter_dn   = aci_filter.filter_dhcp.id
  name        = "udp_547"
  ether_t     = "ipv6" 
  prot        = "udp"
  d_from_port = "547"
  d_to_port   = "547"
}


################################################################
# Contract Definitions and Contract Subjects
################################################################

resource "aci_contract" "contract_network_services" {
  tenant_dn   = aci_tenant.dmacprod_tenant.id
  name        = "NetworkServices_Contract"
  description = "${var.tform_managed} - Allow Network Services (DNS, DHCP, Etc.)"
  
  scope       = "tenant" # To allow route leaking between Prod and Shared VRFs
}

resource "aci_contract_subject" "subject_network_services" {
  contract_dn = aci_contract.contract_network_services.id
  name        = "NetworkServices_Subject"
}

resource "aci_contract_subject_filter" "bind_dns" {
  contract_subject_dn = aci_contract_subject.subject_network_services.id
  filter_dn           = aci_filter.filter_dns.id
  action              = "permit"
}

resource "aci_contract_subject_filter" "bind_dhcp" {
  contract_subject_dn = aci_contract_subject.subject_network_services.id
  filter_dn           = aci_filter.filter_dhcp.id
  action              = "permit"
  directives          = ["log"] # To Log DHCP traffic
}


################################################################
# Contract Bindings (Consumer -> Provider)
################################################################

# NetServices EPG Provider
resource "aci_epg_to_contract" "provide_network_services" {
  application_epg_dn = aci_application_epg.epg_netservices.id
  contract_dn        = aci_contract.contract_network_services.id
  contract_type      = "provider"
}

# Consumers EPGs
resource "aci_epg_to_contract" "compute01_to_netservices" {
  application_epg_dn = aci_application_epg.epg_compute01.id
  contract_dn        = aci_contract.contract_network_services.id
  contract_type      = "consumer"
}

resource "aci_epg_to_contract" "compute02_to_netservices" {
  application_epg_dn = aci_application_epg.epg_compute02.id
  contract_dn        = aci_contract.contract_network_services.id
  contract_type      = "consumer"
}
