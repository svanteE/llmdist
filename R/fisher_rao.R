#' @importFrom stats optim rnorm
NULL

# Helper: Generate initial value for y from de and diagonal De entries
start_val <- function(de, De_diag) {
  de <- as.numeric(de)
  # Accept either vector of diagonal entries or a diagonal matrix
  denom <- if (is.matrix(De_diag)) diag(De_diag) else as.numeric(De_diag)
  p <- length(de)
  # phi is p x p
  phi <- -outer(de, de / denom) / 2
  if (p == 1) return(numeric(0))
  if (p == 2) return(phi[1, 2])
  ud <- c()
  for (i in 1:(p - 1)) ud <- c(ud, phi[i, (i + 1):p])
  ud
}

# Helper: Construct Z matrix from y (upper triangular part)
construct_Z <- function(y, d, D) {
  p <- length(d)
  
  # Handle univariate case
  if (p == 1) {
    return(matrix(-d[1]^2 / (2 * D[1]), 1, 1))
  }
  
  Z <- matrix(0, p, p)
  
  # Diagonal elements (known)
  for (i in 1:p) {
    Z[i, i] <- -d[i]^2 / (2 * D[i])
  }
  
  # Upper triangular part from y
  idx <- 1
  for (i in 1:(p-1)) {
    for (j in (i+1):p) {
      Z[i, j] <- y[idx]
      idx <- idx + 1
    }
  }
   # Lower triangular part determined from upper
  for (i in 1:(p-1)) {
    for (j in (i+1):p) {
      Z[j, i] <- -(d[i] * d[j] + D[j] * Z[i, j]) / D[i]
    }
  }
  
  Z
}

#' Helper: Construct T matrix
#' @noRd
construct_T <- function(y, d, D) {
  p <- length(d)
  Z <- construct_Z(y, d, D)
  
  T_mat <- matrix(0, 2*p+1, 2*p+1)
  
  # Block structure: T = [D, d, Z; 0, 1, -d'*D^-1; 0, 0, D^-1]
  T_mat[1:p, 1:p] <- diag(D)
  T_mat[1:p, p+1] <- d
  T_mat[1:p, (p+2):(2*p+1)] <- Z
  
  T_mat[p+1, p+1] <- 1
  T_mat[p+1, (p+2):(2*p+1)] <- -d / D
  
  T_mat[(p+2):(2*p+1), (p+2):(2*p+1)] <- diag(1/D)
  
  T_mat
}

#' Helper: Build Λ₀(y) explicitly from T(y)
#'
#' Λ₀(y) = T(y)' T(y) with the block structure you specified:
#'   Λ₀(y) = [De,        de,          Φ₀(y)      ]
#'           [de',      1+τ,         γ₀(y)'      ]
#'           [Φ₀(y)',   γ₀(y),       Γ₀(y)       ]
#' where De = diag(D^2), de = D·d, τ = d'd, and Φ₀, γ₀, Γ₀ are implied by y via T.
#' We form Λ₀ via T to preserve the exact induced relations among blocks.
#' @noRd
construct_Lambda0 <- function(y, d, D) {
  T_mat <- construct_T(y, d, D)
  t(T_mat) %*% T_mat
}

#' Helper: Extract A matrix blocks
#'
#' Extracts the six blocks from A(y):
#' A(y) = [B(y)    x(y)    C(y)  ]
#'        [x(y)^t  e(y)    z(y)^t]
#'        [C(y)^t  z(y)    E(y)  ]
#'
#' @param A The (2p+1) × (2p+1) A matrix
#'
#' @return A list with:
#'   \item{B}{p×p block}
#'   \item{x}{p×1 vector}
#'   \item{C}{p×p block}
#'   \item{e}{1×1 scalar}
#'   \item{z}{p×1 vector}
#'   \item{E}{p×p block}
#'
#' @noRd
extract_A_blocks <- function(A) {
  p <- (nrow(A) - 1) / 2
  
  B <- A[1:p, 1:p, drop = FALSE]
  x <- A[1:p, p+1, drop = FALSE]
  C <- A[1:p, (p+2):(2*p+1), drop = FALSE]
  e <- A[p+1, p+1]
  z <- A[(p+2):(2*p+1), p+1, drop = FALSE]
  E <- A[(p+2):(2*p+1), (p+2):(2*p+1), drop = FALSE]
  
  list(B = B, x = x, C = C, e = e, z = z, E = E)
}

#' Helper: Objective function f(y) = tr(C^2) + tr((B+E)^2) + sum((x+z)^2) + e^2
#'
#' Minimizes the A matrix block structure to drive all off-diagonal constraints to zero:
#' - C block (p×p)
#' - B+E sum (should be antisymmetric)
#' - x+z sum (coupling vectors should cancel)
#' - e scalar
#'
#' @noRd
objective_f <- function(y, d, D) {
  p <- length(d)

  # Build Λ₀(y) with the exact block structure via T(y)
  Lambda0 <- construct_Lambda0(y, d, D)
  #Lambda0=(Lambda0+t(Lambda0))/2
  ela=eigen(Lambda0)
  w=length(ela$val)
  A_log=ela$vector%*%diag(log(ela$val),w,w)%*%t(ela$vector)
  # Compute A_log(y) = log(Λ₀(y))
  #A_log <- expm::logm(Lambda0,method="Eigen")

  # Extract blocks
  blocks <- extract_A_blocks(A_log)
  B <- blocks$B
  x <- blocks$x
  C <- blocks$C
  e <- blocks$e
  z <- blocks$z
  E <- blocks$E

  # Return f(y) = tr(C^2) + tr((B+E)^2) + sum((x+z)^2) + e^2
  f <- sum(C^2) + sum((B + E)^2) + sum((x + z)^2) + e^2
  f
}

#' Helper: Check optimal A matrix block structure
#'
#' Verifies that A_optimal has the geodesic block structure:
#' A_optimal = [B    x    0  ]
#'             [x^t  0   -x^t]
#'             [0   -x   -B  ]
#'
#' where C = 0, e = 0, z = -x, and E = -B.
#'
#' @param A The A matrix to check
#'
#' @return A list with:
#'   \item{has_optimal_structure}{TRUE if all constraints satisfied within tolerance}
#'   \item{residuals}{Frobenius norms of constraint violations}
#'   \item{blocks}{Extracted blocks B, x, C, e, z, E}
#'
#' @noRd
check_optimal_A_structure <- function(A, tol = 1e-6) {
  p <- (nrow(A) - 1) / 2
  
  # Extract blocks
  blocks <- extract_A_blocks(A)
  B <- blocks$B
  x <- blocks$x
  C <- blocks$C
  e <- blocks$e
  z <- blocks$z
  E <- blocks$E
  
  # Compute constraint residuals
  C_residual <- sqrt(sum(C^2))  # Should be 0
  e_residual <- abs(e)           # Should be 0
  z_plus_x_residual <- sqrt(sum((z + x)^2))  # z should equal -x
  E_plus_B_residual <- sqrt(sum((E + B)^2))  # E should equal -B
  
  # Overall check
  is_optimal <- (C_residual < tol) && 
                (e_residual < tol) && 
                (z_plus_x_residual < tol) && 
                (E_plus_B_residual < tol)
  
  list(
    has_optimal_structure = is_optimal,
    residuals = list(
      C_norm = C_residual,
      e_abs = e_residual,
      z_plus_x_norm = z_plus_x_residual,
      E_plus_B_norm = E_plus_B_residual,
      max_residual = max(C_residual, e_residual, z_plus_x_residual, E_plus_B_residual)
    ),
    blocks = blocks,
    tolerance = tol
  )
}

