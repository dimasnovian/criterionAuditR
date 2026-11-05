# Comparing scoring and construction audits

The comparison uses the same 2,000 simulated eight-item questionnaire profiles and scoring key as the primary example. The scoring range is 1 to 5, with one reverse-keyed item, two subscales, their total, and an illustrative threshold label. The comparison addresses score recomputation, rule agreement, and tracing declared dependencies.

| Workflow | Role in this example | Evidence produced |
| --- | --- | --- |
| `psych::scoreItems()` with a declared scoring key | Recompute sums from raw items, including reversal | Three composites per profile. The function also provides reliability and overlap-adjusted associations. |
| Manual base R comparisons | Check each stored output against its immediate stored inputs | Counts of comparable and discordant values for each equation. |
| `criterionAuditR` | Run the same local checks and trace declared construction relationships | Counts, denominators, tolerances, directed edges, and predictor-to-criterion relationships derived from the rule specification. |

The first workflow uses the published `scoreItems` implementation. A separate comparison of its returned scores with stored scores identifies disagreements. The manual workflow implements six explicit equations and serves as an independent reference for the audit counts. General-purpose data validation tools can also check specified predicates, as illustrated by [pointblank's `col_vals_expr()`](https://rstudio.github.io/pointblank/reference/col_vals_expr.html). The experimental comparison uses base R for those checks. The graph provides a reusable link between a declared scoring equation and the variables that contribute to the criterion.

## Observed agreement and differences

All 6,000 recomputed composite values agreed with the clean data. The injected changes affected stored fields, so `scoreItems` returned the same recomputed values from the unchanged raw items. Comparing those values with the faulty stored fields yielded 20 differences for subscale A, zero for subscale B, and 35 for the total. Twenty of the total differences were propagated from a missed reversal. Fifteen were introduced at the total-score stage.

| Check against immediate stored inputs | Evaluated | Differences with criterionAuditR | Differences with manual R |
| --- | ---: | ---: | ---: |
| Reverse-keyed item | 2,000 | 20 | 20 |
| Subscale A | 2,000 | 0 | 0 |
| Subscale B | 2,000 | 0 | 0 |
| Total | 2,000 | 15 | 15 |
| Threshold label | 2,000 | 10 | 10 |
| Rescaled total | 2,000 | 0 | 0 |

The two approaches answer different questions. Recalculation from raw responses finds the full extent of deviations in stored totals. The local checks identify the particular equation that disagrees with its stored inputs, allowing an analyst to separate errors introduced at a stage from values consistently propagated from an earlier stage. The graph retains the declared path from the raw reverse-keyed item through its keyed value, subscale, and total to the label. The rescaled total shares a declared ancestor with the label. This distinction is relevant when a score-derived feature is proposed as a predictor of a classification built from the same score.

In a third scenario, 25 stored keyed responses were made missing, outside the injected fault rows. The reverse-key and subscale A checks each evaluated 1,975 records. The total and threshold equations still evaluated 2,000 records because their immediate stored inputs remained present. All 18 rule-by-scenario counts and denominators agreed with the independent manual reference. This design evaluates one scoring key and controlled faults. Results depend on the supplied equations and their coverage of the instrument's construction.

## Reproduce the comparison

Run from the repository root in R. The first script generates the source inputs. The comparison script uses an installed `psych` package by default.

```sh
Rscript run_psychometric_example.R
Rscript run_psychometric_comparison.R
```

The reported run used R 4.6.1 on Windows 11 and executed unchanged `psych` 2.6.9 R source functions in a separate R environment. Its source commit is [f0e9e6f](https://github.com/cran/psych/tree/f0e9e6f5beeaf5206c2b846f45a94edabb294d76/R). To reproduce that exact execution, obtain `make.keys.R`, `Pinv.R`, `smc.R`, `correct.cor.R`, `score.multiple.choice.R`, and `score.items.R` from that commit. Pass their directory as the second argument. The runner verifies the source files before loading them.

```sh
Rscript run_psychometric_comparison.R outputs/psychometric_comparison path/to/psych_source
```

The version and execution mode are recorded in `outputs/psychometric_comparison/sessionInfo.txt`. `recomputed_scores.csv` reports agreement with rescored composites. `rule_comparison.csv` contains the 18 comparisons. `criterion_paths.csv` contains graph evidence for the threshold criterion.

William Revelle's [scoreItems documentation](https://search.r-project.org/CRAN/refmans/psych/html/score.items.html) describes its scoring, reliability, and overlap corrections. The external comparator source remains under its own license and is obtained separately.
