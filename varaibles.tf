
# Everything below is for the module

variable "vnet_resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-demo-southeast-01"
}


variable "vnet_location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type  = string
}

variable "vnet_name" {
  description = "Name of your Azure Virtual Network"
  type  = string
}

variable "vnet_address_space" {
  description = "The address space to be used for the Azure virtual network."
  default     = ["10.0.0.0/16"]
}

variable "vnet_ddos_enable" {
  description = "Create an ddos plan - Default is false"
  default     = false
}

#variable "vnet_network_mananger_name" {
#  description = "Controls if Network Watcher resources should be created for the Azure subscription"
#  type  =  string
#}

variable "subnets" {
  description = "For each subnet, create an object that contain fields"
  default     = {}
}

variable "vnet_tags" {
  description = "A map of tags to add to all resources"
  type        = map(any)
  default     = {}
}

variable "ddos_plan_name" {
  type  = string
}

variable "vnet_ddos_id" {
  type = string
}
variable "firewall_subnet_address_prefix" {
  default     = ["10.0.0.0/24"]
}

variable "firewall_service_endpoints" {
  default = []
}

variable "bastion_subnet_address_prefix" {
  default     = ["10.0.0.0/24"]
}

variable "bastion_service_endpoints" {
  default = []
}