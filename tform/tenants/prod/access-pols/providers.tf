terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = "2.18.0"
    }
  }
}

# Configure the provider with your Cisco APIC credentials.
provider "aci" {
  # APIC Username
  username = var.user.username
  # APIC Password
  password = var.user.password
  # APIC URL
  url      = var.user.url
  insecure = true
}