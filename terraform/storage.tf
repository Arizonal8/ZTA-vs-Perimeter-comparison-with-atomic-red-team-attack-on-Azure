# ── ZTA Storage Account — hardened ────────────────────────────
# public_network_access_enabled = false is the single config
# difference responsible for the misconfiguration exploitation
# result documented in Chapter 4 (HTTP 200 vs AuthorizationFailure).

resource "azurerm_storage_account" "zta" {
  name                = "saztaresearch01"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  min_tls_version                  = "TLS1_2"
}

resource "azurerm_storage_container" "zta_sensitive" {
  name                  = "sensitive-documents"
  storage_account_name = azurerm_storage_account.zta.name
  container_access_type = "private"
}

# ── Conventional Storage Account — intentionally permissive ──

resource "azurerm_storage_account" "conventional" {
  name                = "saconvresearch01"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location

  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true
  min_tls_version                  = "TLS1_2"
}

resource "azurerm_storage_container" "conventional_sensitive" {
  name                  = "sensitive-documents"
  storage_account_name = azurerm_storage_account.conventional.name
  container_access_type = "blob"
}
