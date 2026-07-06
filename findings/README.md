# Research Findings Summary

> **Arinze Ihekweme — Sheffield Hallam University — MSc Dissertation 2026**
> Module: Research Methods and Strategies (55-710260)
> Supervisor: Jack Jacobi

---

## What Was Tested

This study empirically evaluated the effectiveness of Zero Trust Architecture (ZTA) controls in Microsoft Azure against five MITRE ATT&CK attack categories, comparing outcomes against a matched conventional perimeter-security baseline.

**Experimental design:**
- Two parallel Azure environments provisioned via Terraform IaC in UK South
- One ZTA-configured, one conventionally-secured — identical in every respect except security controls
- Five attack categories executed using Atomic Red Team v2.1.0 from a dedicated attacker VM
- Three repetitions per category per environment — 30 total attack runs
- Attack window: 16 June 2026, 19:08–20:21 UTC (73 minutes)
- Statistical validation: Fisher's exact test + Mann-Whitney U test (Python/SciPy)

**ZTA controls evaluated:**

| Control | Azure Implementation |
|---|---|
| Network micro-segmentation | NSG deny rules (priority 220/230) |
| Just-In-Time VM access | Defender for Cloud JIT policy |
| Enhanced threat detection | Defender for Cloud Standard tier |
| Storage private endpoint | PublicNetworkAccess: Disabled |
| Conditional Access | Entra ID P2 — Require MFA, Block Legacy Auth |
| Privileged Identity Management | PIM: 1hr max, approval required, MFA on activation |
| Security monitoring | Microsoft Sentinel + 5 scheduled analytics rules |

---

## What Was Discovered

### Finding 1 — ZTA blocked 100% of testable attacks

Across 12 testable attack runs (four categories × three repetitions — credential theft excluded), ZTA controls blocked every single attack. The conventional environment was compromised in all 12 equivalent runs.

```
ZTA:          0 / 12 attacks succeeded
Conventional: 12 / 12 attacks succeeded

Fisher's exact test: p = 7.40 × 10⁻⁷ (p < 0.0001)
Odds ratio: infinity
```

This result is statistically significant at the p < 0.001 level, meaning the difference cannot be attributed to chance or random variation in the experimental environment.

### Finding 2 — Network micro-segmentation was the highest-impact single control

A single NSG deny rule (`block-attacker-to-fs`, priority 220, denying TCP from 10.2.0.0/16 to 10.0.1.20 on port 445) was responsible for blocking three of four successfully-blocked attack categories:

- **Lateral Movement (T1021.002)** — Error 53, network path not found
- **Data Exfiltration (T1039)** — File exfiltrated: False (same NSG rule cascaded)
- **Privilege Escalation (T1078)** — Error 64/53 (JIT + NSG combined)

This finding directly supports Rose et al.'s (2020) micro-segmentation tenet — and demonstrates that a single correctly-configured network deny rule provides categorical protection against multiple post-compromise attack techniques simultaneously.

### Finding 3 — ZTA introduced statistically significant friction even where not categorically blocking

Mann-Whitney U test on attack duration data: **U = 119.0, p = 0.0016**

ZTA attacks took 22–23 seconds in categories where NSG overhead was measurable (credential theft Runs 1–2, lateral movement). Conventional attacks completed in under one second. This friction effect is independent of whether attacks were ultimately blocked — it confirms that ZTA controls impose measurable adversarial overhead even in ambiguous scenarios.

### Finding 4 — Storage misconfiguration is a one-setting vulnerability

The misconfiguration exploitation test (T1530) produced the clearest result in the entire study. Identical unauthenticated HTTP GET requests returned:

- **Conventional:** `StatusCode: 200` + full file contents (`CONFIDENTIAL DUMMY DATA`)
- **ZTA:** `AuthorizationFailure: This request is not authorized to perform this operation`

The single configuration difference: `public_network_access_enabled = true` vs `false`.

This directly replicates the conditions of the 2022 BlueBleed Azure Blob misconfiguration, which exposed data from 65,000+ organisations. The ZTA storage hardening — a single boolean configuration change — provides categorical protection against this attack class at zero performance cost.

### Finding 5 — Sentinel captured attacker activity but detection gaps remain

Microsoft Sentinel captured 623 security events during the attack window. EventID 4648 (Explicit Credentials) events at 19:36 and 20:21 UTC directly corresponded to attacker activity. The absence of EventID 4625 (Failed Logon) events confirmed that credential theft attempts were blocked at the network layer before reaching the authentication service.

Detection gaps identified:
- Azure Activity Log not connected as Sentinel data connector — T1530 storage attacks invisible to Sentinel
- Sentinel analytics rules used 5-minute scheduled interval — not real-time
- AzureActivity table empty — storage AuthorizationFailure events not captured in SIEM

---

## What Improved Security

Ranked by impact on attack outcomes:

1. **NSG micro-segmentation** — blocked 3/4 successfully-blocked categories. Highest ROI control.
2. **Storage private endpoint** — blocked T1530 categorically. Single boolean flag, zero performance cost.
3. **JIT VM access** — contributed to T1078 blocking via Error 64 (connection termination).
4. **Defender for Cloud Standard** — enhanced detection telemetry; did not directly block attacks but supported Sentinel monitoring.
5. **Microsoft Sentinel** — captured 623 events; detected attacker activity at 19:36 and 20:21 UTC.
6. **Conditional Access MFA** — not empirically tested due to wordlist gap but architecturally prevents credential-only authentication.
7. **PIM** — contributed to T1078 friction alongside JIT and NSG.

---

## What Failed

### Credential Theft (T1110.001) — Inconclusive

The attack wordlist (`Password1`, `1q2w3e4r`, `Password!`, `Spring2022`, `ChangeMe!`, `Summer2023`, `Winter2024`) did not contain the correct account passwords (`UserPass@123`, `AdminPass@123`). Both environments returned identical "all failed" outcomes.

**This is a methodological failure, not an architectural one.** A wordlist containing the correct passwords would have tested whether Conditional Access MFA could prevent authentication even with valid credentials — which is the primary identity-layer ZTA control. This test was not completed.

Recommended fix: include the target account passwords in the wordlist in future studies, or use a separate credential-stuffing wordlist known to contain the correct credentials.

### Sentinel Storage Detection — Configuration Gap

The `AzureActivity` table was empty throughout the experiment, meaning the T1530 storage attacks generated `AuthorizationFailure` events in Azure storage diagnostics but not in Sentinel. A Sentinel-only analyst would not have seen the storage attack.

Recommended fix: connect Azure Activity Log as a Sentinel data connector before the next experiment.

### Conventional Environment Telemetry — Export Error

Both Sentinel and Azure Monitor CSV exports appear to have been generated from the ZTA workspace scope. Comparative conventional environment monitoring data was therefore unavailable, limiting telemetry analysis to the ZTA environment only.

---

## What Is Recommended

### For Organisations Deploying ZTA in Azure

**Immediate (zero/low cost):**
1. Set `public_network_access_enabled = false` on all Azure Blob storage accounts containing sensitive data — the most impactful single configuration change available
2. Implement NSG deny rules at the subnet level blocking direct attacker-subnet-to-target-subnet traffic on ports 445 and 3389
3. Enable Microsoft Sentinel with the Azure Activity Log data connector (required to detect T1530 storage attacks in SIEM)

**Short-term (requires Entra ID P2):**
4. Implement Conditional Access requiring MFA for all users and all applications
5. Block legacy authentication protocols via Conditional Access
6. Enable Just-In-Time VM access on all internet-exposed or sensitive VMs

**Medium-term:**
7. Implement Privileged Identity Management for all privileged roles with approval workflows and time-bounded activation
8. Upgrade Sentinel analytics rules from 5-minute scheduled to NRT (Near Real-Time) for faster threat detection
9. Implement a credential attack wordlist covering all known/suspected account passwords in red team exercises

### For Future Research

1. **Repeat credential theft with correct passwords in wordlist** to empirically test Conditional Access MFA effectiveness
2. **Extend to container and serverless workloads** (AKS, Azure Functions) — these present different attack surfaces not covered in this study
3. **Add outbound traffic controls** — this study evaluated inbound attacks only; ZTA's effectiveness against data exfiltration via outbound channels (T1048) was not tested
4. **Longitudinal study** — a multi-session study would enable alert fatigue analysis and attacker persistence detection
5. **Test against evasion techniques** — this study used straightforward attack commands; real adversaries use obfuscation and living-off-the-land techniques that may behave differently against ZTA controls

---

## Statistical Summary

| Test | Input | Result | Interpretation |
|---|---|---|---|
| Fisher's Exact Test | `[[0,12],[12,0]]` — ZTA vs conventional, 4 categories × 3 runs | p = 7.40 × 10⁻⁷, OR = ∞ | Reject H₀ at p < 0.0001 — difference not attributable to chance |
| Mann-Whitney U Test | 12 ZTA durations vs 12 conventional durations (seconds) | U = 119.0, p = 0.0016 | ZTA significantly slower — friction effect confirmed |

**Hypothesis result:** The null hypothesis (H₀: ZTA controls do not significantly reduce attack success rates compared to conventional perimeter security in Microsoft Azure) is rejected at p < 0.0001.

---

## Academic Contribution

This study makes three specific contributions to the cloud security literature:

1. **First controlled experimental comparison** of ZTA and conventional security in Microsoft Azure using genuine attack tooling (Atomic Red Team) rather than simulation, across five MITRE ATT&CK categories in a single study

2. **Quantitative statistical validation** of ZTA effectiveness using Fisher's exact test and Mann-Whitney U test applied to empirical attack outcomes — not theoretical claims

3. **Replicable open-source framework** — this entire experimental environment (Terraform IaC, PowerShell configuration, Python analysis, KQL queries) is published in this repository, enabling independent replication and extension by future researchers

---

*Full dissertation: "Evaluating the Effectiveness of Zero Trust Architecture in Securing Microsoft Azure Cloud Environments" — Sheffield Hallam University, June 2026*
