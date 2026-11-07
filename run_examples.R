args <- commandArgs(trailingOnly=TRUE)
full <- commandArgs(trailingOnly=FALSE)
script <- sub("^--file=","",full[grepl("^--file=",full)][1L])
root <- dirname(normalizePath(script,mustWork=TRUE))
source(file.path(root,"criterionAuditR.R"))
source(file.path(root,"examples","financial_rules.R"))
out <- if(length(args)) args[1L] else file.path(root,"outputs")
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

# Original demonstration input with known financial identities.
toy <- data.frame(total_assets=c(800000,1100000,2000000,5500000,500000),
                  total_liabilities=c(100000,50000,200000,200000,20000),
                  net_worth=c(700000,1050000,1800000,5300000,480000),
                  millionaire_status=c(0,1,1,1,0),savings_rate=c(.1,.2,.3,.4,.15),
                  high_saver_status=c(0,1,1,1,0),investment_assets=c(0,100000,500000,3000000,50000),
                  high_investor_status=c(0,1,1,1,0),multi_millionaire_status=c(0,0,0,1,0),
                  monthly_expenses=c(2000,2500,3000,4000,1500),financial_independence_status=c(1,1,1,1,1))
write.csv(toy,file.path(root,"examples","financial_input.csv"),row.names=FALSE)
toy_audit <- ca_audit(toy,"millionaire_status",setdiff(names(toy),"millionaire_status"),rules)
ca_write(toy_audit,file.path(out,"financial_demo"))

capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
cat("\nIndependent response illustration\n");print(pw,row.names=FALSE)
cat("\nOutputs:",normalizePath(out),"\n")
