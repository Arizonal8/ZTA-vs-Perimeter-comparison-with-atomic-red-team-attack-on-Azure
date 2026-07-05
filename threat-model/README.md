# Threat Model — STRIDE Analysis

## Overview

This section presents a STRIDE threat model for the research environment, applied both as a design tool (informing which ZTA controls were selected) and as a retrospective validation (confirming the controls addressed the identified threats). STRIDE is Microsoft's threat modelling methodology — appropriate for an Azure-hosted environment.

**STRIDE categories:**
- **S**poofing — impersonating a legitimate identity
- **T**ampering — modifying data or systems without authorisation
- **R**epudiation — denying actions that were taken
- **I**nformation Disclosure — exposing data to unauthorised parties
- **D**enial of Service — making a system unavailable
- **E**levation of Privilege — gaining higher permissions than authorised

---

## System Components Modelled

```
External:       vm-attacker (10.2.1.4) — adversary-controlled
Internal ZTA:   vm-dc-zta (10.0.1.10) — Domain Controller
                vm-fs-zta (10.0.1.20) — File Server
                saztaresearch01 — Blob Storage
Internal Conv:  vm-dc-conventional (10.1.1.10)
                vm-fs-conventional (10.1.1.20)
                saconvresearch01 — Blob Storage
Identity:       Entra ID (ztaresearch.local / convresearch.local)
                testuser01, adminuser01
Monitoring:     law-zta-sentinel (Sentinel), law-conventional-monitor (Monitor)
Network:        vnet-zta, vnet-conventional, vnet-attacker (peered)
```

---

## S — Spoofing

**Threat:** An attacker impersonates a legitimate user or service to gain unauthorised access.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| S-01 | testuser01 domain account | Password guessing via `net use \\DC\IPC$` (T1110.001) | Conditional Access MFA — correct password alone is insufficient | None — password is the only factor | Low (ZTA) / High (Conv) |
| S-02 | adminuser01 Domain Admin account | Valid credentials used to access ADMIN$ (T1078) | JIT access requires time-boxed approval + MFA | None | Low (ZTA) / Critical (Conv) |
| S-03 | Blob storage anonymous request | Unauthenticated HTTP GET masquerading as legitimate request | PublicNetworkAccess: Disabled — no anonymous request reaches storage | PublicNetworkAccess: Enabled — no authentication required | None (ZTA) / Critical (Conv) |
| S-04 | Sentinel analytics identity | Rogue rule or modified query | Not in scope for this experiment | N/A | |

**STRIDE-S finding:** ZTA Conditional Access eliminates the risk of credential-only spoofing. Even if an attacker obtained valid credentials via phishing or data breach, the MFA requirement means they cannot authenticate without access to the registered MFA device. This addresses the most common real-world initial access technique. In the conventional environment, a correct password provides full identity spoofing capability.

---

## T — Tampering

**Threat:** An attacker modifies data, files, or system configuration without authorisation.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| T-01 | SMB file shares (HR_Records etc.) | Lateral movement to FS then file modification | NSG block-attacker-to-fs prevents SMB access entirely | None — SMB fully accessible once in VNet | None (ZTA) / High (Conv) |
| T-02 | Active Directory — domain objects | Modification of AD accounts/groups post-privilege escalation | JIT + NSG blocks ADMIN$ and DC admin share access | None — DC accessible with Domain Admin creds | Low (ZTA) / Critical (Conv) |
| T-03 | Blob storage files | Overwrite or delete blob contents | PublicNetworkAccess: Disabled — no write access possible | Public access enabled — write access possible with blob SAS | None (ZTA) / High (Conv) |
| T-04 | NSG rules | Modification of deny rules to allow attacker traffic | Contributor RBAC required — not available to attacker VM | Same | Low (both) |
| T-05 | Sentinel analytics rules | Disabling detection rules to evade monitoring | SecurityInsights RBAC required — not available to attacker | N/A | Low (ZTA) |

**STRIDE-T finding:** The ZTA network-layer controls (NSG + private endpoint) make tampering with file system assets impossible from the attacker's network position. The attacker cannot reach the file server SMB shares to modify them, and cannot reach the blob storage to write or delete objects. In the conventional environment, an attacker with valid credentials has full write access to file shares and, with a SAS token, could modify blob contents.

---

## R — Repudiation

**Threat:** A legitimate or malicious actor denies having performed an action, and there is insufficient evidence to refute the denial.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| R-01 | File share access | Attacker claims they did not access HR_Records | Sentinel EventID 4648 (explicit credential use) logged at time of access | No Sentinel — no audit trail | Low (ZTA) / High (Conv) |
| R-02 | Blob storage access | Attacker claims no storage access was attempted | Azure storage diagnostics log all AuthorizationFailure events with source IP | Storage diagnostics — but no SIEM correlation | Low (ZTA) / Medium (Conv) |
| R-03 | Domain Admin privilege use | Legitimate admin denies using elevated privileges during attack window | EventID 4672 (special privileges) + EventID 4648 logged for every privileged session | No equivalent audit trail | Low (ZTA) / High (Conv) |
| R-04 | Conditional Access policy changes | Admin denies disabling Security Defaults | Entra ID audit logs capture all CA policy changes with actor identity | Same | Low (both) |

**STRIDE-R finding:** Microsoft Sentinel provides non-repudiation for the ZTA environment — every EventID 4648 (explicit credential use) and 4672 (special privileges) event is timestamped, immutable, and correlated with source IP. The four attacker events captured at 19:36 and 20:21 UTC constitute forensic evidence of adversary activity that cannot be repudiated. The conventional environment has no equivalent non-repudiation capability.

