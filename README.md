# Penalized for Faith: Muslim Bias in Economic Behavioral Games Across 25 EU Countries

**Course:** Causal Inference — Term Paper  
**Status:** Work in progress

---

## Research Summary

This project reanalyzes data from [Hahm, Hilpert & König (2024)](#data-source), a large-scale conjoint survey experiment fielded across all 25 EU member states in 2019. In the original study, respondents participated in economic behavioral games — a **dictator/solidarity game** and a **trust game** — in which they allocated tokens to a fictitious co-player. Co-player profiles were constructed with randomized attributes (including religion, nationality, age, and others), allowing causal identification of attribute-specific biases via the conjoint design.

We exploit the religion attribute to study **Muslim bias**: the causal effect of a co-player being presented as Muslim (vs. all other religions pooled) on the respondent's token allocation. Rather than a comparative cross-national study, the focus is on **treatment effect heterogeneity** — what drives variation in the well-documented Muslim penalty. Two families of moderators are examined:

1. **Profile-level heterogeneity** — which *other conjoint attributes* shown in the same co-player profile (e.g., occupation, nationality, partisan affiliation, EU stance) amplify or attenuate the Muslim effect.
2. **Respondent-level heterogeneity** — which *respondent characteristics* (e.g., political attitudes, religiosity, contact with Muslims, socioeconomic status) are associated with stronger or weaker Muslim bias.

Country-level structure is treated as a nuisance to account for, not interpreted substantively. The analysis is exploratory and descriptive throughout.

### Empirical Strategy

Heterogeneity is estimated with a dual strategy targeting the conditional average treatment effect (CATE) of the Muslim attribute. The primary method is **hierarchical Bayesian Causal Forests** with nested random intercepts (respondent within country) to account for the clustered data structure. As a frequentist robustness check, we additionally fit **causal random forests** (`grf`) with respondent-level clusters and country fixed effects. Separate models are estimated for each behavioral game (dictator and trust). See `index.qmd` for more details.

### Data Source

> Hahm, H., Hilpert, D., & König, T. (2024). Divided we unite: The nature of partyism and the role of coalition partnership in Europe. *American Political Science Review*, 118(1), 69–87. https://doi.org/10.1017/S0003055423000266

---

## Repository Structure

```
MBEU25/
│
├── index.qmd                    # Main manuscript (paper)
├── presentation.qmd             # Revealjs presentation slides
├── _quarto.yml                  # Quarto project config (authors, formats, bibliography)
├── references.bib               # BibTeX bibliography
├── theme.scss                   # Custom SCSS theme for the presentation
├── robots.txt                   # Prevents search engine indexing of HTML output
├── CLAUDE.md                    # Guidance for Claude Code AI assistant
│
├── code/
│   ├── 00_template.qmd                   # Template for new analysis notebooks
│   ├── 01_exploration4presentation.qmd  # Exploratory analysis for the slides
│   ├── 02_data_prep.qmd                  # Data cleaning / prep for heterogeneity analysis
│   ├── 03_multibart_nested_ri_test.qmd  # Hierarchical (nested RI) BCF mechanism test
│   ├── 04_grf_nested_test.qmd           # grf causal-forest nested-structure test
│   ├── multibart/                        # Local R package: hierarchical BCF with nested random intercepts
│   └── helper_scripts/
│       ├── copy_figures.R                # Post-render: copies figures into _manuscript/
│       └── glftrackeR.R                  # Helper utilities
│
├── data/
│   ├── 01_raw/                  # Raw, unmodified source data (never overwrite)
│   ├── 02_processed/            # Cleaned and analysis-ready datasets
│   └── 03_final/               # Final analysis datasets
│
├── images/
│   ├── uma_palace.png           # University of Mannheim branding (slides)
│   └── uma_ss.png               # University of Mannheim logo (slides)
│
└── literature/                  # PDF papers — gitignored, not tracked in Git
```

> **Generated folders** (`_freeze/`, `_manuscript/`, `.quarto/`, `site_libs/`) are created by Quarto at render time and are gitignored.

### The `multibart` package

The local `code/multibart/` package implements **hierarchical Bayesian Causal Forests with nested random intercepts** (respondent within country), the primary method for this project. The code is adapted from the BCF implementation released with the following study:

> Yeager, D. S., Bryan, C. J., Gross, J. J., Murray, J. S., Krettek Cobb, D., HF Santos, P., Gravelding, H., Johnson, M., & Jamieson, J. P. (2022). A synergistic mindsets intervention protects adolescents from stress. *Nature*, 607(7919), 512–520. https://doi.org/10.1038/s41586-022-04907-7

**Adaptation for two-level nesting.** The original implementation supports single-level (site) random effects. The extension to two-level nesting (respondent within country) was made **entirely in R** — a `nested_random_intercepts()` constructor and a matching posterior extractor added to `R/groups.R` and exported in `NAMESPACE`. **No C++/`src` source was modified** for the nesting logic (the only commit touching `src/` is an unrelated `PI` declaration bugfix). See the package commit history for details.

---

## Getting Started

### Prerequisites

- [Quarto](https://quarto.org/docs/get-started/) (≥ 1.4)
- R with the following packages: `tidyverse`, `here`, `ggpubr`, `sessioninfo`

### Render the project

```bash
# Full project (manuscript + all notebooks)
quarto render

# Main manuscript only
quarto render index.qmd

# Presentation only
quarto render presentation.qmd

# Single analysis notebook
quarto render code/01_test.qmd

# Live preview with hot reload
quarto preview
```

Output formats are **HTML**, **PDF**, and **DOCX** for the manuscript; **Revealjs HTML** (self-contained) for the presentation.

### Adding a new analysis notebook

1. Copy `code/00_template.qmd` → `code/NN_name.qmd`
2. Register it in `_quarto.yml`:
   ```yaml
   manuscript:
     notebooks:
       - notebook: code/NN_name.qmd
         title: "Descriptive title"
   ```
3. Embed outputs in `index.qmd`:
   ```
   {{< embed code/NN_name.qmd#fig-label >}}
   ```

Quarto caches computed results in `_freeze/` (`freeze: auto`). A notebook only re-executes when its source changes. To force re-execution, delete the notebook's subfolder under `_freeze/code/`.

---

## Documentation

| Topic | Link |
|---|---|
| Quarto manuscripts | https://quarto.org/docs/manuscripts/ |
| Quarto output formats | https://quarto.org/docs/output-formats/all-formats.html |
| Quarto Revealjs presentations | https://quarto.org/docs/presentations/revealjs/ |
| Quarto execution & freeze | https://quarto.org/docs/projects/code-execution.html |
| Quarto citations & bibliography | https://quarto.org/docs/authoring/citations.html |
| Quarto authors & affiliations | https://quarto.org/docs/journals/authors.html |
| APSR citation style | https://www.apsanet.org/PUBLICATIONS/Journals/APSR |
| `tidyverse` | https://www.tidyverse.org/ |
| `here` (relative paths in R) | https://here.r-lib.org/ |
