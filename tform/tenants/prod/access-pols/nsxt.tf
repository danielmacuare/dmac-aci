
# Create L3 Domain Profile for NSX-T
resource "aci_l3_domain_profile" "nsxt_ext_domain" {
  name = "DmacProdNSX_L3Domain"

  relation_infra_rs_vlan_ns = aci_vlan_pool.prod_vlan_pool.id
}


# Create Interface Access Port Policy Group for NSX-T Edge Uplinks
resource "aci_leaf_access_port_policy_group" "nsxt_edge_pg" {
  for_each = local.nsxt_edge_uplinks

  name        = "${each.value.display_name}_PG"
  description = "${var.tform_managed} - NSX-T Edge Uplink ${each.value.display_name}"

  relation_infra_rs_cdp_if_pol  = aci_cdp_interface_policy.cdp_enable.id
  relation_infra_rs_lldp_if_pol = aci_lldp_interface_policy.lldp_enable.id
  relation_infra_rs_att_ent_p   = aci_attachable_access_entity_profile.dmacprod_aaep.id
  relation_infra_rs_h_if_pol    = aci_fabric_if_pol.ten_gig_speed.id
}

# Port Selectors and Port Blocks for NSX-T Edge Uplinks
resource "aci_access_port_selector" "nsxt_edge_port" {
  for_each = local.nsxt_edge_uplinks

  leaf_interface_profile_dn = aci_leaf_interface_profile.leaf101_102_ip.id

  name                      = "eth1_${each.value.port}"
  description               = "${var.tform_managed} - Port Selector ${each.value.display_name} Eth1/${each.value.port}"
  access_port_selector_type = "range"

  relation_infra_rs_acc_base_grp = aci_leaf_access_port_policy_group.nsxt_edge_pg[each.key].id
}

resource "aci_access_port_block" "nsxt_edge_port_block" {
  for_each    = local.nsxt_edge_uplinks
  description = "${var.tform_managed} - Port Block ${each.value.display_name} Eth1/${each.value.port}"

  access_port_selector_dn = aci_access_port_selector.nsxt_edge_port[each.key].id
  name                    = "blk1"
  from_card               = "1"
  from_port               = each.value.port
  to_card                 = "1"
  to_port                 = each.value.port
}