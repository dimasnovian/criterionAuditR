# Rscript audit_file.R INPUT.csv CRITERION RULES.R OUTPUT_DIR
# RULES.R must be your reviewed local R file assigning a list named rules.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=4L) stop("Usage: Rscript audit_file.R INPUT.csv CRITERION RULES.R OUTPUT_DIR")
full <- commandArgs(trailingOnly=FALSE)
root <- dirname(normalizePath(sub("^--file=","",full[grepl("^--file=",full)][1L]),mustWork=TRUE))
source(file.path(root,"criterionAuditR.R"))
d <- read.csv(args[1L],stringsAsFactors=FALSE,check.names=FALSE)
scope <- new.env(parent=globalenv())
sys.source(args[3L],envir=scope)
if(!exists("rules",envir=scope,inherits=FALSE)) stop("Rule file must assign rules")
a <- ca_audit(d,args[2L],setdiff(names(d),args[2L]),scope$rules)
ca_write(a,args[4L])
print(a$checks)
