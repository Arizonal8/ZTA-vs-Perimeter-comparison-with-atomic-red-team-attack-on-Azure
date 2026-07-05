SECTION 1 — vm-dc-zta (ZTA Domain Controller)
IP: 10.0.1.10 | Domain: ztaresearch.local
----------------------------------------------------------------

# Open PowerShell as Administrator inside VM

# Step 1 — Install Active Directory Domain Services
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Step 2 — Promote to Domain Controller
Import-Module ADDSDeployment

Install-ADDSForest -DomainName "ztaresearch.local" -DomainNetbiosName "ZTARESEARCH" -ForestMode "WinThreshold" -DomainMode "WinThreshold" -InstallDns:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeMode@2026!" -AsPlainText -Force) -Force:$true

# VM restarts automatically — wait 3 minutes then reconnect via Bastion

# Step 3 — After restart — verify domain created
Get-ADDomain | Select-Object DNSRoot, DomainMode, PDCEmulator

# Step 4 — Create test users
New-ADUser -Name "TestUser01" -SamAccountName "testuser01" -AccountPassword (ConvertTo-SecureString "UserPass@123" -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "AdminUser01" -SamAccountName "adminuser01" -AccountPassword (ConvertTo-SecureString "AdminPass@123" -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true

Add-ADGroupMember -Identity "Domain Admins" -Members "adminuser01"

# Step 5 — Verify users created
Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled

# Step 6 — Verify admin group membership
Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name, SamAccountName

# Step 7 — Open AD Users GUI for screenshot
dsa.msc

----------------------------------------------------------------
