# MITRE ATT&CK Mapping

## Overview

This section maps every attack technique simulated in this research to the MITRE ATT&CK Enterprise Matrix v15.1, organised by tactic. The mapping covers both the techniques directly executed during the 16 June 2026 attack simulation and the broader tactics they represent in a real adversary campaign.

---

## ATT&CK Navigator Coverage

The five primary techniques tested span four MITRE ATT&CK tactics:

```
Tactics covered:
  ├── Credential Access     ← T1110.001
  ├── Lateral Movement      ← T1021.002
  ├── Collection            ← T1039
  ├── Privilege Escalation  ← T1078
  └── Initial Access/Collection ← T1530
```

---

## Full MITRE ATT&CK Technique Mapping

### Tactic: Credential Access

| Technique ID | Technique Name | Sub-Technique | How Simulated | ZTA Result | Conv Result |
|---|---|---|---|---|---|
| **T1110** | Brute Force | **T1110.001** Password Guessing | `net use \\<DC>\IPC$ /user:<domain>\testuser01 <password>` across 7-password wordlist, 3 runs per environment | Failed (wordlist gap) + 22–23s NSG delay | Failed (wordlist gap) — no friction |
| T1110 | Brute Force | T1110.002 Password Cracking | Not simulated — would require offline hash capture first | N/A | N/A |
| T1110 | Brute Force | T1110.003 Password Spraying | Partially covered by T1110.001 simulation (same `net use` mechanism) | NSG friction | No friction |
| T1556 | Modify Auth Process | — | Not simulated | N/A | N/A |
| T1558 | Steal/Forge Kerberos Tickets | — | Not simulated — Kerberos ticket capture would require prior code execution on DC | N/A | N/A |

**Key finding — T1110.001:** The credential theft limitation (wordlist gap) meant the ZTA identity controls (Conditional Access MFA, Block Legacy Auth) could not be fully tested. In a real scenario with a successful password guess, the ZTA environment would require an additional registered MFA device — the conventional environment would grant full access on credentials alone.

---

### Tactic: Lateral Movement

| Technique ID | Technique Name | Sub-Technique | How Simulated | ZTA Result | Conv Result |
|---|---|---|---|---|---|
| **T1021** | Remote Services | **T1021.002** SMB/Windows Admin Shares | `net use \\<FS>\HR_Records /user:<domain>\testuser01 UserPass@123` — 3 runs per environment | ❌ BLOCKED — Error 53 all 3 runs | ✅ SUCCEEDED — SMB session in <1s |
| T1021 | Remote Services | T1021.001 RDP | Not simulated as primary technique — RDP was used for Bastion research access only | N/A | N/A |
| T1021 | Remote Services | T1021.004 SSH | Not applicable — Windows environment | N/A | N/A |
| T1550 | Use Alternate Auth Material | T1550.002 Pass the Hash | Not simulated — would require credential dumping from memory first | N/A | N/A |
| T1534 | Internal Spearphishing | — | Not simulated | N/A | N/A |

**Key finding — T1021.002:** This was the clearest ZTA success in the experiment. NSG rule `block-attacker-to-fs` (priority 220) blocked all SMB traffic from the attacker subnet to the file server IP — `net use` returned Error 53 all three runs. The conventional environment had no equivalent rule and the share was accessible in under one second every run.

---

### Tactic: Collection

| Technique ID | Technique Name | Sub-Technique | How Simulated | ZTA Result | Conv Result |
|---|---|---|---|---|---|
| **T1039** | Data from Network Shared Drive | — | `Copy-Item "\\<FS>\HR_Records\document_1.txt" "C:\exfil.txt"` after SMB session — 3 runs per environment | ❌ BLOCKED — File exfiltrated: False all 3 runs | ✅ SUCCEEDED — File exfiltrated: True all 3 runs |
| **T1530** | Data from Cloud Storage Object | — | `Invoke-WebRequest -Uri "https://<storage>.blob.core.windows.net/sensitive-documents/document_1.txt"` — 3 runs per environment | ❌ BLOCKED — AuthorizationFailure all 3 runs | ✅ SUCCEEDED — HTTP 200 + file contents all 3 runs |
| T1005 | Data from Local System | — | Not simulated | N/A | N/A |
| T1074 | Data Staged | — | Not simulated | N/A | N/A |

**Key finding — T1039:** Dependent on T1021.002. ZTA's network-layer block of SMB access meant `Copy-Item` had no path to the file — the data exfiltration attack was blocked by the same NSG rule as lateral movement.

**Key finding — T1530:** The storage misconfiguration test directly replicates the 2022 BlueBleed vulnerability pattern. The result: `public_network_access_enabled = false` provides categorical protection. `public_network_access_enabled = true` with `allow_nested_items_to_be_public = true` exposed full file contents to an unauthenticated HTTP request.

---

### Tactic: Privilege Escalation

