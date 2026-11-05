# Rules distinguished by documentation strength. Generic dictionary entries do
# not supply a formula. They are recorded as provenance-only, not computed.
kaggle_rules <- function() list(
  ca_rule("net_worth",c("total_assets","total_liabilities"),
          function(d) d$total_assets-d$total_liabilities,
          "Source validation report identity; 0.02 USD rounding tolerance",0.02),
  ca_rule("millionaire_status","net_worth",function(d) as.integer(d$net_worth >= 1000000),
          "Source README threshold in USD"),
  ca_rule("multi_millionaire_status","net_worth",function(d) as.integer(d$net_worth >= 5000000),
          "Source README threshold in USD"),
  ca_rule("high_saver_status","savings_rate",function(d) as.integer(d$savings_rate >= 0.20),
          "Source README threshold"),
  ca_rule("high_investor_status","investment_assets",function(d) as.integer(d$investment_assets >= 100000),
          "Source README threshold in USD"),
  ca_rule("financial_independence_status",c("net_worth","monthly_expenses"),
          function(d) as.integer(d$net_worth >= 25*12*d$monthly_expenses),
          "Source README: 25 times annual expenses; monthly expenses annualized"),
  ca_rule("net_worth_log","net_worth",description="Transformation identified by variable name; exact formula unspecified"),
  ca_rule("net_worth_percentile","net_worth",description="Rank transformation; reference population unspecified"),
  ca_rule("wealth_bracket","net_worth",description="Wealth bracket; exact cutpoints unspecified"),
  ca_rule("wealth_category","net_worth",description="Wealth category; exact cutpoints unspecified")
)
