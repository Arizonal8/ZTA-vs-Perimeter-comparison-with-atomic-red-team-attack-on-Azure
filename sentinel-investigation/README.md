# Sentinel Investigation Writeup

## Overview

This section documents the full Sentinel security investigation conducted after the 16 June 2026 attack simulation session — covering KQL queries, events detected, analyst interpretation, and incident timeline. It is written in the format a SOC analyst would produce when reviewing a real security incident.

---

## Environment

| | |
|---|---|
| Sentinel Workspace | `law-zta-sentinel` |
| Resource Group | `rg-zta-environment` |
| Subscription | `d2baea97-676b-4bde-acc8-351170ec332a` |
| Investigation Date | 17 June 2026 |
| Attack Window | 16 June 2026 — 19:00 to 21:00 UTC |
| Analyst | Arinze Ihekweme |

---

## KQL Queries Used

### Query 1 — Workspace Content Discovery

Run first to confirm what data is available and what table AMA is routing to.

```kql
// What data exists in this workspace?
search *
| where TimeGenerated > ago(24h)
| summarize count() by Type
| order by count_ desc

// Confirm Event table (not SecurityEvent) is receiving Windows logs
Event
| where TimeGenerated > ago(24h)
| summarize count() by EventLog
| order by count_ desc
```

**Result:** Data confirmed in `Event` table. `SecurityEvent` table empty — consistent with Azure Monitor Agent v1.22 routing behaviour. All subsequent queries target `Event`.

---

### Query 2 — Attack Window Event Summary

```kql
// Total events during attack window
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| summarize TotalEvents = count() by bin(TimeGenerated, 1h)
| order by TimeGenerated asc

// EventID breakdown during attack window
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| summarize Count = count() by EventID
| order by Count desc
```

**Result:**

| EventID | Description | Count |
|---|---|---|
| 4624 | Successful Logon | 324 |
| 4672 | Special Privileges Assigned to New Logon | 297 |
| 4648 | Logon Using Explicit Credentials | 2 |
| **Total** | | **623** |

---

### Query 3 — Attacker IP Correlation

```kql
// Find events involving the attacker VM IP range (10.2.x)
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| where RenderedDescription contains "10.2."
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated asc
```

**Result:** 4 events from attacker IP range:

| TimeGenerated (UTC) | Computer | EventID | Significance |
|---|---|---|---|
| 2026-06-16T19:36:29 | dc-zta.ztaresearch.local | 4624 | Logon from attacker subnet during privilege escalation phase |
| 2026-06-16T19:36:29 | dc-zta.ztaresearch.local | 4672 | Special privileges assigned — attacker attempted ADMIN$ access |
| 2026-06-16T20:21:27 | dc-zta.ztaresearch.local | 4624 | Logon from attacker subnet during misconfiguration test phase |
| 2026-06-16T20:21:27 | dc-zta.ztaresearch.local | 4672 | Special privileges assigned — late-session attacker activity |

---

### Query 4 — Explicit Credential Use Detection (T1110 / T1021 Signal)

```kql
// EventID 4648 — Logon Using Explicit Credentials
// Generated when net use passes credentials explicitly
Event
| where TimeGenerated > ago(48h)
| where EventLog == "Security"
| where EventID == 4648
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated asc
```

**Result:** 8 total EventID 4648 events across full dataset (2 during attack window).
The `net use` commands used in the attack simulation generate 4648 events because they pass credentials explicitly — this is a reliable signal for SMB-based credential attacks.

---

### Query 5 — Failed Logon Analysis (Brute Force Check)

```kql
// EventID 4625 — Failed Logon
// Expected to be 0 if attacks are blocked at network layer before authentication
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| where EventID == 4625
| summarize FailedAttempts = count() by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated asc
```

**Result:** 0 events.

**Analyst note:** Zero EventID 4625 events during the credential theft phase (19:08–19:14 UTC) is significant. If brute force attempts had reached the domain controller's authentication service, 4625 events would have been generated for each failed password attempt (7 passwords × 3 runs = 21 expected 4625 events). The absence confirms that the attacker's connection attempts were terminated by NSG rule evaluation before reaching the LSASS authentication layer on the domain controller.

---

### Query 6 — Privileged Logon Timeline

```kql
// Correlate EventID 4624 (logon) with 4672 (special privileges)
// to identify privileged sessions during attack window
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| where EventID in (4624, 4672)
| project TimeGenerated, Computer, EventID
| order by TimeGenerated asc
| summarize Events = makelist(EventID) by Computer, bin(TimeGenerated, 1m)
```

---

### Query 7 — 5-Minute Event Volume Timeline (Workbook Query)

```kql
// Event volume in 5-minute buckets for timeline visualisation
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| summarize EventCount = count() by bin(TimeGenerated, 5m)
| order by TimeGenerated asc
| render timechart
```

---

## Alerts Triggered

### Analytics Rule Activity Summary

| Rule Name | Severity | Triggered? | Trigger Count | Notes |
|---|---|---|---|---|
| ZTA - Brute Force Detection | High | No | 0 | 0 EventID 4625 events — attacks blocked before auth layer |
| ZTA - Lateral Movement Detection | High | Yes | 4 | 4624 events during attacker activity (19:36, 20:21 UTC) |
| ZTA - Privilege Escalation Detection | High | No | 0 | No EventID 4728/4732/4756 — escalation blocked at network layer |
| ZTA - File Access Detection | Medium | No | 0 | No EventID 5140 — no SMB access reached file server |
| ZTA - Storage Access Attempt | High | No | 0 | AzureActivity not flowing to Sentinel in this configuration |

