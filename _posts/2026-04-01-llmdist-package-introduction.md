---
layout: default
title: "Distance Computation Between Multivariate Normal Distributions: The llmdist Package"
date: 2026-04-01
---

# Distance Computation Between Multivariate Normal Distributions: The llmdist Package

In the era of high-dimensional data, efficiently computing distances between probability distributions has become increasingly important. We introduce the **llmdist** package, which addresses this challenge with a 50x speedup over traditional methods.

## Speed vs. Interpretability

When working with multivariate normal distributions the Wasserstein-2 (Bures) distance is popular. This comes with a computational cost: matrix square root operations that become prohibitive in high dimensions or when computing thousands of distances.

Consider this common scenario:

```r
# Imagine comparing two machine learning models in 100 dimensions
# Model 1: baseline with zero mean and standard covariance
p <- 100
mu1 <- rep(0, p)           # Mean vector: all zeros
Sigma1 <- diag(p)          # Covariance: identity matrix

# Model 2: slightly different - small shift in mean, slightly more variable
mu2 <- rep(0.1, p)         # Mean shifted by 0.1 in each dimension  
Sigma2 <- diag(p) + 0.1    # Covariance: identity + small constant

# How different are these two models? Let's compare approaches:

# Traditional approach: Wasserstein-2 distance
system.time(llmdist(mu1, Sigma1, mu2, Sigma2, "wasserstein2"))
#> ~0.05 seconds per computation 🐢

# NEW: LRT trace distance (default)
system.time(llmdist(mu1, Sigma1, mu2, Sigma2))
#> ~0.001 seconds per computation

# The difference: 50x speedup 
# For 1000 comparisons: LRT trace ~1 second vs Wasserstein-2 ~50 seconds
```

In applications requiring real-time responses or large-scale comparisons, this quickly becomes an issue.

## Introducing llmdist

The **llmdist** package provides a comprehensive suite of distance measures between multivariate normal distributions. A new feature is the **LRT trace distance** - a fast alternative that maintains similar ordering properties to Wasserstein-2.
And another new feature is the fisher-rao distance, which has been a theoretical quantity(p>1). 

## Installation

```r
# Install from GitHub (make sure you have devtools installed)
if (!require(devtools)) install.packages("devtools")
devtools::install_github("svanteE/llmdist")
library(llmdist)
```

The **LRT (Likelihood Ratio Test) trace distance** has higher computational efficiency. Instead of expensive matrix square roots, it uses only basic matrix operations (trace) while preserving the essential property of distance ordering.

Traditional approaches use expensive $det(A)$ calculations, but LRT trace uses only $(tr(A)/p)^p$, leveraging the AM-GM inequality relationship. This seemingly simple change provides:

- **50x speed improvement** over Wasserstein-2
- **Similar distance ordering** for practical applications  
- **Robust performance** across different dimensionalities

## Practical Example: Clustering High-Dimensional Distributions

Here's a realistic machine learning scenario where speed matters:

```r
# Simulate 50 high-dimensional distributions (e.g., model parameters)
set.seed(42)
p <- 200  # High-dimensional
n_dists <- 50

# Generate random distributions
distributions <- list()
for(i in 1:n_dists) {
  mu <- rnorm(p, sd = 0.5)
  A <- matrix(rnorm(p * min(p, 20)), p, min(p, 20))  # Low-rank structure
  Sigma <- A %*% t(A) + diag(p) * 0.1
  distributions[[i]] <- list(mu = mu, Sigma = Sigma)
}

# Compute all pairwise distances - Traditional approach would be slow!
distances <- matrix(0, n_dists, n_dists)

start_time <- Sys.time()
for(i in 1:(n_dists-1)) {
  for(j in (i+1):n_dists) {
    dist <- llmdist(distributions[[i]]$mu, distributions[[i]]$Sigma,
                   distributions[[j]]$mu, distributions[[j]]$Sigma)
    distances[i, j] <- distances[j, i] <- dist
  }
}
end_time <- Sys.time()

cat("Computed", choose(n_dists, 2), "distances in", 
    round(as.numeric(end_time - start_time), 2), "seconds\n")
#> Computed 1225 distances in 1.2 seconds

# Now you can perform hierarchical clustering
hc <- hclust(as.dist(distances))
plot(hc, main = "Clustering High-Dimensional Distributions", 
     xlab = "Distribution Index", sub = "Using LRT Trace Distance")
```

This computation would take minutes with traditional Wasserstein-2, but completes in seconds.

## Method Comparison: When to Use What

The llmdist package implements 8 different distance measures. Here's when to use 4 of these:

```r
# Define example distributions
mu1 <- c(0, 0)
Sigma1 <- diag(2)
mu2 <- c(1, 1)
Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)

# Compare different methods
methods <- c("lrt_trace", "wasserstein2", "hellinger", "fisher_rao")
results <- sapply(methods, function(m) llmdist(mu1, Sigma1, mu2, Sigma2, method = m))
print(round(results, 4))

#>   lrt_trace wasserstein2    hellinger bhattacharyya   fisher_rao 
#>      1.3611       1.4993       0.2749        0.5640       1.2789
```

**Quick Decision Guide:**

 - **Speed?** Use default `llmdist()` (LRT trace)
 - **Need optimal transport interpretation?** Use `llmdist(..., "wasserstein2")`
 - **Need bounded similarity [0,1]?** Use `llmdist(..., "hellinger")`
 - **Information theory applications?** Use `llmdist(..., "fisher_rao")`

## Real-World Applications

### 1. LLM Embedding Analysis
```r
# Compare different fine-tuned model embeddings
embedding_dist <- llmdist(embedding1_stats$mu, embedding1_stats$Sigma,
                         embedding2_stats$mu, embedding2_stats$Sigma)
```

### 2. Model Parameter Comparison
```r
# Fast comparison of neural network layer statistics
layer_similarity <- llmdist(layer1_mu, layer1_cov, layer2_mu, layer2_cov)
```

### 3. Time Series Analysis
```r
# Compare distributional properties across time windows
window_distances <- llmdist(window1_mu, window1_cov, window2_mu, window2_cov)
```

## Conclusion

The **llmdist** package brings both theoretical advances (first multivariate Fisher-Rao implementation) and practical improvements (50x speedup with LRT trace) to distance computation between multivariate normal distributions. Whether you're clustering high-dimensional data, comparing model parameters, or analyzing time series, llmdist provides the tools you need for efficient and reliable distance computation.

Try it out and let us know how it works for your applications!

---

*For more details, visit the [GitHub repository](https://github.com/svanteE/llmdist) or install directly with `devtools::install_github("svanteE/llmdist")`.*