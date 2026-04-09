
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
  for_each = local.nsxt_border_leaves

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
  for_each = local.nsxt_border_leaves

  logical_interface_profile_dn = aci_logical_interface_profile.nsxt_l3out_intprof.id
  
  target_dn                    = each.value.interface_path
  addr                         = each.value.ip
  
  #L3 Routed sub interfaces are p2p connections so leaf101 and leaf102 can't share the same /29 segment.
  # Since we are building a common L2 Domain for all BGP peers, we need to use an SVI here "ext-svi". 
  if_inst_t                    = "ext-svi"
  encap                        = "vlan-405"
}

################################################################
# BGP Peer Connectivity Profile for NSX-T L3 Out
################################################################

resource "aci_bgp_peer_connectivity_profile" "nsxt_bgp_peer" {
  for_each = local.nsxt_border_leaves

  parent_dn = aci_l3out_path_attachment.nsxt_paths[each.key].id

  addr      = each.value.peer_ip
  as_number = each.value.remote_asn
}

################################################################
# External EPG Container and subnets for NSX-T Workloads
################################################################

resource "aci_external_network_instance_profile" "nsxt_ext_epg" {
  l3_outside_dn = aci_l3_outside.nsxt_l3out.id
  name          = "NSXT_ExtEPG"
  description   = "${var.tform_managed} - External EPG for NSX-T Workloads"
}

resource "aci_l3_ext_subnet" "nsxt_catch_all_subnet" {


  for_each = local.nsxt_received_prefixes
  external_network_instance_profile_dn = aci_external_network_instance_profile.nsxt_ext_epg.id
  
  ip                                   = each.value
  
  # CRITICAL: 'import-security' is required to allow Contracts to apply to this subnet
  scope                                = ["import-security"] 
}