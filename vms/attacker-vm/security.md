# Security Configuration — Attacker VM

Security context and configuration for the adversary-controlled platform. These settings make the attacker VM functional as an attack host — they are not applied to any defended asset.

## Why Windows Defender Was Disabled

Atomic Red Team techniques are correctly detected and blocked by Windows Defender because they replicate real adversary behaviour. Disabling Defender on the attacker VM replicates the realistic adversary assumption that an attacker who has compromised a host will disable endpoint protection before deploying tooling. This is a standard assumption in red team and penetration testing methodology.

```powershell
# Disable Defender real-time monitoring — ATTACKER VM ONLY
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableBlockAtFirstSeen $true

# Add exclusion for Atomic Red Team directory
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"
Add-MpPreference -ExclusionPath "C:\Temp"

# Verify Defender is disabled
Get-MpPreference | Select-Object DisableRealtimeMonitoring, DisableBehaviorMonitoring
```

## Atomic Red Team Installation

```powershell
# Set execution policy to allow script execution
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Download and run installer
IEX (New-Object Net.WebClient).DownloadString(
  'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1')

# Install atomics library (the technique definitions)
Install-AtomicRedTeam -getAtomics -Force

# Import module
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force

# Confirm version and available commands
Get-Command Invoke-AtomicTest
(Get-Module invoke-atomicredteam).Version
```

## Pre-Attack Connectivity Verification

Run before each experimental session to confirm VNet peering is active and all target VMs are reachable.

```powershell
Write-Host "=== PRE-ATTACK CONNECTIVITY CHECK ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

$checks = @(
  @{ IP="10.0.1.10"; Port=3389; Label="ZTA DC    (vm-dc-zta)"      },
  @{ IP="10.0.1.20"; Port=445;  Label="ZTA FS    (vm-fs-zta)"      },
  @{ IP="10.1.1.10"; Port=3389; Label="Conv DC   (vm-dc-conv)"     },
  @{ IP="10.1.1.20"; Port=445;  Label="Conv FS   (vm-fs-conv)"     }
)

foreach ($c in $checks) {
  $result = Test-NetConnection -ComputerName $c.IP -Port $c.Port -WarningAction SilentlyContinue
  $status = if ($result.TcpTestSucceeded) { "REACHABLE" } else { "UNREACHABLE" }
  Write-Host "$($c.Label) : $status" -ForegroundColor $(if ($result.TcpTestSucceeded) {"Green"} else {"Red"})
}
```

All four should show REACHABLE before beginning attack simulation.
