# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Quarto manuscript project for academic research: **"Muslim Bias in Europe: Evidence from Conjoint Experiments"** (authors: Tristan Muno, Raphael Klöckner, Vera Okisheva — University of Mannheim). The project produces a manuscript (HTML/PDF/DOCX), a Revealjs presentation, and embedded computational notebooks written in R.

**Context:** Final paper for Theory Building and Causal Inference (Marc Ratkovic, Spring 2026). Target length is a 7-page research note. Data comes from Hahm et al.'s conjoint experiment (`eu25games`): 25 European countries, ~1,500 respondents per country, 3 conjoint tasks per respondent (~112,500 observations total).

## Research Plan

Three-stage analysis, descriptive throughout:

1. **Identify strongest conjoint effects** — empirical AMCEs across all attributes; expect Muslim to be among the largest.
2. **Profile-level moderators of Muslim bias** — which *other conjoint attributes* (occupation, language skills, education, etc., shown in the same profile) amplify or attenuate the Muslim effect.
3. **Respondent-level moderators** — which *respondent characteristics* are associated with stronger or weaker Muslim-attribute effects.

The two outcomes are behavioral game decisions: **Dictator Game** and **Trust Game**. Treatment is the Muslim attribute (binary: Muslim vs. comparison categories, pooled). Analysis is exploratory/descriptive — no confirmatory claims, no mediation, no causal claims beyond CATE estimation.

**Substantive focus:** individual-level (respondent) and profile-level (other conjoint attributes) heterogeneity in Muslim bias. **Not** a comparative cross-national study. Country-level structure is treated as a nuisance to account for, not interpreted substantively.

## Empirical Strategy

