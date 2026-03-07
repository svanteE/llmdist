#' Simulate Geodesic from Block Structure
#'
#' Simulates B and x, constructs the A matrix with geodesic block structure,
#' then computes Fisher-Rao distance, extracts (De, de), and computes LRT distance.
#'
#' @param p Dimension of the problem (default: 2)
#' @param n_sims Number of simulations (default: 100)
#' @param seed Random seed for reproducibility (default: NULL)
#'
#' @return A data frame with columns:
#'   \item{sim}{Simulation index}
#'   \item{fisher_rao_from_A}{Fisher-Rao distance computed from A matrix}
#'   \item{De_from_expA}{De block extracted from exp(A)}
#'   \item{de_from_expA}{de block extracted from exp(A)}
#'   \item{lrt_distance}{LRT distance computed from extracted (De, de)}
#'   \item{ratio_lrt_fr}{Ratio of LRT to Fisher-Rao distance}
#'
#' @details
#' The A matrix has the geodesic block structure:
#' A = [B,   x,   0  ]
#'     [x^t, 0,  -x^t]
#'     [0,  -x,  -B  ]
#'
#' where B is symmetric (constructed by symmetrizing random normals)
#' and x is a random normal vector.
#'
#' At t=1, Λ(1) = exp(A) yields canonical parameters (De, de).
#' We compare the Fisher-Rao distance (from A) with the LRT distance
#' computed from the extracted (De, de).
#'
#' @examples
#' \dontrun{
#' results <- simulate_geodesic_comparison(p = 2, n_sims = 50)
#' head(results)
#' mean(results$ratio_lrt_fr)  # Average ratio
#' plot(results$fisher_rao_from_A, results$lrt_distance)
#' }
#'
#' @export
simulate_geodesic_comparison <- function(p = 2, n_sims = 100, k=1, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  results <- data.frame(
    sim = integer(n_sims),
    fisher_rao_from_A = numeric(n_sims),
    de_from_expA = I(vector("list", n_sims)),
    De_from_expA = I(vector("list", n_sims)),
    lrt_distance = numeric(n_sims),
    ratio_lrt_fr = numeric(n_sims)
  )
  
  for (i in 1:n_sims) {
    # Simulate B as symmetric (symmetrize random normal matrix)
      # Scale by 1/sqrt(p) for reasonable distances in high dimensions
    B_raw <- matrix(rnorm(p^2,0,k), p, p)
      B <- 0.5 * (B_raw + t(B_raw)) / sqrt(p)
    
    # Simulate x as random normal vector, scaled consistently
      x <- matrix(rnorm(p,0,k), p, 1) / sqrt(p)
    
    # Construct A matrix with geodesic block structure:
    # A = [B,   x,   0  ]
    #     [x^t, 0,  -x^t]
    #     [0,  -x,  -B  ]
    A <- matrix(0, 2*p + 1, 2*p + 1)
    A[1:p, 1:p] <- B
    A[1:p, p+1] <- as.vector(x)
    A[p+1, 1:p] <- as.vector(t(x))
    A[p+1, (p+2):(2*p+1)] <- as.vector(-t(x))
    A[(p+2):(2*p+1), 1:p] <- 0  # lower-left block should be 0
    A[(p+2):(2*p+1), p+1] <- as.vector(-x)
    A[(p+2):(2*p+1), (p+2):(2*p+1)] <- -B
    
    # Compute Fisher-Rao distance from A
    fisher_rao_from_A <- sqrt(sum(A^2)) / 2
    
    # Extract (De, de) from exp(A)
    expA <- expm::expm(A)
    De_from_expA <- expA[1:p, 1:p]
    de_from_expA <- expA[1:p, p+1, drop = FALSE]
    
    # Convert (De, de) to (mu, Sigma) for starting point
    # Using reference distribution (0, I)
    mu1 <- rep(0,p)
    Sigma1 <- diag(p)
    Sigma2 <- solve.default(De_from_expA)
    mu2 <- Sigma2 %*%de_from_expA
    
    # Compute LRT distance
    lrt_dist <- lrt_distance(mu1, Sigma1, as.vector(mu2), Sigma2)
    #if(abs(lrt_dist-fisher_rao_from_A)>1) break
    # Store results
    results$sim[i] <- i
    results$fisher_rao_from_A[i] <- fisher_rao_from_A
    results$De_from_expA[[i]] <- De_from_expA
    results$de_from_expA[[i]] <- de_from_expA
    results$lrt_distance[i] <- lrt_dist
    results$ratio_lrt_fr[i] <- lrt_dist / fisher_rao_from_A
  }
  
  results
}

