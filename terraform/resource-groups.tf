resource "azurerm_resource_group" "zta" {
  name     = "rg-zta-environment"
  location = var.location

  tags = {
    environment = "zta"
    project     = "msc-dissertation"
  }
}

resource "azurerm_resource_group" "conventional" {
  name     = "rg-conventional-environment"
  location = var.location

  tags = {
    environment = "conventional"
    project     = "msc-dissertation"
  }
}

resource "azurerm_resource_group" "attacker" {
  name     = "rg-attacker-vm"
  location = var.location

  tags = {
    environment = "attacker"
    project     = "msc-dissertation"
  }
}
