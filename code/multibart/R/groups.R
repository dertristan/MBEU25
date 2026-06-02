
#' Title
#'
#' @param dummies 
#'
#' @return
#' @export
#'
#' @examples
get_group_indices = function(dummies) {
  apply(dummies, 2, function(g) Position(function(x) abs(x - 0)>1e-6, g))
}

#' Construct (redundant) dummies from a factor
#'
#' @param grouping_var A factor defining the groups
#' @param original_colnames If true, use the original factor levels as column names. Otherwise "Group" will be pre-pended to the column names of the dummy matrix
#'
#' @return A matrix of dummy variables
#' @export
#'
#' @examples
get_dummies = function(grouping_var, original_colnames = TRUE) {
  gpind = fastDummies::dummy_cols(data.frame(group = factor(grouping_var)),
                                  remove_selected_columns = TRUE)
  gpind = as.matrix(gpind)
  if(original_colnames==TRUE) {
    colnames(gpind) = make.names(substring(colnames(gpind), first=7))
  }
  
  return(gpind)
}


#' Construct metadata for BCF with random intercepts and slopes (on the treatment variable)
#'
#' @param groups A factor variable defining the groups
#' @param treatment Treatment assignments/levels
#' @param original_colnames If true, use the original factor levels as column names for the matrix of dummies for the groups. Otherwise "Group" will be pre-pended to the column names of the dummy matrix
#'
#' @return
#' @export
#'
#' @examples
random_intercepts_slopes = function(groups, treatment, original_colnames=TRUE) {
  #dummies = makeModelMatrixFromDataFrame(as.data.frame(factor(groups)))
  #dummies = makeModelMatrixFromDataFrame(as.data.frame(factor(groups)))
  
  dummies = get_dummies(groups, original_colnames=original_colnames)
  
  random_des = cbind(dummies, dummies*trt) #cbind(Xschool, Xschool*dat$treatment)
  Q = matrix(0, nrow=ncol(random_des), ncol=2)
  Q[1:ncol(random_des)/2,1] = 1
  Q[(1+ncol(random_des)/2):nrow(Q),2] = 1
  
  intercept_ix = get_group_indices(dummies)
  trt_ix = get_group_indices(dummies*trt)
  
  return(list(randeff_design = random_des,
              randeff_variance_component_design = as.matrix(Q),
              group_dummies = dummies,
              intercept_ix = intercept_ix,
              treatment_ix = trt_ix
              
  ))
  
}

#' Construct metadata for BCF with random intercepts 
#'
#' @param groups A factor variable defining the groups
#' @param original_colnames If true, use the original factor levels as column names for the matrix of dummies for the groups. Otherwise "Group" will be pre-pended to the column names of the dummy matrix
#'
#' @return
#' @export
#'
#' @examples
random_intercepts = function(groups, original_colnames=TRUE) {
  
  dummies = get_dummies(groups, original_colnames=soriginal_colnames)
  
  random_des = cbind(dummies)#cbind(Xschool, Xschool*dat$treatment)
  Q = matrix(1, nrow=ncol(random_des), ncol=1)
  
  dummies = get_dummies(groups, original_colnames)
  
  intercept_ix = get_group_indices(dummies)
  
  return(list(randeff_design = random_des,
              randeff_variance_component_design = as.matrix(Q),
              group_dummies = dummies,
              intercept_ix = intercept_ix
  ))
  
}

