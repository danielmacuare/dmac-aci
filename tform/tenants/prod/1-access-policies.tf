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

# Bind AAEP to Physical Domain

resource "aci_aaep_to_domain" "dmacprod_aaep_to_phydom" {
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.dmacprod_aaep.id
  domain_dn                           = aci_physical_domain.dmac_prod.id
}


# Interface Policy Group

# Interface Profile

# Switch Profile

# Output: The physical ports on Leaf 101 are now awake, configured, and legally allowed to carry VLANs 31-40. But they are waiting for a Tenant to actually use them.