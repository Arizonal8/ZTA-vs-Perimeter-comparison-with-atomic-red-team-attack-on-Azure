# ── Virtual Networks ─────────────────────────────────────────

resource "azurerm_virtual_network" "zta" {
  name                = "vnet-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "zta" {
  name                 = "subnet-zta"
  resource_group_name  = azurerm_resource_group.zta.name
  virtual_network_name = azurerm_virtual_network.zta.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "conventional" {
  name                = "vnet-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "conventional" {
  name                 = "subnet-conventional"
  resource_group_name  = azurerm_resource_group.conventional.name
  virtual_network_name = azurerm_virtual_network.conventional.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network" "attacker" {
  name                = "vnet-attacker"
  resource_group_name = azurerm_resource_group.attacker.name
  location            = azurerm_resource_group.attacker.location
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "attacker" {
  name                 = "subnet-attacker"
  resource_group_name  = azurerm_resource_group.attacker.name
  virtual_network_name = azurerm_virtual_network.attacker.name
  address_prefixes     = ["10.2.1.0/24"]
}

# ── VNet Peering — attacker reaches both target environments ──

resource "azurerm_virtual_network_peering" "attacker_to_zta" {
  name                         = "peer-attacker-zta"
  resource_group_name         = azurerm_resource_group.attacker.name
  virtual_network_name         = azurerm_virtual_network.attacker.name
  remote_virtual_network_id    = azurerm_virtual_network.zta.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "zta_to_attacker" {
  name                         = "peer-zta-attacker"
  resource_group_name         = azurerm_resource_group.zta.name
  virtual_network_name         = azurerm_virtual_network.zta.name
  remote_virtual_network_id    = azurerm_virtual_network.attacker.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "attacker_to_conventional" {
  name                         = "peer-attacker-conventional"
  resource_group_name         = azurerm_resource_group.attacker.name
  virtual_network_name         = azurerm_virtual_network.attacker.name
  remote_virtual_network_id    = azurerm_virtual_network.conventional.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "conventional_to_attacker" {
  name                         = "peer-conventional-attacker"
  resource_group_name         = azurerm_resource_group.conventional.name
  virtual_network_name         = azurerm_virtual_network.conventional.name
  remote_virtual_network_id    = azurerm_virtual_network.attacker.id
  allow_virtual_network_access = true
}