#' Helper: Diagnostic check of Λ₀(y) and A_log(y) blocks
#'
#' Validates that Λ₀(y) = T(y)'T(y) has the expected block structure and that
#' A_log(y) = log(Λ₀(y)) produces small C and e blocks when y is near optimal.
#'
#' @param y The parameters (upper triangular of Z)
#' @param d Rotated canonical mean / D
#' @param D Square roots of De eigenvalues (diagonal matrix of precision)
#'
#' @return A list with:
#'   \item{Lambda0_blocks}{Expected block values: De_block (should be diag(D^2)), 
#'                        de_block (should be D*d), tau (should be d'd)}
#'   \item{Lambda0_check}{Residuals from block structure: De_residual, de_residual, tau_residual}
#'   \item{A_log_blocks}{Extracted C and e blocks from log(Λ₀)}
#'   \item{A_log_norms}{Frobenius norm of C and squared norm of e}
#'   \item{expm_test}{Verify expm(A_log)[1:p,1:p] ≈ Lambda0[1:p,1:p]}
#'
#' @noRd
validate_Lambda0_structure <- function(y, d, D) {
  p <- length(d)
  
  # Build Λ₀(y)
  Lambda0 <- construct_Lambda0(y, d, D)
  
  # Expected blocks
  De_expected <- diag(D^2)
  de_expected <- D * d
  tau_expected <- sum(d^2)
  
  # Extract actual blocks from Λ₀
  De_block <- Lambda0[1:p, 1:p, drop = FALSE]
  de_block <- Lambda0[1:p, p+1, drop = FALSE]
  tau_block <- Lambda0[p+1, p+1]
  
  # Compute residuals
  De_residual <- norm(De_block - De_expected, type = "F")
  de_residual <- norm(de_block - matrix(de_expected, ncol = 1), type = "F")
  tau_residual <- abs(tau_block - (1 + tau_expected))
  
  # Extract blocks from A_log = log(Λ₀)
  A_log <- expm::logm(Lambda0)
  C <- A_log[1:p, (p+2):(2*p+1), drop = FALSE]
  e <- A_log[p+1, p+1]
  
  # Norms: C should be small at optimum, e should be small
  C_norm <- sqrt(sum(C^2))
  e_sq <- e^2
  
  # Test round-trip: expm(A_log) should recover Λ₀
  Lambda0_recon <- expm::expm(A_log)
  recon_error <- norm(Lambda0_recon - Lambda0, type = "F")
  
  list(
    Lambda0_blocks = list(
      De_expected = De_expected,
      de_expected = de_expected,
      tau_expected = tau_expected,
      tau_actual = tau_block
    ),
    Lambda0_check = list(
      De_residual = De_residual,
      de_residual = de_residual,
      tau_residual = tau_residual,
      all_blocks_match = (De_residual < 1e-10) && (de_residual < 1e-10) && (tau_residual < 1e-10)
    ),
    A_log_blocks = list(
      C = C,
      e = e
    ),
    A_log_norms = list(
      C_frobenius_norm = C_norm,
      e_squared = e_sq,
      f_value = C_norm^2 + e_sq
    ),
    expm_test = list(
      round_trip_error = recon_error,
      reconstruction_accurate = recon_error < 1e-10
    )
  )
}

#' Helper: Gradient of objective function (optional, for speed)
#' @noRd
gradient_f <- function(y, d, D) {
  # Numerical gradient via finite differences
  p <- length(d)
  n_y <- length(y)
  grad <- numeric(n_y)
  h <- 1e-8
  
  f0 <- objective_f(y, d, D)
  
  for (i in 1:n_y) {
    y_plus <- y
    y_plus[i] <- y[i] + h
    grad[i] <- (objective_f(y_plus, d, D) - f0) / h
  }
  
  grad
}

