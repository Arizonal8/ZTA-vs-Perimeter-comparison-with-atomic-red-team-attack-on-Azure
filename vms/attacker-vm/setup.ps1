================================================================
FILE 4 — ATTACKER VM (vm-attacker)
Atomic Red Team Setup and MITRE ATT&CK Attack Simulation
Sheffield Hallam University · MSc Dissertation 2026
================================================================

Access: RDP via public IP 51.143.166.82 or Azure Bastion
  Username: researchadmin
  Password: Research@ZTA2026!

Experiment date: 16 June 2026
Attack window:   19:00 – 21:00 UTC

Target IPs:
  ZTA Domain Controller:          10.0.1.10
  ZTA File Server:                10.0.1.20
  Conventional Domain Controller: 10.1.1.10
  Conventional File Server:       10.1.1.20

SECTION 1 — ATTACKER VM SETUP
----------------------------------------------------------------

# Open PowerShell as Administrator

# Step 1 — Set execution policy
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Step 2 — Disable Windows Defender (attacker VM only)
Set-MpPreference -DisableRealtimeMonitoring $true
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"

# Step 3 — Download and run Atomic Red Team installer
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1')

# Step 4 — Install atomics library
Install-AtomicRedTeam -getAtomics -Force

# Step 5 — Import module
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force

# Step 6 — Verify installation
Get-Command Invoke-AtomicTest

# Step 7 — Test connectivity to all target VMs
Test-NetConnection -ComputerName "10.0.1.10" -Port 3389
Test-NetConnection -ComputerName "10.0.1.20" -Port 445
Test-NetConnection -ComputerName "10.1.1.10" -Port 3389
Test-NetConnection -ComputerName "10.1.1.20" -Port 445

# All should return TcpTestSucceeded : True

----------------------------------------------------------------