---

## I — Information Disclosure

**Threat:** Sensitive data is exposed to parties who are not authorised to access it.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| I-01 | HR_Records SMB share | Lateral movement + data copy (T1039) | NSG blocks SMB access to file server | None — `Copy-Item` succeeds | None (ZTA) / Critical (Conv) |
| I-02 | Blob storage sensitive-documents | Unauthenticated HTTP GET (T1530) | PublicNetworkAccess: Disabled — AuthorizationFailure returned | HTTP 200 + file contents returned | None (ZTA) / Critical (Conv) |
| I-03 | Active Directory password hashes | DCSync or NTDS.dit dump after DC compromise | JIT + NSG blocks DC admin access | ADMIN$ accessible — DCSync possible post-compromise | Low (ZTA) / Critical (Conv) |
| I-04 | Network traffic contents | Man-in-the-middle within VNet | VNet encryption at rest/transit + Azure platform protection | Same | Low (both) |
| I-05 | Sentinel logs | Unauthorised query of security logs | SecurityInsights Reader RBAC required | N/A | Low (ZTA) |

**STRIDE-I empirical evidence:** Information disclosure was completely prevented in the ZTA environment across all three applicable test categories (T1039, T1530, T1078). The conventional environment disclosed information in 9 of 9 applicable runs — HR_Records documents were exfiltrated in all three T1039 runs, blob storage contents were returned in all three T1530 runs, and ADMIN$ access exposing the Windows system directory was granted in all three T1078 runs.

---

## D — Denial of Service

**Threat:** A legitimate service is made unavailable to authorised users.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| D-01 | Domain Controller availability | Brute force flood consuming LSASS resources | NSG throttles connection rate to DC (22–23s overhead observed) | No throttling — immediate connection | Low (ZTA) / Medium (Conv) |
| D-02 | File server SMB availability | Flood of connection requests to port 445 | NSG blocks all attacker connections before reaching FS | No block — connection requests reach FS | None (ZTA) / Medium (Conv) |
| D-03 | Azure Blob storage | Request flood to storage endpoint | PublicNetworkAccess: Disabled — requests rejected immediately at Azure infrastructure | Public access — requests processed | Low (ZTA) / Medium (Conv) |
| D-04 | Sentinel workspace | Log flooding to exhaust workspace capacity | 5GB/day free tier — legitimate concern for high-volume environments | N/A | Medium (both) |

**STRIDE-D finding:** DoS was not tested in this experiment (out of scope for a ZTA effectiveness study). However, the NSG micro-segmentation architecture provides indirect DoS resistance — because the attacker VNet cannot reach the file server on any port, a connection flood targeting the file server would be blocked at the NSG before consuming any file server resources.

---

## E — Elevation of Privilege

**Threat:** A lower-privileged account or process gains access to higher-privileged resources.

| Threat ID | Asset | Attack Vector | ZTA Mitigation | Conv Mitigation | Residual Risk |
|---|---|---|---|---|---|
| E-01 | ADMIN$ share (system-level access) | T1078 — valid Domain Admin account accesses ADMIN$ | JIT access locks port 445 on DC + NSG denies connection. Errors 64/53 returned. | No protection — ADMIN$ immediately accessible | None (ZTA) / Critical (Conv) |
| E-02 | Domain Admin group membership | T1136 — create new user, add to Domain Admins | Not simulated — would require prior code execution on DC | N/A | Medium (if DC initially compromised) |
| E-03 | PIM role activation | Attacker activates Global Administrator role | PIM: max 1hr, requires approval, requires MFA | N/A | Low (ZTA) |
| E-04 | Defender for Cloud access | Downgrade Defender tier to disable monitoring | Contributor RBAC required — not available to attacker | Free tier already — can't downgrade further | Low (both) |
| E-05 | Storage Blob Data Contributor | Attacker gains write access to storage | Private endpoint — no external write access | Role assignment via public management plane possible | Low (ZTA) / Medium (Conv) |

**STRIDE-E empirical evidence:** Privilege escalation (T1078 — ADMIN$ access) was blocked in all three ZTA runs by the combined operation of JIT access control (Error 64 — Run 1) and NSG deny rules (Error 53 — Runs 2–3). In the conventional environment, ADMIN$ was immediately accessible in all three runs, representing complete elevation of privilege — the attacker achieved domain controller-level file system access using a Domain Admin account with no additional control point.

---

## STRIDE Summary Matrix

| Threat Category | ZTA Risk Level | Conv Risk Level | Primary ZTA Control |
|---|---|---|---|
| **S** — Spoofing | 🟡 Low | 🔴 Critical | Conditional Access MFA + Block Legacy Auth |
| **T** — Tampering | 🟢 None | 🔴 Critical | NSG micro-segmentation + private endpoint |
| **R** — Repudiation | 🟡 Low | 🔴 High | Microsoft Sentinel EventID logging |
| **I** — Information Disclosure | 🟢 None | 🔴 Critical | NSG + PublicNetworkAccess: Disabled |
| **D** — Denial of Service | 🟡 Low | 🟠 Medium | NSG connection filtering |
| **E** — Elevation of Privilege | 🟢 None | 🔴 Critical | JIT access + NSG + PIM |

**Overall threat posture:**
- ZTA: 2 Low / 4 None — no critical or high residual risks
- Conventional: 1 Medium / 1 High / 4 Critical — all STRIDE categories at elevated risk