#' Fisher-Rao Geodesic (Optimized)
#'
#' Computes the Fisher-Rao geodesic path between two multivariate normal distributions
#' using the method of Eriksen (1987), which solves the geodesic equations for the
#' Fisher information metric formulated by Skovgaard (1984). 
#'
#' When the canonical parameter de is an eigenvector of the precision matrix De
#' (which includes all univariate cases), uses the closed-form formula (7) for
#' efficient computation. Otherwise, minimizes f(y) = tr(C(y)^2) where C(y) is the
#' off-diagonal block in the matrix logarithm decomposition. Once optimal y is found,
#' it constructs A(y) and computes Λ(t) = exp(t·A) to extract the geodesic path μ(t) and Σ(t).
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#' @param n_steps Number of points along the geodesic path (default: 100)
#' @param tol Tolerance for endpoint error (default: 1e-6)
#'
#' @return A list of length n_steps, each element containing:
#'   \item{t}{Parameter value (0 to 1)}
#'   \item{mu}{Mean vector at this point}
#'   \item{Sigma}{Covariance matrix at this point}
#'
#' @references
#' Skovgaard, L. T. (1984). A Riemannian geometry of the multivariate
#' normal model. Scandinavian Journal of Statistics, 11(4), 211-223.
#' (Established the Riemannian geometry framework and differential equations)
#'
#' Eriksen, P. S. (1987). Geodesics connected with the Fisher metric on
#' the multivariate normal manifold. Proceedings of the GST Workshop.
#' (Solved the geodesic equations, enabling practical computation)
#'
#' For detailed theory and implementation, see the included paper:
#' \code{system.file("fisher_rao_geodesic.pdf", package = "llmdist")}
#'
#' @importFrom expm logm expm
#' @export
fisher_rao_geodesic_numerical <- function(mu1, Sigma1, mu2, Sigma2, 
                                          n_steps = 100, tol = 1e-6) {
  p <- length(mu1)
  
  # Transform to canonical parameters relative to (0, I)
  U <- chol(solve(Sigma1))
  U_inv <- solve(U)
  
  mu_transformed <- U %*% (mu2 - mu1)
  Sigma_transformed <- U %*% Sigma2 %*% t(U)
  
  De <- solve(Sigma_transformed)
  
  # Check for ill-conditioned De matrix (crucial for geodesic computation)
  cond_De <- kappa(De)
  
  if (cond_De > 1e10) {
    warning(paste("Ill-conditioned De matrix detected (kappa =", round(cond_De, 2), "). Geodesic may be inaccurate."))
    return(NULL)
  }
  de <- De %*% mu_transformed
  
  # Check if de is an eigenvector of De (includes univariate case p=1)
  eigenvector_result <- fisher_rao_de_eigenvector(de, De, tol = 1e-8)
  
  if (eigenvector_result$is_aligned) {
    # de is an eigenvector - use direct geodesic from formula (7)
    # Construct Λ_0 from formula (5) with Φ_0, γ_0, Γ_0
    # Use the mean parameter at t=0 (relative to transformed geometry)
    
    p <- length(de)
    Dei <- solve(De)
    mu <- Dei %*% de  # mean parameter at t=0
    tau <- as.numeric(t(mu) %*% de)
    
    # Define blocks from formula (5)
    Phi_0 <- -de %*% t(mu) / 2
    gamma_0 <- -(1 + tau/2) * mu
    Gamma_0 <- Dei + (1 + tau/4) * mu %*% t(mu)
    
    # Construct Λ_0 (2p+1 × 2p+1):
    # Λ_0 = [De,        de,          Φ_0         ]
    #       [de',      1+τ,         γ_0'        ]
    #       [Φ_0',     γ_0,         Γ_0         ]
    Lambda_0 <- matrix(0, 2*p + 1, 2*p + 1)
    Lambda_0[1:p, 1:p] <- De
    Lambda_0[1:p, p+1] <- as.vector(de)
    Lambda_0[1:p, (p+2):(2*p+1)] <- Phi_0
    Lambda_0[p+1, 1:p] <- as.vector(t(de))
    Lambda_0[p+1, p+1] <- 1 + tau
    Lambda_0[p+1, (p+2):(2*p+1)] <- as.vector(t(gamma_0))
    Lambda_0[(p+2):(2*p+1), 1:p] <- t(Phi_0)
    Lambda_0[(p+2):(2*p+1), p+1] <- as.vector(gamma_0)
    Lambda_0[(p+2):(2*p+1), (p+2):(2*p+1)] <- Gamma_0
    
    # Compute A = logm(Λ_0)
    A <- expm::logm(Lambda_0)
    
    # Generate geodesic path: Λ(t) = exp(t·A)
    times <- seq(0, 1, length.out = n_steps)
    
    geodesic <- lapply(times, function(t) {
      # Compute Λ(t) = exp(t·A)
      Lambda_t <- expm::expm(t * A)
      
      # Extract De(t) and de(t) from Λ(t)
      De_t_canonical <- Lambda_t[1:p, 1:p]
      de_t_canonical <- Lambda_t[1:p, p+1, drop=FALSE]
      
      # Convert (De, de) to (mu, Sigma) in canonical space
      Sigma_t_canonical <- solve(De_t_canonical)
      mu_t_canonical <- Sigma_t_canonical %*% de_t_canonical
      
      # Transform back to original coordinates
      mu_original <- mu1 + U_inv %*% mu_t_canonical
      Sigma_original <- U_inv %*% Sigma_t_canonical %*% t(U_inv)
      
      list(t = t, 
           mu = as.vector(mu_original),
           Sigma = Sigma_original)
    })
    
    return(geodesic)
  }
  
  # General multivariate case - de is NOT an eigenvector of De, use optimized method
  # Diagonalize De via eigendecomposition
  eigen_De <- eigen(De)
  De_diag <- diag(eigen_De$values)
  V <- eigen_De$vectors
  de_rotated <- t(V) %*% de
  
  # Transform to d and D
  D <- sqrt(diag(De_diag))
  d <- de_rotated / D
  
  # Optimize y to minimize tr(C(y)^2)
  n_y <- p*(p-1)/2
  #y0 <- rnorm(n_y, mean = 0, sd = 0.01)
  y0 <- start_val(de_rotated, eigen_De$values)  
  # Multi-restart optimization
  best_result <- list(value = Inf)
  
  for (attempt in 1:3) {
    result <- optim(
      par = if (attempt == 1) y0 else rnorm(y0, sd = 0.05),
      fn = objective_f,
      gr = gradient_f,
      d = d,
      D = D,
      method = "BFGS",
      control = list()
    )
    
    if (result$value < best_result$value) {
      best_result <- result
    }
    
    if (result$value < 1e-6) break
  }
  
  y_opt <- best_result$par
  
  # Check convergence
  if (best_result$value > 1e-4) {
    warning(paste("Optimization may not have converged. f(y) =", 
                  round(best_result$value, 8)))
  }
  
  # Construct optimal T matrix and compute TtT = Lambda_0 in ROTATED space
  T_mat <- construct_T(y_opt, d, D)
  TtT_rotated <- t(T_mat) %*% T_mat
  
  # Rotate Λ_0 back to canonical coordinates via orthogonal similarity:
  # S = block-diagonal diag(V, 1, V); TtT = S %*% TtT_rotated %*% t(S)
  S <- matrix(0, 2*p + 1, 2*p + 1)
  S[1:p, 1:p] <- V
  S[p+1, p+1] <- 1
  S[(p+2):(2*p+1), (p+2):(2*p+1)] <- V
  TtT <- S %*% TtT_rotated %*% t(S)
  
  # Now compute A = log(TtT) in canonical coordinates
  A <- expm::logm(TtT)
  
  # At optimum, C(y) = 0, so A has the block structure:
  # A = [A11, a12,  0   ]
  #     [a21,  0,  -a12^t]
  #     [0,  -a12, -A11]
  # where A11 is p×p, a12 is p×1
  
  # Generate geodesic path: Λ(t) = exp(t·A)
  times <- seq(0, 1, length.out = n_steps)
  
  geodesic <- lapply(times, function(t) {
    # Compute Λ(t) = exp(t·A)
    Lambda_t <- expm::expm(t * A)
    
    # Extract De(t) and de(t) from Λ(t) - these are already in the rotated (d,D) space
    # Λ[1:p, 1:p] = De(t) in rotated coordinates
    # Λ[1:p, p+1] = de(t) in rotated coordinates
    De_t_rotated <- Lambda_t[1:p, 1:p]
    de_t_rotated <- Lambda_t[1:p, p+1, drop=FALSE]
    
    # Rotate back using V to get to canonical space (before the d,D rotation)
    De_t_canonical <- V %*% De_t_rotated %*% t(V)
    de_t_canonical <- V %*% de_t_rotated
    
    # Convert (De, de) to (mu, Sigma) in canonical space
    Sigma_t_canonical <- solve(De_t_canonical)
    mu_t_canonical <- Sigma_t_canonical %*% de_t_canonical
    
    # Transform back to original coordinates
    mu_original <- mu1 + U_inv %*% mu_t_canonical
    Sigma_original <- U_inv %*% Sigma_t_canonical %*% t(U_inv)
    
    list(t = t, 
         mu = as.vector(mu_original),
         Sigma = Sigma_original)
  })
  
  geodesic
}

