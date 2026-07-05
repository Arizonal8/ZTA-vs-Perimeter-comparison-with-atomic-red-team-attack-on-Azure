# Zero Trust vs Conventional Security — Comparison

## What This Section Does

This section provides a structured side-by-side comparison of the two security architectures evaluated in this research, across five dimensions: identity-based access, network segmentation, logging depth, attack surface, and lateral movement resistance. The comparison is grounded entirely in empirical evidence from the 30-run attack simulation, not theoretical claims.

---

## 1 — Identity-Based Access

The core philosophical difference between ZTA and conventional security is how they treat identity. Conventional security grants access based on network location — if you are inside the perimeter, you are trusted. ZTA treats every identity as untrusted regardless of location, requiring continuous verification.

| Dimension | ZTA Environment | Conventional Environment |
|---|---|---|
| Authentication model | Identity + MFA + device compliance | Username + password only |
| Conditional Access | Require MFA policy enforced for all users and all apps | Not configured |
| Legacy auth protocols | Blocked by CA policy (exchangeActiveSync, other) | Allowed — no restriction |
| Privileged access | PIM: max 1 hour, approval required, MFA on activation | Permanent Domain Admin — no time limit |
| Admin share access | ADMIN$ access rejected (Error 64/53) even with valid Domain Admin credentials | ADMIN$ accessible immediately with valid credentials |
| Credential theft resilience | Correct password alone is insufficient — MFA device also required | Correct password is sufficient for full authentication |

**Empirical finding:** Even though the credential theft wordlist did not contain the correct passwords in this study, the Conditional Access architecture means that in a real breach scenario where an attacker obtained valid credentials (e.g. via phishing), the ZTA environment would require an additional MFA factor that the attacker does not possess. The conventional environment would grant full access on credentials alone.

---

## 2 — Network Segmentation

Conventional perimeter security places trust in network location. ZTA implements micro-segmentation — granting the minimum network access required for each specific communication path, enforced at the packet level.

| Dimension | ZTA Environment | Conventional Environment |
|---|---|---|
| Architecture model | Micro-segmentation (deny by default, allow by exception) | Flat trust zone (allow by default inside perimeter) |
| Key NSG rule | block-attacker-to-fs priority 220 — Deny TCP 10.2.0.0/16 → 10.0.1.20 port 445 | allow-all-inbound — Allow TCP 10.2.0.0/16 → * port * |
| Attacker-to-DC access | Allowed on ports 3389/445 (required for credential theft simulation) | Allowed |
| Attacker-to-FS access | Denied at network layer — Error 53 | Allowed — SMB session established in <1 second |
| Inter-VM trust | DC can reach FS on port 445 (explicit allow) — all other paths denied | All VMs trust all VMs — no explicit deny rules |
| JIT access | Ports 3389 and 445 locked by default — 3-hour time-boxed approval required | Always open |

**Empirical finding:** The single NSG rule `block-attacker-to-fs` (priority 220) was the mechanism behind three of four successfully-blocked attack categories — Lateral Movement (T1021.002), Data Exfiltration (T1039), and partially Privilege Escalation (T1078). A single correctly-configured deny rule was worth more than the entire conventional security stack.

```
ZTA NSG Rule Evaluation Order:
150 → Allow Bastion (168.63.129.16)
200 → Allow attacker to DC only (10.0.1.10)
210 → Allow DC to FS on SMB (10.0.1.10 → 10.0.1.20)
220 → DENY attacker to FS on port 445 ← THE KEY RULE
230 → DENY attacker to FS on RDP
...
Default Deny — everything else blocked
```

---

## 3 — Logging Depth

A ZTA environment logs more, correlates better, and detects faster than a conventional environment because monitoring is a first-class security control, not an afterthought.

| Dimension | ZTA Environment | Conventional Environment |
|---|---|---|
| Monitoring platform | Microsoft Sentinel (SIEM + SOAR) | Azure Monitor (basic logging only) |
| Analytics rules | 5 scheduled rules — brute force, lateral movement, privilege escalation, file access, storage access | None configured |
| Log Analytics workspace | law-zta-sentinel — Sentinel-enabled | law-conventional-monitor — no Sentinel |
| Events during attack window | 623 security events (19:00–21:00 UTC, 16 June 2026) | Not available (export error — see data-analysis limitation) |
| Attacker IP detected | 4 events from 10.2.x in Sentinel logs | Not captured |
| EventID 4648 (explicit creds) | 2 events — attacker net use activity detected | Not captured |
| EventID 4625 (failed logon) | 0 events — attacks blocked before reaching auth layer | Not captured |
| Detection capability | Network-layer blocks visible as absence of 4625 events | No detection layer |

