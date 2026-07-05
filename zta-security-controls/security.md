# Security Configuration Commands — ZTA Controls

Full PowerShell commands for all ZTA controls applied to the ZTA environment. None of these are applied to the conventional environment.

## 1 — Defender for Cloud Standard Tier

```powershell
Connect-AzAccount -TenantId "arizaylab.tech"
Set-AzContext -SubscriptionId "d2baea97-676b-4bde-acc8-351170ec332a"

Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard"
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard"

# Verify
Get-AzSecurityPricing | Where-Object { $_.PricingTier -eq "Standard" } |
  Select-Object Name, PricingTier
```

## 2 — Just-In-Time VM Access

```powershell
$dcVmId = (Get-AzVM -ResourceGroupName "rg-zta-environment" -Name "vm-dc-zta").Id
$fsVmId = (Get-AzVM -ResourceGroupName "rg-zta-environment" -Name "vm-fs-zta").Id

Set-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" `
  -Location "UK South" -Name "default" -Kind "Basic" `
  -VirtualMachine @(@{
    id    = $dcVmId
    ports = @(
      @{ number=3389; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H" },
      @{ number=445;  protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H" }
    )
  })

Set-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" `
  -Location "UK South" -Name "default-fs" -Kind "Basic" `
  -VirtualMachine @(@{
    id    = $fsVmId
    ports = @(
      @{ number=3389; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H" },
      @{ number=445;  protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H" }
    )
  })

# Verify
Get-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" |
  Select-Object Name, ProvisioningState
```

## 3 — Storage Account Lockdown

```powershell
Set-AzStorageAccount -ResourceGroupName "rg-zta-environment" `
  -Name "saztaresearch01" -PublicNetworkAccess "Disabled"

# Verify ZTA locked, conventional still open
Get-AzStorageAccount -ResourceGroupName "rg-zta-environment" -Name "saztaresearch01" |
  Select-Object StorageAccountName, PublicNetworkAccess

Get-AzStorageAccount -ResourceGroupName "rg-conventional-environment" -Name "saconvresearch01" |
  Select-Object StorageAccountName, PublicNetworkAccess
```

## 4 — Microsoft Sentinel Analytics Rules

```powershell
Install-Module Az.SecurityInsights -Force -AllowClobber -Scope CurrentUser

# Rule 1 — Brute Force Detection (T1110.001)
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" `
  -DisplayName "ZTA - Brute Force Detection" `
  -Query "Event | where EventLog == 'Security' | where EventID == 4625
    | summarize FailedAttempts = count() by Computer, bin(TimeGenerated, 5m)
    | where FailedAttempts > 3" `
  -QueryFrequency ([TimeSpan]::FromMinutes(5)) `
  -QueryPeriod ([TimeSpan]::FromMinutes(5)) `
  -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 2 — Lateral Movement Detection (T1021.002)
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" `
  -DisplayName "ZTA - Lateral Movement Detection" `
  -Query "Event | where EventLog == 'Security' | where EventID == 4624
    | where RenderedDescription contains 'Logon Type:'
    | project TimeGenerated, Computer, EventID, RenderedDescription" `
  -QueryFrequency ([TimeSpan]::FromMinutes(5)) `
  -QueryPeriod ([TimeSpan]::FromMinutes(5)) `
  -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 3 — Privilege Escalation Detection (T1078)
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" `
  -DisplayName "ZTA - Privilege Escalation Detection" `
  -Query "Event | where EventLog == 'Security'
    | where EventID in (4728, 4732, 4756)
    | project TimeGenerated, Computer, EventID, RenderedDescription" `
  -QueryFrequency ([TimeSpan]::FromMinutes(5)) `
  -QueryPeriod ([TimeSpan]::FromMinutes(5)) `
  -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 4 — File Share Access Detection (T1039)
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" `
  -DisplayName "ZTA - File Access Detection" `
  -Query "Event | where EventLog == 'Security' | where EventID == 5140
    | where RenderedDescription contains 'HR_Records'
       or RenderedDescription contains 'Finance'
       or RenderedDescription contains 'Confidential'
    | project TimeGenerated, Computer, EventID, RenderedDescription" `
  -QueryFrequency ([TimeSpan]::FromMinutes(5)) `
  -QueryPeriod ([TimeSpan]::FromMinutes(5)) `
  -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "Medium"

# Rule 5 — Storage Access Attempt (T1530)
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" `
  -DisplayName "ZTA - Storage Access Attempt" `
  -Query "AzureActivity
    | where OperationNameValue contains 'storageAccounts'
    | where ActivityStatusValue == 'Failure'
    | project TimeGenerated, Caller, ResourceGroup, OperationNameValue" `
  -QueryFrequency ([TimeSpan]::FromMinutes(5)) `
  -QueryPeriod ([TimeSpan]::FromMinutes(5)) `
  -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Verify all enabled
Get-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" `
  -WorkspaceName "law-zta-sentinel" |
  Where-Object { $_.DisplayName -like "ZTA -*" } |
  Select-Object DisplayName, Enabled
```

## 5 — Conditional Access Policies (requires Entra ID P2)

```powershell
Connect-MgGraph -TenantId "dcdf602d-ada3-49ed-b7ce-f3f4bd25b124" `
  -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All",`
          "RoleManagement.ReadWrite.Directory","Directory.ReadWrite.All"

# Disable Security Defaults (prerequisite)
Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy `
  -BodyParameter @{ IsEnabled = $false }

# Policy 1 — Require MFA for all users and all apps
$body = @{
  displayName   = "Require MFA - ZTA Research"
  state         = "enabled"
  conditions    = @{
    users        = @{ includeUsers = @("All") }
    applications = @{ includeApplications = @("All") }
  }
  grantControls = @{ operator = "OR"; builtInControls = @("mfa") }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $body

# Policy 2 — Block legacy authentication protocols
$body2 = @{
  displayName   = "Block Legacy Auth - ZTA Research"
  state         = "enabled"
  conditions    = @{
    users           = @{ includeUsers = @("All") }
    applications    = @{ includeApplications = @("All") }
    clientAppTypes  = @("exchangeActiveSync", "other")
  }
  grantControls = @{ operator = "OR"; builtInControls = @("block") }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $body2

# Verify both enabled
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State
```

## 6 — Post-Experiment Cleanup

```powershell
# Disable Conditional Access policies
Get-MgIdentityConditionalAccessPolicy | ForEach-Object {
  Update-MgIdentityConditionalAccessPolicy `
    -ConditionalAccessPolicyId $_.Id -State "disabled"
}

# Re-enable Security Defaults
Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy `
  -BodyParameter @{ IsEnabled = $true }

# Downgrade Defender to Free tier
Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Free"
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free"

# Verify final state
Get-AzSecurityPricing | Select-Object Name, PricingTier
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State
```
