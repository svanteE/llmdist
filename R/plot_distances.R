#' Plot LRT Distance vs Fisher-Rao Distance Along a Geodesic
#'
#' Generates points along the Fisher-Rao geodesic between two multivariate normal
#' distributions and plots the LRT distance against the Fisher-Rao distance at each point.
#'
#' @param mu1 Mean vector of the first distribution
#' @param Sigma1 Covariance matrix of the first distribution
#' @param mu2 Mean vector of the second distribution
#' @param Sigma2 Covariance matrix of the second distribution
#' @param n_steps Number of points along the geodesic (default: 50)
#'
#' @return A ggplot2 object showing LRT distance vs Fisher-Rao distance
#'
#' @examples
#' \dontrun{
#' mu1 <- rep(0, 3)
#' Sigma1 <- diag(3)
#' mu2 <- rep(1, 3)
#' Sigma2 <- matrix(c(1, .1, .1, .1, 1, .1, .1, .1, 1), 3, 3)
#' plot_lrt_vs_fisher_rao(mu1, Sigma1, mu2, Sigma2)
#' }
#'
#' @export
plot_lrt_vs_fisher_rao <- function(mu1, Sigma1, mu2, Sigma2, n_steps = 50) {
  # Generate geodesic path
  cat("Computing Fisher-Rao geodesic...\n")
  geodesic <- fisher_rao_geodesic_numerical(mu1, Sigma1, mu2, Sigma2, n_steps = n_steps)
  
  if (is.null(geodesic)) {
    stop("Failed to compute geodesic. Check for ill-conditioned matrices.")
  }
  
  # Compute distances at each point along the geodesic
  cat("Computing distances along geodesic...\n")
  distances <- data.frame(
    t = numeric(n_steps),
    fisher_rao = numeric(n_steps),
    lrt = numeric(n_steps)
  )
  
  for (i in seq_along(geodesic)) {
    point <- geodesic[[i]]
    distances$t[i] <- point$t
    
    # Fisher-Rao distance from starting point
    distances$fisher_rao[i] <- fisher_rao_distance(mu1, Sigma1, point$mu, point$Sigma)
    
    # LRT distance from starting point
    distances$lrt[i] <- lrt_distance(mu1, Sigma1, point$mu, point$Sigma)
  }
  
  # Create plot
  cat("Creating plot...\n")
  
  # Check if ggplot2 is available
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    p <- ggplot2::ggplot(distances, ggplot2::aes(x = fisher_rao, y = lrt)) +
      ggplot2::geom_line(color = "blue", linewidth = 1) +
      ggplot2::geom_point(color = "darkblue", size = 2, alpha = 0.6) +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", 
                          color = "red", alpha = 0.5) +
      ggplot2::labs(
        title = "LRT Distance vs Fisher-Rao Distance",
        subtitle = "Along the Fisher-Rao geodesic",
        x = "Fisher-Rao Distance",
        y = "LRT Distance"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = ggplot2::element_text(hjust = 0.5, color = "gray40")
      )
    
    print(p)
    return(invisible(list(plot = p, data = distances)))
  } else {
    # Fallback to base R plotting
    plot(distances$fisher_rao, distances$lrt,
         type = "b", pch = 19, col = "blue",
         xlab = "Fisher-Rao Distance",
         ylab = "LRT Distance",
         main = "LRT Distance vs Fisher-Rao Distance\nAlong the Fisher-Rao geodesic")
    abline(0, 1, lty = 2, col = "red")
    grid()
    
    return(invisible(distances))
  }
}

#' Plot Distance Comparison Example
#'
#' Generates a specific example plot comparing LRT and Fisher-Rao distances
#' along a geodesic from identity covariance to a correlated structure.
#'
#' @param n_steps Number of points along the geodesic (default: 50)
#'
#' @return A plot object
#'
#' @examples
#' \dontrun{
#' plot_distance_comparison_example()
#' }
#'
#' @export
plot_distance_comparison_example <- function(n_steps = 50) {
  # Define starting and ending distributions
  mu1 <- rep(0, 3)
  Sigma1 <- diag(3)
  
  mu2 <- rep(1, 3)
  Sigma2 <- matrix(c(1, .1, 0,
                     .1, 1, .2,
                     0, .2, 1), 3, 3)
  
  cat("Example: 3D normal distributions\n")
  cat("Start: mu1 = (0,0,0), Sigma1 = I_3\n")
  cat("End:   mu2 = (1,1,1), Sigma2 = [1, 0.1, 0; 0.1, 1, 0.2; 0, 0.2, 1]\\n\\n")
  
  plot_lrt_vs_fisher_rao(mu1, Sigma1, mu2, Sigma2, n_steps = n_steps)
}