#' Fisher-Rao Distance (Optimized)
#'
#' Computes the Fisher-Rao distance using the geodesic solution method of Eriksen (1987).
#' When the canonical parameter de is an eigenvector of the precision matrix De
#' (which includes all univariate cases), uses the closed-form formula (7) for
#' efficient computation. Otherwise, solves the optimization problem f(y) = tr(C(y)^2) = 0
#' to find the exact geodesic for the Fisher information metric (Skovgaard 1984),
#' then computes the distance as the path length.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#' @param method Optimization method (default: "BFGS")
#' @param control Control parameters for optim()
#'
#' @return The Fisher-Rao distance (non-negative scalar), or NA if computation fails
#'
#' @examples
#' # Bivariate example
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- diag(2)
#' d <- fisher_rao_distance(mu1, Sigma1, mu2, Sigma2)
#' print(d)
#' 
#' # Univariate example (uses eigenvector formula)
#' d_uni <- fisher_rao_distance(0, matrix(1), 2, matrix(4))
#' print(d_uni)
#'
#' @references
#' Skovgaard, L. T. (1984). A Riemannian geometry of the multivariate
#' normal model. Scandinavian Journal of Statistics, 11(4), 211-223.
#'
#' Eriksen, P. S. (1987). Geodesics connected with the Fisher metric on
#' the multivariate normal manifold. Proceedings of the GST Workshop.
#'
#' When means are equal (mu1 = mu2), the Fisher-Rao distance reduces to a
#' geodesic on the manifold of positive definite matrices (the covariance
#' component only). This is the affine-invariant distance:
#'
#' Moakher, M. (2005). A differential geometric approach to the geometric
#' mean of symmetric positive-definite matrices. SIAM Journal on Matrix
#' Analysis and Applications, 26(3), 735-747.
#'
#' For detailed theory and implementation, see the included paper:
#' \code{system.file("fisher_rao_geodesic.pdf", package = "llmdist")}
#'
#' @importFrom expm logm
#' @export
fisher_rao_distance <- function(mu1, Sigma1, mu2, Sigma2, 
                                 method = "BFGS", control = list(),returnA=FALSE) {
  p <- length(mu1)
  
  # Transform to canonical parameters relative to (0, I)
  U <- chol(solve(Sigma1))
  U_inv <- solve(U)
  
  mu_transformed <- U %*% (mu2 - mu1)
  Sigma_transformed <- U %*% Sigma2 %*% t(U)
  
  De <- solve(Sigma_transformed)
  
  # Check for ill-conditioned De matrix (crucial for Fisher-Rao computation)
  cond_De <- kappa(De)
  
  if (cond_De > 1e10) {
    warning(paste("Ill-conditioned De matrix detected (kappa =", round(cond_De, 2), ").",
                  "Fisher-Rao distance may be inaccurate."))
    return(NA_real_)
  }
  de <- De %*% mu_transformed
  
  # Check if de is an eigenvector of De (includes univariate case p=1)
  eigenvector_result <- fisher_rao_de_eigenvector(de, De, tol = 1e-8)
  
  if (eigenvector_result$is_aligned) {
    # de is an eigenvector of De - use formula (7) for distance
    if(returnA)
    return(list(distance=eigenvector_result$distance,A=eigenvector_result$A)) else
      return(eigenvector_result$distance)
  }
  
  # General multivariate case - de is NOT an eigenvector of De, optimize to find geodesic
  # Diagonalize De via eigendecomposition
  eigen_De <- eigen(De)
  De_diag <- diag(eigen_De$values)
  V <- eigen_De$vectors
  de_rotated <- t(V) %*% de
  
  # Transform to d and D
  D <- sqrt(diag(De_diag))
  d <- de_rotated / D
  
  # Optimize y (upper triangular part of Z)
  
  # Better initial guess: use small random perturbations
  # This helps escape poor local minima
  y0 <- start_val(de_rotated, eigen_De$values)  
  
  # Try optimization with multiple restarts if it doesn't converge
  best_result <- list(value = Inf)
  
  for (attempt in 1:3) { result <- optim(
        par = if (attempt == 1) y0 else rnorm(y0, sd = sd(y0)/10),
        fn = objective_f,
        gr = gradient_f,
        d = d,
        D = D,
        method = "BFGS",
        control = list()
      )
    #print(result)
    if (result$value < best_result$value) {
      best_result <- result
    }
    
    # Break early if converged well
    if (result$value < 1e-6) break
  }
  
  result <- best_result
  
  # Compute distance from optimized T matrix
  T_mat <- construct_T(result$par, d, D)
  TtT_rotated <- t(T_mat) %*% T_mat
  
  # Rotate Λ_0 back to canonical coordinates via orthogonal similarity:
  # S = block-diagonal diag(V, 1, V); TtT = S %*% TtT_rotated %*% t(S)
  S <- matrix(0, 2*p + 1, 2*p + 1)
  S[1:p, 1:p] <- V
  S[p+1, p+1] <- 1
  S[(p+2):(2*p+1), (p+2):(2*p+1)] <- V
  TtT <- S %*% TtT_rotated %*% t(S)
  
  A <- expm::logm(TtT)
  distance <- sqrt(sum(A^2)) / 2
  
  # Check optimal A matrix structure
  #structure_check <- check_optimal_A_structure(A, tol = 1e-4)
  assign("zzztmp",1,envir=.GlobalEnv)
  # Check convergence
  if (result$value > 1e-4) {
    warning(paste("Optimization may not have converged. f(y) =", 
                  round(result$value, 8)))
    assign("zzztmp",0,envir=.GlobalEnv)
  }
  
  # Warn if optimal structure not achieved
  #if (!structure_check$has_optimal_structure) {
  #  warning(paste("A matrix does not have optimal geodesic structure.",
  #                "Max residual:", round(structure_check$residuals$max_residual, 8)))
  #}
  if(returnA)
  list(distance=distance,A=A) else
    return(distance)

}

