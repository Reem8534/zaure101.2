variable "prefix" {
  description = "The prefix which should be used for all resources in this deployment"
  default     = "webapp"
}

variable "location" {
  description = "The azure region in which all resources in this deployment should be created."
  default     = "eastus"
}

variable "number_of_vms" {
  description = "Number of VMs to provision"
  type        = number
  default     = 3
}

variable "admin_username" {
  description = "The admin username for the VMs"
  default     = "reemadmin"
}

variable "admin_password" {
  description = "The admin password for the VMs"
  default     = "NewP@ssw0rd123!"
}
#were not used
variable "address_space" {
  description = "VNET address space"
  default     = ["10.4.0.0/16"]
}
#were not used
variable "subnet" {
  description = "Subnet address space"
  default     = ["10.4.0.0/24"]
}

variable "environment" {
  description = "Environment tag, e.g. prod, dev"
  default     = "dev"
}

variable "project" {
  description = "Project tag"
  default     = "deploy-web"
}

variable "owner" {
  description = "Owner tag"
  default     = "Reem Alzahrani"
}

variable "image" {
  description = "The VM image to deploy"
  default     = "myPackerImage"
}

variable "group_name" {
  description = "The name of the resource group"
  default     = "Azuredevops"
}
