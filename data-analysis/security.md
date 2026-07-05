# Security Analysis — Data Collection and Statistical Interpretation

## Sentinel KQL Queries — ZTA Environment (law-zta-sentinel)

```kql
// Full security event export for Python analysis
Event
| where TimeGenerated > ago(7d)
| where EventLog == "Security"
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated desc
// Export: click Export → Export to CSV

// Attack window filter (16 June 2026 19:00-21:00 UTC)
Event
| where TimeGenerated between
    (datetime(2026-06-16T19:00:00) .. datetime(2026-06-16T21:00:00))
| where EventLog == "Security"
| summarize count() by EventID, Computer
| order by count_ desc

// Attacker IP correlation — events referencing 10.2.x
Event
| where TimeGenerated > ago(24h)
| where EventLog == "Security"
| where RenderedDescription contains "10.2."
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated desc

// Brute force detection (>3 failed logons in 5 min)
Event
| where TimeGenerated > ago(24h)
| where EventLog == "Security"
| where EventID == 4625
| summarize FailedAttempts = count() by Computer, bin(TimeGenerated, 5m)
| where FailedAttempts > 3

// Explicit credential use (net use attack evidence — EventID 4648)
Event
| where TimeGenerated > ago(24h)
| where EventLog == "Security"
| where EventID == 4648
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated desc
```

## Azure Monitor KQL Queries — Conventional (law-conventional-monitor)

```kql
// Heartbeat — confirm Azure Monitor Agent is running
Heartbeat
| where TimeGenerated > ago(24h)
| summarize count() by Computer
| order by count_ desc

// Security events export
Event
| where TimeGenerated > ago(7d)
| where EventLog == "Security"
| project TimeGenerated, Computer, EventID, RenderedDescription
| order by TimeGenerated desc
```

## Python Statistical Analysis

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats

# -- Load and filter Sentinel CSV export --
df = pd.read_csv("query_data_security_event.csv")
df["time"] = pd.to_datetime(df["TimeGenerated [UTC]"], errors="coerce")

attack = df[
  (df["time"].dt.hour >= 19) &
  (df["time"].dt.hour <= 21) &
  (df["time"].dt.date == pd.Timestamp("2026-06-16").date())
]

print("Events during attack window:", len(attack))
print(attack["EventID"].value_counts())

# -- Fisher's exact test: binary attack outcomes --
# Contingency table: [[ZTA_success, ZTA_fail], [Conv_success, Conv_fail]]
# 4 categories x 3 runs = 12 testable runs per environment (Credential Theft excluded)
table = [[0, 12], [12, 0]]
oddsratio, pvalue = stats.fisher_exact(table)
print(f"Fisher: OR={oddsratio}, p={pvalue:.2e}")
# Expected: OR=inf, p=7.40e-07

# -- Mann-Whitney U: attack duration --
conv_dur = [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]  # seconds, 12 runs
zta_dur  = [23,23, 1,22,23, 1,22, 1, 1, 0, 0, 0]  # seconds, 12 runs
U, p_mw = stats.mannwhitneyu(zta_dur, conv_dur, alternative="greater")
print(f"Mann-Whitney: U={U}, p={p_mw:.4f}")
# Expected: U=119.0, p=0.0016
```

## Security Event ID Reference

| EventID | Name | Relevance to Experiment |
|---|---|---|
| 4624 | Successful Logon | Normal logon activity — 324 events during attack window |
| 4625 | Failed Logon | Brute force indicator — 0 events (attacks blocked at network layer before auth) |
| 4648 | Logon Using Explicit Credentials | `net use` credential events — 2 events during attack window, 4 from attacker IP (10.2.x) |
| 4672 | Special Privileges Assigned | Privileged session activity — 297 events during attack window |
| 5140 | Network Share Object Accessed | File share access — not triggered (all SMB blocked by NSG before reaching share) |

**Key insight:** The complete absence of EventID 4625 (Failed Logon) events confirms that brute force attempts were blocked at the network layer (NSG) before reaching the authentication layer. If they had reached the DC's authentication service, 4625 events would have been generated.