#' Check if a vector is an eigenvector of a matrix
#'
#' @description
#' Verifies whether a given vector is an eigenvector of a matrix by checking
#' if \eqn{Av = \lambda v} for some eigenvalue \eqn{\lambda}, where \eqn{A} is
#' the matrix and \eqn{v} is the vector.
#'
#' @param A A square numeric matrix.
#' @param v A numeric vector to check as a potential eigenvector.
#' @param tol Numeric tolerance for determining equality (default: 1e-10).
#'
#' @return
#' A list containing:
#' \item{is_eigenvector}{Logical: TRUE if v is an eigenvector of A, FALSE otherwise.}
#' \item{eigenvalue}{Numeric: The estimated eigenvalue if v is an eigenvector, NA otherwise.}
#' \item{residual}{Numeric: The norm of the residual Av - λv (measure of how close to being an eigenvector).}
#'
#' @details
#' The function computes \eqn{A v} and compares it to \eqn{\lambda v} where \eqn{\lambda}
#' is estimated from the Rayleigh quotient: \eqn{\lambda = \frac{v^T A v}{v^T v}}.
#' The vector is considered an eigenvector if the residual norm is below the tolerance.
#'
#' @examples
#' A <- matrix(c(1, 2, 2, 4), nrow = 2)
#' eigendecomp <- eigen(A)
#' v <- eigendecomp$vectors[, 1]
#'
#' result <- is_eigenvector(A, v)
#' result$is_eigenvector
#'
#' @export
is_eigenvector <- function(A, v, tol = 1e-10) {
  # Input validation
  if (!is.matrix(A)) {
    A <- as.matrix(A)
  }
  if (nrow(A) != ncol(A)) {
    stop("A must be a square matrix")
  }
  if (!is.numeric(v)) {
    v <- as.numeric(v)
  }
  if (nrow(A) != length(v)) {
    stop("Vector v must have the same length as the dimension of matrix A")
  }
  
  # Handle zero vector
  if (all(v == 0)) {
    return(list(
      is_eigenvector = TRUE,
      eigenvalue = NA_real_,
      residual = 0
    ))
  }
  
  # Estimate eigenvalue using Rayleigh quotient
  Av <- A %*% v
  lambda <- as.numeric((t(v) %*% Av) / (t(v) %*% v))
  
  # Compute residual: ||Av - λv||
  residual <- norm(as.matrix(Av - lambda * v), type = "F")
  
  # Determine if it's an eigenvector
  is_eigen <- residual < tol
  
  list(
    is_eigenvector = is_eigen,
    eigenvalue = lambda,
    residual = residual
  )
}

#' Fisher-Rao Distance (Formula 7) when de is an eigenvector of De
#'
#' @description
#' Computes the Fisher-Rao distance using formula (7) when \eqn{de} is an eigenvector
#' of the precision matrix \eqn{De}. This special case arises in canonical parameters
#' when the mean direction aligns with the covariance structure.
#'
#' @param de A numeric vector of canonical mean parameter.
#' @param De A square numeric matrix, the precision (inverse covariance) matrix.
#' @param tol Numeric tolerance for eigenvector check (default: 1e-8).
#'
#' @return
#' A list containing:
#' \item{is_aligned}{Logical: TRUE if de is an eigenvector of De, FALSE otherwise.}
#' \item{distance}{Numeric: The Fisher-Rao distance D_0 from formula (7) if de is aligned,
#'                  NA otherwise.}
#' \item{eigenvalue}{Numeric: The eigenvalue if de is an eigenvector, NA otherwise.}
#'
#' @details
#' When \eqn{de} is an eigenvector of \eqn{De}, the geodesic computation simplifies.
#' The distance is computed using:
#' \deqn{D_0 = \sqrt{\frac{\text{tr}(A^2)}{2}}}
#' where \eqn{A = \log(\Lambda_0)} and \eqn{\Lambda_0} is the matrix at the starting point
#' of the geodesic in the expanded space (Fisher-Rao geodesic theory by Eriksen 1987).
#'
#' @references
#' Eriksen, P. S. (1987). Geodesics connected with the Fisher metric on
#' the multivariate normal manifold. Proceedings of the GST Workshop.
#'
#' @examples
#' # Create a simple example where de is an eigenvector of De
#' De <- diag(c(2, 3, 4))  # Diagonal matrix (all vectors are eigenvectors)
#' de <- matrix(c(1, 0, 0), ncol = 1)  # Eigenvector with eigenvalue 2
#'
#' result <- fisher_rao_de_eigenvector(de, De)
#' if (result$is_aligned) {
#'   cat("D_0 (Fisher-Rao distance):", result$distance, "\n")
#' }
#'
#' @importFrom expm logm
#' @export
fisher_rao_de_eigenvector <- function(de, De, tol = 1e-8) {
  # Input validation
  if (!is.matrix(De)) {
    De <- as.matrix(De)
  }
  if (nrow(De) != ncol(De)) {
    stop("De must be a square matrix (precision matrix)")
  }
  if (!is.numeric(de)) {
    de <- as.numeric(de)
  }
  if (length(de) != nrow(De)) {
    stop("de must have the same length as the dimension of De")
  }
  
  # Ensure de is a column vector
  if (!is.matrix(de)) {
    de <- as.matrix(de, ncol = 1)
  }
  
  # Check if de is an eigenvector of De
  eigen_check <- is_eigenvector(De, as.vector(de), tol = tol)
  
  if (!eigen_check$is_eigenvector) {
    return(list(
      is_aligned = FALSE,
      distance = NA_real_,
      eigenvalue = NA_real_
    ))
  }
  
  # de is an eigenvector - compute D_0 using formula (7)
  # Construct Λ_0 from formula (5) with Φ_0, γ_0, Γ_0
  
  p <- length(de)
  Dei <- solve(De)
  mu <- Dei %*% de
  tau <- as.numeric(t(mu) %*% de)
  
  # Define blocks from formula (5)
  Phi_0 <- -de %*% t(mu) / 2
  gamma_0 <- -(1 + tau/2) * mu
  Gamma_0 <- Dei + (1 + tau/4) * mu %*% t(mu)
  
  # Construct Λ_0 (2p+1 × 2p+1):
  # Λ_0 = [De,        de,          Φ_0         ]
  #       [de',      1+τ,         γ_0'        ]
  #       [Φ_0',     γ_0,         Γ_0         ]
  Lambda_0 <- matrix(0, 2*p + 1, 2*p + 1)
  Lambda_0[1:p, 1:p] <- De
  Lambda_0[1:p, p+1] <- as.vector(de)
  Lambda_0[1:p, (p+2):(2*p+1)] <- Phi_0
  Lambda_0[p+1, 1:p] <- as.vector(t(de))
  Lambda_0[p+1, p+1] <- 1 + tau
  Lambda_0[p+1, (p+2):(2*p+1)] <- as.vector(t(gamma_0))
  Lambda_0[(p+2):(2*p+1), 1:p] <- t(Phi_0)
  Lambda_0[(p+2):(2*p+1), p+1] <- as.vector(gamma_0)
  Lambda_0[(p+2):(2*p+1), (p+2):(2*p+1)] <- Gamma_0
  
  # Compute A = logm(Λ_0)
  A <- expm::logm(Lambda_0)
  
  # Distance is sqrt(tr(A^2)/2)
  distance <- sqrt(sum(A^2))/2
  
  list(
    is_aligned = TRUE,
    distance = distance,
    eigenvalue = eigen_check$eigenvalue,
    A=A
  )
}

