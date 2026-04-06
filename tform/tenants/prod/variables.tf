variable "user" {
  description = "Login information for Cisco ACI Sandbox"
  sensitive = true
  type        = object({
    username = string
    password = string
    url      = string
  })
}

variable "tform_managed" {
  description = "Standard annotation for Terraform-managed objects"
  type        = string
  default     = "This object is managed by Terraform"
}