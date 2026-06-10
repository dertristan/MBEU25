# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Quarto manuscript project for academic research: **"Muslim Bias in Europe: Evidence from Conjoint Experiments"** (Working Title). The project produces a manuscript (HTML/PDF/DOCX), a Revealjs presentation, and embedded computational notebooks written in R.

**Context:** Final paper for Theory Building and Causal Inference (Marc Ratkovic, Spring 2026). Target length is a 7-page research note. Data comes from Hahm et al.'s conjoint experiment (`eu25games`): 25 European countries, ~1,500 respondents per country, 3 conjoint tasks per respondent (~112,500 observations total). Full dataset (and pre-processing pipeline) is available at [GitHub](https://github.com/LS-Konig/eu25games2019).

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
> 1. **Estimator mechanism tests are DONE.** Mechanism tests on synthetic data pass (`code/03_multibart_nested_ri_test.qmd` for hierarchical BCF; `code/04_grf_nested_test.qmd` for `grf`). The `multibart` nested random-intercept extension is implemented and passes the synthetic smoke test on the **continuous path only** (`bcf_continuous_linear`): the two variance components recover in the right order and magnitude (country SD above respondent SD, with the expected downward shrinkage given few groups), and the prognostic/treatment surfaces μ(x)/τ(x) recover against planted truth. The country random-intercept caterpillar is the appendix-only clustering diagnostic; it is correct once compared in **centred** form — the apparent constant offset was a centring convention, not a fitting failure, because the random intercepts are identified only up to a constant shared with μ's grand mean (every reported quantity — τ(x), the projection, the ATE — is centring-invariant). The smoke test now also runs `n_chains` chains (default 4) for convergence diagnostics: per-functional trace plots, R̂, and bulk-ESS. `multibart` is single-chain per call, so multiple chains are obtained by looping over RNG seeds (the C++ sampler draws from R's RNG, so distinct seeds give distinct chains). The binary path was dropped as out of scope. The `grf` test runs on the **same synthetic data and seed**, continuous outcome only (no binary path either): it recovers the cluster-robust ATE, individual τ̂(x), and the best linear projection against planted truth (country as FE dummies in `X`, respondent as `clusters`; μ(x) and the variance components are nuisance that `grf` partials out, so they are not separately checked). Its figure set is two figures — a true-vs-recovered τ scatter against the 45° identity, and a BLP coefficient figure with the analytic true projection coefficients (x3 ≈ 0.75·φ(0), others zero) overlaid as crosses. **Update (2026-06-06): the nested-RE feasibility gate is resolved — nested fit infeasible, country-only REs adopted (see Open Question #1).** The dense `WtW` cost was bounded on a real-data subsample and the nested respondent-level fit is prohibitive; the BCF path now uses country random intercepts only, with respondent dependence handled by a cluster bootstrap. **The remaining gate before the substantive analysis is** (2) freezing the pre-specified moderator list (item 2 below) — now also done.
> 2. **Covariates frozen (2026-06-04).** The pre-specified moderator list (profile-level + respondent-level; see Open Question #4) is frozen. Heterogeneity findings outside this list are exploratory addenda, not main results. **Resolved decisions:** (a) to guard against post-treatment / collider bias, the respondent-level moderator set is restricted to **pre-treatment measures only** — do not condition on variables affected by the treatment; (b) because that restriction shrinks the candidate pool, the set includes **both individual survey items and aggregate indices** (interpretation at the construct level). Profile-level conjoint attributes are randomized and remain in scope.

**Primary method: Causal Random Forests (honest causal forests, Athey et al.)** via `grf::causal_forest()` (`athey2019generalized`, `wager2018estimation`) with:
- `clusters = respondent_id` for honest cluster-aware sampling and cluster-robust variance.
- Country fixed effects in the covariate matrix `X` (factor; `grf` handles factors natively).
- CATE recovery by moderator — the **headline results figure**: subset/binned τ̂ across the levels of each pre-specified moderator with honest cluster-robust CIs. The visual-grammar template is fig 3 (`fig-cate-by-cov-grf`) in `04_grf_nested_test.qmd`.
- Best linear projection (`best_linear_projection()`) onto the pre-specified moderator set — an appendix/robustness coefficient summary (the linear counterpart to the CATE-by-moderator surface), **not** the headline.
- Honesty (sample-splitting) gives valid CIs on τ̂(x) and the ATE without distributional assumptions; favoured as primary after its stronger synthetic-test performance (`04_grf_nested_test.qmd`).

**Robustness: hierarchical Bayesian Causal Forests (BCF)** with nested random intercepts to account for the clustered structure, following the Yeager et al. application lineage (`yeager2019national`, `yeager2022synergistic`) and extended to two-level nesting in the local `multibart` package. Hierarchical BCF complements the primary analysis because:
- It targets τ(x) directly with a separate prior, addressing regularization-induced confounding (RIC) that affects the BART-then-difference approach in `green2012modeling`.
- The Bayesian posterior gives credible intervals on individual CATEs and any functional of τ for free.
- Nested random intercepts (respondent within country) handle the clustered structure via partial pooling on μ(x) — see Role of Random Intercepts below.
- The BCF headline is likewise the CATE-by-moderator surface (posterior mean + credible ribbon across each moderator's levels), the Bayesian counterpart to the CRF fig 3 template.
- Posterior projection onto the same pre-specified moderator set used for the CRF BLP makes the CRF/BCF comparison legible — appendix material (the BCF counterpart to the CRF BLP), not a headline result.

**Why both:** They search the same heterogeneity space with different machinery. Agreement is a strong robustness story; disagreement is substantively interesting and worth flagging.

> [!NOTE]
> **Main-vs-robustness framing decided (2026-06-04): CRF/GRF primary, BCF robustness.** The empirical strategy (fit both CRF and BCF) is unchanged; only the framing is settled, driven by GRF's stronger synthetic-test performance (`04_grf_nested_test.qmd`). Planned notebook numbers are historical (`05_*`=BCF, `06_*`=CRF) and do not imply priority.

## Role of Random Intercepts

**Country and (if feasible) respondent random intercepts are nuisance corrections for the nested data structure, not objects of substantive interpretation.** Concretely:

- Country REs absorb between-country baseline variation so that within-country heterogeneity in τ is the focus.
- Respondent REs (if implemented) absorb within-person dependence across the 3 conjoint tasks.
- REs enter on μ(x) only — no REs on τ, since country- or respondent-level τ variation is not the target.
- No country-specific ATE plot as a headline result. A diagnostic plot of country-level variation may appear in the appendix to justify the RE specification.

## Open Questions (Empirical Strategy)

These need to be resolved before fitting begins. **Do not let Claude Code freelance past them.**

1. **Nested random intercepts feasibility. RESOLVED (2026-06-06): nested fit infeasible; country-only REs adopted (the documented fallback).** Data has two clustering levels: observations nested in respondents nested in countries. The two-level nested extension is implemented in `multibart` and passes the synthetic smoke test (`03_multibart_nested_ri_test.qmd`, continuous path) — the math and machinery are correct. But the sampler forms the random-effects precision `Phi = adj·WtW·adj` densely and Cholesky-solves it every Gibbs sweep, an `O(q³)` cost in `q = C + R` dominated by the ~22k–37.5k respondent dummies. On a 10k-row real-data subsample this took >20 min to reach iteration 1; the cubic term makes the full-scale nested fit prohibitive in the project window. **Decision: drop the respondent RE and fit country random intercepts only** (`q ≈ 25`, the RE block is a trivial `C × C` solve), the fallback flagged here from the start. Respondent within-person dependence (3 conjoint tasks each) is handled by a **respondent cluster bootstrap** as a sensitivity check on the BCF side (the primary GRF/CRF side gets it free via `clusters = respondent_id`). The real-data path in `03_multibart_nested_ri_test.qmd` (`#sec-subsample`) now fits country-only REs and explains the cluster bootstrap (`#sec-cluster-bootstrap`); the synthetic section retains the full nested mechanism test (cheap at small scale). **Do not re-attempt the nested respondent-level fit** unless the sampler is rewritten to exploit the sparsity of `W`/`WtW` (a non-trivial C++ change, out of scope for this window).
2. **If nested REs are feasible:** specify formally — random intercepts at respondent and country levels on μ(x); none on τ(x).
3. **If only single-level REs:** use country as the RE (clustering level with substantively meaningful between-cluster variation; partial pooling across 25 countries is principled).
4. **Pre-specified moderator list.** **Status (2026-06-04): frozen** at the covariate-selection stage, *before* seeing heterogeneity results. Split into two families matching the research plan:
    - **Profile-level moderators:** other conjoint attributes shown in the same profile (occupation, education of profile, language skills, etc.). Randomized — unaffected by the post-treatment-bias restriction.
    - **Respondent-level moderators (pre-treatment measures only):** anti-immigration attitudes, EU identity/attachment, religiosity, education of respondent, political ideology, age, gender, prior contact, and pre-treatment anti-Muslim items. Variables measured after the experiment are excluded to avoid post-treatment / collider bias.
    - Construct scores (aggregate indices) for multi-item respondent scales built at the same stage (before fitting). Frozen decision: **both the individual items and the aggregate indices** enter `X` for fitting and the projection set; interpretation is at the construct level. The set may exceed the earlier ~10–15-variable rule of thumb because items and indices are included together.
5. **Treatment coding.** Muslim attribute is one level of a multi-level conjoint factor. Frozen decision: **Muslim vs. all-else-pooled (binary)**.

## Causal Estimand

Drafted in the Research Design section of `index.qmd` (2026-06-08). Sketch:

- Potential outcomes Y_i(z) for z ∈ {0, 1} where z indexes Muslim attribute presence in the profile.
- Conditional average treatment effect: τ(x) = E[Y(1) − Y(0) | X = x].
- Average treatment effect: τ = E[τ(X)].
- Identification by randomization (conjoint design): Y(z) ⫫ Z | X with known propensities π(x) = 1/k for k profile levels (cite `hainmueller2014causal` for identification under conjoint randomization).
- Known propensities passed to BCF directly; no first-stage propensity estimation needed.

## Execution Plan (Thu 2026-06-04 → Thu 2026-06-11)

> [!NOTE]
> **Status (Wed 2026-06-10):** ahead of the table; in the writing phase. Data prep, both full fits (all four `data/03_final/*.rds`), and post-processing/figures are done — the planned `07_*` figures step shipped as three notebooks (`07_postprocess_grf`, `08_postprocess_bcf`, `09_additional_figs_tables`). The manuscript (`index.qmd`) is now substantially drafted across all sections: Introduction, Research Design (Data and Experiment, Causal Estimand, Estimation Strategy), Empirical Analysis (headline GRF CATE-by-moderator figures with full written interpretation), Robustness (BCF comparison), Limitations, a Conclusion stub, and Appendices A/B/C with figures/tables embedded. Remaining writing work (through Thu 2026-06-11): tighten the Conclusion and Introduction, length trim to the 7-page target. The Mon buffer day was not needed for firefighting; effort rolled into writing.

| Day | Task |
|-----|------|
| **Thu 2026-06-04 (today)** | (1) Write `02_data_prep.qmd` — data summary/overview (also for collaborators) + clean long-format analysis tibble (Y, Z, X, respondent_id, country_id). (2) Covariate set settled with coauthors and frozen: (a) **pre-treatment variables only** (drop post-treatment measures); (b) **both items and aggregate indices** ("all items + index"). (3) Estimator tests on a **real few-country subsample** (both methods) — confirm estimation runs and bound full-sample compute time/memory; **no results inspection**. (4) Framing decided: **GRF/CRF is the primary analysis, BCF the robustness check** (synthetic tests favour GRF); empirical strategy (fit both) unchanged. |
| **Fri 2026-06-05** | Full fits on real data: BCF (`05_*.qmd`) + CRF (`06_*.qmd`), both outcomes. Save posterior τ̂(x) draws / forests, ATE, posterior projection / BLP, variable importance (construct-aggregated, split by profile-level vs. respondent-level). **Don't look at results.** |
| **Sat–Sun 2026-06-06/07** | `07_*.qmd`: Green & Kern–style figures (see below). Tables as TeX fragments. |
| **Mon 2026-06-08** | Buffer — reserve for things that went wrong (MCMC convergence, OOM, weird data quirks). |
| **Tue–Thu 2026-06-09/10/11** | Write manuscript (intro 0.5pp, data/methods 1.5pp, results 3–4pp, discussion 0.5–1pp). |

**Explicitly out of scope for this execution window:** formal pre-registration, causal mediation, secondary treatments, cross-country comparative analysis, model comparison beyond BCF vs. CRF, sensitivity to unmeasured confounding (randomized treatment), task-position analysis.

## Figures (Green & Kern Visual Grammar)

Target figure set, organized around individual-level and profile-level heterogeneity:

The two headline results figures are the CATE density (#1) and the CATE-recovery-by-moderator small multiples (#2–#3). The latter are the substantive payoff — they follow the visual grammar of **fig 3 (`fig-cate-by-cov-grf`) in `04_grf_nested_test.qmd`**: per-bin/per-level CATE across each moderator with cluster-robust CIs (CRF) or posterior ribbon (BCF). The linear projection is **not** a headline figure — it is appendix/supplement material.

1. **Headline density of individual CATEs** (`green2012modeling` Figure 2 style) with permuted-X null band overlay. One panel per outcome. "Is there heterogeneity at all" — the headline figure.
2. **Top respondent-level moderator marginal plots (CATE recovery by moderator):** 4–6 small multiples, τ̂ vs. levels of top respondent moderators (construct-level), per-bin/per-level CATE with cluster-robust CIs (CRF) / posterior mean + credible ribbon (BCF), following fig 3 (`fig-cate-by-cov-grf`) of `04_grf_nested_test.qmd`. One figure per outcome. **Headline results figure.**
3. **Top profile-level moderator marginal plots (CATE recovery by moderator):** 3–5 small multiples for other conjoint attributes that moderate Muslim bias, same fig-3 grammar as #2. Separate figure or clearly separated panels. **Headline results figure.**
4. **Variable importance bar plot:** constructs ranked, profile- and respondent-level moderators distinguished by color/facet. Likely supplement.
5. **Appendix / supplement — dropped from the manuscript (2026-06-10).** The linear projection figure was cut from the appendix; the embed is commented out in `index.qmd` (Appendix B). The CRF `best_linear_projection` / BCF posterior projection are still computed in `07_`/`08_` but no longer surfaced as a figure. (Originally: CRF BLP coefficients alongside BCF posterior projection on the same pre-specified moderators, the linear-summary counterpart to #2–#3, template fig 4 `fig-blp` in `04_grf_nested_test.qmd`.)
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
- `data/` — `01_raw/` (raw source `eu25games2019.rds`), `02_processed/` (clean long-format analysis tibble `eu25_long.rds`), `03_final/` (saved fits: `grf_{dictator,trust}.rds`, `bcf_{dictator,trust}.rds`); full dataset and pre-processing pipeline available at [GitHub](https://github.com/LS-Konig/eu25games2019)
- `literature/` — source papers (gitignored — not tracked in Git); `literature/pdf/` holds the PDFs and `literature/md/` holds converted Markdown. Each file is named by its `references.bib` citation key (e.g. `hahn2020bayesian.pdf` / `hahn2020bayesian.md`). **Do not read these files on your own — always ask first (see Workflow Constraints).**
- `notes/` — working notes including `analysis_plan.md`
- `_extensions/andrewheiss/wordcount/` — Quarto extension providing word count and custom citeproc

### Analysis notebooks
Existing:
- `code/01_exploration4presentation.qmd` — exploratory data work for the presentation
- `code/02_data_prep.qmd` — data prep for heterogeneity analysis: data summary/overview for collaborators + clean long-format analysis tibble (Y, Z, X, respondent_id, country_id), written to `data/02_processed/eu25_long.rds`
- `code/03_multibart_nested_ri_test.qmd` — **estimator test** for hierarchical BCF (`multibart`) on synthetic data; recovers variance components and μ(x)/τ(x) against planted truth (continuous path only), plus parallel multi-chain convergence diagnostics (trace plots, R̂, bulk-ESS via `posterior`; chains via `furrr`/`future`). Its real-data section (`#sec-subsample`) fits country-only REs on a subsample and bounds the nested-fit compute cost — the basis for the feasibility decision
- `code/04_grf_nested_test.qmd` — **estimator test** for `grf` on the same synthetic data/seed; recovers cluster-robust ATE, τ̂(x), and BLP against planted truth

Note: `03_` and `04_` are mechanism/smoke tests of the estimators, **not** the substantive analyses.

Full fits on the real data (**fitting and saving only** — no τ(x) extraction, projection, variable importance, figures, or tables; those are deferred to the post-processing/figures step). Both done; all four fits saved under `data/03_final/`:
- `code/05_bcf_fit.qmd` — full hierarchical BCF fits (Dictator + Trust), **country-only REs** (nested respondent fit infeasible; respondent dependence left for a cluster bootstrap downstream), saved to `data/03_final/bcf_{dictator,trust}.rds`. The **robustness** estimator.
- `code/06_grf_fit.qmd` — full `grf` causal-forest fits (Dictator + Trust), `clusters = respondent_id` + country FE in `X`, saved to `data/03_final/grf_{dictator,trust}.rds`. The **primary** estimator.

Post-processing + figures (the planned single `07_*` was split into three notebooks; all exist as of 2026-06-08). Green & Kern visual grammar throughout:
- `code/07_postprocess_grf.qmd` — post-processes the **primary** GRF fits into ATE (`average_treatment_effect`, doubly-robust/AIPW with cluster-robust SE), TOC/RATE (`rank_average_treatment_effect`, AUTOC), BLP (`best_linear_projection`), variable importance (aggregated from the expanded dummy columns up to construct level), and the headline **CATE-by-moderator** figures (per-level subset ATE with honest cluster-robust 95% CIs). Written line-by-line, one explicit chunk per moderator; moderators split into `prof_mods` (conjoint round-level) and `resp_mods` (respondent-level). Includes combined figures overlaying both games on one canvas.
- `code/08_postprocess_bcf.qmd` — BCF counterpart, structurally parallel to `07`: ATE posterior, **posterior linear projection** (`woody2021model`, the Bayesian counterpart to GRF's BLP), and CATE-by-moderator figures with **posterior medians + 95% credible intervals** read off the τ(x) draws via `get_forest_fit()`. Combined-figure grammar (each game encoded by colour + shape + linetype together, so it survives greyscale and colourblindness). The respondent cluster bootstrap is a separate downstream step, not done here.
- `code/09_additional_figs_tables.qmd` — manuscript-level descriptive figures and tables built from `eu25_long.rds` (not from the fits): house-style definitions (Okabe-Ito game palette, golden-ratio helpers), token-allocation difference-in-means by game (Welch t-test), outcome distributions, the covariate-balance table, and the survey-item reference table.

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
- Do not relitigate the open questions once decided, including the now-frozen covariate set and the GRF/CRF-primary / BCF-robustness framing (decided 2026-06-04). Do not propose alternative methods (e.g., `stan4bart`, plain `bcf`) once Yeager et al.'s code is committed.
- Pre-specified moderator list is frozen after the covariate-selection stage (Thu 2026-06-04): pre-treatment variables only, both items and aggregate indices. Heterogeneity findings outside this list are exploratory addenda, not main results.
- Output escaped source markdown for copy-paste use when generating prose for the manuscript.
- **Never read files under `literature/` on your own initiative** — always ask first and wait for confirmation before opening any PDF or converted Markdown there. This is a context-management rule: the papers are large and should only be pulled in when explicitly needed.

## Methodological References

Core methods literature for the manuscript and methods discussion (all entries already in `references.bib` with verified DOIs):

- **BCF (foundational):** `hahn2020bayesian`.
- **BCF extensions / hierarchical:** `caron2022shrinkage`, `thal2024aggregate`, `mcjames2025bayesian`, `prevot2025hierarchical`.
- **BCF applications (Yeager lineage):** `yeager2019national`, `yeager2022synergistic`.
- **BART (foundational):** `chipman2010bart`, `chipman2006bayesian`, `hill2020bayesian`, `carnegie2019examining`, `hill2011bayesian` (BART-for-causal-inference precursor to BCF).
- **BART for HTE in political science (visual grammar reference):** `green2012modeling`.
- **Causal forests:** `wager2018estimation`, `athey2019estimating`, `athey2019generalized` (GRF — methodological basis for the `grf` package), `davis2017using`, `jawadekar2023practical`, `zheng2023estimating`.
- **Posterior projection / lower-dimensional summarization:** `woody2021model` (basis for the BCF posterior-projection step).
- **Conjoint identification:** `hainmueller2014causal`.
- **Conjoint subgroup / heterogeneity analysis:** `leeper2020measuring`, `robinson2024detect`, `goplerud2025estimating`.
- **Benchmarking causal inference methods:** `dorie2019automated`.
- **Data context:** `hahm2023divided`, `hahm2024divided`.
- **Substantive (Muslim bias / Islamophobia literature):** `helbling2012islamophobia`, `helbling2014framing`, `helbling2014opposing`, `helbling2020islamophobia`, `helbling2022muslim`, `choi2023hijab`, `findor2025anti`.