# Helper: normalize MVN inputs (accepts scalar mean/cov and expands as needed)
#' @noRd
normalize_mvnorm_inputs <- function(mu1, Sigma1, mu2, Sigma2) {
  mu1 <- as.numeric(mu1)
  mu2 <- as.numeric(mu2)
  # Allow scalar mean recycled to match the other
  if (length(mu1) == 1L && length(mu2) > 1L) mu1 <- rep(mu1, length(mu2))
  if (length(mu2) == 1L && length(mu1) > 1L) mu2 <- rep(mu2, length(mu1))
  p <- length(mu1)
  if (length(mu2) != p) {
    stop("mu1 and mu2 must have the same length")
  }
  Sigma1 <- as.matrix(Sigma1)
  Sigma2 <- as.matrix(Sigma2)
  # Allow scalar covariance expanded to isotropic diag
  if (nrow(Sigma1) == 1L && ncol(Sigma1) == 1L && p > 1L) {
    Sigma1 <- diag(as.numeric(Sigma1), p)
  }
  if (nrow(Sigma2) == 1L && ncol(Sigma2) == 1L && p > 1L) {
    Sigma2 <- diag(as.numeric(Sigma2), p)
  }
  if (!all(dim(Sigma1) == c(p, p))) stop("Sigma1 must be a ", p, "x", p, " matrix")
  if (!all(dim(Sigma2) == c(p, p))) stop("Sigma2 must be a ", p, "x", p, " matrix")
  list(mu1 = mu1, Sigma1 = Sigma1, mu2 = mu2, Sigma2 = Sigma2, p = p)
}

#' Debug A Matrix Structure - Eigenvector Case
#'
#' Computes the A matrix using the eigenvector-aligned case formula as an alternative
#' to the standard optimization method. This is useful for validating A matrix computation
#' and debugging geodesic calculations.
#'
#' When the canonical parameter de is an eigenvector of the precision matrix De
#' (which includes all univariate cases), this function computes the A matrix directly
#' from the closed-form formula using Λ_0 (the initial parameter point on the geodesic).
#' The A matrix is defined as A = log(Λ_0).
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return A list containing:
#'   \item{A_eigenvector}{A matrix (2p+1) × (2p+1) computed from eigenvector formula}
#'   \item{Lambda_0}{The parameter point Λ_0 at t=0}
#'   \item{is_aligned}{Logical: TRUE if de is an eigenvector of De}
#'   \item{eigenvalue}{The corresponding eigenvalue if de is an eigenvector}
#'   \item{de}{The canonical parameter vector}
#'   \item{De}{The precision matrix in canonical coordinates}
#'
#' @details
#' This function is primarily for debugging and validation purposes. It computes
#' the A matrix directly from the formula:
#' A = log(Λ_0) where Λ_0 is constructed from (De, de, μ, τ) via formula (5).
#'
#' The block structure of Λ_0 is:
#' Λ_0 = [De,        de,          Φ_0         ]
#'       [de',      1+τ,         γ_0'        ]
#'       [Φ_0',     γ_0,         Γ_0         ]
#'
#' where:
#'   - De = precision matrix (p × p)
#'   - de = canonical parameter (p × 1)
#'   - Φ_0 = -de·μ'/2 (p × p)
#'   - γ_0 = -(1 + τ/2)·μ (p × 1)
#'   - Γ_0 = De^{-1} + (1 + τ/4)·μ·μ' (p × p)
#'   - τ = μ'·de
#'
#' @examples
#' \dontrun{
#' mu1 <- c(0, 0)
#' Sigma1 <- diag(2)
#' mu2 <- c(1, 1)
#' Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)
#'
#' debug_result <- debug_A_structure(mu1, Sigma1, mu2, Sigma2)
#' print(debug_result$A_eigenvector)
#' print(debug_result$is_aligned)
#' }
#'
#' @importFrom expm logm
#' @export
#'
debug_A_structure <- function(mu1, Sigma1, mu2, Sigma2) {
  norm <- normalize_mvnorm_inputs(mu1, Sigma1, mu2, Sigma2)
  mu1 <- norm$mu1; mu2 <- norm$mu2; Sigma1 <- norm$Sigma1; Sigma2 <- norm$Sigma2; p <- norm$p
  
  # Ensure mu1, mu2 are column vectors
  mu1 <- as.matrix(mu1, ncol = 1)
  mu2 <- as.matrix(mu2, ncol = 1)
  
  # Transform to canonical parameters relative to (0, I)
  U <- chol(solve(Sigma1))
  mu_transformed <- U %*% (mu2 - mu1)
  Sigma_transformed <- U %*% Sigma2 %*% t(U)
  
  De <- solve(Sigma_transformed)
  de <- De %*% mu_transformed
  
  # Check if de is an eigenvector of De
  eigenvector_result <- fisher_rao_de_eigenvector(de, De, tol = 1e-8)
  
  # ===== EIGENVECTOR CASE (when de is aligned with De) =====
  A_eigenvector <- NULL
  Lambda_0_eigenvector <- NULL
  mu_eigen <- NULL
  tau_eigen <- NULL
  Phi_0_eigen <- NULL
  gamma_0_eigen <- NULL
  Gamma_0_eigen <- NULL
  
  if (eigenvector_result$is_aligned) {
    # Compute A matrix from eigenvector formula
    Dei <- solve(De)
    mu_eigen <- Dei %*% de
    tau_eigen <- as.numeric(t(mu_eigen) %*% de)
    
    # Define blocks from formula (5)
    Phi_0_eigen <- -de %*% t(mu_eigen) / 2
    gamma_0_eigen <- -(1 + tau_eigen/2) * mu_eigen
    Gamma_0_eigen <- Dei + (1 + tau_eigen/4) * mu_eigen %*% t(mu_eigen)
    
    # Construct Λ_0 (2p+1 × 2p+1)
    Lambda_0_eigenvector <- matrix(0, 2*p + 1, 2*p + 1)
    Lambda_0_eigenvector[1:p, 1:p] <- De
    Lambda_0_eigenvector[1:p, p+1] <- as.vector(de)
    Lambda_0_eigenvector[1:p, (p+2):(2*p+1)] <- Phi_0_eigen
    Lambda_0_eigenvector[p+1, 1:p] <- as.vector(t(de))
    Lambda_0_eigenvector[p+1, p+1] <- 1 + tau_eigen
    Lambda_0_eigenvector[p+1, (p+2):(2*p+1)] <- as.vector(t(gamma_0_eigen))
    Lambda_0_eigenvector[(p+2):(2*p+1), 1:p] <- t(Phi_0_eigen)
    Lambda_0_eigenvector[(p+2):(2*p+1), p+1] <- as.vector(gamma_0_eigen)
    Lambda_0_eigenvector[(p+2):(2*p+1), (p+2):(2*p+1)] <- Gamma_0_eigen
    
    # Compute A = logm(Λ_0)
    A_eigenvector <- expm::logm(Lambda_0_eigenvector)
  }
  
  # ===== NON-EIGENVECTOR CASE (optimization method) =====
  A_optimized <- NULL
  opt_result <- NULL
  y_optimal <- NULL
  
  if (p > 1) {
    # Diagonalize De via eigendecomposition
    eigen_De <- eigen(De)
    De_diag <- diag(eigen_De$values)
    V <- eigen_De$vectors
    de_rotated <- t(V) %*% de
    
    # Transform to d and D
    D <- sqrt(diag(De_diag))
    d <- as.vector(de_rotated) / D
    
    # Optimize y to minimize tr(C(y)^2)
    n_y <- p*(p-1)/2
    y0 <- start_val(d, diag(D^2))
    
    # Multi-restart optimization
    best_result <- list(value = Inf)
    
    for (attempt in 1:3) {
      result <- optim(
        par = if (attempt == 1) y0 else rnorm(n_y, sd = 0.05),
        fn = objective_f,
        gr = gradient_f,
        d = d,
        D = D,
        method = "BFGS",
        control = list()
      )
      
      if (result$value < best_result$value) {
        best_result <- result
      }
      
      if (result$value < 1e-6) break
    }
    
    opt_result <- best_result
    y_optimal <- best_result$par
    
    # Construct optimal T matrix and compute TtT = Lambda_0 in ROTATED space
    T_mat <- construct_T(y_optimal, d, D)
    TtT_rotated <- t(T_mat) %*% T_mat
    
    # Rotate Λ_0 back to canonical coordinates via orthogonal similarity:
    # S = block-diagonal diag(V, 1, V); TtT = S %*% TtT_rotated %*% t(S)
    S <- matrix(0, 2*p + 1, 2*p + 1)
    S[1:p, 1:p] <- V
    S[p+1, p+1] <- 1
    S[(p+2):(2*p+1), (p+2):(2*p+1)] <- V
    TtT <- S %*% TtT_rotated %*% t(S)
    
    # Now compute A = log(TtT) in canonical coordinates
    A_optimized <- expm::logm(TtT)
  } else {
    # Univariate case: A matrix is simple
    A_optimized <- matrix(0, 3, 3)
    de_scalar <- as.numeric(de)
    De_scalar <- as.numeric(De)
    A_optimized[1, 1] <- 0.5 * log(De_scalar)
    A_optimized[3, 3] <- -0.5 * log(De_scalar)
    A_optimized[1, 2] <- de_scalar / (2 * sqrt(De_scalar))
    A_optimized[2, 3] <- -de_scalar / (2 * sqrt(De_scalar))
    opt_result <- list(value = 0)
    y_optimal <- numeric(0)
  }
  
  # Return results with both methods
  list(
    A_eigenvector = A_eigenvector,
    A_optimized = A_optimized,
    is_aligned = eigenvector_result$is_aligned,
    eigenvalue = eigenvector_result$eigenvalue,
    Lambda_0_eigenvector = Lambda_0_eigenvector,
    y_optimal = y_optimal,
    optimization_result = opt_result,
    de = de,
    De = De,
    # Eigenvector method components
    mu_eigen = mu_eigen,
    tau_eigen = tau_eigen,
    Phi_0_eigen = Phi_0_eigen,
    gamma_0_eigen = gamma_0_eigen,
    Gamma_0_eigen = Gamma_0_eigen
  )
}

