rules <- list(
  ca_rule("net_worth",c("total_assets","total_liabilities"),
          function(d)d$total_assets-d$total_liabilities,tolerance=.02),
  ca_rule("millionaire_status","net_worth",function(d)as.integer(d$net_worth>=1000000))
)
