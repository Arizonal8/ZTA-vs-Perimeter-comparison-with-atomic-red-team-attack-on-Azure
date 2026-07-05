"""
ZTA Research Statistical Analysis Pipeline
Sheffield Hallam University — MSc Dissertation 2026
Arinze Ihekweme | Module 55-710260

Run: python3 analysis.py
Requires: pandas, matplotlib, numpy, scipy
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats

# ── Load Sentinel CSV export ──────────────────────────────────
zta = pd.read_csv("data-analysis/Azure _Sentinel_query_data_ZTA.csv")
zta["time"] = pd.to_datetime(
    zta["TimeGenerated [UTC]"],
    format="%m/%d/%Y, %I:%M:%S.%f %p", errors="coerce")

attack = zta[
    (zta["time"].dt.hour >= 19) & (zta["time"].dt.hour <= 21) &
    (zta["time"].dt.date == pd.Timestamp("2026-06-16").date())]

print("Total events in workspace:", len(zta))
print("Events during attack window:", len(attack))
print(attack["EventID"].value_counts().to_string())

attacker = attack[attack["RenderedDescription"].str.contains("10.2.", na=False)]
print("Events from attacker VM (10.2.x):", len(attacker))

# ── Fisher's exact test: attack outcomes ──────────────────────
# Contingency: [[CONV_success, ZTA_success], [CONV_fail, ZTA_fail]]
# 4 categories x 3 runs = 12 per environment (Credential Theft excluded)
contingency_table = [[12, 0], [0, 12]]
oddsratio, pvalue = stats.fisher_exact(contingency_table)
print(f"\nFisher's Exact Test: OR={oddsratio}, p={pvalue:.2e}")

# ── Mann-Whitney U test: attack duration ──────────────────────
conv_durations = [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
zta_durations  = [23, 23, 1, 22, 23, 1, 22, 1, 1, 0, 0, 0]
statistic, p_duration = stats.mannwhitneyu(
    zta_durations, conv_durations, alternative="greater")
print(f"Mann-Whitney U: U={statistic}, p={p_duration:.4f}")

# ── Chart 1: Attack Success Rate ──────────────────────────────
categories = ["Credential\nTheft","Lateral\nMovement","Data\nExfiltration",
              "Privilege\nEscalation","Misconfiguration"]
conv_pct = [0, 100, 100, 100, 100]
zta_pct  = [0,   0,   0,   0,   0]
x = np.arange(len(categories)); w = 0.35
fig, ax = plt.subplots(figsize=(13, 6))
bars1 = ax.bar(x - w/2, conv_pct, w, label="Conventional", color="#C0392B", alpha=0.9)
bars2 = ax.bar(x + w/2, zta_pct,  w, label="ZTA",          color="#27AE60", alpha=0.9)
ax.set_ylabel("Attack Success Rate (%)", fontsize=12)
ax.set_title("Attack Success Rate: ZTA vs Conventional Perimeter Security", fontsize=13, fontweight="bold")
ax.set_xticks(x); ax.set_xticklabels(categories)
ax.set_ylim(0, 120); ax.legend(fontsize=11)
ax.axhline(y=100, color="grey", linestyle="--", alpha=0.4)
for bar in bars1:
    if bar.get_height() > 0:
        ax.annotate(f'{bar.get_height():.0f}%',
                    xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                    xytext=(0, 3), textcoords="offset points", ha="center", fontsize=10)
plt.tight_layout()
plt.savefig("data-analysis/charts/screenshots/chart1_attack_success_rate.png", dpi=300)
plt.close()
print("Chart 1 saved")

# ── Chart 2: Sentinel Event Volume ───────────────────────────
event_ids   = ["4624", "4672", "4648", "4625", "5140"]
event_names = ["Successful\nLogon", "Special\nPrivileges", "Explicit\nCredentials",
               "Failed\nLogon", "Share\nAccess"]
counts      = [324, 297, 2, 0, 0]
colors      = ["#2E75B6","#1F4E79","#E67E22","#E74C3C","#95A5A6"]
fig, ax = plt.subplots(figsize=(12, 6))
bars = ax.bar(event_names, counts, color=colors, alpha=0.9, width=0.5)
ax.set_title("Microsoft Sentinel Events During Attack Window (19:00–21:00 UTC, 16 June 2026)",
             fontsize=12, fontweight="bold")
ax.set_ylabel("Event Count", fontsize=11)
for bar in bars:
    h = bar.get_height()
    ax.annotate(str(int(h)),
                xy=(bar.get_x() + bar.get_width()/2, h),
                xytext=(0, 3), textcoords="offset points", ha="center", fontsize=11)
ax.axhline(y=0, color="black", linewidth=0.5)
plt.tight_layout()
plt.savefig("data-analysis/charts/screenshots/chart2_sentinel_events.png", dpi=300)
plt.close()
print("Chart 2 saved")

# ── Chart 3: ZTA Effectiveness Pie ───────────────────────────
labels  = ["ZTA Blocked\n(4 categories)", "Inconclusive\n(Credential Theft)"]
sizes   = [80, 20]
colors3 = ["#27AE60", "#F39C12"]
explode = (0.05, 0)
fig, ax = plt.subplots(figsize=(8, 8))
wedges, texts, autotexts = ax.pie(
    sizes, labels=labels, colors=colors3, explode=explode,
    autopct="%1.0f%%", startangle=90, textprops={"fontsize": 13})
for at in autotexts:
    at.set_fontsize(14); at.set_fontweight("bold")
ax.set_title("ZTA Effectiveness Across All 5 MITRE ATT&CK Categories",
             fontsize=13, fontweight="bold", pad=20)
plt.tight_layout()
plt.savefig("data-analysis/charts/screenshots/chart3_zta_effectiveness.png", dpi=300)
plt.close()
print("Chart 3 saved")

# ── Chart 4: Attack Duration Comparison ──────────────────────
cat_labels = ["Cred Theft\n(Runs 1-2)", "Cred Theft\n(Run 3)",
              "Lat Move\n(Runs 1-2)", "Lat Move\n(Run 3)",
              "Priv Esc\n(Run 1)", "Priv Esc\n(Runs 2-3)",
              "Data Exfil\n(Run 1)", "Data Exfil\n(Runs 2-3)",
              "Misconfig\n(All runs)"]
conv_durs = [0.7, 0.7, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
zta_durs  = [22.5, 1,  22.5, 1,  22,  0.3, 22,  0.3, 0.3]
x4 = np.arange(len(cat_labels)); w4 = 0.35
fig, ax = plt.subplots(figsize=(15, 6))
ax.bar(x4 - w4/2, conv_durs, w4, label="Conventional", color="#C0392B", alpha=0.9)
ax.bar(x4 + w4/2, zta_durs,  w4, label="ZTA",          color="#27AE60", alpha=0.9)
ax.set_ylabel("Duration (seconds)", fontsize=11)
ax.set_title("Attack Duration Comparison: ZTA Friction Effect vs Conventional (<1s)", fontsize=12, fontweight="bold")
ax.set_xticks(x4); ax.set_xticklabels(cat_labels, fontsize=9)
ax.legend(fontsize=11)
ax.axhline(y=0, color="black", linewidth=0.5)
plt.tight_layout()
plt.savefig("data-analysis/charts/screenshots/chart4_attack_duration.png", dpi=300)
plt.close()
print("Chart 4 saved")

# ── Chart 5: Statistical Results ─────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Left: p-values log scale
tests   = ["Fisher's Exact\n(Outcomes)", "Mann-Whitney U\n(Duration)"]
pvalues = [pvalue, p_duration]
colors5 = ["#27AE60", "#2980B9"]
axes[0].bar(tests, pvalues, color=colors5, alpha=0.9, width=0.4)
axes[0].axhline(y=0.05, color="red", linestyle="--", linewidth=1.5, label="p = 0.05 threshold")
axes[0].set_yscale("log")
axes[0].set_ylabel("p-value (log scale)", fontsize=11)
axes[0].set_title("Statistical Significance Tests", fontsize=12, fontweight="bold")
axes[0].legend(fontsize=10)
for i, (t, p) in enumerate(zip(tests, pvalues)):
    axes[0].text(i, p * 1.5, f"p={p:.2e}", ha="center", fontsize=10, fontweight="bold")

# Right: attack success count per category
cats5   = ["Cred\nTheft", "Lateral\nMove", "Data\nExfil", "Priv\nEsc", "Misconfig"]
conv5   = [0, 3, 3, 3, 3]
zta5    = [0, 0, 0, 0, 0]
x5 = np.arange(len(cats5)); w5 = 0.35
axes[1].bar(x5 - w5/2, conv5, w5, label="Conventional", color="#C0392B", alpha=0.9)
axes[1].bar(x5 + w5/2, zta5,  w5, label="ZTA",          color="#27AE60", alpha=0.9)
axes[1].set_ylabel("Successful Attacks (out of 3)", fontsize=11)
axes[1].set_title("Attack Successes Per Category", fontsize=12, fontweight="bold")
axes[1].set_xticks(x5); axes[1].set_xticklabels(cats5)
axes[1].set_yticks([0, 1, 2, 3]); axes[1].legend(fontsize=10)

plt.suptitle(f"Fisher p={pvalue:.2e} | Mann-Whitney U={statistic}, p={p_duration:.4f}",
             fontsize=11, style="italic", y=1.01)
plt.tight_layout()
plt.savefig("data-analysis/charts/screenshots/chart5_statistical_results.png", dpi=300)
plt.close()
print("Chart 5 saved")
print("\nAnalysis complete — 5 charts saved to data-analysis/charts/screenshots/")