#' Compare A Matrices (Eigen vs Optimized)
#'
#' Diagnostic helper to compare the two A-matrix constructions produced by
#' `debug_A_structure()`: the closed-form eigenvector case and the optimized
#' general case. It reports C-block residuals, reconstructed endpoint error, and
#' distances derived from each A.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return A list with:
#'   \item{eigen}{Diagnostics for eigenvector A (NULL if not aligned)}
#'   \item{optimized}{Diagnostics for optimized A}
#'
#' Each diagnostics element contains:
#'   \item{distance}{sqrt(tr(A^2)/2)}
#'   \item{C_norm}{Frobenius norm of C-block (should be ~0 at optimum)}
#'   \item{endpoint_error}{List with mu_error and Sigma_error relative to target}
#'   \item{A}{The A matrix used}
#'
#' @importFrom expm expm
#' @export
compare_A_matrices <- function(mu1, Sigma1, mu2, Sigma2) {
  norm <- normalize_mvnorm_inputs(mu1, Sigma1, mu2, Sigma2)
  mu1 <- norm$mu1; mu2 <- norm$mu2; Sigma1 <- norm$Sigma1; Sigma2 <- norm$Sigma2; p <- norm$p

  dbg <- debug_A_structure(mu1, Sigma1, mu2, Sigma2)

  # Transform utility
  build_endpoint <- function(A, U_inv) {
    if (is.null(A)) return(NULL)
    Lambda1 <- expm::expm(A)
    De_t <- Lambda1[1:p, 1:p]
    de_t <- Lambda1[1:p, p+1, drop = FALSE]
    Sigma_c <- solve(De_t)
    mu_c <- Sigma_c %*% de_t
    mu_o <- mu1 + U_inv %*% mu_c
    Sigma_o <- U_inv %*% Sigma_c %*% t(U_inv)
    list(mu = as.vector(mu_o), Sigma = Sigma_o)
  }

  endpoint_errors <- function(recon) {
    if (is.null(recon)) return(NULL)
    mu_err <- sqrt(sum((recon$mu - mu2)^2))
    Sigma_err <- norm(recon$Sigma - Sigma2, type = "F")
    list(mu_error = mu_err, Sigma_error = Sigma_err)
  }

  c_block_norm <- function(A) {
    if (is.null(A)) return(NULL)
    C <- A[1:p, (p + 2):(2 * p + 1), drop = FALSE]
    sqrt(sum(C^2))
  }

  summarize <- function(A, U_inv) {
    if (is.null(A)) return(NULL)
    list(
      distance = sqrt(sum(A^2) / 2),
      C_norm = c_block_norm(A),
      endpoint_error = endpoint_errors(build_endpoint(A, U_inv)),
      A = A
    )
  }

  U <- chol(solve(Sigma1))
  U_inv <- solve(U)

  list(
    eigen = summarize(dbg$A_eigenvector, U_inv),
    optimized = summarize(dbg$A_optimized, U_inv),
    # Additional diagnostics
    summary = list(
      is_aligned = dbg$is_aligned,
      eigenvalue = dbg$eigenvalue,
      both_distances_match = if (!is.null(dbg$A_eigenvector) && !is.null(dbg$A_optimized)) {
        abs(sqrt(sum(dbg$A_eigenvector^2)/2) - sqrt(sum(dbg$A_optimized^2)/2)) < 1e-6
      } else { NA },
      optimization_converged = if (!is.null(dbg$optimization_result)) {
        dbg$optimization_result$value < 1e-4
      } else { NA }
    )
  )
}