#' Construct metadata for BCF with nested random intercepts (two grouping factors)
#'
#' Builds the random-effects design for an additive two-level nested
#' random-intercept model, e.g. respondents nested within countries. Each
#' grouping factor contributes its own block of intercept dummies and its own
#' variance component, so the two levels shrink independently. Nesting (as
#' opposed to crossing) is encoded entirely by the dummies: because level-2
#' identifiers (e.g. respondent ids) are globally unique, each level-2 dummy
#' belongs to exactly one level-1 group. This reuses the same q-by-2 variance
#' component machinery as \code{random_intercepts_slopes}, with the two blocks
#' being two grouping factors rather than intercept and slope.
#'
#' @param level1_groups A factor variable defining the outer groups (e.g. country)
#' @param level2_groups A factor variable defining the inner groups (e.g. respondent)
#' @param original_colnames If true, use the original factor levels as column names for the dummy matrices. Otherwise "Group" will be pre-pended to the column names
#'
#' @return
#' @export
#'
#' @examples
nested_random_intercepts = function(level1_groups, level2_groups, original_colnames=TRUE) {

  level1_dummies = get_dummies(level1_groups, original_colnames=original_colnames)
  level2_dummies = get_dummies(level2_groups, original_colnames=original_colnames)

  n_level1 = ncol(level1_dummies)
  n_level2 = ncol(level2_dummies)

  random_des = cbind(level1_dummies, level2_dummies)

  Q = matrix(0, nrow=ncol(random_des), ncol=2)
  Q[1:n_level1, 1] = 1
  Q[(n_level1+1):(n_level1+n_level2), 2] = 1

  level1_ix = get_group_indices(level1_dummies)
  level2_ix = get_group_indices(level2_dummies)

  return(list(randeff_design = random_des,
              randeff_variance_component_design = as.matrix(Q),
              level1_dummies = level1_dummies,
              level2_dummies = level2_dummies,
              n_level1 = n_level1,
              n_level2 = n_level2,
              level1_ix = level1_ix,
              level2_ix = level2_ix
  ))

}

#' Get posteriors for random effects/parameters in a varying intercepts/slopes model
#'
#' @param bcf_fit 
#' @param randeff_setup 
#'
#' @return
#' @export
#'
#' @examples
get_random_intercepts_slopes_posteriors = function(bcf_fit, randeff_setup) {
  ngroups = length(randeff_setup$intercept_ix)
  
  intercept_posterior = bcf_fit$random_effects[,1:ngroups]
  #cat(dim(intercept_posterior))
  colnames(intercept_posterior) = colnames(randeff_setup$group_dummies)
  
  
  treatment_posterior = bcf_fit$random_effects[,(ngroups+1):(2*ngroups)]
  #cat(dim(treatment_posterior))
  colnames(treatment_posterior) = colnames(randeff_setup$group_dummies)
  
  intercept_sd = bcf_fit$random_effects_sd[,1]
  treatment_sd = bcf_fit$random_effects_sd[,2]
  
  return(list(intercept_posterior=intercept_posterior,
              treatment_posterior=treatment_posterior,
              intercept_sd=intercept_sd,
              treatment_sd=treatment_sd))
}

#' Get posteriors for the random intercepts in a nested two-level model
#'
#' Companion extractor for \code{nested_random_intercepts}. The fitted random
#' coefficients in \code{bcf_fit$random_effects} are ordered as the columns of
#' the design W = [D_level1 | D_level2], so the first \code{n_level1} columns are
#' the level-1 (e.g. country) intercepts and the next \code{n_level2} columns are
#' the level-2 (e.g. respondent) intercepts. The two variance-component SDs are
#' returned in the first two columns of \code{random_effects_sd}. This must not
#' reuse \code{get_random_intercepts_slopes_posteriors}, whose hard-coded
#' 1:ngroups / (ngroups+1):(2*ngroups) split assumes the two blocks are equal in
#' width and would mislabel a nested fit.
#'
#' @param bcf_fit A fitted bcf object carrying random_effects and random_effects_sd
#' @param randeff_setup The list returned by \code{nested_random_intercepts}
#'
#' @return
#' @export
#'
#' @examples
get_nested_random_intercepts_posteriors = function(bcf_fit, randeff_setup) {
  n_level1 = randeff_setup$n_level1
  n_level2 = randeff_setup$n_level2

  level1_posterior = bcf_fit$random_effects[,1:n_level1]
  colnames(level1_posterior) = colnames(randeff_setup$level1_dummies)

  level2_posterior = bcf_fit$random_effects[,(n_level1+1):(n_level1+n_level2)]
  colnames(level2_posterior) = colnames(randeff_setup$level2_dummies)

  level1_sd = bcf_fit$random_effects_sd[,1]
  level2_sd = bcf_fit$random_effects_sd[,2]

  return(list(level1_posterior=level1_posterior,
              level2_posterior=level2_posterior,
              level1_sd=level1_sd,
              level2_sd=level2_sd))
}
