# Compare identical simulated inputs with published psych scoring and explicit base R checks.
full <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", full[grepl("^--file=", full)][1L])
root <- dirname(normalizePath(script, mustWork = TRUE))
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1L] else file.path(root, "outputs", "psychometric_comparison")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source(file.path(root, "criterionAuditR.R"))
source(file.path(root, "examples", "psychometric_rules.R"))

# With no second argument, use the installed package. The second argument accepts
# the unchanged R source files from the pinned 2.6.9 release for offline execution.
if (length(args) >= 2L) {
  upstream <- new.env()
  files <- c("make.keys.R", "Pinv.R", "smc.R", "correct.cor.R",
             "score.multiple.choice.R", "score.items.R")
  paths <- file.path(args[2L], files)
  expected_md5 <- c("57bccbaf3cbd2a46cb95149ee99119a5", "c550dee75a4dcaaf22d9d2748edb41d2",
                    "92653249587ab2eec617de48acd20689", "fc3df7b6ce61ea84b0f01507f60d9a72",
                    "24756e9e9bda9043a0b0c98bfb1b74a3", "c865ac9677c7800577ea7922ddefe486")
  if (!identical(unname(tools::md5sum(paths)), expected_md5)) {
    stop("Source files must match the pinned psych 2.6.9 release exactly.")
  }
  for (path in paths) sys.source(path, envir = upstream)
  score_items <- upstream$scoreItems
  implementation <- "psych 2.6.9 upstream R sources, commit f0e9e6f5beeaf5206c2b846f45a94edabb294d76"
} else {
  if (!requireNamespace("psych", quietly = TRUE)) stop("Install psych or supply the pinned upstream source directory as the second argument.")
  score_items <- psych::scoreItems
  implementation <- paste("installed psych", packageVersion("psych"))
}

d <- read.csv(file.path(root, "outputs", "psychometric_demo", "simulated_questionnaire.csv"))
stopifnot(nrow(d) == 2000L)
bad <- inject_psychometric_faults(d)
incomplete <- bad
incomplete$q4_key[seq.int(101L, 125L)] <- NA
items <- c("q1", "q2", "q3", "q4_raw", "q5", "q6", "q7", "q8")
keys <- list(subscale_a = c("q1", "q2", "q3", "-q4_raw"), subscale_b = items[5:8],
             total = c("q1", "q2", "q3", "-q4_raw", items[5:8]))
recompute <- function(data) {
  score_items(keys, data[, items], totals = TRUE, missing = FALSE,
              delete = FALSE, min = 1, max = 5)$scores
}
reference <- recompute(d)
rescored <- recompute(bad)
score_comparison <- data.frame(
  score = names(keys),
  clean_mismatches = colSums(reference != as.matrix(d[, names(keys)])),
  faulty_mismatches = colSums(rescored != as.matrix(bad[, names(keys)])),
  recomputed_values_changed = colSums(rescored != reference),
  n_evaluated = nrow(d), row.names = NULL)
stopifnot(all(score_comparison$clean_mismatches == 0L),
          identical(as.integer(score_comparison$faulty_mismatches), c(20L, 0L, 35L)),
          all(score_comparison$recomputed_values_changed == 0L))

# Manual checks use each stage's stored immediate inputs, matching the audit estimand.
manual_checks <- function(data) {
  expected <- data.frame(
    q4_key = 6 - data$q4_raw,
    subscale_a = rowSums(data[, c("q1", "q2", "q3", "q4_key")]),
    subscale_b = rowSums(data[, c("q5", "q6", "q7", "q8")]),
    total = rowSums(data[, c("subscale_a", "subscale_b")]),
    score_band = as.integer(data$total >= 24),
    rescaled_total = 100 * (data$total - 8) / 32)
  actual <- as.matrix(data[, names(expected)])
  expected <- as.matrix(expected)
  usable <- is.finite(actual) & is.finite(expected)
  data.frame(output = colnames(expected), n_evaluated = colSums(usable),
             n_mismatch = colSums(usable & (actual != expected)), row.names = NULL)
}
rules <- psychometric_rules()
predictors <- c("q4_raw", "total", "rescaled_total", "external_noise")
cases <- list(clean = d, injected = bad, incomplete = incomplete)
audit <- lapply(cases, ca_audit, criterion = "score_band", predictors = predictors, rules = rules)
comparison <- do.call(rbind, lapply(names(cases), function(name) {
  manual <- manual_checks(cases[[name]])
  checked <- audit[[name]]$checks
  stopifnot(identical(checked$output, manual$output),
            all(checked$n_evaluated == manual$n_evaluated),
            all(checked$n_mismatch == manual$n_mismatch))
  data.frame(scenario = name, output = checked$output,
             n_evaluated_audit = checked$n_evaluated, n_evaluated_manual = manual$n_evaluated,
             n_mismatch_audit = checked$n_mismatch, n_mismatch_manual = manual$n_mismatch)
}))
flags <- audit$injected$flags
stopifnot(flags$evidence[flags$predictor == "q4_raw"] ==
            "q4_raw -> q4_key -> subscale_a -> total -> score_band",
          flags$relationship[flags$predictor == "rescaled_total"] == "shared_component",
          flags$relationship[flags$predictor == "external_noise"] == "not_flagged")

write.csv(score_comparison, file.path(out, "recomputed_scores.csv"), row.names = FALSE)
write.csv(comparison, file.path(out, "rule_comparison.csv"), row.names = FALSE)
write.csv(flags, file.path(out, "criterion_paths.csv"), row.names = FALSE)
capture.output(cat(implementation, "\n"), sessionInfo(), file = file.path(out, "sessionInfo.txt"))
cat("Matched six manual checks in each of three scenarios.\n")
print(score_comparison, row.names = FALSE)
print(comparison[comparison$scenario != "clean", ], row.names = FALSE)
print(flags[, c("predictor", "relationship")], row.names = FALSE)