#' Fisher-Rao Distance (both A matrices)
#'
#' Returns both A matrices (eigenvector case always computed, and optimized) and their distances.
#' Useful for diagnosing cases where de is close to an eigenvector of De.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#'
#' @return A list with:
#'   \item{A_eigenvector}{A matrix from eigenvector formula (always computed)}
#'   \item{distance_eigen}{Distance from A_eigenvector}
#'   \item{A_optimized}{A matrix from optimization method}
#'   \item{distance_optimized}{Distance from A_optimized}
#'   \item{is_aligned}{Whether de is an eigenvector of De (tolerance check)}
#'   \item{eigenvalue}{Eigenvalue when strictly aligned}
#'   \item{eigen_residual}{Residual ||De·de - λ·de|| (how close to eigenvector)}
#'
#' Helper: Check A matrix block structure and symmetry properties
#'
#' Inspects the block structure of A to diagnose issues with sign relationships.
#' At optimum, the blocks should satisfy structural constraints from the geodesic.
#'
#' @param A The A matrix (2p+1 × 2p+1)
#'
#' @return A list with:
#'   \item{B_block}{A[1:p, 1:p] — the precision-related block}
#'   \item{x_block}{A[1:p, p+1] — the coupling vector}
#'   \item{C_block}{A[1:p, (p+2):(2p+1)] — off-diagonal C}
#'   \item{e_value}{A[p+1, p+1] — the middle scalar}
#'   \item{Gamma_block}{A[(p+2):(2p+1), (p+2):(2p+1)] — the endpoint block}
#'   \item{block_analysis}{Sign patterns and relationships}
#'
#' @noRd
inspect_A_blocks <- function(A) {
  p <- (nrow(A) - 1) / 2
  
  B <- A[1:p, 1:p, drop = FALSE]
  x <- A[1:p, p+1, drop = FALSE]
  C <- A[1:p, (p+2):(2*p+1), drop = FALSE]
  e <- A[p+1, p+1]
  Gamma <- A[(p+2):(2*p+1), (p+2):(2*p+1), drop = FALSE]
  
  # Diagnose sign structure
  B_diag_mean <- mean(diag(B))
  Gamma_diag_mean <- mean(diag(Gamma))
  
  list(
    B_block = B,
    x_block = x,
    C_block = C,
    e_value = e,
    Gamma_block = Gamma,
    block_analysis = list(
      B_diag_mean = B_diag_mean,
      Gamma_diag_mean = Gamma_diag_mean,
      opposite_signs = (B_diag_mean * Gamma_diag_mean < 0),
      C_norm = sqrt(sum(C^2)),
      e_value = e,
      e_abs = abs(e),
      is_antisymmetric_structure = isSymmetric(B + Gamma, tol = 1e-10)
    )
  )
}

#' @importFrom expm logm
#' @export
fisher_rao_distance_both <- function(mu1, Sigma1, mu2, Sigma2) {
  dbg <- debug_A_structure(mu1, Sigma1, mu2, Sigma2)
  dist_eigen <- if (!is.null(dbg$A_eigenvector)) sqrt(sum(dbg$A_eigenvector^2) / 2) else NA_real_
  dist_opt <- if (!is.null(dbg$A_optimized)) sqrt(sum(dbg$A_optimized^2) / 2) else NA_real_
  
  # Compute residual for how close de is to being an eigenvector
  eigen_check <- is_eigenvector(dbg$De, as.vector(dbg$de), tol = 1e-8)
  
  # Inspect optimized A block structure
  A_opt_analysis <- if (!is.null(dbg$A_optimized)) inspect_A_blocks(dbg$A_optimized) else NULL
  
  list(
    A_eigenvector = dbg$A_eigenvector,
    distance_eigen = dist_eigen,
    A_optimized = dbg$A_optimized,
    distance_optimized = dist_opt,
    is_aligned = dbg$is_aligned,
    eigenvalue = dbg$eigenvalue,
    eigen_residual = eigen_check$residual,
    A_optimized_structure = A_opt_analysis
  )
}

#' Validate A Matrix Solution
#'
#' Checks whether an A matrix is a valid geodesic solution by verifying
#' endpoint reconstruction, C-block condition, and symmetry properties.
#'
#' @param A The A matrix to validate (2p+1 × 2p+1)
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution  
#' @param mu2 Mean vector of the second distribution (target)
#' @param Sigma2 Covariance matrix of the second distribution (target)
#'
#' @return A list with validation results:
#'   \item{is_valid}{Overall validity (all checks pass)}
#'   \item{endpoint_mu_error}{Euclidean error in reconstructed mu2}
#'   \item{endpoint_Sigma_error}{Frobenius error in reconstructed Sigma2}
#'   \item{C_block_norm}{Frobenius norm of C-block (should be ~0)}
#'   \item{is_symmetric}{Whether A is symmetric}
#'   \item{distance}{Fisher-Rao distance from A}
#'   \item{reconstructed_mu}{Reconstructed mean at t=1}
#'   \item{reconstructed_Sigma}{Reconstructed covariance at t=1}
#'
#' @importFrom expm expm
#' @export
validate_A_solution <- function(A, mu1, Sigma1, mu2, Sigma2) {
  norm <- normalize_mvnorm_inputs(mu1, Sigma1, mu2, Sigma2)
  mu1 <- norm$mu1; mu2 <- norm$mu2; Sigma1 <- norm$Sigma1; Sigma2 <- norm$Sigma2; p <- norm$p
  
  # Check symmetry
  is_sym <- isSymmetric(A, tol = 1e-10)
  
  # Extract C-block
  C <- A[1:p, (p+2):(2*p+1), drop = FALSE]
  C_norm <- sqrt(sum(C^2))
  
  # Compute distance
  distance <- sqrt(sum(A^2) / 2)
  
  # Reconstruct endpoint at t=1
  U <- chol(solve(Sigma1))
  U_inv <- solve(U)
  
  Lambda1 <- expm::expm(A)
  De_t <- Lambda1[1:p, 1:p, drop = FALSE]
  de_t <- Lambda1[1:p, p+1, drop = FALSE]
  
  Sigma_c <- solve(De_t)
  mu_c <- Sigma_c %*% de_t
  
  mu_recon <- as.vector(mu1 + U_inv %*% mu_c)
  Sigma_recon <- U_inv %*% Sigma_c %*% t(U_inv)
  
  # Compute errors
  mu_err <- sqrt(sum((mu_recon - mu2)^2))
  Sigma_err <- norm(Sigma_recon - Sigma2, type = "F")
  
  # Overall validity: symmetric, small C-block, accurate endpoint
  is_valid <- is_sym && C_norm < 1e-3 && mu_err < 1e-4 && Sigma_err < 1e-4
  
  list(
    is_valid = is_valid,
    endpoint_mu_error = mu_err,
    endpoint_Sigma_error = Sigma_err,
    C_block_norm = C_norm,
    is_symmetric = is_sym,
    distance = distance,
    reconstructed_mu = mu_recon,
    reconstructed_Sigma = Sigma_recon
  )
}
