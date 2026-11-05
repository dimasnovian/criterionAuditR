# Audit distinct score constructions using simulated and published response data.
full <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", full[grepl("^--file=", full)][1L])
root <- dirname(normalizePath(script, mustWork = TRUE))
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1L] else file.path(root, "outputs", "score_transfer")
source(file.path(root, "criterionAuditR.R"))
source(file.path(root, "examples", "psychometric_rules.R"))

if (length(args) >= 2L) {
  stopifnot(unname(tools::md5sum(args[2L])) == "30457c8d5652d78793d228f992867481")
  external <- new.env(parent = emptyenv())
  load(args[2L], envir = external)
  ability <- external$ability
  ability_source <- "psychTools 2.6.4 ability.rda at 7dc591f8ac11c0ef1764cf853f3065aa60653d09"
} else {
  if (!requireNamespace("psychTools", quietly = TRUE)) {
    stop("Use psychTools or supply the pinned ability.rda file as the second argument.")
  }
  ability <- psychTools::ability
  ability_source <- paste("psychTools", packageVersion("psychTools"), "ability")
}
stopifnot(identical(dim(ability), c(1525L, 16L)), all(unlist(ability) %in% c(0, 1, NA)))
ability <- as.data.frame(ability)

audit_case <- function(design, origin, clean, faulty, criterion, predictors, rules,
                       denominators, planted) {
  baseline <- ca_audit(clean, criterion, predictors, rules)
  challenge <- ca_audit(faulty, criterion, predictors, rules)
  checks <- challenge$checks
  order <- match(checks$output, names(denominators))
  expected_counts <- vapply(checks$output, function(name) length(planted[[name]]), integer(1L))
  stopifnot(length(denominators) == nrow(checks), !anyNA(order), all(names(planted) %in% checks$output),
            all(baseline$checks$n_mismatch == 0L),
            all(baseline$checks$n_evaluated == denominators[order]),
            all(checks$n_evaluated == denominators[order]),
            all(checks$n_mismatch == expected_counts))
  # Each planted row group must fully fail its intended rule. Combined with the
  # full-table counts, this also checks for unplanted failures at those stages.
  for (name in names(planted)) {
    rows <- planted[[name]]
    subset <- ca_audit(faulty[rows, , drop = FALSE], criterion, character(), rules)
    result <- subset$checks[subset$checks$output == name, ]
    stopifnot(result$n_evaluated == length(rows), result$n_mismatch == length(rows))
  }
  list(
    summary = data.frame(design, origin, profiles = nrow(clean), rules = nrow(checks),
                         evaluated = sum(checks$n_evaluated), unevaluated = sum(checks$n_unevaluated),
                         clean_disagreements = sum(baseline$checks$n_mismatch),
                         planted = sum(expected_counts), detected = sum(checks$n_mismatch)),
    checks = data.frame(design, output = checks$output, expected_evaluated = denominators[order],
                        evaluated = checks$n_evaluated, unevaluated = checks$n_unevaluated,
                        clean_disagreements = baseline$checks$n_mismatch,
                        planted = expected_counts, detected = checks$n_mismatch, row.names = NULL),
    paths = data.frame(design, criterion, challenge$flags, row.names = NULL)
  )
}

# Existing questionnaire case with reverse scoring and nested sums.
ordinal <- read.csv(file.path(root, "outputs", "psychometric_demo", "simulated_questionnaire.csv"))
stopifnot(nrow(ordinal) == 2000L)
ordinal_bad <- inject_psychometric_faults(ordinal)
ordinal_key <- which(ordinal_bad$q4_key != ordinal$q4_key)
ordinal_total <- which(ordinal_bad$total != ordinal_bad$subscale_a + ordinal_bad$subscale_b)
ordinal_label <- which(ordinal_bad$score_band != as.integer(ordinal_bad$total >= 24L))
stopifnot(length(ordinal_key) == 20L, length(ordinal_total) == 15L, length(ordinal_label) == 10L)
ordinal_rules <- psychometric_rules()
ordinal_denominators <- setNames(rep(nrow(ordinal), length(ordinal_rules)),
                                vapply(ordinal_rules, `[[`, character(1L), "output"))
ordinal_case <- audit_case("ordinal_questionnaire", "simulated", ordinal, ordinal_bad,
  "score_band", c("q4_raw", "total", "rescaled_total", "external_noise"), ordinal_rules,
  ordinal_denominators, list(q4_key = ordinal_key, total = ordinal_total, score_band = ordinal_label))

