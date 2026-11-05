# criterionAuditR

Base R software for auditing declared overlap between predictors and the variables used to construct a score or classification criterion.

**Version 0.1.0: development source distributed as executable R scripts.** This repository does not yet provide an installable R package or a CRAN release.

## Quick start

Download the repository ZIP using **Code > Download ZIP**, extract it, and open a terminal in the extracted directory. Alternatively:

```sh
git clone https://github.com/dimasnovian/criterionAuditR.git
cd criterionAuditR
```

Run the included demonstrations and tests:

```sh
Rscript run_examples.R
Rscript tests/run_tests.R
Rscript audit_file.R examples/financial_input.csv millionaire_status examples/financial_rules.R outputs/cli_demo
```

In PowerShell, when Rscript is not on PATH, use the quoted executable path with `&`, for example:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" .\run_examples.R
& "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" .\tests\run_tests.R
```

## What it does

- Records user-specified construction rules and rejects cyclic definitions.
- Traces direct and indirect criterion components, descendants, and shared construction ancestors.
- Checks executable equations with explicit tolerances and evaluated denominators.
- Distinguishes provenance-only relationships, missing columns, and unevaluable rows from verified equations.
- Exports CSV audit evidence and RDS result objects.
- Illustrates conventional item-total and item-rest correlations using independent generated responses.

For interactive use:

```r
source("criterionAuditR.R")
rules <- list(
  ca_rule("score", c("item1", "item2"),
          function(d) d$item1 + d$item2, tolerance = 1e-10),
  ca_rule("pass", "score", function(d) as.integer(d$score >= 10))
)
result <- ca_audit(my_data, "pass", c("item1", "item2", "score"), rules)
ca_write(result, "outputs/my_audit")
```

See [MANUAL.md](MANUAL.md) for arguments, interpretation, and limitations, and [VALIDATION.md](VALIDATION.md) for executed checks and observed results.

## Requirements and validation

Only base R is required. The program was tested under **R 4.6.1 on Windows 11 x64**, where all **15 automated tests passed**. macOS and Linux execution have not been tested. The input is read into memory, so required memory scales with input size. No API keys, network access, or contributed R packages are needed to run the included examples.

## Data and reproducibility

`examples/financial_input.csv` and `examples/score_input.csv` are original generated examples, recreated by `run_examples.R`.

An optional demonstration uses the external [Millionaire Habits Dataset](https://www.kaggle.com/datasets/datascikhan/millionaire-habits-dataset). Obtain that dataset separately, then run:

```sh
Rscript run_examples.R "/absolute/path/to/sample_10k_rows.csv" outputs
```

The observed external-data outputs in this repository use the supplied **10,000-row, 274-variable sample**. The full 100,000-row source file was not recomputed. The provider declares the data entirely synthetic. Original Kaggle records are not redistributed, and their terms are separate from the software license.

The sample's millionaire rule agrees with all 10,000 labels. Seven high-saver labels disagree at a published savings rate of 0.20; their cause remains unresolved. The control with ten deliberately flipped millionaire labels reports exactly ten mismatches. These are software demonstrations, not behavioral findings about real people.

Running demonstrations overwrites their generated input and output files in the selected example/output locations. To preserve the committed observed outputs, pass a separate output directory when using an external input.

## Repository contents

| Path | Contents |
| --- | --- |
| `criterionAuditR.R` | Core source functions |
| `audit_file.R` | Command-line CSV audit |
| `run_examples.R` | Executable demonstrations |
| `examples/` | Original generated inputs and rule definitions |
| `outputs/` | Observed CSV and RDS outputs, with the recorded R session |
| `tests/` | Automated tests and the observed test log |
| `MANUAL.md` | Program manual |
| `VALIDATION.md` | Validation evidence and scientific limits |

## Interpretation limits

An audit flag identifies a relationship in the supplied rule graph; it does not automatically prove inappropriate leakage. An unflagged variable is not guaranteed independent. The program cannot recover undisclosed construction rules, establish construct validity, or identify all statistical proxies. Conventional item-rest calculations are not claimed as a new estimator.

## License and source

The original software, documentation, and locally generated examples use the [MIT license](LICENSE). This license does not apply to external Kaggle data.

Source repository: https://github.com/dimasnovian/criterionAuditR

Data citation: datascikhan. (n.d.). *Millionaire habits dataset* [Synthetic data set]. Kaggle. https://www.kaggle.com/datasets/datascikhan/millionaire-habits-dataset
