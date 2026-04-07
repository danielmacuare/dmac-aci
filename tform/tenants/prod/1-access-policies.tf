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
  name                      = "DMACProd_PhysDom"
  relation_infra_rs_vlan_ns = aci_vlan_pool.prod_vlan_pool.id # Binds VLAN pool to physical domain
}


# AAEP (Attachable Access Entity Profile)

resource "aci_attachable_access_entity_profile" "dmacprod_aaep" {
  name        = "DMACProd_AAEP"
  description = "${var.tform_managed} - AAEP DMAC Prod"
  relation_infra_rs_dom_p = [aci_physical_domain.dmac_prod.id] # Binds AAEP to physical domain
}

# Enable CDP, LLDP, LACP and 10G_SPEED for the Policy Group:

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
  mode        = "active"
}

resource "aci_fabric_if_pol" "ten_gig_speed" {
  name        = "10G_SPEED"
  description = "${var.tform_managed} - 10G Speed"
  speed       = "10G"
}

# Create Interface vPC Policy Groups

resource "aci_leaf_access_bundle_policy_group" "esxilab01_VPC" {
  name                            = "ESXILab01_VPC"
  description = "${var.tform_managed} - Interface vPC Policy Group ESXILab01_VPC"
  lag_t       = "node" #node for vCP, link for single switches Port Channel
  relation_infra_rs_cdp_if_pol  = aci_cdp_interface_policy.cdp_enable.id
  relation_infra_rs_lldp_if_pol = aci_lldp_interface_policy.lldp_enable.id
  relation_infra_rs_lacp_pol    = aci_lacp_policy.lacp_active.id
  relation_infra_rs_att_ent_p   = aci_attachable_access_entity_profile.dmacprod_aaep.id
  relation_infra_rs_h_if_pol    = aci_fabric_if_pol.ten_gig_speed.id
}

resource "aci_leaf_access_bundle_policy_group" "esxilab02_VPC" {
  name                            = "ESXILab02_VPC"
  description = "${var.tform_managed} - Interface vPC Policy Group ESXILab02_VPC"
  lag_t       = "node" #node for vCP, link for single switches Port Channel
  relation_infra_rs_cdp_if_pol  = aci_cdp_interface_policy.cdp_enable.id
  relation_infra_rs_lldp_if_pol = aci_lldp_interface_policy.lldp_enable.id
  relation_infra_rs_lacp_pol    = aci_lacp_policy.lacp_active.id
  relation_infra_rs_att_ent_p   = aci_attachable_access_entity_profile.dmacprod_aaep.id
  relation_infra_rs_h_if_pol    = aci_fabric_if_pol.ten_gig_speed.id
}

resource "aci_leaf_access_bundle_policy_group" "esxilab03_VPC" {
  name                            = "ESXILab03_VPC"
  description = "${var.tform_managed} - Interface vPC Policy Group ESXILab03_VPC"
  lag_t       = "node" #node for vCP, link for single switches Port Channel
  relation_infra_rs_cdp_if_pol  = aci_cdp_interface_policy.cdp_enable.id
  relation_infra_rs_lldp_if_pol = aci_lldp_interface_policy.lldp_enable.id
  relation_infra_rs_lacp_pol    = aci_lacp_policy.lacp_active.id
  relation_infra_rs_att_ent_p   = aci_attachable_access_entity_profile.dmacprod_aaep.id
  relation_infra_rs_h_if_pol    = aci_fabric_if_pol.ten_gig_speed.id
}


# Interface Profile 
resource "aci_leaf_interface_profile" "leaf101_102_ip" {
  name        = "Leaf101_102_IP"
  description = "${var.tform_managed} - Interface Profile L101 and L102"
}

# Port Selectors: Eth-1/31, Eth-1/32, Eth-1/33
# esxi-lab-01 (Eth-1/31)
resource "aci_access_port_selector" "esxilab01_port_1_31" {
  leaf_interface_profile_dn      = aci_leaf_interface_profile.leaf101_102_ip.id
  name                           = "eth1_31"
  description                    = "${var.tform_managed} - Port Selector ESXILab01 Eth1/31"
  access_port_selector_type      = "range"
  relation_infra_rs_acc_base_grp = aci_leaf_access_bundle_policy_group.esxilab01_VPC.id
}

resource "aci_access_port_block" "esxilab01_blk" {
  access_port_selector_dn = aci_access_port_selector.esxilab01_port_1_31.id
  name                    = "blk1"
  description             = "${var.tform_managed} - Port Block ESXILab01 Eth1/31"
  from_card               = "1"
  from_port               = "31" # Defines Port 1/31
  to_card                 = "1"
  to_port                 = "31"
}

# esxi-lab-02 (Eth-1/32)
resource "aci_access_port_selector" "esxilab02_port_1_32" {
  leaf_interface_profile_dn      = aci_leaf_interface_profile.leaf101_102_ip.id
  name                           = "eth1_32"
  description                    = "${var.tform_managed} - Port Selector ESXILab02 Eth1/32"
  access_port_selector_type      = "range"
  relation_infra_rs_acc_base_grp = aci_leaf_access_bundle_policy_group.esxilab02_VPC.id
}

resource "aci_access_port_block" "esxilab02_blk" {
  access_port_selector_dn = aci_access_port_selector.esxilab02_port_1_32.id
  name                    = "blk1"
  description             = "${var.tform_managed} - Port Block ESXILab02 Eth1/32"
  from_card               = "1"
  from_port               = "32" # Defines Port 1/32
  to_card                 = "1"
  to_port                 = "32"
}


# esxi-lab-03 (Eth-1/33)
resource "aci_access_port_selector" "esxilab03_port_1_33" {
  leaf_interface_profile_dn      = aci_leaf_interface_profile.leaf101_102_ip.id
  name                           = "eth1_33"
  description                    = "${var.tform_managed} - Port Selector ESXILab03 Eth1/33"
  access_port_selector_type      = "range"
  relation_infra_rs_acc_base_grp = aci_leaf_access_bundle_policy_group.esxilab03_VPC.id
}

resource "aci_access_port_block" "esxilab03_blk" {
  access_port_selector_dn = aci_access_port_selector.esxilab03_port_1_33.id
  name                    = "blk1"
  description             = "${var.tform_managed} - Port Block ESXILab03 Eth1/33"
  from_card               = "1"
  from_port               = "33" # Defines Port 1/33
  to_card                 = "1"
  to_port                 = "33"
}



# Switch Profile

resource "aci_leaf_profile" "leaf101_102_sp" {
  name                         = "Leaf101_102_SP"
  description                  = "${var.tform_managed} - Leaf Profile L101 and L102"
  relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.leaf101_102_ip.id]
}



# Leaf Selector - Associates the interface profile with the selector

resource "aci_leaf_selector" "leaf101_102_selector" {
  name                = "Leaf101_102_Selector"
  description         = "${var.tform_managed} - Leaf 101 and 102"
  switch_association_type = "range"
  leaf_profile_dn     = aci_leaf_profile.leaf101_102_sp.id
}


# Node Blocks - Actually selects the leave switches

resource "aci_node_block" "check" {
  switch_association_dn   = aci_leaf_selector.leaf101_102_selector.id
  name                    = "block"
  description             = "${var.tform_managed} - Node Block L101-L102"
  from_                   = "101"
  to_                     = "102"
}

# Output: The physical ports on Leaf 101 and 102 (vPC) are now awake, configured, and legally allowed to carry VLANs 400-500.
# But they are waiting for a Tenant to actually use them.