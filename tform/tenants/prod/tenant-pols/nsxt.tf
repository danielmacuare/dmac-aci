

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