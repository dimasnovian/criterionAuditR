# Reproducible applied-measurement demonstration; all responses are simulated.
full <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", full[grepl("^--file=", full)][1L])
root <- dirname(normalizePath(script, mustWork = TRUE))
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1L] else file.path(root, "outputs", "psychometric_demo")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source(file.path(root, "criterionAuditR.R"))
source(file.path(root, "examples", "psychometric_rules.R"))

set.seed(20261106)
n <- 2000L
theta_a <- rnorm(n)
theta_b <- .35 * theta_a + sqrt(1 - .35^2) * rnorm(n)
thresholds <- c(-Inf, -1, -.3, .3, 1, Inf)
ordinal <- function(z) as.integer(cut(z, breaks = thresholds, labels = FALSE))
latent <- cbind(matrix(rep(theta_a, 4L), ncol = 4L),
                matrix(rep(theta_b, 4L), ncol = 4L))
continuous <- .7 * latent + sqrt(1 - .7^2) * matrix(rnorm(n * 8L), ncol = 8L)
# The fourth raw item is negatively keyed. The remaining seven are positive.
continuous[, 4L] <- -continuous[, 4L]
d <- as.data.frame(apply(continuous, 2L, ordinal))
names(d) <- c("q1", "q2", "q3", "q4_raw", "q5", "q6", "q7", "q8")
d$q4_key <- 6L - d$q4_raw
d$subscale_a <- rowSums(d[, c("q1", "q2", "q3", "q4_key")])
d$subscale_b <- rowSums(d[, c("q5", "q6", "q7", "q8")])
d$total <- d$subscale_a + d$subscale_b
d$score_band <- as.integer(d$total >= 24L)
d$rescaled_total <- 100 * (d$total - 8) / 32
d$external_noise <- rnorm(n)

rules <- psychometric_rules()
predictors <- c("q1", "q4_raw", "q4_key", "subscale_a", "subscale_b",
                "score_band", "rescaled_total", "external_noise")
clean <- ca_audit(d, "total", predictors, rules)
ca_write(clean, file.path(out, "clean"))
write.csv(d, file.path(out, "simulated_questionnaire.csv"), row.names = FALSE)

# Prespecified software fault controls, not prevalence estimates.
# Propagate an uncorrected reverse key through its downstream scoring pipeline.
bad <- d
key_rows <- head(which(d$q4_raw != 3L), 20L)
bad$q4_key[key_rows] <- bad$q4_raw[key_rows]
bad$subscale_a <- bad$q1 + bad$q2 + bad$q3 + bad$q4_key
bad$total <- bad$subscale_a + bad$subscale_b
total_rows <- head(setdiff(seq_len(n), key_rows), 15L)
bad$total[total_rows] <- bad$total[total_rows] + 1L
bad$score_band <- as.integer(bad$total >= 24L)
band_rows <- head(setdiff(seq_len(n), c(key_rows, total_rows)), 10L)
bad$score_band[band_rows] <- 1L - bad$score_band[band_rows]
bad$rescaled_total <- 100 * (bad$total - 8) / 32
injected <- ca_audit(bad, "total", predictors, rules)
ca_write(injected, file.path(out, "injected"))
faults <- data.frame(output = c("q4_key", "total", "score_band"),
                    planted_mismatches = c(20L, 15L, 10L))
faults$observed_mismatches <- injected$checks$n_mismatch[
  match(faults$output, injected$checks$output)]
write.csv(faults, file.path(out, "injected_faults.csv"), row.names = FALSE)

keyed <- c("q1", "q2", "q3", "q4_key", "q5", "q6", "q7", "q8")
pw <- ca_partwhole(d, keyed)
write.csv(pw, file.path(out, "questionnaire_item_correlations.csv"), row.names = FALSE)
associations <- data.frame(
  comparison = c("subscale_a_with_inclusive_total", "subscale_a_with_nonoverlapping_subscale_b"),
  pearson_r = c(cor(d$subscale_a, d$total), cor(d$subscale_a, d$subscale_b)))
write.csv(associations, file.path(out, "subscale_correlations.csv"), row.names = FALSE)

# Null control with no shared latent trait: independent five-category responses.
set.seed(20261107)
null <- as.data.frame(matrix(sample.int(5L, 5000L * 5L, replace = TRUE), ncol = 5L))
names(null) <- paste0("null", 1:5)
null_pw <- ca_partwhole(null, names(null))
write.csv(null, file.path(out, "independent_ordinal_responses.csv"), row.names = FALSE)
write.csv(null_pw, file.path(out, "independent_item_correlations.csv"), row.names = FALSE)

# Six integration checks use known design properties and explicit planted faults.
checks <- c(
  clean_scoring_agrees = all(clean$checks$n_mismatch == 0L & clean$checks$n_evaluated == n),
  total_matches_raw_scoring_key = all(d$total == d$q1 + d$q2 + d$q3 + (6L - d$q4_raw) + d$q5 + d$q6 + d$q7 + d$q8),
  planted_faults_recovered = all(faults$planted_mismatches == faults$observed_mismatches) &&
    all(injected$checks$n_mismatch[!injected$checks$output %in% faults$output] == 0L),
  graph_relations_match_design = identical(clean$flags$relationship,
    c(rep("criterion_component", 5L), rep("criterion_descendant", 2L), "not_flagged")),
  independent_ordinal_null = max(abs(null_pw$item_rest)) < .06 &&
    max(abs(null_pw$item_total - 1 / sqrt(5))) < .06,
  disjoint_subscales_have_no_declared_overlap =
    ca_audit(d, "subscale_b", "subscale_a", rules)$flags$relationship == "not_flagged"
)
write.csv(data.frame(check = names(checks), passed = as.logical(checks)),
          file.path(out, "integration_checks.csv"), row.names = FALSE)
stopifnot(all(checks))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
cat("SIX PSYCHOMETRIC DEMONSTRATION CHECKS PASSED\n")
print(faults, row.names = FALSE)
print(associations, row.names = FALSE)
print(null_pw, row.names = FALSE)
