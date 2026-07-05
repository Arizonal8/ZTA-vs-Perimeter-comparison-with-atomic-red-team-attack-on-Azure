# ── ZTA Domain Controller (vm-dc-zta — 10.0.1.10) ─────────────

resource "azurerm_network_interface" "dc_zta" {
  name                = "nic-dc-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.zta.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

resource "azurerm_windows_virtual_machine" "dc_zta" {
  name                = "vm-dc-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.dc_zta.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# ── ZTA File Server (vm-fs-zta — 10.0.1.20) ───────────────────

resource "azurerm_network_interface" "fs_zta" {
  name                = "nic-fs-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.zta.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.20"
  }
}

resource "azurerm_windows_virtual_machine" "fs_zta" {
  name                = "vm-fs-zta"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.fs_zta.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# ── Conventional Domain Controller (vm-dc-conventional — 10.1.1.10) ──

resource "azurerm_network_interface" "dc_conventional" {
  name                = "nic-dc-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.conventional.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.10"
  }
}

resource "azurerm_windows_virtual_machine" "dc_conventional" {
  name                = "vm-dc-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.dc_conventional.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# ── Conventional File Server (vm-fs-conventional — 10.1.1.20) ──

resource "azurerm_network_interface" "fs_conventional" {
  name                = "nic-fs-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.conventional.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.20"
  }
}

resource "azurerm_windows_virtual_machine" "fs_conventional" {
  name                = "vm-fs-conventional"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.fs_conventional.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# ── Attacker VM (vm-attacker — 10.2.1.4 private / public IP) ──

resource "azurerm_public_ip" "attacker" {
  name                = "pip-attacker"
  resource_group_name = azurerm_resource_group.attacker.name
  location            = azurerm_resource_group.attacker.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "attacker" {
  name                = "nic-attacker"
  resource_group_name = azurerm_resource_group.attacker.name
  location            = azurerm_resource_group.attacker.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.attacker.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.1.4"
    public_ip_address_id          = azurerm_public_ip.attacker.id
  }
}

resource "azurerm_windows_virtual_machine" "attacker" {
  name                = "vm-attacker"
  resource_group_name = azurerm_resource_group.attacker.name
  location            = azurerm_resource_group.attacker.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.attacker.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
