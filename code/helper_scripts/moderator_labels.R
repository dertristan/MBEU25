# Shared moderator label/order lookup for the combined CATE-by-moderator figures.
# Sourced by 07_postprocess_grf.qmd and 08_postprocess_bcf.qmd so the mapping
# lives in one place. Presentation only: no effect on any estimate.

# Concise construct labels (facet strip titles), drafted from the Survey Item
# Reference table in 09_additional_figs_tables.qmd#tbl-wordings.
mod_labels <- c(
  cj_nationality_shown     = "Profile nationality",
  der_cj_eu_identity       = "Profile EU identity",
  der_cj_partisanship      = "Profile partisanship",
  cj_age                   = "Profile age",
  cj_sex                   = "Profile gender",
  cj_class                 = "Profile social class",
  q_gender                 = "Respondent gender",
  q_age                    = "Respondent age",
  q_identity_country       = "Attachment to country",
  q_identity_eu            = "Attachment to EU",
  q_identity_europe        = "Attachment to Europe",
  q_religion               = "Religion",
  q_class                  = "Subjective social class",
  q_eu_efficacy_understand = "Can understand EU politics",
  q_pop_reps               = "Officials talk, not act",
  q_pop_goodevil           = "Politics: good vs evil",
  q_pop_compromise         = "Compromise = selling out",
  q_dem_compromise         = "Compromise is important",
  q_dem_listen             = "Listen to other groups",
  q_tech_experts           = "Leave decisions to experts",
  q_tech_leaders           = "Leaders above ordinary citizens",
  q_party_harm             = "Parties do more harm",
  q_people_incompetent     = "Ordinary people don't know",
  q_eu_longterm            = "EU should pursue long-term goals",
  q_eu_responsive          = "EU should heed the people",
  q_eu_imp_nat_econ        = "EU effect on economy",
  q_eu_imp_nat_cul         = "EU effect on culture/identity",
  q_eu_imp_nat_pol         = "EU effect on political status",
  q_eu_abolish             = "Better to abolish EU",
  q_eu_satisfaction        = "Satisfied with EU",
  q_rural_urban            = "Residence type",
  q_edu_age_stop           = "Age left education"
)

# Categorical moderators (push these facets first). cj_age is numeric-but-
# discrete (fixed conjoint ages, numeric ticks), so it carries no value relabel.
cat_mods <- c(
  "cj_nationality_shown", "der_cj_eu_identity", "der_cj_partisanship",
  "cj_age", "cj_sex", "cj_class",
  "q_gender", "q_religion", "q_class", "q_rural_urban"
)

# Readable value labels for categorical moderators (raw level -> display),
# covering exactly the observed levels in eu25_long.
value_labels <- list(
  cj_nationality_shown = c(
    own_country = "co-national", eu = "EU national", non_eu = "Non-EU national"
  ),
  cj_sex = c(female = "Female", male = "Male"),
  cj_class = c(lower = "Lower", middle = "Middle", upper = "Upper"),
  der_cj_eu_identity = c(
    eu_citizen = "sees herself\nas EU citizen",
    not_eu_citizen = "does not see herself\nas EU citizen",
    not_displayed = "not displayed\n(control)"
  ),
  der_cj_partisanship = c(
    shown = "shown",
    not_shown = "not shown",
    not_applicable = "not applicable"
  ),
  q_gender = c(female = "Female", male = "Male", other = "Other"),
  q_religion = c(
    catholic = "Catholic", protestant = "Protestant", orthodox = "Orthodox",
    muslim = "Muslim", jewish = "Jewish", buddhist = "Buddhist",
    hindu = "Hindu", sikh = "Sikh", atheist = "Atheist",
    nonbeliever_agnostic = "Agnostic", other_christian = "Other Christian",
    dont_know = "Don't know", other = "Other"
  ),
  q_class = c(
    working_class = "Working", lower_middle_class = "Lower-middle",
    middle_class = "Middle", upper_middle_class = "Upper-middle",
    higher_class = "Higher", dont_know = "Don't know", other = "Other"
  ),
  q_rural_urban = c(
    large_city = "Large city", small_med_town = "Small/med town", rural = "Rural"
  )
)

# Facet labeller: variable name -> wrapped concise label.
mod_strip <- function(x) {
  lab <- ifelse(x %in% names(mod_labels), mod_labels[x], x)
  unname(stringr::str_wrap(lab, 20))
}

# Tick relabeller for the "mod@@level" keys: categorical values get readable
# labels; scale items fall through to the raw numeric level.
relabel_key <- function(k) {
  m <- sub("@@.*", "", k)
  l <- sub(".*@@", "", k)
  mapply(function(mm, ll) {
    vl <- value_labels[[mm]]
    if (!is.null(vl) && ll %in% names(vl)) vl[[ll]] else ll
  }, m, l) |>
    unname()
}
