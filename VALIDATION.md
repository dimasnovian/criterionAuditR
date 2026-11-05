# criterionAuditR validation evidence

## Primary psychological measurement demonstration

The executable `run_psychometric_example.R` generated and audited 2,000 profiles on a hypothetical eight-item questionnaire with two correlated facets and five ordered response categories. The clean run evaluated each of six equations in all 2,000 profiles with zero mismatches. The controlled faulty run found 20 reverse-key mismatches, 15 total-score mismatches, and 10 classification mismatches, exactly matching the planted errors. The remaining equations were internally consistent. See `outputs/psychometric_demo/injected_faults.csv` and the clean/injected rule checks.

The correlation of subscale A with its inclusive total was 0.7850655; with nonoverlapping subscale B it was 0.2524326. The independent five-item ordinal control (5,000 profiles) yielded item-total correlations .4346255 to .4602663 and item-rest correlations -.004573489 to .011864448. These are single seeded demonstrations. They do not estimate error prevalence, general detection performance, construct validity, or a newly proposed psychometric estimator.

The 15 core tests were rerun and passed under R 4.6.1 on Windows 11. Six additional demonstration integration checks passed: clean equations, agreement with the complete raw scoring key, exact planted-fault recovery, expected graph relationships, the independent ordinal control, and absence of declared overlap between disjoint subscales. Runtime locale warnings were unchanged; other operating systems remain untested.

The new example uses existing core API version 0.1.0. Full design details, seeds, scoring key, interpretation, and output paths are in `examples/PSYCHOMETRIC_EXAMPLE.md`. All new response data were simulated; no questionnaire was administered to people. The financial demonstration below is retained as a secondary software example.

## Observed external-data results

The data file used for the executed demonstration was the source-provided sample_10k_rows.csv, reconstructed from all 10,001 text lines without changing field values. It has 10,000 records and 274 variables, including 4,263 millionaire labels. The provider's separate validation report describes 100,000 records in the full source file; those full-file results were not recomputed here.

Local normalized UTF-8 LF copy SHA-256: `49340dfd1a2c90b5cd50d6ee1b7f3914a853adac1857281401cb4274acb84b0b`. This hash applies to the locally reconstructed CSV, not a byte-identical claim about the provider's download if line endings differ.

| Explicit executable rule | Evaluated sample records | Mismatches | Interpretation |
| --- | ---: | ---: | --- |
| net_worth = total_assets - total_liabilities | 10,000 | 0 | Absolute tolerance USD 0.02; maximum observed numeric error 0.01000000164 |
| millionaire_status = 1 if net_worth >= 1,000,000 | 10,000 | 0 | Exact binary equality |
| multi_millionaire_status = 1 if net_worth >= 5,000,000 | 10,000 | 0 | Exact binary equality |
| high_saver_status = 1 if savings_rate >= 0.20 | 10,000 | 7 | All discordances have published savings_rate=0.20 and label 0 |
| high_investor_status = 1 if investment_assets >= 100,000 | 10,000 | 0 | Exact binary equality |
| financial_independence_status = 1 if net_worth >= 25*12*monthly_expenses | 10,000 | 0 | Annual expenses operationalized as 12 times monthly expenses |

Seven saver-label discrepancies remain unresolved. They could reflect precision differences between internal and published values, a strict rather than inclusive threshold, or another undocumented generating choice. They are not automatically repaired or relabelled. Do not claim that the original generator was recovered.

Ten intentionally flipped millionaire labels yielded exactly ten mismatches, with all 10,000 sample labels evaluated. This control supports detection of those introduced errors only. It is not a general sensitivity/specificity benchmark of every leakage type.

The graph records three criterion ancestors for millionaire_status: net_worth, total_assets, and total_liabilities. Six additional variables share a declared ancestor. Four of those six rely on provenance-only analyst assumptions about the net-worth transforms or categories and have not been numerically verified. High correlations and dictionary flags alone do not prove a deterministic construction dependency.

## Independent response demonstration

Seed 20261105 generated a 5,000 by 5 matrix of independent standard normal responses using R. No latent psychological construct or real instrument was simulated. The five item-total correlations were 0.4483701, 0.4299349, 0.4581638, 0.4556624, and 0.4620708. The corresponding item-rest correlations were 0.00433845, -0.01164563, 0.01690634, 0.01452712, and 0.01691993. All five responses were declared construction parents of the summed criterion. This is one reproducible illustration, not a repeated-simulation estimator study.

## Execution and tests

Validation used R 4.6.1 (2026-06-24), x86_64-w64-mingw32/x64, on Windows 11 x64 build 26300. All 15 tests passed. The command-line entry point additionally produced zero mismatches on the included five-row original financial example. Source parsing and actual execution were both exercised. No installation into an R package library is required.

The observed external sample audit took 0.15 seconds in this single run, excluding input reading. This is not a hardware-controlled benchmark. The external sample data object occupied 20,660,648 bytes, not peak process memory. These incidental runtime values are retained in outputs/sample_summary.txt and are intentionally omitted from the brief manuscript.

Locale warnings were emitted at startup for LC_COLLATE, LC_CTYPE, LC_MONETARY, and LC_TIME because C.UTF-8 was unavailable in the Windows R session. The recorded session used locale C and system code page 65001. The numeric examples and tests completed successfully. Other operating systems have not been executed.

## Contribution and limitations

The practical contribution is recording user-declared score construction, graph paths, equation-check coverage, and exported audit evidence in one small base R program. Item-rest correlation and the general problem of leakage are established. The current work does not establish that this program is the first of its kind or superior to competing tools.

Revelle's official psych alpha documentation already reports raw and corrected item-whole correlations, including r.drop: https://www.personality-project.org/r/psych/help/alpha.html . criterionAuditR adds explicit rule provenance and graph paths; it is not a replacement for psych::alpha or a novel reliability estimator.

The financial data contain simulated behavioral scores without evidence here of validated item content, reliability, or construct validity. Their labels must not be represented as diagnoses or validated psychological classifications. The independent response demonstration explains an applied measurement issue, but editor interest and journal fit still require assessment. No acceptance or publication outcome is predicted.

