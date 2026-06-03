# Report: Nested Random Intercepts in `code/multibart/` (Yeager
  et al. BCF)

  ## TL;DR

  **Nested respondent-within-country random intercepts are
  achievable as a MODEST
  code change — not a rewrite.** The C++ MCMC sampler is already
  fully general over
  an arbitrary number of variance components and an arbitrary
  random-effects design
  matrix. Nesting is just a wider design matrix `W` plus a
  block-structured
  component-assignment matrix `Q`. The only "single-level"
  assumptions in the whole
  package live in two small R *convenience constructors* and one
  posterior
  *extractor* — none of them in the sampler. You write one new R
  helper (~15 lines)
  and one generalized extractor; you compile nothing new.

  ---

  ## 1. How the existing code handles random effects

  ### 1.1 The math (what the sampler actually does)

  The random-effects contribution to the linear predictor is a
  classic
  parameter-expanded (PX) varying-coefficients term. In the
  notation of the C++ code
  (`multibart.cpp:304-328`, `525-578`; identical block in
  `bcf_core.cpp:285-305`,
  `525-571`):

  - `random_des` = **W**, an `n × q` design matrix (one column per
  random
    coefficient).
  - `random_var_ix` = **Q**, a `q × K` 0/1 matrix mapping each of
  the `q` random
    coefficients to exactly one of `K` variance components.
  - `random_var` = the `K`-vector of variance-component values
  `σ²_k`.
  - `gamma` = **γ**, the `q`-vector of random coefficients.
  - `eta` = the `K`-vector of PX working parameters.

  The fitted random part is

  ```
  allfit_random = random_des * diagmat(random_var_ix * eta) * gamma
      // multibart.cpp:568
  ```

  i.e. `Wγ̃` where each coefficient's effective scale is `(Qη)_j`.
  The prior on γ is

  ```
  Sigma_inv_random = diagmat(1 / (random_var_ix * random_var));
      // multibart.cpp:312, 564
  ```

  so coefficient `γ_j` has prior variance `(Q·σ²)_j` — **every
  coefficient that loads
  on component `k` shares the same variance `σ²_k`.** The Gibbs
  updates are:

  - **γ** (random coefficients): conjugate MVN draw,
  `rmvnorm_post(m, Phi)`
    (`multibart.cpp:532-540`).
  - **η** (PX scales): conjugate MVN draw (`:546-550`).
  - **σ²_k** (variance components): half-t via inverse-gamma,
  looped over **all `K`
    components** (`:556-562`):

    ```cpp
    arma::vec ssqs   = random_var_ix.t()*(gamma % gamma);   //
  per-component sum of γ²
    arma::rowvec counts = sum(random_var_ix, 0);            //
  per-component # of coefs
    for(size_t ii=0; ii<random_var_ix.n_cols; ++ii) {       // <--
  loops over K, not hard-coded
      random_var(ii) = 1.0/gen.gamma(0.5*(random_var_df +
  counts(ii)), 1.0)
                       *
  2.0/(random_var_df/randeff_scales(ii)*randeff_scales(ii) +
  ssqs(ii));
    }
    ```

    The reported SDs are `sqrt(eta² · random_var)` (`:615`).

  **Crucial fact:** nothing in this loop, in the prior, in the γ/η
  draws, or in the
  fit assembles assumes one level. `random_dim = random_des.n_cols`
  and the component
  count `random_var_ix.n_cols` are both read off the inputs at
  runtime
  (`multibart.cpp:304`, `:315`). The sampler does linear algebra of
  whatever
  dimension you hand it.

  ### 1.2 Where single-level structure IS baked in (the R layer)

  The "one grouping factor" assumption exists only in the R helper
  constructors in
  `code/multibart/R/groups.R`:

  - `random_intercepts(groups)` (`groups.R:78-95`) — builds dummies
  for **one**
    factor, sets `Q = matrix(1, q, 1)` (a single variance
  component). This is the
    single-site / single-level intercept model.
  - `random_intercepts_slopes(groups, treatment)`
  (`groups.R:45-67`) — builds
    `W = [dummies | dummies*trt]` and a `q × 2` `Q` splitting
  intercepts vs. slopes
    into two components. (This is what Yeager et al. use for
  varying site
    intercepts + varying treatment effects.)
  - `get_random_intercepts_slopes_posteriors()`
  (`groups.R:106-125`) — extractor
    **hard-coded to exactly 2 component blocks** (`1:ngroups` and
    `(ngroups+1):(2*ngroups)`).

  The fitting wrappers `bcf_binary()` (`bcf_binary.R:144-147,
  332-336`) and
  `bcf_core()` (`bcf_core.R:134-137, 297-300`) simply pass
  `randeff_design`,
  `randeff_variance_component_design`, `randeff_scales`,
  `randeff_df` straight
  through to the compiled sampler. They make **no** assumption
  about the number of
  levels. Default `randeff_*` args (`matrix(1)`) disable REs,
  detected by
  `random_var_ix.n_elem == 1` → `randeff = false`
  (`multibart.cpp:46-48`).

  ---

  ## 2. Why nested intercepts fit this framework directly

  Respondent IDs are globally unique (each respondent belongs to
  exactly one
  country), so an **additive** two-level nested random-intercept
  model

  ```
  y_ijk = mu(x) + tau(x)·z + b_country[c(i)] + b_resp[r(i)] + e_i
  b_country[c] ~ N(0, σ²_country),   b_resp[r] ~ N(0, σ²_resp)
  ```

  is represented exactly by stacking two blocks of intercept
  dummies and giving each
  block its own variance component:

  ```
  W = [ D_country | D_resp ]                      # n × (C + R)
  Q = [ 1_C    0_C ]                               # (C+R) × 2
      [ 0_R    1_R ]                               # country rows
  -> comp 1, resp rows -> comp 2
  γ = [ b_country ; b_resp ]
  ```

  Then `Wγ = b_country[c(i)] + b_resp[r(i)]`, each block shrinks to
  its own variance,
  and the existing σ²_k loop estimates `σ²_country` and `σ²_resp`
  separately. **No
  special "nesting" machinery is required** — nesting vs. crossing
  is entirely
  encoded by how the dummies are built (unique respondent dummies ⇒
  nested). This is
  the standard sparse-dummy representation of nested REs used by
  `lme4`/`mgcv`.

  This generalizes the existing `random_intercepts_slopes` pattern:
  that helper
  already proves the sampler handles a `q × 2` `Q` with two
  independent variance
  components. We are reusing the identical mechanism, just with the
  two blocks being
  *two grouping factors* rather than *intercept + slope*.

  ---

  ## 3. Classification: MODEST code change (R-only, no
  recompilation)

  | Aspect | Verdict |
  |---|---|
  | C++ sampler (`multibart.cpp` / `bcf_core.cpp`) | **No change.**
  Already general over `K` components and arbitrary `W`. |
  | Fitting wrappers (`bcf_binary` / `bcf_core`) | **No change**
  (pass-through). One caveat on `randeff_scales`, below. |
  | R helper to build `W`, `Q` | **New function** (~15 lines),
  mirrors `random_intercepts_slopes`. |
  | Posterior extractor | **New / generalized function**; existing
  one is hard-coded to 2 blocks. |
  | Recompilation | **None needed.** |

  So: config/data + a small amount of new R glue. Not a rewrite.

  ---

  ## 4. Specific functions / files / lines to touch

  1. **New constructor** — add
  `nested_random_intercepts(level1_groups,
     level2_groups, ...)` to `code/multibart/R/groups.R` (alongside
     `random_intercepts` at `:78` and `random_intercepts_slopes` at
  `:45`). It should:
     - build dummies for each level via `get_dummies()`
  (`groups.R:23`);
     - `W <- cbind(D_country, D_resp)`;
     - `Q <- rbind(cbind(1,0)[rep,], cbind(0,1)[rep,])` block
  structure
       (`C` rows on col 1, `R` rows on col 2);
     - return `randeff_design`,
  `randeff_variance_component_design`, plus per-level
       `intercept_ix` for labeling.

  2. **New extractor** — generalize
  `get_random_intercepts_slopes_posteriors()`
     (`groups.R:106-125`) to slice `bcf_fit$random_effects` into
  the country block
     `1:C` and the respondent block `(C+1):(C+R)`, and to read both
  SDs from
     `random_effects_sd[,1]` / `[,2]`. The current version's
  hard-coded
     `1:ngroups` / `(ngroups+1):(2*ngroups)` split (`:109,:114`)
  will mislabel a
     nested fit, so do not reuse it verbatim.

  3. **`randeff_scales` must become length-`K`** — at the call site
  you must pass
     `randeff_scales = c(s_country, s_resp)`. Reason:
  `multibart.cpp:561` (and
     `bcf_core.cpp:564`) index `randeff_scales(ii)` for `ii` up to
  `K-1`. The
     wrapper default is a scalar `1` (`bcf_binary.R:146`,
  normalized at `:336`),
     which would be out-of-bounds for `K=2` in Armadillo. This is a
  **data/argument
     change**, not a code change — but it is mandatory and easy to
  miss.

  4. **Choose the fitting path** — `bcf_binary()` (binary outcome →
  uses
     `multibart.cpp`) vs. `bcf_core()` (continuous → uses
  `bcf_core.cpp`). Both
     carry the identical RE block, so the helper works for either.
  Pick based on
     whether the Dictator/Trust outcomes are coded binary or
  continuous.

  ---

  ## 5. Structural blockers, caveats, identifiability

  - **No hard-coded single-level assumption in the sampler.**
  Confirmed in both
    `multibart.cpp` and `bcf_core.cpp`: variance-component count
  and design width are
    runtime-derived (`:304/:315` and `:285/:296` respectively).
  This is the key
    result — the perceived blocker does not exist at the C++ level.

  - **REs are on μ(x) only by construction here** — exactly what
  the analysis plan
    wants (CLAUDE.md §"Role of Random Intercepts": REs on μ, none
  on τ). The random
    part is added to the global `allfit`, independent of the τ
  forest. Nothing needs
    to be done to *prevent* REs on τ; the additive-intercept
  construction already
    excludes them.

  - **Identifiability of the global intercept.**
  `bcf_binary`/`bcf_core` center `y`
    (`yscale = scale(y)`), and the μ forest is `vanilla=TRUE`
  (carries its own
    intercept-like behavior). With two full sets of intercept
  dummies plus a centered
    outcome, the **overall** level is only weakly identified (the
  classic
    "sum-to-zero vs. free intercept" redundancy in dummy-coded
  REs). In practice the
    half-t shrinkage priors (`σ²_country`, `σ²_resp`) regularize
  this, and PX
    improves mixing — this is exactly how the existing single-level
  fits already
    operate — but expect the country-level intercepts and the
  global mean to trade
    off. Recommend monitoring convergence of the variance
  components and the global
    fit, and consider whether to drop one redundant column or rely
  on shrinkage
    (shrinkage is the lighter-touch, on-brand choice for this
  codebase).

  - **Two latent bugs in `groups.R` worth knowing before you copy
  patterns:**
    - `random_intercepts()` line 80 references `soriginal_colnames`
  (typo for
      `original_colnames`) — that function would error if called.
  Do **not** copy
      that line into the new helper.
    - `random_intercepts_slopes()` line 51 uses a bare `trt` but
  the argument is
      named `treatment` (and line 54 `Q[1:ncol(random_des)/2,1]`
  relies on operator
      precedence). Mirror the *intent*, not the literal code.

  - **Variance-scale prior precedence quirk (cosmetic,
  pre-existing):** at
    `multibart.cpp:561` the expression
  `random_var_df/randeff_scales(ii)*randeff_scales(ii)`
    evaluates left-to-right to `random_var_df` — the scale
  algebraically cancels, so
    `randeff_scales` currently has no effect on the prior *beyond
  requiring a
    correctly-sized vector*. Not a blocker for nesting; just don't
  expect tuning
    `randeff_scales` to change the half-t scale until that line is
  fixed.

  - **Cost/scale.** `W` is `n × (C+R)` ≈ `112,500 × (25 + 37,500)`.
  It is built dense
    (`random_des.t()*random_des` at `:311`). With ~37.5k respondent
  dummies this
    `WtW` is ~37.5k², and the conjugate γ draw solves a system of
  that order each
    iteration — **this is the real practical risk, not
  correctness.** A dense
    implementation may be memory/time-prohibitive. Mitigations to
  evaluate:
    sparse-matrix substitution for `W`/`WtW` (an actual
  C++/Armadillo change, would
    upgrade this to a non-trivial change), subsetting (smoke-test
  on one country as
    the Tue plan already suggests), or falling back to the plan's
  documented
    contingency (country REs only + cluster-bootstrap for
  respondent dependence).

  ---

  ## 6. Recommendation

  The statistical/structural path is clear and modest, and I'd flag
  a **follow-up
  implementation prompt** scoped to:

  1. Write `nested_random_intercepts()` + generalized posterior
  extractor in
     `groups.R`, export both in `NAMESPACE`.
  2. Wire `randeff_scales = c(.,.)` at the fit call.
  3. **Benchmark the dense `WtW` cost on a one- or few-country
  subset first** — this,
     not the math, decides whether full nested REs are viable in
  the one-week window
     or whether the country-REs-only fallback (CLAUDE.md Open
  Question #1) is the
     pragmatic call.

  The correctness story is solid; treat the implementation prompt's
  success
  criterion as *"does the 37.5k-column dense sampler run in
  acceptable time/memory,"*
  because the sampler-generality blocker that motivated the
  question turns out not to
  exist.