# Charts — Python-Generated Analysis Figures

All figures produced by `analysis.py` using matplotlib 3.11.0, numpy 2.4.6, pandas 3.0.3, and scipy on the Ubuntu research host. All saved at 300 DPI.

| File | Figure | Contents |
|---|---|---|
| `chart1_attack_success_rate.png` | Fig 4.1 | Attack success rate (%) — ZTA vs conventional. Conventional: 100% success in 4 categories. ZTA: 0% in all 4. |
| `chart2_sentinel_events.png` | Fig 4.14 | Sentinel event volume during attack window — EventID bar chart + 5-minute timeline |
| `chart3_zta_effectiveness.png` | Fig 4.12 | ZTA effectiveness pie — 80% blocked, 20% inconclusive (Credential Theft wordlist gap) |
| `chart4_attack_duration.png` | Fig 4.15 | Mean attack duration — ZTA 15–22s vs conventional < 1s in 4 categories |
| `chart5_statistical_results.png` | Fig 4.16 | Statistical results — Fisher's p = 7.40×10⁻⁷ and Mann-Whitney p = 0.0016 on log scale + per-category success count |
| `fig_28_attack_success_rate_chart.png` | Fig 4.11 | Dissertation screenshot of chart1 as rendered in the Python terminal session |
| `fig_29_zta_effectiveness_pie_chart.png` | Fig 4.12 | Dissertation screenshot of chart3 |
| `fig_30_attack_duration_comparison_chart.png` | Fig 4.15 | Dissertation screenshot of chart4 |
| `fig_33_sentinel_event_volume_chart.png` | Fig 4.13 | Dissertation screenshot of Sentinel event volume |
| `fig_34_attack_duration_analysis_chart.png` | Fig 4.15b | Dissertation screenshot of duration analysis |
| `fig_35_statistical_results_chart5.png` | Fig 4.16 | Dissertation screenshot of chart5 |

The full `analysis.py` script that produced these is in `../commands.txt` Section 3.