> [!IMPORTANT]
> **Before implementing the full analysis — to-do list (resolve first):**
> 1. **Test on a subsample of the real data.** Mechanism tests on synthetic data are done (`code/03_multibart_nested_ri_test.qmd` for hierarchical BCF; `code/04_grf_nested_test.qmd` for `grf`). The `multibart` test covers the **continuous path only** (`bcf_continuous_linear`); it recovers the two variance components (country SD above respondent SD) and the prognostic/treatment surfaces μ(x)/τ(x) against planted truth, with a country random-intercept caterpillar plot as the clustering diagnostic. The binary path was dropped as out of scope for the smoke test. The `grf` test runs on the **same synthetic data and seed**, continuous outcome only (no binary path either): it recovers the cluster-robust ATE, individual τ̂(x), and the best linear projection against planted truth (country as FE dummies in `X`, respondent as `clusters`; μ(x) and the variance components are nuisance that `grf` partials out, so they are not separately checked). Its figure set is two figures — a true-vs-recovered τ scatter against the 45° identity, and a BLP coefficient figure with the analytic true projection coefficients (x3 ≈ 0.75·φ(0), others zero) overlaid as crosses. The next gate is running both methods on a few-country subsample of the prepared `01_prep_hte` data to confirm the real data flows through and to bound the dense `WtW` cost of the nested-RE BCF fit (see CLAUDE.md Open Question #1).
> 2. **Decide on covariates to explore.** Freeze the pre-specified moderator list (profile-level + respondent-level; see Open Question #4) before fitting. Heterogeneity findings outside this list are exploratory addenda, not main results.

**Primary method: hierarchical Bayesian Causal Forests (BCF)** with nested random intercepts to account for the clustered structure, following the Yeager et al. application lineage (`yeager2019national`, `yeager2022synergistic`) and extended to two-level nesting in the local `multibart` package. Hierarchical BCF is preferred because:
- It targets τ(x) directly with a separate prior, addressing regularization-induced confounding (RIC) that affects the BART-then-difference approach in `green2012modeling`.
- The Bayesian posterior gives credible intervals on individual CATEs and any functional of τ for free.
- Nested random intercepts (respondent within country) handle the clustered structure via partial pooling on μ(x) — see Role of Random Intercepts below.

**Additional robustness: Causal Random Forests (CRF)** via `grf::causal_forest()` with:
- `clusters = respondent_id` for honest cluster-aware sampling and cluster-robust variance.
- Country fixed effects in the covariate matrix `X` (factor; `grf` handles factors natively).
- Frequentist counterpart to BCF: same estimand (CATE), different inferential machinery.
- Best linear projection (`best_linear_projection()`) onto the same pre-specified moderator set used for BCF posterior projection — makes the BCF/CRF comparison legible.

**Why both:** They search the same heterogeneity space with different machinery. Agreement is a strong robustness story; disagreement is substantively interesting and worth flagging.

## Role of Random Intercepts

**Country and (if feasible) respondent random intercepts are nuisance corrections for the nested data structure, not objects of substantive interpretation.** Concretely:

- Country REs absorb between-country baseline variation so that within-country heterogeneity in τ is the focus.
- Respondent REs (if implemented) absorb within-person dependence across the 3 conjoint tasks.
- REs enter on μ(x) only — no REs on τ, since country- or respondent-level τ variation is not the target.
- No country-specific ATE plot as a headline result. A diagnostic plot of country-level variation may appear in the appendix to justify the RE specification.

## Open Questions (Empirical Strategy)

These need to be resolved before fitting begins. **Do not let Claude Code freelance past them.**

1. **Nested random intercepts feasibility.** Data has two clustering levels: observations nested in respondents nested in countries. Yeager et al.'s code implements single-level (site) random effects, matching their multi-site RCT application. Open: can we extend it to two-level nesting in the time available, or do we use single-level country REs and address respondent dependence via cluster-bootstrapped CIs as a sensitivity check? **Default fallback if extension is non-trivial:** country REs only + cluster-bootstrap respondent-level uncertainty + acknowledge in limitations.
2. **If nested REs are feasible:** specify formally — random intercepts at respondent and country levels on μ(x); none on τ(x).
3. **If only single-level REs:** use country as the RE (clustering level with substantively meaningful between-cluster variation; partial pooling across 25 countries is principled).
4. **Pre-specified moderator list** (~10–15 variables for the projection / BLP step) needs to be frozen on Day 1, *before* seeing heterogeneity results. Split into two families matching the research plan:
    - **Profile-level moderators:** other conjoint attributes shown in the same profile (occupation, education of profile, language skills, etc.).
    - **Respondent-level moderators:** anti-immigration attitudes, EU identity/attachment, religiosity, education of respondent, political ideology, age, gender; possibly prior contact and pre-treatment anti-Muslim items.
    - Construct scores for multi-item respondent scales built on Day 1; both scores and items enter `X` for fitting, but interpretation is at the construct level.
5. **Treatment coding.** Muslim attribute is one level of a multi-level conjoint factor. Frozen decision: **Muslim vs. all-else-pooled (binary)**.

## Causal Estimand

To be written formally in Research Design section. Sketch:

- Potential outcomes Y_i(z) for z ∈ {0, 1} where z indexes Muslim attribute presence in the profile.
- Conditional average treatment effect: τ(x) = E[Y(1) − Y(0) | X = x].
- Average treatment effect: τ = E[τ(X)].
- Identification by randomization (conjoint design): Y(z) ⫫ Z | X with known propensities π(x) = 1/k for k profile levels (cite `hainmueller2014causal` for identification under conjoint randomization).
- Known propensities passed to BCF directly; no first-stage propensity estimation needed.

## One-Week Execution Plan

| Day | Task |
|-----|------|
| Mon | Pre-analysis note (`notes/analysis_plan.md`), covariate inventory, construct scores, freeze moderator list, project skeleton. |
| Tue | `01_prep_hte.qmd`: clean tibble per outcome (Y, Z, X, respondent_id, country_id). Smoke-test Yeager et al.'s code on one-country subset. Resolve open questions 1–3 above. |
| Wed | Full BCF fits for Dictator and Trust outcomes. Save full posterior τ̂(x) draws. **Don't look at results.** |
| Thu | CRF fits with `clusters = respondent_id`, country FEs. Compute headline quantities for both methods: ATE, variable importance (construct-aggregated, split by profile-level vs. respondent-level), posterior projection / BLP onto pre-specified moderators. |
| Fri | `05_figures.qmd`: Green & Kern–style figures (see below). Tables as TeX fragments. |
| Sat/Mon | Write manuscript (intro 0.5pp, data/methods 1.5pp, results 3–4pp, discussion 0.5–1pp). |
| Buffer | Reserve a full day for things that go wrong (MCMC convergence, OOM, weird data quirks). |

**Explicitly out of scope this week:** formal pre-registration, causal mediation, secondary treatments, cross-country comparative analysis, model comparison beyond BCF vs. CRF, sensitivity to unmeasured confounding (randomized treatment), task-position analysis.

## Figures (Green & Kern Visual Grammar)

Target figure set, organized around individual-level and profile-level heterogeneity:

1. **Headline density of individual CATEs** (`green2012modeling` Figure 2 style) with permuted-X null band overlay. One panel per outcome. "Is there heterogeneity at all" — the headline figure.
2. **Top respondent-level moderator marginal plots:** 4–6 small multiples, posterior τ̂ vs. levels of top respondent moderators (construct-level), posterior mean + credible ribbon. One figure per outcome.
3. **Top profile-level moderator marginal plots:** 3–5 small multiples for other conjoint attributes that moderate Muslim bias. Separate figure or clearly separated panels.
4. **Projection table:** BCF posterior projection coefficients alongside CRF `best_linear_projection` coefficients on the same pre-specified moderators. Split into profile-level and respondent-level subtables.
5. **Variable importance bar plot:** constructs ranked, profile- and respondent-level moderators distinguished by color/facet. Likely supplement.
6. **Appendix only:** country-level ATE variation as a clustering diagnostic.

## Key Commands

```bash
# Render the full project (manuscript + all notebooks)
quarto render

# Render only the main manuscript
quarto render index.qmd

# Render only the presentation
quarto render presentation.qmd

# Render a single analysis notebook
quarto render code/01_test.qmd

# Live preview with hot reload
quarto preview

# Live preview a specific file
quarto preview index.qmd
```

## Repository Structure

- `index.qmd` — main manuscript (Introduction, Theory, Design, Analysis, Conclusion, Appendix)
- `presentation.qmd` — Revealjs slides using `theme.scss`
- `_quarto.yml` — project-level config: authors, bibliography, output formats, post-render hooks
- `references.bib` — BibTeX bibliography (APSR style); **all entries require a DOI**
- `code/` — numbered R analysis notebooks (`01_`, `02_`, …); `00_template.qmd` is the template for new notebooks
- `code/helper_scripts/copy_figures.R` — post-render script that copies figures from `_freeze/` into `_manuscript/` so the HTML preview renders correctly
- `data/` — datasets (structure TBD as project grows)
- `literature/` — PDF papers (gitignored — not tracked in Git)
- `notes/` — working notes including `analysis_plan.md`
- `_extensions/andrewheiss/wordcount/` — Quarto extension providing word count and custom citeproc

### Planned analysis notebooks
- `code/01_prep_hte.qmd` — data prep for heterogeneity analysis
- `code/02_fit_bcf.qmd` — BCF fits (Dictator + Trust)
- `code/03_fit_crf.qmd` — CRF fits + cluster-robust ATE
- `code/04_summarize.qmd` — posterior summaries, projection, variable importance
- `code/05_figures.qmd` — manuscript figures

## Workflow Notes

### Freeze / caching
`execute: freeze: auto` is set globally. Quarto caches computed outputs in `_freeze/`. Notebooks only re-execute when their source changes. To force re-execution of a notebook, delete its subfolder under `_freeze/code/`.

**BCF fits are expensive** (long MCMC runs on ~100k obs with many covariates). Once a fit is complete and saved to `.rds`, do not re-execute unless the data or model spec changes. Save `sessionInfo()`, seed, and run time alongside the posterior object.

**Do not set knitr per-chunk `cache: true` in `multibart` notebooks.** The fitted forest's `tree_samples` is a live Rcpp external pointer that does not survive cache serialize/reload; a partial re-run then loads a fit with a dead pointer and `get_forest_fit()` fails with `external pointer is not valid`. Rely on Quarto `freeze: auto` (file-level) for re-execution caching instead.

### Adding a new analysis notebook
1. Copy `code/00_template.qmd` to `code/NN_name.qmd`.
2. Register it in `_quarto.yml` under `manuscript.notebooks`:
```yaml
   manuscript:
     notebooks:
       - notebook: code/NN_name.qmd
         title: "Descriptive title"
```
3. Embed figures/tables in `index.qmd` with `{{< embed code/NN_name.qmd#label >}}`.

### Output formats
The manuscript renders to three formats defined in `_quarto.yml`:
- **HTML** — TOC, noindex meta tag, wordcount filter, citeproc via Lua filter
- **PDF** — A4, 12pt, double-spaced, 2 cm margins, APSR footnote citations
- **DOCX** — default styling

### What is gitignored
`_freeze/`, `.quarto/`, `_manuscript/`, `site_libs/`, all rendered outputs (`*.pdf`, `*.html`, `*.docx`), `literature/`, and `notes.md` are excluded from Git.

## Coding Conventions

These rules apply to all code in this project. Follow them without being asked.

### R Code
- Tidyverse paradigm throughout; follow `00_template.qmd` as structural template
- Use `|>` (base pipe) consistently
- Minimal new packages — ask and justify before adding any; add a brief inline comment to the package loading call explaining what it's used for
- Code comments: 1–3 words max; put explanation in surrounding Markdown prose
- Use `colour =` (not `color =`) in ggplot2 calls
- Use `case_match()` instead of deprecated `recode()` for factor relabelling
- Setup chunk: `start_time <- Sys.time()`, package install-and-load block, `rm()` cleanup; session-info and exec-time chunks at end always have `eval: true`
- Verification chunks with `stopifnot()` after data prep steps (row counts, no NAs in Z and X, balance checks)

### Quarto Documents
- YAML: `toc: true`, `toc-depth: 3`, `code-fold: true`, `code-tools: true`; execute block: `echo/warning/eval/message: true`
- One sentence per line in `.qmd` prose
- Add section labels to every heading (e.g. `{#sec-intro}`) so sections are cross-referenceable
- Math: `$...$` inline; display equations use `$$` with a blank line after opening and before closing `$$`, always with an equation label

### Figures
- `ggplot2` as primary plotting system; `theme_pubr` (ggpubr) as default theme
- Golden ratio (~1.618:1) as aspect ratio where appropriate — not for facets or auto-sized contexts
- Multi-panel plots: use `patchwork`
- Each plot in its own chunk; cell options: `label: fig-*`, add `fig-cap`, set `dpi: 500`
- Always include `title =` in `labs()`
- Design: maximize information/ink ratio (Tufte), colorblind-safe palette, readable in color and black-and-white print

### Tables
- Simple overviews → raw Quarto Markdown tables
- Computation-based → `kable()` from knitr
- Regression/model output → `modelsummary`
- Complex formatting → `gt`
- Always set cell `label: tbl-*` and add a caption

## Bibliography Rules

- **Every entry in `references.bib` must have a DOI.** No exceptions. If a reference lacks a DOI, do not add it; flag it for manual review.
- Use existing citation keys from `references.bib` whenever possible.
- When proposing a new reference, supply the DOI alongside the BibTeX entry so it can be verified before being added.

## Claude Code Workflow Constraints

- Use terse imperative prompts with explicit scope constraints and stop gates.
- One scope-limited prompt per notebook. No freelancing into "should we also try X."
- Stop gate after each notebook: posterior/forest objects saved, summary objects extracted, figures rendered, then move on.
- Do not relitigate open questions 1–3 once decided. Do not propose alternative methods (e.g., `stan4bart`, plain `bcf`) once Yeager et al.'s code is committed.
- Pre-specified moderator list is frozen after Day 1. Heterogeneity findings outside this list are exploratory addenda, not main results.
- Output escaped source markdown for copy-paste use when generating prose for the manuscript.

## Methodological References

Core methods literature for the manuscript and methods discussion (all entries already in `references.bib` with verified DOIs):

- **BCF (foundational):** `hahn2020bayesian`.
- **BCF extensions / hierarchical:** `caron2022shrinkage`, `thal2024aggregate`, `mcjames2025bayesian`, `prevot2025hierarchical`.
- **BCF applications (Yeager lineage):** `yeager2019national`, `yeager2022synergistic`.
- **BART:** `chipman2010bart`, `chipman2006bayesian`, `hill2020bayesian`, `carnegie2019examining`.
- **BART for HTE in political science (visual grammar reference):** `green2012modeling`.
- **Causal forests:** `wager2018estimation`, `athey2019estimating`, `davis2017using`, `jawadekar2023practical`, `zheng2023estimating`.
- **Conjoint subgroup analysis:** `leeper2020measuring`.
- **Benchmarking causal inference methods:** `dorie2019automated`.
- **Data context:** `hahm2023divided`, `hahm2024divided`.

**Additional references recommended but not yet in `references.bib` — DOIs to verify before adding:**

- **Hill (2011), "Bayesian Nonparametric Modeling for Causal Inference,"** *JCGS* 20(1): 217–240. DOI: `10.1198/jcgs.2010.08162`. Foundational for BART-for-causal-inference; precursor to BCF.
- **Hainmueller, Hopkins & Yamamoto (2014), "Causal Inference in Conjoint Analysis,"** *Political Analysis* 22(1): 1–30. DOI: `10.1093/pan/mpt024`. Standard methodological citation for conjoint identification.
- **Athey, Tibshirani & Wager (2019), "Generalized Random Forests,"** *Annals of Statistics* 47(2): 1148–1178. DOI: `10.1214/18-AOS1709`. Methodological basis for the `grf` package.
- **Woody, Carvalho & Murray (2021), "Model Interpretation Through Lower-Dimensional Posterior Summarization,"** *JCGS* 30(1): 144–161. DOI: `10.1080/10618600.2020.1796684`. Methodological basis for the posterior-projection step on BCF output.