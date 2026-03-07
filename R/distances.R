#' Wasserstein-2 (Bures) Distance Between Multivariate Normals
#'
#' Computes the Wasserstein-2 distance (also known as Bures or Frechet distance)
#' between two multivariate normal distributions. This metric has a closed-form
#' solution for Gaussian distributions and is based on optimal transport theory.
#' 
#' **Note**: For high-dimensional problems or when computational speed is critical,
#' consider using the faster \code{\link{lrt_trace_distance}} as an approximation.
#'
#' @param mu1 Mean vector of the first distribution (numeric vector)
#' @param Sigma1 Covariance matrix of the first distribution (positive definite matrix)
#' @param mu2 Mean vector of the second distribution (numeric vector)
#' @param Sigma2 Covariance matrix of the second distribution (positive definite matrix)
#'
#' @return The Wasserstein-2 distance (non-negative scalar)
#'
#' @details
#' The Wasserstein-2 distance provides the most geometrically meaningful measure
#' but requires expensive matrix square root computations via eigendecomposition.
#' For large matrices (p > 50) or applications requiring many distance computations,
#' the \code{\link{lrt_trace_distance}} provides a much faster alternative.
#'
#' @references
#' Takatsu, A. (2011). Wasserstein geometry of Gaussian measures.
#' Osaka Journal of Mathematics, 48(4), 1005-1026.
#'
#' @seealso \code{\link{lrt_trace_distance}} for a computationally efficient alternative
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' 
#' # Precise but slower
#' wasserstein2_distance(mu1, Sigma1, mu2, Sigma2)
#' 
#' # Fast approximation
#' lrt_trace_distance(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
wasserstein2_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  # Check for identical distributions (avoid numerical precision issues)
  if (isTRUE(all.equal(mu1, mu2)) && isTRUE(all.equal(Sigma1, Sigma2))) {
    return(0)
  }

  # Mean part
  mu_dist_sq <- sum((mu1 - mu2)^2)
  
  # Covariance part (Bures metric)
  Sigma1_sqrt <- expm::sqrtm(Sigma1)
  M <- Sigma1_sqrt %*% Sigma2 %*% Sigma1_sqrt
  M_sqrt <- expm::sqrtm(M)
  
  Sigma_dist_sq <- sum(diag(Sigma1)) + sum(diag(Sigma2)) - 2 * sum(diag(M_sqrt))
  
  sqrt(mu_dist_sq + Sigma_dist_sq)
}

#' Hellinger Distance Between Multivariate Normals
#'
#' Computes the Hellinger distance between two multivariate normal distributions.
#' This distance is bounded between 0 and 1, making it interpretable as a similarity measure.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The Hellinger distance (scalar in [0, 1])
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' hellinger_distance(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
hellinger_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  Sigma_sum <- (Sigma1 + Sigma2) / 2
  det_term <- sqrt(det(Sigma1) * det(Sigma2)) / det(Sigma_sum)
  
  exp_term <- exp(-0.125 * t(mu1 - mu2) %*% solve(Sigma_sum) %*% (mu1 - mu2))
  
  sqrt(1 - det_term^0.25 * as.numeric(exp_term))
}

#' Bhattacharyya Distance Between Multivariate Normals
#'
#' Computes the Bhattacharyya distance between two multivariate normal distributions.
#' This distance is related to the Bhattacharyya coefficient and Bayes classification error.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The Bhattacharyya distance (non-negative scalar)
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' bhattacharyya_distance(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
bhattacharyya_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  Sigma_avg <- (Sigma1 + Sigma2) / 2
  
  as.numeric(0.125 * t(mu1 - mu2) %*% solve(Sigma_avg) %*% (mu1 - mu2) +
    0.5 * log(det(Sigma_avg) / sqrt(det(Sigma1) * det(Sigma2))))
}

#' KL Divergence Between Multivariate Normals
#'
#' Computes the Kullback-Leibler divergence from distribution 1 to distribution 2.
#' Note: KL divergence is asymmetric (not a true distance metric).
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The KL divergence (non-negative scalar)
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' kl_divergence(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
kl_divergence <- function(mu1, Sigma1, mu2, Sigma2) {
  d <- length(mu1)
  Sigma2_inv <- solve(Sigma2)
  
  as.numeric(0.5 * (sum(diag(Sigma2_inv %*% Sigma1)) + 
         t(mu2 - mu1) %*% Sigma2_inv %*% (mu2 - mu1) - 
         d + log(det(Sigma2) / det(Sigma1))))
}

#' Symmetrized KL Divergence
#'
#' Computes the symmetrized Kullback-Leibler divergence, which is the average
#' of KL(P||Q) and KL(Q||P). This provides a symmetric measure.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The symmetrized KL divergence (non-negative scalar)
#'
#' @export
symmetrized_kl <- function(mu1, Sigma1, mu2, Sigma2) {
  0.5 * (kl_divergence(mu1, Sigma1, mu2, Sigma2) + 
         kl_divergence(mu2, Sigma2, mu1, Sigma1))
}

