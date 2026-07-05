# ── ZTA Network Security Group — micro-segmentation ──────────
# Deny rules are the primary blocking mechanism evidenced in
# Chapter 4 of the dissertation (lateral movement, data
# exfiltration, and privilege escalation results).

resource "azurerm_network_security_group" "zta" {
  name                = "nsg-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location
}

resource "azurerm_network_security_rule" "allow_bastion" {
  name                        = "allow-bastion"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["3389", "22"]
  source_address_prefix       = "168.63.129.16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.zta.name
  network_security_group_name = azurerm_network_security_group.zta.name
}

resource "azurerm_network_security_rule" "allow_attacker_to_dc_only" {
  name                        = "allow-attacker-to-dc-only"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["3389", "445"]
  source_address_prefix       = "10.2.0.0/16"
  destination_address_prefix  = "10.0.1.10"
  resource_group_name         = azurerm_resource_group.zta.name
  network_security_group_name = azurerm_network_security_group.zta.name
}

resource "azurerm_network_security_rule" "allow_dc_to_fs_smb" {
  name                        = "allow-dc-to-fs-smb"
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "445"
  source_address_prefix       = "10.0.1.10"
  destination_address_prefix  = "10.0.1.20"
  resource_group_name         = azurerm_resource_group.zta.name
  network_security_group_name = azurerm_network_security_group.zta.name
}

resource "azurerm_network_security_rule" "block_attacker_to_fs" {
  name                        = "block-attacker-to-fs"
  priority                    = 220
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "445"
  source_address_prefix       = "10.2.0.0/16"
  destination_address_prefix  = "10.0.1.20"
  resource_group_name         = azurerm_resource_group.zta.name
  network_security_group_name = azurerm_network_security_group.zta.name
}

resource "azurerm_network_security_rule" "block_attacker_to_fs_rdp" {
  name                        = "block-attacker-to-fs-rdp"
  priority                    = 230
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.2.0.0/16"
  destination_address_prefix  = "10.0.1.20"
  resource_group_name         = azurerm_resource_group.zta.name
  network_security_group_name = azurerm_network_security_group.zta.name
}

resource "azurerm_subnet_network_security_group_association" "zta" {
  subnet_id                 = azurerm_subnet.zta.id
  network_security_group_id = azurerm_network_security_group.zta.id
}

# ── Conventional NSG — permissive baseline (no micro-segmentation) ──

resource "azurerm_network_security_group" "conventional" {
  name                = "nsg-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location
}

resource "azurerm_network_security_rule" "allow_bastion_conventional" {
  name                        = "allow-bastion"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["3389", "22"]
  source_address_prefix       = "168.63.129.16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.conventional.name
  network_security_group_name = azurerm_network_security_group.conventional.name
}

resource "azurerm_network_security_rule" "allow_rdp_from_anywhere" {
  name                        = "allow-rdp-from-anywhere"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.conventional.name
  network_security_group_name = azurerm_network_security_group.conventional.name
}

resource "azurerm_network_security_rule" "allow_all_inbound" {
  name                        = "allow-all-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.2.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.conventional.name
  network_security_group_name = azurerm_network_security_group.conventional.name
}

resource "azurerm_subnet_network_security_group_association" "conventional" {
  subnet_id                 = azurerm_subnet.conventional.id
  network_security_group_id = azurerm_network_security_group.conventional.id
}

# ── Attacker NSG ──────────────────────────────────────────────

resource "azurerm_network_security_group" "attacker" {
  name                = "nsg-attacker"
  resource_group_name = azurerm_resource_group.attacker.name
  location            = azurerm_resource_group.attacker.location
}

resource "azurerm_network_security_rule" "attacker_allow_rdp" {
  name                        = "allow-rdp-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.attacker.name
  network_security_group_name = azurerm_network_security_group.attacker.name
}

resource "azurerm_subnet_network_security_group_association" "attacker" {
  subnet_id                 = azurerm_subnet.attacker.id
  network_security_group_id = azurerm_network_security_group.attacker.id
}
