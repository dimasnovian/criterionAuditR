# An original, hypothetical questionnaire scoring key, not a validated scale.
psychometric_rules <- function() {
  list(
    ca_rule("q4_key", "q4_raw", function(d) 6 - d$q4_raw,
            "Reverse-key item 4 on a 1 to 5 response scale"),
    ca_rule("subscale_a", c("q1", "q2", "q3", "q4_key"),
            function(d) d$q1 + d$q2 + d$q3 + d$q4_key,
            "Sum four keyed self-regulation items"),
    ca_rule("subscale_b", c("q5", "q6", "q7", "q8"),
            function(d) d$q5 + d$q6 + d$q7 + d$q8,
            "Sum four keyed persistence items"),
    ca_rule("total", c("subscale_a", "subscale_b"),
            function(d) d$subscale_a + d$subscale_b,
            "Sum two subscales, range 8 to 40"),
    ca_rule("score_band", "total", function(d) as.integer(d$total >= 24),
            "Illustrative threshold at 24; no diagnostic interpretation"),
    ca_rule("rescaled_total", "total", function(d) 100 * (d$total - 8) / 32,
            "Linear rescaling of total to 0 to 100", tolerance = 1e-10)
  )
}

inject_psychometric_faults <- function(data) {
  faulty <- data
  key_rows <- head(which(data$q4_raw != 3L), 20L)
  faulty$q4_key[key_rows] <- faulty$q4_raw[key_rows]
  # Propagate the incorrect key before introducing faults at later stages.
  faulty$subscale_a <- faulty$q1 + faulty$q2 + faulty$q3 + faulty$q4_key
  faulty$total <- faulty$subscale_a + faulty$subscale_b
  total_rows <- head(setdiff(seq_len(nrow(data)), key_rows), 15L)
  faulty$total[total_rows] <- faulty$total[total_rows] + 1L
  faulty$score_band <- as.integer(faulty$total >= 24L)
  band_rows <- head(setdiff(seq_len(nrow(data)), c(key_rows, total_rows)), 10L)
  faulty$score_band[band_rows] <- 1L - faulty$score_band[band_rows]
  faulty$rescaled_total <- 100 * (faulty$total - 8) / 32
  faulty
}
