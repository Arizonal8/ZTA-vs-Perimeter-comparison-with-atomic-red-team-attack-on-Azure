# Security Configuration — Terraform

Security-relevant Terraform configuration embedded in the IaC codebase. These settings define the security posture difference between the two environments at the infrastructure layer.

## NSG Micro-Segmentation — ZTA Environment (`nsg.tf`)

The single most impactful security decision in the entire experiment. Priority 220 blocks the attacker VM subnet from reaching the file server on SMB (port 445). This one rule is responsible for blocking three of four successfully-blocked MITRE ATT&CK categories.

```hcl
# Block attacker reaching ZTA file server on SMB (port 445)
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

# Block attacker reaching ZTA file server on RDP (port 3389)
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
```

## Conventional NSG — Permissive Baseline (`nsg.tf`)

The conventional environment NSG contains only permissive rules. No deny rules targeting the attacker subnet — this is the deliberate baseline representing perimeter security's trust-by-default model.

```hcl
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
```

## Storage Account Security Posture (`storage.tf`)

The single configuration line responsible for the misconfiguration exploitation result — HTTP 200 vs AuthorizationFailure.

```hcl
# ZTA — hardened
resource "azurerm_storage_account" "zta" {
  name                          = "saztaresearch01"
  public_network_access_enabled = false    # ← AuthorizationFailure in attack
  allow_nested_items_to_be_public = false
}

# Conventional — intentionally misconfigured
resource "azurerm_storage_account" "conventional" {
  name                          = "saconvresearch01"
  public_network_access_enabled = true     # ← HTTP 200 in attack
  allow_nested_items_to_be_public = true
}
```

## Monitoring Security (`monitoring.tf`)

Microsoft Sentinel was onboarded to the ZTA workspace only, reflecting the ZTA principle that all activity must be continuously monitored.

```hcl
# Sentinel onboarding — ZTA environment only
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "zta" {
  workspace_id = azurerm_log_analytics_workspace.zta.id
}

# Note: No Sentinel onboarding on law-conventional-monitor
# The conventional environment represents a baseline without advanced monitoring
```

## Security Controls NOT in Terraform

The following ZTA controls could not be expressed as `azurerm` resources and were applied via PowerShell post-deploy — see `../zta-security-controls/security.md`:

- Just-In-Time VM access (`Set-AzJitNetworkAccessPolicy` via Defender for Cloud API)
- Defender for Cloud Standard pricing tier (`Set-AzSecurityPricing`)
- Conditional Access policies (Microsoft Graph API — requires Entra ID P2)
- Privileged Identity Management (Microsoft Graph API)
- Sentinel analytics rules (`Az.SecurityInsights` PowerShell module)
