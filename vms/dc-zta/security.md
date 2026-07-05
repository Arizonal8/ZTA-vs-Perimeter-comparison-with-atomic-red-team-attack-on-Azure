# Security Configuration — vm-dc-zta (ZTA Domain Controller)

## Active Directory Domain Promotion

```powershell
# Run inside vm-dc-zta via Azure Bastion
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName "ztaresearch.local" `
  -DomainNetbiosName "ZTARESEARCH" `
  -ForestMode "WinThreshold" -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeMode@2026!" -AsPlainText -Force) `
  -Force:$true
# VM reboots automatically — reconnect via Bastion after 3 minutes
```

## Test Account Creation

```powershell
# Standard domain user — used for lateral movement and exfiltration attacks
New-ADUser -Name "TestUser01" -SamAccountName "testuser01" `
  -AccountPassword (ConvertTo-SecureString "UserPass@123" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

# Domain Administrator — used for privilege escalation attack
New-ADUser -Name "AdminUser01" -SamAccountName "adminuser01" `
  -AccountPassword (ConvertTo-SecureString "AdminPass@123" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

Add-ADGroupMember -Identity "Domain Admins" -Members "adminuser01"

# Verify
Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled
Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name, SamAccountName
```
