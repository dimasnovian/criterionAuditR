# Validation results

The [cross-design protocol](examples/TRANSFER.md) covers 2,000 simulated ordinal profiles, 1,600 simulated dichotomous ability profiles, and 6,048 generated weighted task combinations. All 93 planted discrepancies across 20 rules were detected. Clean data agreed on all 64,576 evaluable rule values. The ability case checked 1,360 complete profiles for its total and classification rules.

On the simulated ordinal data, recomputation with `psych` 2.6.9 `scoreItems` exposed 35 discordant totals. The local audit distinguished 20 reverse-key errors, 15 total-score errors, and 10 threshold-label errors. All 18 checks matched explicit base R calculations across clean, faulty, and incomplete scenarios. See [COMPARISON.md](examples/COMPARISON.md).

The verification ran under R 4.6.1 on Windows 11. All 15 core tests and six psychometric demonstration checks passed. The command-line financial example used five original generated rows and returned zero discrepancies on its two rules. The case-specific results do not estimate validity or general diagnostic accuracy.
