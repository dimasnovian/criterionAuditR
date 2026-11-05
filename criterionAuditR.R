# criterionAuditR 0.1.0 - base R program for declared criterion provenance
# Source this file or run the companion run_examples.R with Rscript.

ca_rule <- function(output, parents, compute = NULL, description = "", tolerance = 0) {
  if (!is.character(output) || length(output) != 1L || is.na(output) || !nzchar(output))
    stop("output must be one nonempty name")
  if (!is.character(parents) || !length(parents) || anyNA(parents) || any(!nzchar(parents)) || anyDuplicated(parents))
    stop("parents must be unique nonempty names")
  if (!is.null(compute) && !is.function(compute)) stop("compute must be a function or NULL")
  if (!is.numeric(tolerance) || length(tolerance) != 1L || !is.finite(tolerance) || tolerance < 0)
    stop("tolerance must be a finite nonnegative number")
  structure(list(output = output, parents = parents, compute = compute,
                 description = description, tolerance = tolerance), class = "ca_rule")
}

ca_graph <- function(rules) {
  if (!is.list(rules) || !length(rules) || !all(vapply(rules, inherits, logical(1), "ca_rule")))
    stop("rules must be a nonempty list of ca_rule objects")
  outputs <- vapply(rules, `[[`, character(1), "output")
  if (anyDuplicated(outputs)) stop("each output must have exactly one declared rule")
  edges <- do.call(rbind, lapply(rules, function(r) data.frame(parent = r$parents, child = r$output)))
  nodes <- unique(c(edges$parent, edges$child))
  remaining <- nodes
  while (length(remaining)) {
    incoming <- edges$child[edges$parent %in% remaining & edges$child %in% remaining]
    roots <- setdiff(remaining, incoming)
    if (!length(roots)) stop("declared dependency graph contains a cycle")
    remaining <- setdiff(remaining, roots)
  }
  edges
}

ca_ancestors <- function(node, edges) {
  seen <- character(); pending <- node
  while (length(pending)) {
    parents <- unique(edges$parent[edges$child %in% pending])
    pending <- setdiff(parents, seen)
    seen <- union(seen, pending)
  }
  seen
}

ca_path <- function(from, to, edges) {
  queue <- list(from); seen <- character()
  while (length(queue)) {
    path <- queue[[1L]]; queue <- queue[-1L]; last <- tail(path, 1L)
    if (last == to) return(paste(path, collapse = " -> "))
    if (last %in% seen) next
    seen <- c(seen, last)
    for (child in unique(edges$child[edges$parent == last])) queue[[length(queue) + 1L]] <- c(path, child)
  }
  ""
}