**Empirical finding:** The absence of EventID 4625 (Failed Logon) events in Sentinel during the credential theft phase is itself evidence that ZTA controls worked — attacks were blocked at the NSG layer before reaching the authentication service that would have generated 4625 events. In a conventional SIEM, you would see hundreds of 4625 events and know an attack was in progress. In the ZTA environment, the attacker never reached authentication, so there was nothing to log at that layer.

---

## 4 — Attack Surface

ZTA systematically reduces attack surface by applying the principle of least privilege not just to identities but to every network path, service, and resource.

| Dimension | ZTA Environment | Conventional Environment |
|---|---|---|
| Storage exposure | saztaresearch01 — PublicNetworkAccess: Disabled | saconvresearch01 — PublicNetworkAccess: Enabled |
| Blob container | Private — no anonymous access | Blob-level public access enabled |
| File server exposure | Not reachable from attacker VNet on port 445 | Fully reachable from attacker VNet |
| Domain controller exposure | Reachable on 445/3389 for simulation but JIT-protected | Fully reachable — no JIT |
| Defender for Cloud | Standard tier — vulnerability scanning, threat detection, regulatory compliance | Free tier — basic security recommendations only |
| Public attack surface | vm-attacker public IP only (research access) — all target VMs private | Same — but no network-layer protection once attacker enters VNet |

**The BlueBleed comparison:** In 2022, misconfigured Azure Blob storage containers with `allow_nested_items_to_be_public = true` exposed data belonging to 65,000+ organisations. The conventional environment in this study reproduced that exact configuration. `Invoke-WebRequest` returned HTTP 200 with file contents. The ZTA environment returned `AuthorizationFailure`. The difference: one boolean flag — `public_network_access_enabled`.

---

## 5 — Lateral Movement Resistance

Lateral movement is the post-compromise technique most responsible for turning a minor breach into a catastrophic one. It is where ZTA's micro-segmentation provides the most decisive advantage.

| Dimension | ZTA Environment | Conventional Environment |
|---|---|---|
| Lateral movement possible? | No — Error 53 all 3 runs | Yes — HR_Records share accessed in <1 second, all 3 runs |
| Data exfiltration possible? | No — File exfiltrated: False all 3 runs | Yes — documents copied to attacker machine all 3 runs |
| Privilege escalation possible? | No — Error 64 / Error 53 all 3 runs | Yes — ADMIN$ accessed with Domain Admin credentials |
| Attacker can reach file server? | No — NSG blocks port 445 from attacker subnet | Yes — no NSG deny rule |
| Blast radius if DC compromised | Limited — file server still protected by independent NSG rule | Total — file server immediately accessible once DC credentials obtained |
| Mean attack duration (ZTA) | 7.3–15.3 seconds per run (NSG evaluation overhead) | 0.3 seconds per run |
| Statistical significance | Fisher's exact test p = 7.40 × 10⁻⁷ | — |

**Why this matters beyond the lab:** In a real breach, lateral movement is the difference between an attacker accessing one machine and an attacker accessing every machine. The ZTA architecture in this study would have contained a breach to the initially-compromised machine (or VM) because NSG micro-segmentation means each segment is independently protected — compromising the attacker VM did not grant any access to the ZTA file server or domain controller's administrative shares.

---

## Summary Scorecard

| Security Dimension | ZTA Score | Conventional Score |
|---|---|---|
| Identity-Based Access | ✅ MFA + CA + PIM enforced | ❌ Password only |
| Network Segmentation | ✅ Deny-by-default NSG rules | ❌ Allow-all baseline |
| Logging Depth | ✅ Sentinel + 5 analytics rules | ❌ Basic monitoring only |
| Attack Surface | ✅ Storage private, ports locked | ❌ Storage public, all ports open |
| Lateral Movement Resistance | ✅ 0/12 attacks succeeded | ❌ 12/12 attacks succeeded |
| **Overall** | **5/5** | **0/5** |

**Fisher's exact test on attack outcomes: p = 7.40 × 10⁻⁷** — this difference is not attributable to chance.
