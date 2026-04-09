################################################################
# eSXI Cluster Inventory (Target vPCs - Interface Policy Groups)
################################################################

locals {
  # The list of vPC bundles for your 3 ESXi hosts
  esxi_vpcs = [
    "topology/pod-1/protpaths-101-102/pathep-[ESXILab01_VPC]",
    "topology/pod-1/protpaths-101-102/pathep-[ESXILab02_VPC]",
    "topology/pod-1/protpaths-101-102/pathep-[ESXILab03_VPC]"
  ]
  
  nsxt_border_leaves = {
    leaf101 = { 
      topology_path = "topology/pod-1/node-101"
      interface_path = "topology/pod-1/paths-101/pathep-[eth1/45]"
      ip   = "10.60.10.1/29"
      peer_ip = "10.60.10.2"
      router_id = "1.1.1.101"
      remote_asn = "65002"
      received_prefixes = ["10.40.0.0/16", "10.50.0.0/16", "10.60.0.0/16"]
    }
    leaf102 = { 
      topology_path = "topology/pod-1/node-102"
      interface_path = "topology/pod-1/paths-102/pathep-[eth1/46]"
      ip   = "10.60.10.3/29"
      peer_ip = "10.60.10.4"
      router_id = "1.1.1.102"
      remote_asn = "65003"
      received_prefixes = ["10.40.0.0/16", "10.50.0.0/16", "10.60.0.0/16"]
    }
  }
  # toset - Elimiantes all duplicates
  # flatten - Creates a single list with all the elements matches in the loop
  nsxt_received_prefixes = toset(flatten([
    for node in local.nsxt_border_leaves : node.received_prefixes
  ]))
}