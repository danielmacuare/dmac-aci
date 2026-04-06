variable "user" {
  description = "Login information for Cisco ACI Sandbox"
  sensitive = true
  type        = object({
    username = string
    password = string
    url      = string
  })
}