args <- commandArgs(trailingOnly=TRUE)
full <- commandArgs(trailingOnly=FALSE)
script <- sub("^--file=","",full[grepl("^--file=",full)][1L])
root <- dirname(normalizePath(script,mustWork=TRUE))
source(file.path(root,"criterionAuditR.R"))
source(file.path(root,"examples","kaggle_rules.R"))
out <- if(length(args)>=2L) args[2L] else file.path(root,"outputs")
dir.create(out,recursive=TRUE,showWarnings=FALSE)

# Deliberately independent continuous responses illustrate part-whole overlap.
set.seed(20261105)
items <- as.data.frame(matrix(rnorm(5000L*5L),ncol=5L))
names(items) <- paste0("item",1:5)
items$total <- rowSums(items)
pw <- ca_partwhole(items,paste0("item",1:5))
pw_audit <- ca_audit(items,"total",paste0("item",1:5),
                    list(ca_rule("total",paste0("item",1:5),function(d) rowSums(d[,paste0("item",1:5)]),"Sum of five simulated responses",1e-12)))
write.csv(items,file.path(root,"examples","score_input.csv"),row.names=FALSE)
write.csv(pw,file.path(out,"partwhole_correlations.csv"),row.names=FALSE)
ca_write(pw_audit,file.path(out,"score_demo"))

# Original demonstration input with known financial identities; no Kaggle rows.
toy <- data.frame(total_assets=c(800000,1100000,2000000,5500000,500000),
                  total_liabilities=c(100000,50000,200000,200000,20000),
                  net_worth=c(700000,1050000,1800000,5300000,480000),
                  millionaire_status=c(0,1,1,1,0),savings_rate=c(.1,.2,.3,.4,.15),
                  high_saver_status=c(0,1,1,1,0),investment_assets=c(0,100000,500000,3000000,50000),
                  high_investor_status=c(0,1,1,1,0),multi_millionaire_status=c(0,0,0,1,0),
                  monthly_expenses=c(2000,2500,3000,4000,1500),financial_independence_status=c(1,1,1,1,1))
write.csv(toy,file.path(root,"examples","financial_input.csv"),row.names=FALSE)
toy_audit <- ca_audit(toy,"millionaire_status",setdiff(names(toy),"millionaire_status"),kaggle_rules())
ca_write(toy_audit,file.path(out,"financial_demo"))

if(length(args) && nzchar(args[1L])) {
  input <- normalizePath(args[1L],mustWork=TRUE)
  d <- read.csv(input,check.names=FALSE,stringsAsFactors=FALSE)
  elapsed <- system.time(a <- ca_audit(d,"millionaire_status",setdiff(names(d),"millionaire_status"),kaggle_rules()))
  ca_write(a,file.path(out,"kaggle_sample"))
  corrupted <- d
  corrupted$millionaire_status[1:10] <- 1L-corrupted$millionaire_status[1:10]
  tamper <- ca_audit(corrupted,"millionaire_status","net_worth",kaggle_rules())
  write.csv(tamper$checks,file.path(out,"injected_label_error_checks.csv"),row.names=FALSE)
  capture.output(list(input_basename=basename(input),n_rows=nrow(d),n_columns=ncol(d),
                      n_millionaire=sum(d$millionaire_status==1,na.rm=TRUE),
                      audit_elapsed_seconds=unname(elapsed["elapsed"]),
                      data_object_bytes=as.numeric(object.size(d)),
                      sample_scope="External supplied sample only, not the 100000-row source file"),
                 file=file.path(out,"sample_summary.txt"))
  print(a)
}
capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
cat("\nIndependent response illustration\n");print(pw,row.names=FALSE)
cat("\nOutputs:",normalizePath(out),"\n")