#' Affine-Invariant Distance
#'
#' Computes the affine-invariant Riemannian distance between two multivariate
#' normal distributions. Uses the log-Euclidean metric on covariance matrices.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The affine-invariant distance (non-negative scalar)
#'
#' @references
#' Pennec, X., Fillard, P., & Ayache, N. (2006). A Riemannian framework
#' for tensor computing. International Journal of Computer Vision, 66(1), 41-66.
#'
#' @export
affine_invariant_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  # Mean part
  Sigma1_inv <- solve(Sigma1)
  mu_dist_sq <- as.numeric(t(mu1 - mu2) %*% Sigma1_inv %*% (mu1 - mu2))
  
  # Covariance part (log-Euclidean metric)
  Sigma1_inv_sqrt <- expm::sqrtm(Sigma1_inv)
  M <- Sigma1_inv_sqrt %*% Sigma2 %*% Sigma1_inv_sqrt
  Sigma_dist_sq <- sum(expm::logm(M)^2)
  
  sqrt(mu_dist_sq + Sigma_dist_sq)
}

#' Likelihood Ratio Test (LRT) Distance
#'
#' Computes a distance inspired by the likelihood ratio test statistic for
#' multivariate normal distributions. For univariate normals, this distance
#' is equivalent to the Fisher-Rao distance when applied to maximum likelihood
#' estimates from samples of equal size.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The LRT distance (non-negative scalar)
#'
#' @details
#' The LRT distance is defined as:
#' \deqn{D_{LRT} = \frac{\sqrt{2}}{2} \text{acosh}(2 \cdot LRTMV - 1)}
#' where
#' \deqn{LRTMV = \frac{|\frac{1}{2}(\Sigma_1 + \Sigma_2) + \frac{1}{2}(\mu_1-\mu_2)(\mu_1-\mu_2)^T|^2}{|\Sigma_1||\Sigma_2|}}
#'
#' For univariate distributions with sample size n, the relationship to the
#' Fisher-Rao distance is:
#' \deqn{D_{Fisher-Rao} = \frac{\sqrt{2}}{2} \text{acosh}(2 \cdot LRT^{-2/n} - 1)}
#'
#' @references
#' Eriksen, P. S. (1987). Geodesics connected with the Fisher metric on
#' the multivariate normal manifold. Proceedings of the GST Workshop.
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' lrt_distance(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
lrt_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  # Ensure matrices and vectors are properly formatted
  mu1 <- as.numeric(mu1)
  mu2 <- as.numeric(mu2)
  Sigma1 <- as.matrix(Sigma1)
  Sigma2 <- as.matrix(Sigma2)
  
  p <- length(mu1)
  
  # Handle univariate case (p=1)
  if (p == 1) {
    # For scalars, determinant = the value itself
    det_S1 <- as.numeric(Sigma1)
    det_S2 <- as.numeric(Sigma2)
    
    # Compute LRTMV for univariate case
    mu_diff <- mu1 - mu2
    Sigma_avg <- 0.5 * (det_S1 + det_S2)
    numerator <- Sigma_avg + 0.25 * mu_diff^2
    
    LRTMV <- (numerator^2) / (det_S1 * det_S2)
    
    arg <- 2 * LRTMV - 1
    if (!is.finite(arg) || arg < 1) arg <- 1
    
    distance <- (sqrt(2) / 2) * acosh(arg)
    return(as.numeric(distance))
  }
  
  # Multivariate case (p > 1)
  # Compute the mean difference outer product
  mu_diff <- as.matrix(mu1 - mu2)
  mu_outer <- mu_diff %*% t(mu_diff)
  
  # Compute LRTMV statistic using determinants
  Sigma_avg <- 0.5 * (Sigma1 + Sigma2)
  numerator_matrix <- as.matrix(Sigma_avg + 0.25 * mu_outer)
  
  # Ensure symmetry
  numerator_matrix <- 0.5 * (numerator_matrix + t(numerator_matrix))
  
  # Compute determinants
  det_num <- det(numerator_matrix)
  det_S1 <- det(Sigma1)
  det_S2 <- det(Sigma2)
  
  # LRTMV = |numerator|^2 / (|Sigma1||Sigma2|)
  LRTMV <- (det_num^2) / (det_S1 * det_S2)
  
  # Compute acosh argument and clamp to domain [1, inf) to avoid numerical issues
  arg <- 2 * LRTMV - 1
  if (!is.finite(arg) || arg < 1) arg <- 1  # clamp to avoid acosh domain error
  
  distance <- (sqrt(2) / 2) * acosh(arg)
  
  as.numeric(distance)
}

