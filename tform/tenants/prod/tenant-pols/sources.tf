################################################################
# Data Sources
################################################################

data "aci_physical_domain" "dmac_prod" {
  name = "DMACProd_PhysDom"
}

data "aci_l3_domain_profile" "nsxt_ext_domain" {
  name = "DmacProdNSX_L3Domain"
}
