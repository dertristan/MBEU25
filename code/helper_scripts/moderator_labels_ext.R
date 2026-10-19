# Label/order lookup for the extended-correlates figures (13_, 14_).
# Extends moderator_labels.R without editing it, so 07/08 stay unchanged.
# Presentation only: no effect on any estimate.

source(here::here("code", "helper_scripts", "moderator_labels.R"))

# Post-game correlates: concise construct labels
mod_labels <- c(
  mod_labels,
  q_nat_int           = "Interest in national politics",
  q_eu_int            = "Interest in European politics",
  q_nativ_econ        = "Immigration bad for economy",
  q_nativ_cult        = "Immigration undermines culture",
  q_eu_informed_com   = "Informed: Commission",
  q_eu_informed_cou   = "Informed: Council",
  q_eu_informed_ep    = "Informed: Parliament",
  q_eu_informed_cjeu  = "Informed: CJEU",
  q_eu_trust_com      = "Trust: Commission",
  q_eu_trust_cou      = "Trust: Council",
  q_eu_trust_ep       = "Trust: Parliament",
  q_eu_trust_cjeu     = "Trust: CJEU",
  q_cjeu_abolish      = "Better to abolish CJEU",
  q_cjeu_satisfaction = "Satisfied with CJEU",
  q_lr_self           = "Left-right self-placement",
  q_euint_self        = "EU integration position",
  q_risk_taking       = "Willingness to take risks",
  q_future_discount   = "Patience (give up today)",
  q_occ_current       = "Current occupation",
  der_eu_know_correct = "EU knowledge: correct (0-4)",
  der_eu_know_dk      = "EU knowledge: don't know (0-5)"
)

cat_mods <- c(cat_mods, "q_occ_current")

value_labels$q_occ_current <- c(
  emp_desk = "Employed, desk",
  emp_service = "Employed, service",
  emp_travel = "Employed, travelling",
  farmer = "Farmer",
  fisher = "Fisher",
  homemaker = "Homemaker",
  manual_skill = "Skilled manual",
  manual_unskill = "Unskilled manual",
  mgmt_mid = "Middle management",
  mgmt_top = "Top management",
  owner_biz = "Business owner",
  owner_shop = "Shop owner",
  prof_emp = "Employed professional",
  prof_self = "Self-employed professional",
  retired = "Retired",
  student = "Student",
  supervisor = "Supervisor",
  unemployed = "Unemployed"
)
