# criterionAuditR program manual

## Purpose in applied measurement

When an item contributes to a total score, associating the item with that total partly reflects its own inclusion. A classification created by thresholding a score similarly shares information with that score and its transformations. criterionAuditR stores these construction relationships, traces direct and indirect dependencies, and checks supplied equations against observed values. The user interprets whether an overlap is appropriate for the intended analysis. Reconstructing an operational scoring rule can legitimately require its components.

The program's intended contribution is an inspectable record joining declared provenance, row-level rule checks, and exportable review evidence. Item-rest correlations are established statistics. `psych::alpha()` already reports `r.drop`, the correlation of each item with the remaining scale. criterionAuditR does not claim to introduce that statistic or replace psychometric reliability software. See Revelle's official documentation: https://www.personality-project.org/r/psych/help/alpha.html

## Primary questionnaire workflow

Run `Rscript run_psychometric_example.R` from the program directory. The example audits a negatively keyed item, two subscales, the inclusive total, a threshold band, and a linear rescaling. It generates 2,000 five-category profiles and a separate 5,000-profile independent ordinal control. The scoring rule and generating model are documented in [examples/PSYCHOMETRIC_EXAMPLE.md](examples/PSYCHOMETRIC_EXAMPLE.md). No observed human data or validated scale is implied. `ca_partwhole` receives responses after the explicit reverse key has been applied.

For interactive use, source `examples/psychometric_rules.R` after the core file, read `outputs/psychometric_demo/simulated_questionnaire.csv`, and call `ca_audit(data, "total", c("q4_raw", "subscale_a", "score_band"), psychometric_rules())`. The returned paths distinguish an item's indirect contribution through its key and subscale from a label derived from the total. A rule check verifies local numerical consistency against stored direct parents. It does not automatically repair entries or prove that an incorrect upstream value did not propagate to apparently consistent downstream values.

## Define construction rules

```r
source("criterionAuditR.R")
rules <- list(
  ca_rule("score", c("item1", "item2"),
          function(d) d$item1 + d$item2, tolerance = 1e-10),
  ca_rule("pass", "score", function(d) as.integer(d$score >= 10))
)
result <- ca_audit(data, criterion = "pass",
                   predictors = c("item1", "item2", "score"), rules = rules)
ca_write(result, "outputs/my_audit")
```

Each `ca_rule(output, parents, compute=NULL, description="", tolerance=0)` names exactly one output and its direct construction parents. `compute` receives a data frame of complete input rows and must return a single atomic vector with one value per row. A scalar return is rejected rather than recycled. Use `NULL` for an unverified construction relationship without an executable formula. The function must be reviewed code you trust: rule functions execute R code. Factors and character predictions use exact string equality; numeric and logical values use absolute error against `tolerance`. No relative tolerance is added implicitly. Specify a tolerance in the measurement unit of the output.

The graph must be acyclic; duplicate output definitions and cycles are errors. Descriptive rules may refer to columns absent from the current data subset. Those rules receive a visible `missing_columns` status instead of being counted as verified.

## Audit input and return value

`ca_audit(data, criterion, predictors=setdiff(names(data),criterion), rules)` requires a nonempty data frame with unique column names, one observed criterion, and unique observed predictor names. The return value contains:

| Field | Meaning |
| --- | --- |
| criterion | Name of the specified score or classification |
| flags | Predictor relationships and a path or shared-ancestor record |
| checks | Equation results with explicit evaluated and excluded counts |
| edges | Declared parent to output edges |
| n_rows | Number of input observations |
| version | Program version |

## Interpret predictor relationships

| Relationship | Meaning and interpretation |
| --- | --- |
| criterion_itself | The criterion was explicitly included among predictors |
| criterion_component | Predictor is a direct or indirect construction ancestor of the criterion |
| criterion_descendant | Predictor was constructed directly or indirectly from the criterion |
| shared_component | Predictor and criterion share at least one declared construction ancestor |
| not_flagged | No relationship was found in the supplied graph; this is not a guarantee of independence or absence of leakage |

Shared ancestry is broader than deterministic reconstruction. A high threshold sibling of a lower threshold criterion need not reveal every lower-threshold label. The audit records structural overlap and leaves the substantive decision to the researcher. Associations alone are never used to infer a construction rule.

## Interpret rule checks

`evaluated` means at least one complete finite row was numerically or categorically compared. `provenance_only` means a graph relationship has no formula to execute. `missing_columns` identifies absent variables. `no_evaluable_rows` means no row supported a finite comparison. Missing, non-finite, and undefined calculated values do not silently pass. Always inspect `n_evaluated` and `n_unevaluated` alongside `n_mismatch`. A zero mismatch count with zero evaluated rows is not validation.

`max_absolute_error` describes the largest observed numeric difference, even if within the declared tolerance. The financial identity uses USD 0.02 to accommodate cent-level independent rounding; binary thresholds use exact equality. `mismatch_rate` is calculated over evaluated rows only. The supplied program exports counts and aggregate checks, not a list of individual discrepant records.

## Part-whole illustration

`ca_partwhole(data, items)` computes `cor(item, sum(items))` and `cor(item, sum(other items))` using the same complete finite rows for every item. At least two numeric items and three complete rows are required. Constant variables yield `NA` correlations. Reverse scoring, weights, missing-value imputation, polytomous IRT, and measurement invariance are outside this function's scope. Apply a justified scoring key before analysis.

`run_examples.R` generates 5,000 sets of five independent standard normal responses with seed 20261105. These continuous responses are a mathematical teaching example, not a validated psychological instrument. Item-total correlations are expected to reflect structural inclusion. Item-rest correlations provide a control. Neither statistic is evidence of criterion validity for a real scale in this artificial example.

## External dataset rules

Six executable checks are supplied: the net-worth identity and five explicitly documented binary definitions. Four additional relationships for net-worth transforms and wealth groupings are labelled provenance-only because exact formulas or cutpoints are unavailable. Their parent assignment is an analyst interpretation of the variable names and dictionary, and requires source-author confirmation before stronger claims. No empirical formula checks are reported for these four outputs.

The financial-independence rule annualizes monthly expenses as 12 times the reported monthly value. The dataset README defines independence as net worth at least 25 times annual expenses. This is an explicit operationalization and should be reviewed if the source creator provides a different annual expense definition.

## Save and rerun

`ca_write(audit,directory)` saves predictor_flags.csv, rule_checks.csv, declared_edges.csv, and audit.rds. Existing files with those names in the selected output directory are replaced. `Rscript tests/run_tests.R` runs 15 tests. `run_examples.R` recreates the local example inputs and outputs; with an external CSV argument it additionally creates the external audit and a control with ten intentionally flipped labels.

## Scientific limits

The program cannot recover undisclosed score construction, identify every statistical proxy, assess availability of variables at future prediction time, estimate construct validity, infer causal relationships, or establish absence of train-test contamination. Audit completeness is bounded by the rule specification. Strong claims require source provenance, intended-use definitions, and independent validation data. A single demonstration and 15 unit tests are not evidence of superiority to other audit software.
