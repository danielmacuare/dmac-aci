# Notes: We can use the API inspector to see how to relate objects
# /settings / show API Inspector

#Vlan Pool

resource "aci_vlan_pool" "prod_vlan_pool" {
  name  = "DmacProd_StaticVLPool"
  description   = "${var.tform_managed} - VLAN Pool DMAC Prod"
  alloc_mode  = "static"
}

resource "aci_ranges" "prod_aci_ranges" {
  vlan_pool_dn  = aci_vlan_pool.prod_vlan_pool.id
  description   = "${var.tform_managed} - VLAN ACI Ranges"
  from          = "vlan-400"
  to            = "vlan-500"
  alloc_mode    = "static"
  role          = "external"
}


# Physical Domain
resource "aci_physical_domain" "dmac_prod" {
  name = "DMACProd_PhysDom"
  relation_infra_rs_vlan_ns = aci_vlan_pool.prod_vlan_pool.id # Binds VLAN pool to physical domain
}


# AAEP (Attachable Access Entity Profile)

resource "aci_attachable_access_entity_profile" "dmacprod_aaep" {
  name        = "DMACProd_AAEP"
  description = "${var.tform_managed} - AAEP DMAC Prod"
  relation_infra_rs_dom_p = [aci_physical_domain.dmac_prod.id] # Binds AAEP to physical domain
}

# Enable CDP, LLDP, LACP for the Policy Group:

resource "aci_cdp_interface_policy" "cdp_enable" {
  name        = "CDP_Enable"
  description = "${var.tform_managed} - CDP Enable"
}

resource "aci_lldp_interface_policy" "lldp_enable" {
  name        = "LLDP_Enable"
  description = "${var.tform_managed} - LLDP Enable"
}

resource "aci_lacp_policy" "lacp_active" {
  name        = "LACP_Enable"
  description = "${var.tform_managed} - LACP Enable"
}

# Create Interface vPC Policy Groups

resource "aci_leaf_access_bundle_policy_group" "ESXILab01_VPC" {
  name                            = "ESXILab01_VPC"
  description = "${var.tform_managed} - Interface vPC Policy Group ESXILab01_VPC"
  lag_t       = "node" #node for vCP, link for single switches Port Channel
  relation_infra_rs_cdp_if_pol  = aci_cdp_interface_policy.cdp_enable.id
  relation_infra_rs_lldp_if_pol = aci_lldp_interface_policy.lldp_enable.id
  relation_infra_rs_lacp_pol    = aci_lacp_policy.lacp_active.id
  relation_infra_rs_att_ent_p   = aci_attachable_access_entity_profile.dmacprod_aaep.id
}


# Interface Profile (Por Selectors)


# Switch Profile
#resource "aci_leaf_profile" "example" {
  #name        = "Leaf101_102_SP"
  #description  = "${var.tform_managed} - Switch Profile Leaf101_102_SP"
  #leaf_selector {
    #name                    = "leaf101"
    #switch_association_type = "range" # ALL, range or ALL_IN_POD
    #node_block {
      #name  = "blk1"
      #from_ = "101"
      #to_   = "102"
    #}
    #node_block {
      #name  = "blk2"
      #from_ = "103"
      #to_   = "104"
    #}
  #}
  #leaf_selector {
    #name                    = "leaf102"
    #switch_association_type = "range"
    #node_block {
      #name  = "blk3"
      #from_ = "105"
      #to_   = "107"
    #}
  #}
#}







# Output: The physical ports on Leaf 101 are now awake, configured, and legally allowed to carry VLANs 31-40. But they are waiting for a Tenant to actually use them.