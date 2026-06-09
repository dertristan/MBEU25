# Worklog: display-aware profile covariates (2026-06-09)

Debugging reference for the change that added display-aware profile covariates
(`der_cj_eu_identity`, `der_cj_partisanship`) and fixed a Trust-game reshape bug.
If something looks wrong downstream, start here.

## Goal

The conjoint design sits under four high-level treatment conditions (`cj_treatment`)
that govern **which profile features were actually displayed**. The old profile
covariates ignored this: `cj_eupos` carried a behind-the-scenes value even where EU
stance was never shown, and party was not modelled at all. We replaced `cj_eupos`
with a display-aware **EU identity** variable (3 levels incl. "not displayed") and
added a display-aware **partisanship** variable.

## Commits (branch `main`)

| Commit | Phase | Files |
|---|---|---|
| `5a71862` | 1 | `code/02_data_prep.qmd`, `data/02_processed/eu25_long.rds` |
| `bc1f5a9` | 2 | `code/05_bcf_fit.qmd`, `code/06_grf_fit.qmd` |
| `bcc36ba` | 3 | `code/07_postprocess_grf.qmd`, `code/08_postprocess_bcf.qmd`, `code/09_additional_figs_tables.qmd`, `code/helper_scripts/moderator_labels.R` |

(Commit short-hashes may differ if history was rewritten; search commit subjects:
"Add display-aware profile covariates", "Swap cj_eupos for display-aware",
"Wire display-aware moderators".)

## Treatment / display logic (confirmed against data + index.qmd lines 39–42)

| `cj_treatment` | EU stance shown | party shown | rows (both games) |
|---|---|---|---|
| `1_conat_eustance_partisan` | yes | yes | 61,537 |
| `2_conat_partisan` | no | yes | 30,899 |
| `3_eunat_eustance` | yes | no | 30,656 |
| `4_somenat` | no | no | 46,114 |

- EU stance shown ⇔ name contains `eustance` (1,3).
- Party shown ⇔ name contains `partisan` (1,2).
- Conational ⇔ `cj_nat == "own_country"` (drawn nationality == respondent country).
  `cj_nat` is the **drawn** nationality and varies within every condition.

## New variables (`02_data_prep.qmd`, chunk `display-aware-covariates`)

```r
der_cj_eu_identity = case_when(
  grepl("eustance", cj_treatment) & cj_eupos == "eu_citizen"     ~ "eu_citizen",
  grepl("eustance", cj_treatment) & cj_eupos == "not_eu_citizen" ~ "not_eu_citizen",
  !grepl("eustance", cj_treatment)                               ~ "not_displayed"
)
der_cj_partisanship = case_when(
  grepl("partisan", cj_treatment)                       ~ "shown",
  cj_treatment == "4_somenat" & cj_nat == "own_country" ~ "not_shown",
  .default                                              = "not_applicable"
)
```

Expected counts (both games, 169,206 rows), validated by chunk `verify-display-aware`:
- `der_cj_eu_identity`: eu_citizen 46,028 / not_displayed 77,013 / not_eu_citizen 46,165
- `der_cj_partisanship`: not_applicable 53,766 / not_shown 23,004 / shown 92,436
- No NAs.

## ⚠️ Trust-game reshape bug (fixed in Phase 1)

The working-tree `02_data_prep.qmd` (already modified before this work began) used
`starts_with("cj_tr")` in the `pivot_longer`/`rename_with` exclusion lists. That
pattern matches **both** `cj_treatment` and `cj_trust*`, so the **entire Trust game
was excluded from the long reshape**:
- Symptom: `eu25_long` was Dictator-only (84,603 rows) with 60 dead `cj_trust1_*` /
  `cj_trust2_*` / `cj_trust3_*` wide columns; downstream `filter(cj_game_type ==
  "cj_trust")` returned 0 rows.
- Fix: narrowed both exclusions to `starts_with("cj_treatment")`. Both games now
  reshape → 169,206 rows, 0 dead trust columns.
- If Trust ever disappears again, check this exclusion pattern first.

## Design-matrix sanity check (Phase 2, no model fitting)

Reconstructed X exactly as the fit notebooks build it (`model.matrix(~ . - 1, ...)`):
- BCF X (prof + resp): **ncol 55, rank 55** (full).
- GRF X (prof + resp + country FE, first dropped): **ncol 79, rank 79** (full).
- No aliased columns; no NAs.
- Reference levels (factor-alphabetical, first level): `der_cj_eu_identity` →
  `eu_citizen`; `der_cj_partisanship` → `not_applicable`.

**Aliasing was the flagged risk but does NOT occur**, because `cj_treatment` is not a
covariate in 05/06 (treatment is `cj_rel == "muslim"`; condition is not in X). The
new vars are deterministic functions of `cj_treatment`, but since treatment itself is
absent from X there is no collinearity. Structural empty cells exist (e.g. `not_shown`
co-occurs only with EU identity `not_displayed`) but do not cause rank deficiency.

## prof_mods (now 6 moderators) — identical in 05/06/07/08/09

```r
prof_mods <- c(
  "cj_nat", "der_cj_eu_identity", "der_cj_partisanship",
  "cj_age", "cj_sex", "cj_class"
)
```

## Figure/label wiring (Phase 3)

