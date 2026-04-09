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
  
  nsxt_interfaces = {
    leaf101 = { 
      topology_path = "topology/pod-1/node-101"
      interface_path = "topology/pod-1/paths-101/pathep-[eth1/45]"
      ip   = "10.60.10.1/30"
      router_id = "1.1.1.101"
    }
    leaf102 = { 
      topology_path = "topology/pod-1/node-102"
      interface_path = "topology/pod-1/paths-102/pathep-[eth1/46]"
      ip   = "10.60.10.2/30"
      router_id = "1.1.1.102"
    }
  }
}