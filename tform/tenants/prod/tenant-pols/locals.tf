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
}