ca_audit <- function(data, criterion, predictors = setdiff(names(data), criterion), rules) {
  if (!is.data.frame(data) || !nrow(data) || anyDuplicated(names(data))) stop("data must have rows and unique column names")
  if (!is.character(criterion) || length(criterion) != 1L || is.na(criterion) || !criterion %in% names(data))
    stop("criterion must name one data column")
  if (!is.character(predictors) || anyNA(predictors) || anyDuplicated(predictors) || !all(predictors %in% names(data)))
    stop("predictors must name unique data columns")
  edges <- ca_graph(rules)
  target_anc <- ca_ancestors(criterion, edges)
  rows <- lapply(predictors, function(p) {
    pa <- ca_ancestors(p, edges)
    common <- intersect(c(p, pa), c(criterion, target_anc))
    relation <- if (p == criterion) "criterion_itself" else if (p %in% target_anc) "criterion_component" else if (criterion %in% pa) "criterion_descendant" else if (length(common)) "shared_component" else "not_flagged"
    evidence <- if (relation == "criterion_component") ca_path(p, criterion, edges) else if (relation == "criterion_descendant") ca_path(criterion, p, edges) else if (relation == "shared_component") paste(common, collapse = "; ") else if (relation == "criterion_itself") p else "No relationship in supplied rules"
    data.frame(predictor = p, relationship = relation, evidence = evidence)
  })
  flags <- if (length(rows)) do.call(rbind, rows) else data.frame(predictor=character(), relationship=character(), evidence=character())
  checks <- lapply(rules, function(r) {
    required <- unique(c(r$output, r$parents)); missing <- setdiff(required, names(data))
    status <- if (length(missing)) "missing_columns" else if (is.null(r$compute)) "provenance_only" else "evaluated"
    complete_n <- evaluated_n <- mismatch_n <- 0L
    max_error <- mismatch_rate <- NA_real_
    if (status == "evaluated") {
      complete <- complete.cases(data[,required,drop=FALSE]); complete_n <- sum(complete)
      if (complete_n) {
        subset <- data[complete,,drop=FALSE]
        expected <- r$compute(subset); actual <- subset[[r$output]]
        if (!is.atomic(expected) || !is.null(dim(expected)) || length(expected) != complete_n)
          stop(paste("rule must return one value per complete input row:", r$output))
        numeric_pair <- (is.numeric(actual) || is.logical(actual)) && (is.numeric(expected) || is.logical(expected))
        usable <- if (numeric_pair) is.finite(actual) & is.finite(expected) else !is.na(actual) & !is.na(expected)
        evaluated_n <- sum(usable)
        if (evaluated_n) {
          if (numeric_pair) {
            errors <- abs(as.numeric(actual[usable]) - as.numeric(expected[usable]))
            mismatch_n <- sum(errors > r$tolerance); max_error <- max(errors)
          } else mismatch_n <- sum(as.character(actual[usable]) != as.character(expected[usable]))
          mismatch_rate <- mismatch_n/evaluated_n
        }
      }
      if (!evaluated_n) status <- "no_evaluable_rows"
    }
    data.frame(output = r$output, status = status, n_rows = nrow(data),
               n_complete_inputs = complete_n, n_evaluated = evaluated_n,
               n_unevaluated = nrow(data)-evaluated_n, n_mismatch = mismatch_n,
               mismatch_rate = mismatch_rate, max_absolute_error = max_error,
               tolerance = r$tolerance, missing_columns = paste(missing, collapse="; "),
               description = r$description)
  })
  structure(list(criterion = criterion, flags = flags, checks = do.call(rbind,checks),
                 edges = edges, n_rows = nrow(data), version = "0.1.0"), class = "ca_audit")
}

print.ca_audit <- function(x, ...) {
  cat("criterionAuditR", x$version, "\nCriterion:", x$criterion, "\nRows:", x$n_rows, "\n")
  print(x$flags, row.names=FALSE)
  print(x$checks[,c("output","status","n_evaluated","n_mismatch","n_unevaluated")],row.names=FALSE)
  invisible(x)
}

ca_partwhole <- function(data, items) {
  if (!is.data.frame(data) || !is.character(items) || length(items) < 2L || anyDuplicated(items) || !all(items %in% names(data)))
    stop("items must identify at least two unique data columns")
  if (!all(vapply(data[,items,drop=FALSE], is.numeric, logical(1)))) stop("items must be numeric")
  x <- as.matrix(data[,items,drop=FALSE]); keep <- apply(x, 1L, function(v) all(is.finite(v)))
  x <- x[keep,,drop=FALSE]
  if (nrow(x) < 3L) stop("at least three complete finite item response rows are required")
  total <- rowSums(x)
  safe_cor <- function(a,b) if (sd(a) == 0 || sd(b) == 0) NA_real_ else cor(a,b)
  data.frame(item=items,n_complete=nrow(x),n_excluded=nrow(data)-nrow(x),
             item_total=apply(x,2L,function(v) safe_cor(v,total)),
             item_rest=apply(x,2L,function(v) safe_cor(v,total-v)),row.names=NULL)
}

ca_write <- function(audit, directory) {
  if (!inherits(audit,"ca_audit")) stop("audit must be produced by ca_audit")
  dir.create(directory, recursive=TRUE, showWarnings=FALSE)
  write.csv(audit$flags,file.path(directory,"predictor_flags.csv"),row.names=FALSE,na="")
  write.csv(audit$checks,file.path(directory,"rule_checks.csv"),row.names=FALSE,na="")
  write.csv(audit$edges,file.path(directory,"declared_edges.csv"),row.names=FALSE)
  saveRDS(audit,file.path(directory,"audit.rds"))
  invisible(directory)
}