- `code/helper_scripts/moderator_labels.R`: `mod_labels` facet titles
  `der_cj_eu_identity = "EU identity"`, `der_cj_partisanship = "Partisanship"`;
  both added to `cat_mods`; `value_labels` entries:
  - EU identity: eu_citizen → "sees herself as EU citizen"; not_eu_citizen → "does
    not see herself as EU citizen"; not_displayed → "not displayed".
  - Partisanship: shown → "partisanship shown"; not_shown → "partisanship not shown";
    not_applicable → "not applicable".
- Embedded combined figures (`index.qmd`): `fig-grf-combined-prof`,
  `fig-bcf-combined-prof` are `prof_mods`-driven → pick up the two new facets
  automatically (now 6 facets, 2 rows × 3 with `ncol = 3`).
- `07_postprocess_grf.qmd`: the two hardcoded `cj_eupos` per-moderator chunks were
  renamed to `der_cj_eu_identity`; new `der_cj_partisanship` chunks added (Dictator
  + Trust). These individual chunks are NOT embedded in `index.qmd`.
- `08` has no hardcoded `cj_eupos` chunk (driven by `lapply(prof_mods, ...)`); `09`
  uses `all_of(prof_mods)` — both automatic.

## ⚠️ Quarto cache gotcha (cost real debugging time)

`_quarto.yml` has `execute: freeze: auto` AND `execute: cache: true`. Editing an
upstream chunk re-runs that chunk, but unchanged downstream chunks restore from the
knitr cache and do NOT re-execute (no autodep). Symptom: `quarto render` reports
success but the output `.rds` keeps its old contents/mtime.

To force a clean rebuild of a notebook, delete **both** freeze and knitr cache:
```
rm -rf _freeze/code/NN_name code/NN_name_cache
quarto render code/NN_name.qmd
```
For the overnight full render + refit, clear caches for every touched notebook first:
```
rm -rf _freeze/code/0{2,5,6,7,8,9}_* code/0{2,5,6,7,8,9}_*_cache
```
Note: `_freeze/` is git-tracked in this repo (despite CLAUDE.md saying gitignored).
`02`'s cache was already cleared and `eu25_long.rds` regenerated/committed; 05–09
still hold pre-change cache state.

## NOT done (by design — left for the overnight run / follow-up)

- 05/06 NOT refit; 07/08/09 NOT re-run. The saved fits in `data/03_final/*.rds` are
  **stale** (trained on old `cj_eupos` X). Running 07/08/09 against them before
  refitting will error in the BLP/projection step (X column-count mismatch).
- `index.qmd` prose not updated: still says "Profile EU citizenship" (2-level). Wants
  a sentence on the new EU-identity/partisanship facets after refit. (Its current
  working-tree modification is the user's own authorial outline notes, unrelated.)
- Cosmetic: EU-identity facet x-axis orders alphabetically, so `not_displayed` lands
  in the middle.

## Rollback

- Revert all three commits: `git revert bcc36ba bc1f5a9 5a71862` (or
  `git reset --hard <commit-before-5a71862>` if nothing else is layered on top).
- The pre-change `eu25_long.rds` (Dictator-only, with the reshape bug) is the version
  committed before `5a71862`; do not restore it expecting both games.

---

# 2026-06-09 — Postprocessing figure adjustments (07 / 08)

Three display-only tweaks to the post-processing notebooks (no estimator/`X`/`sub_X`/projection
change). Not rendered here — picked up by the overnight render + refit.

1. **BCF ATE reported as numbers, not a figure** (`08_postprocess_bcf.qmd`, `#sec-ate`). Replaced
   the `fig-bcf-combined-ate` `geom_pointrange` chunk with a `cat(sprintf(...))` loop over
   `ate_comb`, printing each game's posterior median + 95% credible interval (mirrors GRF's
   `ate-dict`/`ate-trust` style; the manuscript footnote quotes these). Chunk relabelled
   `ate-bcf-numbers` (no longer a float). Not embedded in `index.qmd`, so no manuscript wiring change.

2. **"EU effect on" 5-point scales flipped** in both `07` and `08` combined figures.
   `q_eu_imp_nat_{econ,cul,pol}` are coded 1 (very positive) → 5 (very negative)
   (`09#tbl-wordings`), so right-on-axis used to mean *more negative*. Added them to the existing
   `flip5 <- \(x) 6 - x` display recode (alongside the three identity scales) so higher/right now
   means a *more positive* evaluation. Applied to the plotting copies only (`m_dict`/`m_trust`;
   GRF `combined-transforms`, BCF `build-dictator`/`build-trust`) — fits untouched. Updated the
   reversal prose and the resp-figure captions in both notebooks.

3. **Formal estimand added to headline titles.** Appended the plotmath estimand symbol via
   `bquote()` to the six main/robustness CATE-by-moderator titles: profile-level →
   `(hat(tau)[ric])`, respondent-level → `(hat(tau)[ic])`, matching the Causal Estimand section of
   `index.qmd` (eq-cate-profile / eq-cate-respondent) and the existing `yl_ric`/`yl_i` y-axis labels.

Follow-up (not done): `index.qmd` ~l.243 still has the self-note "EU effect on economy (x axis to
be flipped)"; that parenthetical is now stale (flip done) — left for the user since prose edits
were out of scope. Substantive interpretation ("more negative evaluation → larger penalty")
unchanged by the flip.
