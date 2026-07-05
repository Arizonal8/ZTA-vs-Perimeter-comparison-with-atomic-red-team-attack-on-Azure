================================================================
FILE 2 — UBUNTU TERMINAL (PowerShell / pwsh)
ZTA Security Configuration Commands
Sheffield Hallam University · MSc Dissertation 2026
================================================================

# Launch PowerShell on Ubuntu
pwsh

----------------------------------------------------------------
SECTION 1 — CONNECT TO AZURE
----------------------------------------------------------------

# Connect to Azure account
Connect-AzAccount -TenantId "arizaylab.tech"

# Set correct subscription
Set-AzContext -SubscriptionId "d2baea97-676b-4bde-acc8-351170ec332a"

# Verify connection
az account show

----------------------------------------------------------------
SECTION 2 — DEFENDER FOR CLOUD (ZTA STANDARD TIER)
----------------------------------------------------------------

# Enable Defender for Virtual Machines — Standard tier
Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard"

# Enable Defender for Storage Accounts — Standard tier
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard"

# Verify Defender tiers applied
Get-AzSecurityPricing | Select-Object Name, PricingTier

# After experiment — downgrade back to Free
# Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Free"
# Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free"

----------------------------------------------------------------
SECTION 3 — JUST-IN-TIME VM ACCESS (ZTA ONLY)
----------------------------------------------------------------

# Get VM resource IDs
$dcVmId = (Get-AzVM -ResourceGroupName "rg-zta-environment" -Name "vm-dc-zta").Id
$fsVmId = (Get-AzVM -ResourceGroupName "rg-zta-environment" -Name "vm-fs-zta").Id

# Enable JIT on Domain Controller
Set-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" -Location "UK South" -Name "default" -Kind "Basic" -VirtualMachine @(@{id=$dcVmId; ports=@(@{number=3389; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H"}, @{number=445; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H"})})

# Enable JIT on File Server
Set-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" -Location "UK South" -Name "default-fs" -Kind "Basic" -VirtualMachine @(@{id=$fsVmId; ports=@(@{number=3389; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H"}, @{number=445; protocol="TCP"; allowedSourceAddressPrefix=@("*"); maxRequestAccessDuration="PT3H"})})

# Verify JIT policies applied
Get-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" | Select-Object Name, ProvisioningState

----------------------------------------------------------------
SECTION 4 — STORAGE ACCOUNT LOCKDOWN (ZTA)
----------------------------------------------------------------

# Disable public network access on ZTA storage
Set-AzStorageAccount -ResourceGroupName "rg-zta-environment" -Name "saztaresearch01" -PublicNetworkAccess "Disabled"

# Verify ZTA storage locked
Get-AzStorageAccount -ResourceGroupName "rg-zta-environment" -Name "saztaresearch01" | Select-Object StorageAccountName, PublicNetworkAccess

# Verify Conventional storage still open
Get-AzStorageAccount -ResourceGroupName "rg-conventional-environment" -Name "saconvresearch01" | Select-Object StorageAccountName, PublicNetworkAccess

----------------------------------------------------------------
SECTION 5 — MICROSOFT SENTINEL ANALYTICS RULES
----------------------------------------------------------------

# Install Sentinel module
Install-Module Az.SecurityInsights -Force -AllowClobber -Scope CurrentUser

# Rule 1 — Brute Force Detection
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" -DisplayName "ZTA - Brute Force Detection" -Query "Event | where EventLog == 'Security' | where EventID == 4625 | summarize FailedAttempts = count() by Computer, bin(TimeGenerated, 5m) | where FailedAttempts > 3" -QueryFrequency ([TimeSpan]::FromMinutes(5)) -QueryPeriod ([TimeSpan]::FromMinutes(5)) -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 2 — Lateral Movement Detection
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" -DisplayName "ZTA - Lateral Movement Detection" -Query "Event | where EventLog == 'Security' | where EventID == 4624 | where RenderedDescription contains 'Logon Type:' | project TimeGenerated, Computer, EventID, RenderedDescription" -QueryFrequency ([TimeSpan]::FromMinutes(5)) -QueryPeriod ([TimeSpan]::FromMinutes(5)) -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 3 — Privilege Escalation Detection
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" -DisplayName "ZTA - Privilege Escalation Detection" -Query "Event | where EventLog == 'Security' | where EventID in (4728, 4732, 4756) | project TimeGenerated, Computer, EventID, RenderedDescription" -QueryFrequency ([TimeSpan]::FromMinutes(5)) -QueryPeriod ([TimeSpan]::FromMinutes(5)) -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Rule 4 — File Access Detection
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" -DisplayName "ZTA - File Access Detection" -Query "Event | where EventLog == 'Security' | where EventID == 5140 | where RenderedDescription contains 'HR_Records' or RenderedDescription contains 'Finance' or RenderedDescription contains 'Confidential' | project TimeGenerated, Computer, EventID, RenderedDescription" -QueryFrequency ([TimeSpan]::FromMinutes(5)) -QueryPeriod ([TimeSpan]::FromMinutes(5)) -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "Medium"