#' Run and Summarize Geodesic Comparison
#'
#' Wrapper function to run the simulation and print summary statistics.
#'
#' @param p Dimension (default: 2)
#' @param n_sims Number of simulations (default: 100)
#' @param seed Random seed (default: NULL)
#'
#' @return Invisibly returns the results data frame
#'
#' @examples
#' \dontrun{
#' run_geodesic_comparison(p = 3, n_sims = 50)
#' }
#'
#' @export
run_geodesic_comparison <- function(p = 2, n_sims = 100, seed = NULL) {
  cat("Simulating geodesic block structure...\n")
  cat("Dimension:", p, "\n")
  cat("Simulations:", n_sims, "\n\n")
  
  results <- simulate_geodesic_comparison(p = p, n_sims = n_sims, seed = seed)
  
  # Summary statistics
  cat("Fisher-Rao Distance (from A):\n")
  cat("  Mean:", round(mean(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n\n")
  
  cat("LRT Distance:\n")
  cat("  Mean:", round(mean(results$lrt_distance, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$lrt_distance, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$lrt_distance, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$lrt_distance, na.rm = TRUE), 6), "\n\n")
  
  cat("Ratio (LRT / Fisher-Rao):\n")
  cat("  Mean:", round(mean(results$ratio_lrt_fr, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$ratio_lrt_fr, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$ratio_lrt_fr, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$ratio_lrt_fr, na.rm = TRUE), 6), "\n\n")
  
  # Plot
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    p_plot <- ggplot2::ggplot(results, ggplot2::aes(x = fisher_rao_from_A, y = lrt_distance)) +
      ggplot2::geom_point(alpha = 0.6, color = "blue") +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
      ggplot2::labs(
        title = paste("LRT vs Fisher-Rao Distance (p =", p, ")"),
        x = "Fisher-Rao Distance (from A)",
        y = "LRT Distance (from exp(A))"
      ) +
      ggplot2::theme_minimal()
    print(p_plot)
  } else {
    plot(results$fisher_rao_from_A, results$lrt_distance,
         main = paste("LRT vs Fisher-Rao Distance (p =", p, ")"),
         xlab = "Fisher-Rao Distance (from A)",
         ylab = "LRT Distance (from exp(A))",
         col = "blue", pch = 19)
    abline(0, 1, lty = 2, col = "red")
    grid()
  }
  
  invisible(results)
}

# Internal helper: check symmetric positive-definite
.is_spd <- function(M, tol = 1e-8) {
  if (!is.matrix(M)) return(FALSE)
  if (!isTRUE(all.equal(M, t(M)))) return(FALSE)
  vals <- tryCatch(eigen(M, symmetric = TRUE, only.values = TRUE)$values,
                   error = function(e) return(NULL))
  if (is.null(vals)) return(FALSE)
  all(is.finite(vals)) && all(vals > tol)
}

#' Simulate Geodesic Comparing Fisher-Rao and LRT Trace Distance
#'
#' Similar to simulate_geodesic_comparison, but compares Fisher-Rao distance
#' with the numerically more stable LRT trace distance variant.
#'
#' @param p Dimension of the problem (default: 2)
#' @param n_sims Number of simulations (default: 100)
#' @param seed Random seed for reproducibility (default: NULL)
#'
#' @return A data frame with columns:
#'   \item{sim}{Simulation index}
#'   \item{fisher_rao_from_A}{Fisher-Rao distance computed from A matrix}
#'   \item{De_from_expA}{De block extracted from exp(A)}
#'   \item{de_from_expA}{de block extracted from exp(A)}
#'   \item{lrt_trace_distance}{LRT trace distance computed from extracted (De, de)}
#'   \item{ratio_lrt_trace_fr}{Ratio of LRT trace to Fisher-Rao distance}
#'
#' @details
#' This function constructs the same geodesic block structure as 
#' simulate_geodesic_comparison() but uses lrt_trace_distance() instead of
#' lrt_distance() for comparison, providing better numerical stability.
#'
#' @examples
#' \dontrun{
#' results <- simulate_fisher_rao_vs_lrt_trace(p = 2, n_sims = 50)
#' head(results)
#' mean(results$ratio_lrt_trace_fr)
#' }
#'
#' @export
simulate_fisher_rao_vs_lrt_trace <- function(p = 2, n_sims = 100, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  results <- data.frame(
    sim = integer(n_sims),
    fisher_rao_from_A = numeric(n_sims),
    de_from_expA = I(vector("list", n_sims)),
    De_from_expA = I(vector("list", n_sims)),
    lrt_trace_distance = numeric(n_sims),
    ratio_lrt_trace_fr = numeric(n_sims)
  )
  
  for (i in 1:n_sims) {
    # Simulate B as symmetric (symmetrize random normal matrix)
    # Heavier scaling (1/p) to keep exp(A) well-conditioned for large p
    B_raw <- matrix(rnorm(p^2), p, p)
    B <- 0.5 * (B_raw + t(B_raw)) / p
    
    # Simulate x as random normal vector, scaled consistently
    x <- matrix(rnorm(p), p, 1) / p
    
    # Construct A matrix with geodesic block structure:
    # A = [B,   x,   0  ]
    #     [x^t, 0,  -x^t]
    #     [0,  -x,  -B  ]
    A <- matrix(0, 2*p + 1, 2*p + 1)
    A[1:p, 1:p] <- B
    A[1:p, p+1] <- as.vector(x)
    A[p+1, 1:p] <- as.vector(t(x))
    A[p+1, (p+2):(2*p+1)] <- as.vector(-t(x))
    A[(p+2):(2*p+1), 1:p] <- 0  # lower-left block should be 0
    A[(p+2):(2*p+1), p+1] <- as.vector(-x)
    A[(p+2):(2*p+1), (p+2):(2*p+1)] <- -B
    
    # Compute Fisher-Rao distance from A
    fisher_rao_from_A <- sqrt(sum(A^2)) / 2
    
    # Extract (De, de) from exp(A)
    expA <- expm::expm(A)
    De_from_expA <- expA[1:p, 1:p]
    de_from_expA <- expA[1:p, p+1, drop = FALSE]
    
    if (any(!is.finite(De_from_expA)) || any(!is.finite(de_from_expA))) {
      results$sim[i] <- i
      results$fisher_rao_from_A[i] <- fisher_rao_from_A
      results$De_from_expA[[i]] <- De_from_expA
      results$de_from_expA[[i]] <- de_from_expA
      results$lrt_trace_distance[i] <- NA_real_
      results$ratio_lrt_trace_fr[i] <- NA_real_
      next
    }

    # Symmetrize De (no SPD check needed for trace distance)
    De_from_expA <- 0.5 * (De_from_expA + t(De_from_expA))
    
    # Convert (De, de) to (mu, Sigma) for starting point
    # Using reference distribution (0, I)
    mu1 <- numeric(p)
    Sigma1 <- diag(p)
    
    # Endpoint parameters - try to invert De
    Sigma2 <- tryCatch(solve(De_from_expA), error = function(e) NULL)
    if (is.null(Sigma2)) {
      # Try pseudoinverse if solve fails
      Sigma2 <- tryCatch({
        if (requireNamespace("MASS", quietly = TRUE)) MASS::ginv(De_from_expA) else NULL
      }, error = function(e) NULL)
    }
    if (is.null(Sigma2)) {
      results$sim[i] <- i
      results$fisher_rao_from_A[i] <- fisher_rao_from_A
      results$De_from_expA[[i]] <- De_from_expA
      results$de_from_expA[[i]] <- de_from_expA
      results$lrt_trace_distance[i] <- NA_real_
      results$ratio_lrt_trace_fr[i] <- NA_real_
      next
    }
    Sigma2 <- 0.5 * (Sigma2 + t(Sigma2))
    mu2 <- Sigma2 %*% de_from_expA
    
    # Compute LRT trace distance
    lrt_trace_dist <- lrt_trace_distance(mu1, Sigma1, as.vector(mu2), Sigma2)
    
    # Store results
    results$sim[i] <- i
    results$fisher_rao_from_A[i] <- fisher_rao_from_A
    results$De_from_expA[[i]] <- De_from_expA
    results$de_from_expA[[i]] <- de_from_expA
    results$lrt_trace_distance[i] <- lrt_trace_dist
    results$ratio_lrt_trace_fr[i] <- lrt_trace_dist / fisher_rao_from_A
  }
  
  results
}

#' Run and Summarize Fisher-Rao vs LRT Trace Comparison
#'
#' Wrapper function to run the simulation and print summary statistics.
#'
#' @param p Dimension (default: 2)
#' @param n_sims Number of simulations (default: 100)
#' @param seed Random seed (default: NULL)
#'
#' @return Invisibly returns the results data frame
#'
#' @examples
#' \dontrun{
#' run_fisher_rao_vs_lrt_trace(p = 3, n_sims = 50)
#' }
#'
#' @export
run_fisher_rao_vs_lrt_trace <- function(p = 2, n_sims = 100, seed = NULL) {
  cat("Simulating geodesic block structure...\n")
  cat("Comparing Fisher-Rao vs LRT Trace Distance\n")
  cat("Dimension:", p, "\n")
  cat("Simulations:", n_sims, "\n\n")
  
  results <- simulate_fisher_rao_vs_lrt_trace(p = p, n_sims = n_sims, seed = seed)
  
  # Summary statistics
  cat("Fisher-Rao Distance (from A):\n")
  cat("  Mean:", round(mean(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$fisher_rao_from_A, na.rm = TRUE), 6), "\n\n")
  
  cat("LRT Trace Distance:\n")
  cat("  Mean:", round(mean(results$lrt_trace_distance, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$lrt_trace_distance, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$lrt_trace_distance, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$lrt_trace_distance, na.rm = TRUE), 6), "\n\n")
  
  cat("Ratio (LRT Trace / Fisher-Rao):\n")
  cat("  Mean:", round(mean(results$ratio_lrt_trace_fr, na.rm = TRUE), 6), "\n")
  cat("  SD:  ", round(sd(results$ratio_lrt_trace_fr, na.rm = TRUE), 6), "\n")
  cat("  Min: ", round(min(results$ratio_lrt_trace_fr, na.rm = TRUE), 6), "\n")
  cat("  Max: ", round(max(results$ratio_lrt_trace_fr, na.rm = TRUE), 6), "\n\n")
  
  # Plot
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    p_plot <- ggplot2::ggplot(results, ggplot2::aes(x = fisher_rao_from_A, y = lrt_trace_distance)) +
      ggplot2::geom_point(alpha = 0.6, color = "darkgreen") +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
      ggplot2::labs(
        title = paste("LRT Trace vs Fisher-Rao Distance (p =", p, ")"),
        x = "Fisher-Rao Distance (from A)",
        y = "LRT Trace Distance (from exp(A))"
      ) +
      ggplot2::theme_minimal()
    print(p_plot)
  } else {
    plot(results$fisher_rao_from_A, results$lrt_trace_distance,
         main = paste("LRT Trace vs Fisher-Rao Distance (p =", p, ")"),
         xlab = "Fisher-Rao Distance (from A)",
         ylab = "LRT Trace Distance (from exp(A))",
         col = "darkgreen", pch = 19)
    abline(0, 1, lty = 2, col = "red")
    grid()
  }
  
  invisible(results)
}