# Published dichotomous responses with a deliberately illustrative decision rule.
items <- names(ability)
domains <- list(
  reasoning = c("reason.4", "reason.16", "reason.17", "reason.19"),
  letters = c("letter.7", "letter.33", "letter.34", "letter.58"),
  matrices = c("matrix.45", "matrix.46", "matrix.47", "matrix.55"),
  rotation = c("rotate.3", "rotate.4", "rotate.6", "rotate.8"))
stopifnot(setequal(unlist(domains), items))
ability <- ability[, unlist(domains)]
rownames(ability) <- NULL
domain_names <- names(domains)
decision <- function(total, reasoning) {
  result <- rep(NA_character_, length(total))
  complete <- !is.na(total) & !is.na(reasoning)
  result[complete] <- ifelse(total[complete] >= 10 & reasoning[complete] >= 2, "meets", "below")
  result
}
observed <- ability
for (domain in domain_names) observed[[domain]] <- rowSums(ability[, domains[[domain]]])
observed$binary_total <- rowSums(ability)
observed$decision <- decision(observed$binary_total, observed$reasoning)
observed$scaled_total <- 100 * observed$binary_total / 16
domain_rules <- Map(function(name, cols) {
  ca_rule(name, cols, function(d) Reduce(`+`, d[, cols]), "Four dichotomous items")
}, domain_names, domains)
observed_rules <- c(unname(domain_rules), list(
  ca_rule("binary_total", domain_names, function(d) Reduce(`+`, d[, domain_names]), "Sum four domain scores"),
  ca_rule("decision", c("binary_total", "reasoning"),
          function(d) ifelse(d$binary_total >= 10 & d$reasoning >= 2, "meets", "below"),
          "Illustrative conjunctive decision"),
  ca_rule("scaled_total", "binary_total", function(d) d$binary_total * 6.25,
          "Scale from 0 to 100", tolerance = 1e-10)))

observed_bad <- observed
eligible <- which(!is.na(observed$decision))
reason_rows <- head(eligible[observed$reasoning[eligible] < 4L], 11L)
observed_bad$reasoning[reason_rows] <- observed_bad$reasoning[reason_rows] + 1L
observed_bad$binary_total <- rowSums(observed_bad[, domain_names])
total_rows <- head(setdiff(eligible[observed$binary_total[eligible] < 16L], reason_rows), 7L)
observed_bad$binary_total[total_rows] <- observed_bad$binary_total[total_rows] + 1L
observed_bad$decision <- decision(observed_bad$binary_total, observed_bad$reasoning)
label_rows <- head(setdiff(which(observed_bad$binary_total == 10L & observed_bad$reasoning >= 2L),
                           c(reason_rows, total_rows)), 5L)
observed_bad$decision[label_rows] <- "below"
observed_bad$scaled_total <- 100 * observed_bad$binary_total / 16
stopifnot(length(reason_rows) == 11L, length(total_rows) == 7L, length(label_rows) == 5L)
complete_profiles <- sum(rowSums(is.na(ability)) == 0L)
stopifnot(complete_profiles == 1248L)
domain_coverage <- vapply(domains, function(cols) sum(rowSums(is.na(ability[, cols])) == 0L), integer(1L))
observed_denominators <- c(domain_coverage, binary_total = complete_profiles,
                           decision = complete_profiles, scaled_total = complete_profiles)
ability_case <- audit_case("dichotomous_ability", "published_item_responses", observed, observed_bad,
  "decision", c("reason.4", "reasoning", "binary_total", "scaled_total"), observed_rules,
  observed_denominators, list(reasoning = reason_rows, binary_total = total_rows, decision = label_rows))

# Exhaustive integer grid for a weighted, rounded three-task index.
weighted <- expand.grid(accuracy = 0:17, recall = 0:13, fluency = 0:23, KEEP.OUT.ATTRS = FALSE)
weighted$accuracy_pct <- 100 * weighted$accuracy / 17
weighted$recall_pct <- 100 * weighted$recall / 13
weighted$fluency_pct <- 100 * weighted$fluency / 23
denominator <- 17 * 13 * 23
numerator <- 47 * weighted$accuracy * 13 * 23 + 31 * weighted$recall * 17 * 23 +
             22 * weighted$fluency * 17 * 13
