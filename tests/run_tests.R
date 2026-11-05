full <- commandArgs(trailingOnly=FALSE)
script <- sub("^--file=","",full[grepl("^--file=",full)][1L])
root <- dirname(dirname(normalizePath(script,mustWork=TRUE)))
source(file.path(root,"criterionAuditR.R"))
n <- 0L
test <- function(label, code) { force(code);n <<- n+1L;cat("PASS",n,label,"\n") }
fails <- function(expr) inherits(tryCatch({force(expr);NULL},error=function(e)e),"error")
d <- data.frame(a=c(1,2,3,4),b=c(0,1,0,1),z=c(1,1,3,3),y=c(0,0,1,1),w=c(2,2,6,6),other=c(7,2,9,1))
rules <- list(ca_rule("z",c("a","b"),function(x)x$a-x$b),ca_rule("y","z",function(x)as.integer(x$z>=2)),ca_rule("w","z",function(x)2*x$z))
a <- ca_audit(d,"y",c("a","z","w","other","y"),rules)
test("multi-hop criterion components",stopifnot(all(a$flags$relationship[1:2]=="criterion_component")))
test("shared component and undeclared variable distinction",stopifnot(identical(a$flags$relationship[3:5],c("shared_component","not_flagged","criterion_itself"))))
test("exact identities checked",stopifnot(all(a$checks$n_mismatch==0),all(a$checks$n_evaluated==4)))
bad <- d;bad$y[2] <- 1L
test("injected label mismatch counted",stopifnot(ca_audit(bad,"y","z",rules)$checks$n_mismatch[2]==1))
bad <- d;bad$a[1] <- NA
test("missing inputs excluded with visible denominator",stopifnot(ca_audit(bad,"y","z",rules)$checks$n_evaluated[1]==3))
bad <- d;bad$z[1] <- 1.005
rr <- list(ca_rule("z",c("a","b"),function(x)x$a-x$b,tolerance=.01))
test("declared rounding tolerance",stopifnot(ca_audit(bad,"z","a",rr)$checks$n_mismatch==0))
test("cycle rejected",stopifnot(fails(ca_graph(list(ca_rule("a","b"),ca_rule("b","a"))))))
test("duplicate output rejected",stopifnot(fails(ca_graph(list(ca_rule("y","z"),ca_rule("y","a"))))))
test("missing rule columns explicit",stopifnot(ca_audit(d[,setdiff(names(d),"a")],"y","z",rules)$checks$status[1]=="missing_columns"))
test("non-vector rule result rejected",stopifnot(fails(ca_audit(d,"y","z",list(ca_rule("y","z",function(x)1))))))
test("criterion descendants",stopifnot(ca_audit(d,"z","y",rules)$flags$relationship=="criterion_descendant"))
test("provenance-only rules never reported as verified",stopifnot(ca_audit(d,"y","z",list(ca_rule("y","z")))$checks$status=="provenance_only"))
set.seed(99); x <- as.data.frame(matrix(rnorm(4000*5),ncol=5))
p <- ca_partwhole(x,names(x))
test("independent item rest control",stopifnot(mean(p$item_total)>.4,max(abs(p$item_rest))<.08))
x$V1[1] <- NA
test("part-whole uses a common complete sample",stopifnot(all(ca_partwhole(x,names(x))$n_complete==3999)))
rr <- list(ca_rule("y","z",function(x)rep(NaN,nrow(x))))
test("undefined expected values cannot pass",stopifnot(ca_audit(d,"y","z",rr)$checks$status=="no_evaluable_rows"))
cat("ALL",n,"TESTS PASSED\n")
