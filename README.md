# Penalized for Faith: Who Drives the Muslim Penalty?

### Treatment-Effect Heterogeneity in European Conjoint Behavioral Games

[![DOI](https://zenodo.org/badge/DOI/<<CONCEPT_DOI>>.svg)](https://doi.org/<<CONCEPT_DOI>>)

Term paper for **Theory Building and Causal Inference** (Prof. Marc Ratkovic), University of Mannheim, Spring 2026.

📄 **Read the rendered manuscript:** [dertristan.github.io/MBEU25](https://dertristan.github.io/MBEU25)

> The Zenodo badge above resolves once the first GitHub release is archived. Replace every `<<CONCEPT_DOI>>` placeholder (here, in the [How to cite](#how-to-cite) section, and in `CITATION.cff`) with the version-agnostic **concept DOI** Zenodo mints.

---

## Research Summary

This project reanalyzes data from [Hahm, Hilpert & König (2024)](#data-source), a conjoint survey experiment fielded across 25 EU member states in 2019. Respondents played two economic behavioral games — a **dictator/solidarity game** and a **trust game** — allocating tokens to a fictitious co-player whose profile carried randomized attributes (religion, nationality, age, social class, partisanship, EU stance, gender). The conjoint randomization identifies attribute-specific biases.

We isolate the **Muslim penalty** — the causal effect of a co-player being shown as Muslim (vs. all other religions pooled) on the respondent's allocation — and treat it as the quantity of interest. The study is **not** a cross-national comparison. Country is a nuisance to account for, not interpreted. Instead we focus on **heterogeneity** in the penalty, shifting from the AMCE to a conditional-average-treatment-effect (CATE) logic, across two sources:

1. **Profile-level interaction** — which *other conjoint attributes* in the same profile (occupation, nationality, partisanship, EU stance, …) amplify or attenuate the Muslim effect.
2. **Respondent-level moderation** — which *respondent characteristics* (political attitudes, religiosity, contact, socioeconomic status, …) predict stronger or weaker bias.

The analysis is exploratory and descriptive throughout.

### Empirical Strategy

We estimate the CATE of the Muslim attribute with a dual strategy. The primary method is **causal random forests** (`grf`) with respondent-level clusters and country fixed effects, giving honest, cluster-robust confidence intervals on τ̂(x). As a Bayesian robustness check we fit **hierarchical Bayesian Causal Forests** (BCF). The clustered structure is handled by **country random intercepts**. Within-respondent dependence across the three conjoint rounds is absorbed by the cluster structure on the `grf` side and by a respondent cluster bootstrap on the BCF side. Separate models are estimated for each game. See `index.qmd` for full detail.

### Data Source

> Hahm, H., Hilpert, D., & König, T. (2024). Divided we unite: The nature of partyism and the role of coalition partnership in Europe. *American Political Science Review*, 118(1), 69–87. https://doi.org/10.1017/S0003055423000266

Full dataset and pre-processing pipeline: [github.com/LS-Konig/eu25games2019](https://github.com/LS-Konig/eu25games2019).

---

## Repository Structure

```
MBEU25/
│
├── index.qmd                    # Main manuscript (paper)
├── presentation.qmd             # Revealjs presentation slides
├── _quarto.yml                  # Quarto project config (authors, formats, bibliography)
├── references.bib               # BibTeX bibliography (APSR style)
├── theme.scss                   # Custom SCSS theme for the presentation
│
├── code/
│   ├── 00_template.qmd                  # Template for new analysis notebooks
│   ├── 01_exploration4presentation.qmd  # Exploratory analysis for the slides
│   ├── 02_data_prep.qmd                 # Data cleaning / prep (long-format analysis tibble)
│   ├── 03_multibart_nested_ri_test.qmd  # Hierarchical (nested RI) BCF mechanism test
│   ├── 04_grf_nested_test.qmd           # grf causal-forest mechanism test
│   ├── 05_bcf_fit.qmd                   # Full BCF fits on real data (robustness)
│   ├── 06_grf_fit.qmd                   # Full grf causal-forest fits (primary)
│   ├── 07_postprocess_grf.qmd           # GRF post-processing: ATE, CATE-by-moderator figures
│   ├── 08_postprocess_bcf.qmd           # BCF post-processing: posterior CATE figures
│   ├── 09_additional_figs_tables.qmd    # Descriptive figures and tables
│   ├── multibart/                       # Local R package: hierarchical BCF (see below)
│   └── helper_scripts/                  # copy_figures.R, moderator_labels.R, glftrackeR.R
│
├── data/
│   ├── 01_raw/                  # Raw source data (eu25games2019.rds)
│   ├── 02_processed/            # Clean long-format analysis tibble (eu25_long.rds)
│   └── 03_final/                # Saved fits: grf_{dictator,trust}.rds, bcf_{dictator,trust}.rds
│
├── images/                      # University of Mannheim branding for slides (see COPYRIGHTS.md)
└── literature/                  # Source PDFs — gitignored, not tracked
```

> **Generated folders** (`_freeze/`, `_manuscript/`, `.quarto/`, `site_libs/`) are created by Quarto at render time and are gitignored.

### The `multibart` package

`code/multibart/` implements **hierarchical Bayesian Causal Forests with nested random intercepts** (respondent within country), used here as the **Bayesian robustness check**. The two-level extension is implemented and validated on synthetic data, but the full-scale nested respondent fit was benchmarked as computationally infeasible in the project window. The real-data BCF fits therefore use **country random intercepts only**, with respondent dependence handled by a cluster bootstrap. The nesting extension was made entirely in R (no C++ changes). The package is adapted from the BCF implementation released with:

> Yeager, D. S., et al. (2022). A synergistic mindsets intervention protects adolescents from stress. *Nature*, 607(7919), 512–520. https://doi.org/10.1038/s41586-022-04907-7

---

## Getting Started

**Prerequisites:** [Quarto](https://quarto.org/docs/get-started/) (≥ 1.4) and R with `tidyverse`, `here`, `ggpubr`, `sessioninfo` (analysis notebooks pull in `grf` and the local `multibart`).

```bash
quarto render                       # Full project (manuscript + all notebooks)
quarto render index.qmd             # Main manuscript only
quarto render presentation.qmd      # Presentation only
quarto preview                      # Live preview with hot reload
```

Quarto caches computed results in `_freeze/` (`freeze: auto`). A notebook re-executes only when its source changes. To force re-execution, delete its subfolder under `_freeze/code/`.

---

## How to cite

If you use this work, please cite the manuscript. Machine-readable metadata is in [`CITATION.cff`](CITATION.cff); GitHub renders a "Cite this repository" widget from it.

> Muno, T., Okisheva, V., & Klöckner, R. (2026). *Penalized for Faith: Who Drives the Muslim Penalty? Treatment-Effect Heterogeneity in European Conjoint Behavioral Games.* University of Mannheim. https://dertristan.github.io/MBEU25. https://doi.org/<<CONCEPT_DOI>>

BibTeX:

```bibtex
@report{muno2026penalized,
  title       = {Penalized for Faith: Who Drives the Muslim Penalty? Treatment-Effect Heterogeneity in European Conjoint Behavioral Games},
  author      = {Muno, Tristan and Okisheva, Vera and Kl\"ockner, Raphael},
  year        = {2026},
  institution = {University of Mannheim},
  url         = {https://dertristan.github.io/MBEU25},
  doi         = {<<CONCEPT_DOI>>}
}
```

Replace `<<CONCEPT_DOI>>` with the Zenodo concept DOI once the first release is archived.

## License

This repository is **dual-licensed**:

- **Manuscript text and original figures** — [CC BY 4.0](LICENSE-CC-BY-4.0.md).
- **The project's own analysis code** (notebooks `code/02`–`code/09`, `code/helper_scripts/`) — [MIT](LICENSE).

The following components are **third-party** and are **not** covered by the licenses above:

- `code/multibart/` — **GNU GPL v3.0** (upstream, Jared Murray, see its `DESCRIPTION`).
- `data/` — **not licensed here.** © Hahm, Hilpert & König, redistributed per the upstream repository [LS-Konig/eu25games2019](https://github.com/LS-Konig/eu25games2019).
- `images/` — University of Mannheim branding, All Rights Reserved (see [`images/COPYRIGHTS.md`](images/COPYRIGHTS.md)).
