###################################################
#####Module for creating VNET and SUBNET and NSG
###################################################

resource azurerm_virtual_network "azure_vnet" {
  address_space           = var.vnet_address_space
  location                = var.vnet_location
  name                    = var.vnet_name
  resource_group_name     = var.vnet_resource_group_name
  # dns_servers = var.vnet_dns_servers
  tags                    = var.vnet_tags


  ddos_protection_plan {
    enable = var.vnet_ddos_enable
    id = var.vnet_ddos_id
  }
}

#resource "azurerm_network_ddos_protection_plan" "ddos" {
#  name                = var.ddos_plan_name
#  resource_group_name = var.vnet_resource_group_name
#  location            = var.vnet_location
#  tags                = var.vnet_tags
#}
#resource azurerm_network_watcher "azure_vnet_network_watcher" {

#  location = var.vnet_location
#  name = var.vnet_network_mananger_name
#  resource_group_name = var.vnet_resource_group_name
#  tags = var.vnet_tags
#}

resource "azurerm_subnet" "fwnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = var.firewall_subnet_address_prefix #[cidrsubnet(element(var.vnet_address_space, 0), 10, 0)]
  service_endpoints    = var.firewall_service_endpoints
}

resource "azurerm_subnet" "bastionsnet" {
  name = "AzureBastionSubnet"
  resource_group_name = var.vnet_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes = var.bastion_subnet_address_prefix
  service_endpoints = var.bastion_service_endpoints
}


resource "azurerm_subnet" "snet" {
  for_each                                       = var.subnets
  name                                           = each.value.subnet_name
  resource_group_name                            = var.vnet_resource_group_name
  virtual_network_name                           = azurerm_virtual_network.azure_vnet.name
  address_prefixes                               = each.value.subnet_address_prefix
  service_endpoints                              = lookup(each.value, "service_endpoints", [])
  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", {}) != {} ? [1] : []
    content {
      name = lookup(each.value.delegation, "name", null)
      service_delegation {
        name    = lookup(each.value.delegation.service_delegation, "name", null)
        actions = lookup(each.value.delegation.service_delegation, "actions", null)
      }
    }
  }
}

#-----------------------------------------------
# Network security group - Default is "false"
#-----------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = lower("nsg_${each.key}_in")
  resource_group_name = var.vnet_resource_group_name
  location            = var.vnet_location
  tags                = var.vnet_tags
  dynamic "security_rule" {
    for_each = concat(lookup(each.value, "nsg_inbound_rules", []), lookup(each.value, "nsg_outbound_rules", []))
    content {
      name                       = security_rule.value[0] == "" ? "Default_Rule" : security_rule.value[0]
      priority                   = security_rule.value[1]
      direction                  = security_rule.value[2] == "" ? "Inbound" : security_rule.value[2]
      access                     = security_rule.value[3] == "" ? "Allow" : security_rule.value[3]
      protocol                   = security_rule.value[4] == "" ? "Tcp" : security_rule.value[4]
      source_port_range          = "*"
      destination_port_range     = security_rule.value[5] == "" ? "*" : security_rule.value[5]
      source_address_prefix      = security_rule.value[6] == "" ? element(each.value.subnet_address_prefix, 0) : security_rule.value[6]
      destination_address_prefix = security_rule.value[7] == "" ? element(each.value.subnet_address_prefix, 0) : security_rule.value[7]
      description                = "${security_rule.value[2]}_Port_${security_rule.value[5]}"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.snet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}