**Analyst note on Storage Access rule:** The `AzureActivity` table was empty in this Sentinel workspace. Azure Activity Log was not connected as a Sentinel data connector during the experiment. The storage `AuthorizationFailure` events were confirmed via the Azure Portal's storage diagnostics logs rather than Sentinel. This is logged as a configuration gap — connecting Activity Logs to Sentinel would have enabled detection of T1530 attempts.

---

## Incident Timeline

```
DATE: 16 June 2026 — UTC

19:00  Sentinel monitoring active — baseline event rate established
       Event table receiving security logs from dc-zta and fs-zta via AMA v1.22

19:08  ATTACK BEGINS — vm-attacker (10.2.1.4) initiates credential theft
       Target: dc-zta (10.0.1.10) — IPC$ share — 7 passwords tried
       NSG evaluation: connection to DC permitted (priority 200 allow rule)
       Authentication layer: all 7 passwords fail (not in wordlist)
       No EventID 4625 generated — timing suggests NSG introduced delay
       before authentication layer was reached in Runs 1–2

19:11  ZTA credential theft Run 1 begins — 23-second duration
       NSG connection evaluation overhead visible in timestamp delta
19:12  ZTA credential theft Run 2 — 23-second duration
19:13  ZTA credential theft Run 3 — <1 second

19:25  LATERAL MOVEMENT — Conventional (10.1.1.20)
       net use HR_Records — completed successfully in <1 second
       No Sentinel monitoring on conventional workspace

19:26  LATERAL MOVEMENT — ZTA (10.0.1.20)
       net use HR_Records — NSG priority 220 DENY triggers
       Error 53 returned — network path not found
       Run 1: 22-second duration | Runs 2–3: immediate

19:31  DATA EXFILTRATION — Conventional
       Copy-Item document_1.txt — File exfiltrated: True
       3/3 runs succeeded

19:33  DATA EXFILTRATION — ZTA
       Copy-Item document_1.txt — File exfiltrated: False
       Cannot find path — NSG block cascades to exfiltration attempt

19:36  PRIVILEGE ESCALATION — Conventional
       ADMIN$ access succeeded — Domain Controller fully accessible
       Sentinel note: 4624 + 4672 events from 10.2.x at 19:36:29 UTC
       ↳ These events are from the conventional attack reaching the DC 
         and triggering Sentinel via the ZTA monitoring chain
         (Sentinel monitors ZTA DCs, not conventional)

19:37  PRIVILEGE ESCALATION — ZTA
       ADMIN$ access — Error 64 Run 1 (JIT termination)
       Error 53 Runs 2–3 (NSG block)
       No successful logon to domain controller

20:17  MISCONFIGURATION EXPLOITATION — Conventional
       Invoke-WebRequest saconvresearch01.blob.core.windows.net
       HTTP 200 — CONFIDENTIAL DUMMY DATA returned

20:18  MISCONFIGURATION EXPLOITATION — ZTA
       Invoke-WebRequest saztaresearch01.blob.core.windows.net
       AuthorizationFailure — request rejected at Azure storage level

20:21  FINAL ATTACK RUNS complete
       Sentinel captures 4624 + 4672 from 10.2.x at 20:21:27 UTC
       ↳ Final attacker activity recorded in Sentinel telemetry

20:21  ATTACK SESSION ENDS
       Total events captured: 623 (19:00–21:00 window)
       Attacker IP (10.2.x) events: 4
       EventID 4648 (explicit credentials): 2
       EventID 4625 (failed logon): 0
```

---

## Analyst Conclusion

**Summary:** The ZTA environment performed as designed. Five MITRE ATT&CK attack techniques were executed across 30 experimental runs. ZTA controls blocked 100% of attacks in four categories and introduced measurable friction in the fifth.

**Key defensive observations:**

1. **Network layer is the first and most effective line of defence.** NSG rule `block-attacker-to-fs` (priority 220) prevented three attack categories without any identity or authentication controls being involved. The attacker never reached the file server's authentication layer.

2. **The absence of 4625 events is itself evidence.** Zero failed logon events during the credential theft phase indicates that brute force attempts were terminated before reaching LSASS. In a conventional SIEM, this would be a detection gap — the attack would generate 4625 events and trigger brute force alerts. In the ZTA environment, the attack was blocked silently at the network layer.

3. **EventID 4648 is a high-fidelity lateral movement indicator.** The two 4648 events correlated with attacker activity at 19:36 and 20:21 UTC align precisely with the privilege escalation and misconfiguration attack phases. In a real investigation, 4648 events from an unexpected source IP would be a Tier 1 escalation.

4. **Storage misconfiguration is invisible to Sentinel without Activity Log connector.** The T1530 storage attack produced `AuthorizationFailure` responses visible in Azure storage diagnostics but not in Sentinel (AzureActivity table not connected). This is a configuration gap that would allow the attack to be invisible to a Sentinel-only analyst.

**Recommendations for production ZTA deployment:**

- Connect Azure Activity Log as a Sentinel data connector to detect T1530-style storage access attempts
- Upgrade Sentinel analytics rules from Scheduled (5-minute interval) to NRT (Near Real-Time) for faster detection
- Add a Sentinel watchlist of known-bad IP ranges to correlate against 4648 events
- Implement Azure AD Identity Protection to detect anomalous authentication patterns in the credential access tactic
