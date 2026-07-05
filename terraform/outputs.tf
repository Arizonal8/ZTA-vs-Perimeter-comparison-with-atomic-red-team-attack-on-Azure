output "zta_dc_private_ip" {
  value = azurerm_network_interface.dc_zta.private_ip_address
}

output "zta_fs_private_ip" {
  value = azurerm_network_interface.fs_zta.private_ip_address
}

output "conventional_dc_private_ip" {
  value = azurerm_network_interface.dc_conventional.private_ip_address
}

output "conventional_fs_private_ip" {
  value = azurerm_network_interface.fs_conventional.private_ip_address
}

output "attacker_public_ip" {
  value = azurerm_public_ip.attacker.ip_address
}

output "zta_storage_account_name" {
  value = azurerm_storage_account.zta.name
}

output "conventional_storage_account_name" {
  value = azurerm_storage_account.conventional.name
}

output "zta_sentinel_workspace" {
  value = azurerm_log_analytics_workspace.zta.name
}

output "conventional_monitor_workspace" {
  value = azurerm_log_analytics_workspace.conventional.name
}
