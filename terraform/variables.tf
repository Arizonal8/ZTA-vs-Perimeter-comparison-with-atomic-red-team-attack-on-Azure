variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "UK South"
}

variable "subscription_id" {
  description = "Azure subscription ID hosting the research environment"
  type        = string
}

variable "admin_username" {
  description = "Local administrator username for all VMs"
  type        = string
  default     = "researchadmin"
}

variable "admin_password" {
  description = "Local administrator password for all VMs (set via terraform.tfvars, never committed)"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "VM SKU used for all five virtual machines"
  type        = string
  default     = "Standard_D2s_v3"
}
