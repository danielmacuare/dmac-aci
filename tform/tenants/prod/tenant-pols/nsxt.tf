
################################################################
# Define NSX-T L3 Out
################################################################
resource "aci_l3_outside" "nsxt_l3out" {
  tenant_dn   = aci_tenant.dmacprod_tenant.id
  name        = "NSXT_L3Out"
  description = "${var.tform_managed} - Direct Peering to NSX-T Tier-0"
  
  # 1. Bind to your existing Production VRF
  relation_l3ext_rs_ectx = aci_vrf.dmacprod_vrf.id
  
  # 2. Bind to the L3 Domain we created in the Access Policies
  relation_l3ext_rs_l3_dom_att = data.aci_l3_domain_profile.nsxt_ext_domain.id
  
  # 3. Enable BGP Route Export (Required to send routes to NSX-T)
  enforce_rtctrl = ["export"] 
}

################################################################
# Define Logical Node Profiles for NSX-T L3 Out
################################################################

resource "aci_logical_node_profile" "nsxt_l3out" {
  l3_outside_dn = aci_l3_outside.nsxt_l3out.id
  name          = "NSXTL3OUT_NodeProfile"
  description   = "${var.tform_managed} - Logical Node Profile for NSX-T L3 Out"
}

# Attach Logical node to Border Leaf101 and 102
resource "aci_logical_node_to_fabric_node" "nsxt_nodes" {
  for_each = local.nsxt_interfaces

  logical_node_profile_dn = aci_logical_node_profile.nsxt_l3out.id
  
  tdn                     = each.value.topology_path
  
  rtr_id                  = each.value.router_id
  rtr_id_loop_back        = "yes"
}

################################################################
# Logical Interface Profiles & SVIs for NSX-T L3 Out
################################################################

resource "aci_logical_interface_profile" "nsxt_l3out_intprof" {
  logical_node_profile_dn = aci_logical_node_profile.nsxt_l3out.id
  name                    = "NSXTL3OUT_InterfaceProfile"
  description             = "${var.tform_managed} - Logical Interface Profile for NSX-T L3 Out"
}

# Attach Paths to Border Leafs dynamically
resource "aci_l3out_path_attachment" "nsxt_paths" {
  for_each = local.nsxt_interfaces

  logical_interface_profile_dn = aci_logical_interface_profile.nsxt_l3out_intprof.id
  
  target_dn                    = each.value.interface_path
  addr                         = each.value.ip
  
  if_inst_t                    = "ext-svi"
  encap                        = "vlan-405"
}