# Rule 5 — Storage Access Attempt
New-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -Kind "Scheduled" -DisplayName "ZTA - Storage Access Attempt" -Query "AzureActivity | where OperationNameValue contains 'storageAccounts' | where ActivityStatusValue == 'Failure' | project TimeGenerated, Caller, ResourceGroup, OperationNameValue" -QueryFrequency ([TimeSpan]::FromMinutes(5)) -QueryPeriod ([TimeSpan]::FromMinutes(5)) -TriggerOperator "GreaterThan" -TriggerThreshold 0 -Severity "High"

# Get rule IDs
Get-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" | Where-Object {$_.DisplayName -like "ZTA -*"} | Select-Object DisplayName, Name

# Enable all ZTA rules
Update-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -RuleId "c05943dd-7efc-4c41-aa49-790072771938" -Scheduled -Enabled
Update-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -RuleId "1d40a80a-b6df-4e27-b3ff-84e6cfcb2b3b" -Scheduled -Enabled
Update-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -RuleId "a5298c69-0b58-4ce7-a7cc-c13338934151" -Scheduled -Enabled
Update-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -RuleId "9b61b707-6fd3-41c4-a2a0-cc23309cd7be" -Scheduled -Enabled
Update-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" -RuleId "14afea5a-89d3-4163-ae5c-e1ef9685a280" -Scheduled -Enabled

# Verify all rules enabled
Get-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" | Select-Object DisplayName, Enabled

----------------------------------------------------------------
SECTION 6 — CONDITIONAL ACCESS POLICIES (P2 REQUIRED)
----------------------------------------------------------------

# Install Microsoft Graph module
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber

# Connect to Microsoft Graph
Connect-MgGraph -TenantId "dcdf602d-ada3-49ed-b7ce-f3f4bd25b124" -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All","RoleManagement.ReadWrite.Directory","Directory.ReadWrite.All"

# Disable Security Defaults (required before CA policies)
$params = @{ IsEnabled = $false }
Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy -BodyParameter $params

# Verify Security Defaults disabled
Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy | Select-Object IsEnabled

# Policy 1 — Require MFA for all users
$body = @{ displayName = "Require MFA - ZTA Research"; state = "enabled"; conditions = @{ users = @{ includeUsers = @("All") }; applications = @{ includeApplications = @("All") } }; grantControls = @{ operator = "OR"; builtInControls = @("mfa") } }; New-MgIdentityConditionalAccessPolicy -BodyParameter $body

# Policy 2 — Block Legacy Authentication
$body2 = @{ displayName = "Block Legacy Auth - ZTA Research"; state = "enabled"; conditions = @{ users = @{ includeUsers = @("All") }; applications = @{ includeApplications = @("All") }; clientAppTypes = @("exchangeActiveSync", "other") }; grantControls = @{ operator = "OR"; builtInControls = @("block") } }; New-MgIdentityConditionalAccessPolicy -BodyParameter $body2

# Verify both policies created and enabled
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State

----------------------------------------------------------------
SECTION 7 — VERIFICATION OF ALL ZTA CONTROLS
----------------------------------------------------------------

# Verify NSG rules
az network nsg rule list --resource-group rg-zta-environment --nsg-name nsg-zta --output table

# Verify JIT policies
Get-AzJitNetworkAccessPolicy -ResourceGroupName "rg-zta-environment" | Select-Object Name, ProvisioningState

# Verify Defender for Cloud
Get-AzSecurityPricing | Where-Object {$_.PricingTier -eq "Standard"} | Select-Object Name, PricingTier

# Verify ZTA storage locked
Get-AzStorageAccount -ResourceGroupName "rg-zta-environment" -Name "saztaresearch01" | Select-Object StorageAccountName, PublicNetworkAccess

# Verify Conventional storage open
Get-AzStorageAccount -ResourceGroupName "rg-conventional-environment" -Name "saconvresearch01" | Select-Object StorageAccountName, PublicNetworkAccess

# Verify Sentinel rules
Get-AzSentinelAlertRule -ResourceGroupName "rg-zta-environment" -WorkspaceName "law-zta-sentinel" | Select-Object DisplayName, Enabled

# Verify CA policies
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State

----------------------------------------------------------------
SECTION 8 — POST-EXPERIMENT CLEANUP
----------------------------------------------------------------

# Disable CA policies
Get-MgIdentityConditionalAccessPolicy | ForEach-Object { Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $_.Id -State "disabled" }

# Re-enable Security Defaults
$params = @{ IsEnabled = $true }
Update-MgPolicyIdentitySecurityDefaultEnforcementPolicy -BodyParameter $params

# Downgrade Defender to Free
Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Free"
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free"

# Verify final state
Get-AzSecurityPricing | Select-Object Name, PricingTier
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State

================================================================
END OF FILE 2
================================================================