weighted$index_raw <- numerator / denominator
# Integer-rational reference for rounding to tenths. The odd denominator
# precludes half-tenth ties for every combination in this grid.
weighted$index_reported <- floor((20 * numerator + denominator) / (2 * denominator)) / 10
weighted$band <- ifelse(weighted$index_reported >= 60, "meets", "below")
weighted$raw_band <- as.integer(numerator >= 60 * denominator)
weighted_rules <- list(
  ca_rule("accuracy_pct", "accuracy", function(d) d$accuracy * (100 / 17), tolerance = 1e-10),
  ca_rule("recall_pct", "recall", function(d) d$recall * (100 / 13), tolerance = 1e-10),
  ca_rule("fluency_pct", "fluency", function(d) d$fluency * (100 / 23), tolerance = 1e-10),
  ca_rule("index_raw", c("accuracy_pct", "recall_pct", "fluency_pct"),
          function(d) .47 * d$accuracy_pct + .31 * d$recall_pct + .22 * d$fluency_pct,
          "Weighted task composite", tolerance = 1e-10),
  ca_rule("index_reported", "index_raw", function(d) round(d$index_raw, 1),
          "Round before applying the cutoff", tolerance = 1e-10),
  ca_rule("band", "index_reported", function(d) ifelse(d$index_reported >= 60, "meets", "below"),
          "Illustrative classification using the reported index"),
  ca_rule("raw_band", "index_raw", function(d) as.integer(d$index_raw >= 60), "Alternative raw-index band"))
boundary <- which(weighted$band == "meets" & weighted$raw_band == 0L)
weight_rows <- head(setdiff(which(abs(weighted$accuracy_pct - weighted$recall_pct) > 1e-6), boundary), 12L)
round_rows <- head(setdiff(which(weighted$index_reported < 99.9), c(boundary, weight_rows)), 9L)
stopifnot(nrow(weighted) == 6048L, length(boundary) > 0L,
          length(weight_rows) == 12L, length(round_rows) == 9L)
weighted_bad <- weighted
weighted_bad$index_raw[weight_rows] <- weighted_bad$index_raw[weight_rows] +
  .02 * (weighted_bad$accuracy_pct[weight_rows] - weighted_bad$recall_pct[weight_rows])
weighted_bad$index_reported <- round(weighted_bad$index_raw, 1)
weighted_bad$index_reported[round_rows] <- weighted_bad$index_reported[round_rows] + .1
weighted_bad$band <- ifelse(weighted_bad$index_reported >= 60, "meets", "below")
weighted_bad$band[boundary] <- "below"
weighted_bad$raw_band <- as.integer(weighted_bad$index_raw >= 60)
weighted_denominators <- setNames(rep(nrow(weighted), length(weighted_rules)),
                                  vapply(weighted_rules, `[[`, character(1L), "output"))
weighted_case <- audit_case("weighted_rounded_index", "exhaustive_simulated_grid", weighted, weighted_bad,
  "band", c("accuracy", "index_raw", "index_reported", "raw_band"), weighted_rules,
  weighted_denominators, list(index_raw = weight_rows, index_reported = round_rows, band = boundary))

cases <- list(ordinal_case, ability_case, weighted_case)
summary <- do.call(rbind, lapply(cases, `[[`, "summary"))
checks <- do.call(rbind, lapply(cases, `[[`, "checks"))
paths <- do.call(rbind, lapply(cases, `[[`, "paths"))
stopifnot(ability_case$paths$evidence[1L] == "reason.4 -> reasoning -> decision",
          weighted_case$paths$evidence[1L] == "accuracy -> accuracy_pct -> index_raw -> index_reported -> band",
          ability_case$paths$relationship[4L] == "shared_component",
          weighted_case$paths$relationship[4L] == "shared_component")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write.csv(summary, file.path(out, "design_summary.csv"), row.names = FALSE)
write.csv(checks, file.path(out, "rule_checks.csv"), row.names = FALSE)
write.csv(paths, file.path(out, "criterion_paths.csv"), row.names = FALSE)
write.csv(weighted[boundary, c("accuracy", "recall", "fluency", "index_raw", "index_reported")],
          file.path(out, "rounding_boundary.csv"), row.names = FALSE)
capture.output(cat(ability_source, "\n"), sessionInfo(), file = file.path(out, "sessionInfo.txt"))
print(summary, row.names = FALSE)
cat("Published complete profiles:", complete_profiles, "of", nrow(ability), "\n")
cat("Rounding-dependent decisions:", length(boundary), "\n")
