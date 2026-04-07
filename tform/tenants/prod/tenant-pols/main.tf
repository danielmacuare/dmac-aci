#Tenants

resource "aci_tenant" "dmacprod_tenant" {
  name        = "DmacProd"
  description = "${var.tform_managed} - DmacProd Tenant"
}

# VRFs Defintion

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

# Bridge Domains and Subnets




# Subnets