#' Likelihood Ratio Test Distance (Trace-based) - Fast Alternative to Wasserstein-2
#'
#' Computes a computationally efficient trace-based variant of the LRT distance.
#' This provides a fast approximation to the Wasserstein-2 distance without requiring 
#' expensive matrix square root operations, making it suitable for high-dimensional 
#' problems and large-scale applications.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return The LRT trace-based distance (non-negative scalar)
#'
#' @details
#' The LRT trace distance is defined as:
#' \deqn{D_{LRT,tr} = \frac{\sqrt{2}}{2} \text{acosh}(2 \cdot LRTMV_{tr} - 1)}
#' where
#' \deqn{LRTMV_{tr} = \frac{((tr(N)/p)^p)^2}{(tr(\Sigma_1)/p)^p \cdot (tr(\Sigma_2)/p)^p}}
#' 
#' with N the numerator matrix and p the dimension.
#'
#' **Performance Advantage**: Unlike the Wasserstein-2 distance which requires 
#' computationally expensive matrix square root operations via eigendecomposition,
#' the LRT trace distance uses only basic matrix operations (trace, determinant).
#' This makes it orders of magnitude faster for large matrices while providing
#' a reasonable approximation to the Wasserstein-2 distance.
#'
#' **When to Use**: 
#' - High-dimensional problems (p > 50)  
#' - Large-scale applications requiring many distance computations
#' - Real-time applications where speed is critical
#' - When approximate distance is sufficient for comparison purposes
#'
#' @note For more precise distance measurement when computational cost is not 
#' a constraint, consider using \code{\link{wasserstein2_distance}}.
#'
#' @examples
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#' 
#' # Fast approximation
#' lrt_trace_distance(mu1, Sigma1, mu2, Sigma2)
#' 
#' # Compare with Wasserstein-2 (slower but more precise)
#' wasserstein2_distance(mu1, Sigma1, mu2, Sigma2)
#'
#' @export
lrt_trace_distance <- function(mu1, Sigma1, mu2, Sigma2) {
  # Ensure matrices and vectors are properly formatted
  mu1 <- as.numeric(mu1)
  mu2 <- as.numeric(mu2)
  Sigma1 <- as.matrix(Sigma1)
  Sigma2 <- as.matrix(Sigma2)
  
  p <- length(mu1)
  
  # Handle univariate case (p=1)
  if (p == 1) {
    # For p=1, (tr(A)/1)^1 = tr(A) = A itself
    S1_scalar <- as.numeric(Sigma1)
    S2_scalar <- as.numeric(Sigma2)
    
    # Same as determinant for univariate
    mu_diff <- mu1 - mu2
    Sigma_avg <- 0.5 * (S1_scalar + S2_scalar)
    numerator <- Sigma_avg + 0.25 * mu_diff^2
    
    LRTMV_tr <- (numerator^2) / (S1_scalar * S2_scalar)
    
    arg <- 2 * LRTMV_tr - 1
    if (!is.finite(arg) || arg < 1) arg <- 1
    
    distance <- (sqrt(2) / 2) * acosh(arg)
    return(as.numeric(distance))
  }
  
  # Multivariate case (p > 1)
  # Compute the mean difference outer product
  mu_diff <- as.matrix(mu1 - mu2)
  mu_outer <- mu_diff %*% t(mu_diff)
  
  # Compute numerator matrix
  Sigma_avg <- 0.5 * (Sigma1 + Sigma2)
  numerator_matrix <- as.matrix(Sigma_avg + 0.25 * mu_outer)
  
  # Ensure symmetry
  numerator_matrix <- 0.5 * (numerator_matrix + t(numerator_matrix))
  
  # Compute trace-based pseudodeterminants: (tr(A)/p)^p
  tr_num <- sum(diag(numerator_matrix))
  tr_S1 <- sum(diag(Sigma1))
  tr_S2 <- sum(diag(Sigma2))
  
  # LRTMV_tr = ((tr_num/p)^p)^2 / ((tr_S1/p)^p * (tr_S2/p)^p)
  pseudodet_num <- (tr_num / p)^p
  pseudodet_S1 <- (tr_S1 / p)^p
  pseudodet_S2 <- (tr_S2 / p)^p
  
  LRTMV_tr <- (pseudodet_num^2) / (pseudodet_S1 * pseudodet_S2)
  
  # Compute acosh argument and clamp to domain [1, inf)
  arg <- 2 * LRTMV_tr - 1
  if (!is.finite(arg) || arg < 1) arg <- 1
  
  distance <- (sqrt(2) / 2) * acosh(arg)
  #if(-distance+fisher_rao_distance(mu1, Sigma1, mu2, Sigma2)>1.5){
  #  assign("zzztmp",list(mu1, Sigma1, mu2, Sigma2),envir=.GlobalEnv)
  #  stop("nullert")
  #}
  
  as.numeric(distance)
}
