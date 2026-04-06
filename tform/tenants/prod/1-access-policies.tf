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

# AAEP (Attachable Access Entity Profile)

# Interface Policy Group

# Interface Profile

# Switch Profile

# Output: The physical ports on Leaf 101 are now awake, configured, and legally allowed to carry VLANs 31-40. But they are waiting for a Tenant to actually use them.