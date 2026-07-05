SECTION 4 — vm-fs-conventional (Conventional File Server)
IP: 10.1.1.20 | Domain: convresearch.local
----------------------------------------------------------------

# Open PowerShell as Administrator inside VM

# Step 1 — Install File Server role
Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools

# Step 2 — Set DNS to point to Conventional Domain Controller
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.1.1.10"

# Step 3 — Test DC is reachable
Test-NetConnection -ComputerName "10.1.1.10" -Port 389

# Step 4 — Join Conventional domain
$password = ConvertTo-SecureString "Research@ZTA2026!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("CONVRESEARCH\researchadmin", $password)
Add-Computer -DomainName "convresearch.local" -Credential $credential -Restart -Force

# VM restarts — reconnect via Bastion after 3 minutes

# Step 5 — After restart — verify domain joined
(Get-WmiObject Win32_ComputerSystem).Domain

# Step 6 — Create identical dummy folders and files
$folders = @("HR_Records", "Finance_Reports", "Project_Confidential"); foreach ($folder in $folders) { New-Item -ItemType Directory -Path "C:\Shares\$folder" -Force; 1..5 | ForEach-Object { "CONFIDENTIAL RESEARCH DATA - Dummy file $_ - $folder" | Out-File "C:\Shares\$folder\document_$_.txt" }; New-SmbShare -Name $folder -Path "C:\Shares\$folder" -FullAccess "CONVRESEARCH\Domain Admins" -ReadAccess "CONVRESEARCH\Domain Users" }

# Step 7 — Verify shares and files
Get-SmbShare | Select-Object Name, Path
Get-ChildItem C:\Shares -Recurse

# NOTE: Do NOT apply any ZTA controls to this VM
# Leave NSG, JIT, and Defender at default permissive settings