| Technique ID | Technique Name | Sub-Technique | How Simulated | ZTA Result | Conv Result |
|---|---|---|---|---|---|
| **T1078** | Valid Accounts | **T1078.002** Domain Accounts | `net use \\<DC>\ADMIN$ /user:<domain>\adminuser01 AdminPass@123` — 3 runs per environment | ❌ BLOCKED — Error 64 (Run 1, JIT termination), Error 53 (Runs 2–3, NSG block) | ✅ SUCCEEDED — ADMIN$ accessible all 3 runs |
| T1068 | Exploitation for Privilege Escalation | — | Not simulated — CVE exploitation not within scope | N/A | N/A |
| T1134 | Access Token Manipulation | — | Not simulated | N/A | N/A |
| T1484 | Domain Policy Modification | — | Not simulated | N/A | N/A |

**Key finding — T1078:** Two ZTA controls operated in sequence. JIT access policy first evaluated the connection request (Error 64 — connection initiated then terminated by JIT). Subsequently, NSG rules blocked reconnection attempts (Error 53). The conventional environment had no equivalent controls — Domain Admin credentials provided immediate ADMIN$ access, equivalent to full domain controller compromise.

---

### Tactic: Initial Access (Simulated via Misconfiguration Exploitation)

| Technique ID | Technique Name | Sub-Technique | How Simulated | ZTA Result | Conv Result |
|---|---|---|---|---|---|
| **T1190** | Exploit Public-Facing Application | — | Unauthenticated HTTP GET to public Azure Blob endpoint (maps to T1530 for cloud storage specifically) | ❌ BLOCKED — AuthorizationFailure | ✅ SUCCEEDED — HTTP 200 |
| T1078 | Valid Accounts | T1078.004 Cloud Accounts | Not directly simulated | N/A | N/A |
| T1566 | Phishing | — | Not simulated | N/A | N/A |

---

### Tactics Not Simulated — Gap Analysis

| Tactic | Reason Not Simulated | Future Recommendation |
|---|---|---|
| **Execution** | Atomic Red Team provides execution capability but focus was on network/identity controls | Add T1059 (PowerShell) and T1047 (WMI) in future study |
| **Persistence** | Beyond scope — study focused on access controls, not persistence mechanisms | Add T1053 (Scheduled Tasks) and T1136 (Create Account) |
| **Defense Evasion** | Not simulated — Defender exclusions on attacker VM only, not on targets | Add T1562 (Impair Defenses) and T1070 (Indicator Removal) |
| **Discovery** | SMB share enumeration partially covered by T1021.002 | Add T1087 (Account Discovery) and T1135 (Network Share Discovery) |
| **Command and Control** | No C2 infrastructure used — out-of-scope for ZTA evaluation | Add T1071 (App Layer Protocol) for outbound traffic testing |
| **Exfiltration** | T1039 and T1530 cover data theft — no dedicated exfiltration channel tested | Add T1048 (Exfiltration Over Alt Protocol) |
| **Impact** | Not simulated — study focused on access prevention | Add T1486 (Ransomware) and T1490 (Inhibit Recovery) |

---

## MITRE ATT&CK Coverage Matrix

```
TACTIC              TECHNIQUE         TESTED  ZTA BLOCKED  CONV SUCCEEDED
─────────────────────────────────────────────────────────────────────────
Credential Access   T1110.001         YES     PARTIAL*     PARTIAL*
Lateral Movement    T1021.002         YES     YES ✓        YES ✓
Collection          T1039             YES     YES ✓        YES ✓
Collection          T1530             YES     YES ✓        YES ✓
Privilege Escalation T1078            YES     YES ✓        YES ✓
Initial Access      T1190             YES     YES ✓        YES ✓
Execution           T1059             NO      –            –
Persistence         T1053/T1136       NO      –            –
Defense Evasion     T1562             NO      –            –
Discovery           T1087/T1135       NO      –            –
Command & Control   T1071             NO      –            –
Impact              T1486             NO      –            –

* Credential theft: both environments failed due to wordlist gap
  ZTA added 22–23 second friction delays — Conditional Access 
  would block even correct credentials (requires MFA device)
```

---

## Detection Mapping — MITRE D3FEND

For each attack technique, the corresponding defensive technique from MITRE D3FEND:

| ATT&CK Technique | D3FEND Countermeasure | Implemented in ZTA? |
|---|---|---|
| T1110.001 Brute Force | D3-MFA (Multi-Factor Authentication) | ✅ Conditional Access MFA policy |
| T1021.002 SMB Lateral Movement | D3-NTF (Network Traffic Filtering) | ✅ NSG block-attacker-to-fs |
| T1039 Data from Network Share | D3-NTF (Network Traffic Filtering) | ✅ Same NSG rule (cascaded) |
| T1530 Cloud Storage Access | D3-ACH (Access Control Hardening) | ✅ PublicNetworkAccess: Disabled |
| T1078 Valid Accounts ADMIN$ | D3-JA (Just-In-Time Access) + D3-NTF | ✅ JIT + NSG combined |
| T1190 Public-Facing Application | D3-ACH (Access Control Hardening) | ✅ Private endpoint enforced |
