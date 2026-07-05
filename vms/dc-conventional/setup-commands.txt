SECTION 3 — vm-dc-conventional (Conventional Domain Controller)
IP: 10.1.1.10 | Domain: convresearch.local
----------------------------------------------------------------

# Open PowerShell as Administrator inside VM

# Step 1 — Install Active Directory Domain Services
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Step 2 — Promote to Domain Controller (different domain name)
Install-ADDSForest -DomainName "convresearch.local" -DomainNetbiosName "CONVRESEARCH" -ForestMode "WinThreshold" -DomainMode "WinThreshold" -InstallDns:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeMode@2026!" -AsPlainText -Force) -Force:$true

# VM restarts automatically — wait 3 minutes then reconnect

# Step 3 — After restart — verify domain created
Get-ADDomain | Select-Object DNSRoot, DomainMode, PDCEmulator

# Step 4 — Create identical test users (same as ZTA)
New-ADUser -Name "TestUser01" -SamAccountName "testuser01" -AccountPassword (ConvertTo-SecureString "UserPass@123" -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "AdminUser01" -SamAccountName "adminuser01" -AccountPassword (ConvertTo-SecureString "AdminPass@123" -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true

Add-ADGroupMember -Identity "Domain Admins" -Members "adminuser01"

# Step 5 — Verify users created
Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled

# NOTE: Do NOT apply any ZTA controls to this VM
# No Conditional Access, no JIT, no Defender — leave defaults

----------------------------------------------------------------
