# criterionAuditR

An MIT-licensed base R program for auditing stored scores against declared rules and tracing how items contribute to constructed criteria. It is distributed as runnable R scripts, with a command-line entry point and reusable functions.

## Run the demonstrations

Open a terminal in the extracted folder and run:

```sh
Rscript run_psychometric_example.R
Rscript run_score_transfer.R
Rscript tests/run_tests.R
Rscript audit_file.R examples/financial_input.csv millionaire_status examples/financial_rules.R outputs/cli_demo
```

The primary examples use only locally generated input. No external response files or contributed R packages are needed. The optional scoring comparison uses the published `psych` implementation on the same simulated ordinal data. See [COMPARISON.md](examples/COMPARISON.md) for the separate dependency and reproduction command.

The archive contains [the manual](MANUAL.md), [the cross-design protocol](examples/TRANSFER.md), [validation results](VALIDATION.md), generated input CSVs, and audit outputs. The data and code are available under the [MIT license](LICENSE). The program reads input into memory and was tested under R 4.6.1 on Windows 11 x64.
