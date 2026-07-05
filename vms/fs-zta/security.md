# Security Configuration — vm-fs-zta (ZTA File Server)

## Domain Join and SMB Share Setup

```powershell
# Run inside vm-fs-zta via Azure Bastion
Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools

# Point DNS to ZTA domain controller
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.0.1.10"

# Test DC reachable
Test-NetConnection -ComputerName "10.0.1.10" -Port 389

# Join domain
$cred = New-Object System.Management.Automation.PSCredential(
  "ZTARESEARCH\researchadmin",
  (ConvertTo-SecureString "Research@ZTA2026!" -AsPlainText -Force))
Add-Computer -DomainName "ztaresearch.local" -Credential $cred -Restart -Force
# Reboots — reconnect after 3 minutes

# Create SMB shares with dummy sensitive files
$folders = @("HR_Records", "Finance_Reports", "Project_Confidential")
foreach ($folder in $folders) {
  New-Item -ItemType Directory -Path "C:\Shares\$folder" -Force
  1..5 | ForEach-Object {
    "CONFIDENTIAL RESEARCH DATA - Dummy file $_ - $folder" |
      Out-File "C:\Shares\$folder\document_$_.txt"
  }
  New-SmbShare -Name $folder -Path "C:\Shares\$folder" `
    -FullAccess "ZTARESEARCH\Domain Admins" `
    -ReadAccess "ZTARESEARCH\Domain Users"
}

# Verify
Get-SmbShare | Select-Object Name, Path
Get-ChildItem C:\Shares -Recurse | Select-Object FullName
```
