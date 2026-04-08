locals {
  esxi_hosts = {
    esxilab01 = {
      display_name = "ESXILab01"
      port         = "25"
    }
    esxilab02 = {
      display_name = "ESXILab02"
      port         = "26"
    }
    esxilab03 = {
      display_name = "ESXILab03"
      port         = "27"
    }
  }
  nsxt_edge_uplinks = {
    edge01 = {
      display_name = "NSXTEdge01"
      port         = "45"
    },
    edge02 = {
      display_name = "NSXTEdge02"
      port         = "46"
    }
  }
}
