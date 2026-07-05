# Security Configuration — vm-dc-conventional (Conventional Domain Controller)

Identical setup to `vm-dc-zta` with `convresearch.local` substituted. No ZTA controls applied.

```powershell
# Run inside vm-dc-conventional via Azure Bastion
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName "convresearch.local" `
  -DomainNetbiosName "CONVRESEARCH" `
  -ForestMode "WinThreshold" -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeMode@2026!" -AsPlainText -Force) `
  -Force:$true

New-ADUser -Name "TestUser01" -SamAccountName "testuser01" `
  -AccountPassword (ConvertTo-SecureString "UserPass@123" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "AdminUser01" -SamAccountName "adminuser01" `
  -AccountPassword (ConvertTo-SecureString "AdminPass@123" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

Add-ADGroupMember -Identity "Domain Admins" -Members "adminuser01"

Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled

# DO NOT apply any ZTA controls to this VM
```
