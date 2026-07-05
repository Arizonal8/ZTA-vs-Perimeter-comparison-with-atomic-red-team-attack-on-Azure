# Security Configuration — vm-fs-conventional (Conventional File Server)

Identical setup to `vm-fs-zta` with `convresearch.local` and `10.1.1.10` substituted. No ZTA controls applied.

```powershell
Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.1.1.10"

Test-NetConnection -ComputerName "10.1.1.10" -Port 389

$cred = New-Object System.Management.Automation.PSCredential(
  "CONVRESEARCH\researchadmin",
  (ConvertTo-SecureString "Research@ZTA2026!" -AsPlainText -Force))
Add-Computer -DomainName "convresearch.local" -Credential $cred -Restart -Force

$folders = @("HR_Records", "Finance_Reports", "Project_Confidential")
foreach ($folder in $folders) {
  New-Item -ItemType Directory -Path "C:\Shares\$folder" -Force
  1..5 | ForEach-Object {
    "CONFIDENTIAL RESEARCH DATA - Dummy file $_ - $folder" |
      Out-File "C:\Shares\$folder\document_$_.txt"
  }
  New-SmbShare -Name $folder -Path "C:\Shares\$folder" `
    -FullAccess "CONVRESEARCH\Domain Admins" `
    -ReadAccess "CONVRESEARCH\Domain Users"
}

# DO NOT apply any ZTA controls to this VM
```
