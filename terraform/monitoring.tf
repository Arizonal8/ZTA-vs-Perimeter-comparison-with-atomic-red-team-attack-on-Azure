# ── Log Analytics Workspaces ──────────────────────────────────

resource "azurerm_log_analytics_workspace" "zta" {
  name                = "law-zta-sentinel"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "conventional" {
  name                = "law-conventional-monitor"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ── Microsoft Sentinel onboarding (ZTA workspace only) ────────

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "zta" {
  workspace_id = azurerm_log_analytics_workspace.zta.id
}

# ── Data Collection Rules ─────────────────────────────────────

resource "azurerm_monitor_data_collection_rule" "zta" {
  name                = "dcr-zta-research"
  resource_group_name = azurerm_resource_group.zta.name
  location            = azurerm_resource_group.zta.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.zta.id
      name                   = "destination-law-zta"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["destination-law-zta"]
  }

  data_sources {
    windows_event_log {
      streams        = ["Microsoft-Event"]
      x_path_queries = ["Security!*"]
      name           = "datasource-windows-security"
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "conventional" {
  name                = "dcr-conventional-research"
  resource_group_name = azurerm_resource_group.conventional.name
  location            = azurerm_resource_group.conventional.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.conventional.id
      name                   = "destination-law-conventional"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["destination-law-conventional"]
  }

  data_sources {
    windows_event_log {
      streams        = ["Microsoft-Event"]
      x_path_queries = ["Security!*"]
      name           = "datasource-windows-security"
    }
  }
}

# ── Azure Monitor Agent — installed on all four target VMs ───
# Note: the attacker VM intentionally does not receive AMA,
# since it is the adversary-controlled host, not a monitored asset.

resource "azurerm_virtual_machine_extension" "ama_dc_zta" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id        = azurerm_windows_virtual_machine.dc_zta.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.22"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "ama_fs_zta" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id        = azurerm_windows_virtual_machine.fs_zta.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.22"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "ama_dc_conventional" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id        = azurerm_windows_virtual_machine.dc_conventional.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.22"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "ama_fs_conventional" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id        = azurerm_windows_virtual_machine.fs_conventional.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.22"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "dc_zta" {
  name                    = "dcr-assoc-dc-zta"
  target_resource_id      = azurerm_windows_virtual_machine.dc_zta.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.zta.id
}

resource "azurerm_monitor_data_collection_rule_association" "fs_zta" {
  name                    = "dcr-assoc-fs-zta"
  target_resource_id      = azurerm_windows_virtual_machine.fs_zta.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.zta.id
}

resource "azurerm_monitor_data_collection_rule_association" "dc_conventional" {
  name                    = "dcr-assoc-dc-conventional"
  target_resource_id      = azurerm_windows_virtual_machine.dc_conventional.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.conventional.id
}

resource "azurerm_monitor_data_collection_rule_association" "fs_conventional" {
  name                    = "dcr-assoc-fs-conventional"
  target_resource_id      = azurerm_windows_virtual_machine.fs_conventional.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.conventional.id
}
