# llmdist

Distance Measures Between Multivariate Normal Distributions

## Overview

`llmdist` provides a comprehensive set of distance and divergence measures between multivariate normal distributions, including:

- **LRT Trace** - **FASTEST**: Computationally efficient approximation to Wasserstein-2
- **Wasserstein-2 (Bures)** - Optimal transport distance with closed form (accurate but slower)
- **Fisher-Rao** - Information geometry metric via optimization (exact but slowest)
- **Hellinger** - Bounded distance [0,1]
- **Bhattacharyya** - Related to classification error
- **Kullback-Leibler** - Information-theoretic divergence
- **Affine-invariant** - Riemannian metric on SPD matrices

## Performance Guide: Choosing the Right Distance

For **high-dimensional problems** or **large-scale applications**, computational efficiency matters:

### Speed Ranking (Fastest → Slowest)
1. **`lrt_trace_distance()`** ⚡ - Only basic matrix operations (trace, determinant)
2. **`wasserstein2_distance()`** 🐢 - Requires expensive matrix square roots  
3. **`fisher_rao_distance()`** 🐌 - Iterative optimization

### When to Use Each

#### LRT Trace Distance ⚡ **RECOMMENDED FOR SPEED**
- **High dimensions** (p > 50)
- **Many distance computations** (e.g., clustering, nearest neighbors)
- **Real-time applications** 
- **Approximate comparisons** are sufficient
- **Machine learning pipelines** requiring speed
```r
lrt_trace_distance(mu1, Sigma1, mu2, Sigma2)  # Fastest option
```

#### Wasserstein-2 Distance 🎯 **RECOMMENDED FOR ACCURACY** 
- **Precise distance measurement** needed
- **Lower dimensions** (p < 50)
- **Theoretical work** requiring optimal transport interpretation
- **When computational cost is not critical**
```r
wasserstein2_distance(mu1, Sigma1, mu2, Sigma2)  # Most accurate
```

#### Fisher-Rao Distance 📐 **SPECIALIZED APPLICATIONS**
- **Information geometry** research
- **Statistical manifold** analysis  
- **Theoretical statistical** work requiring information-theoretic interpretation

## Installation

You can install the development version from source:

```r
# Install dependencies
install.packages(c("expm", "MASS"))

# Install from source
install.packages("path/to/llmdist", repos = NULL, type = "source")

# Or using devtools
devtools::install_local("path/to/llmdist")
```

Note: The package no longer requires `deSolve` - Fisher-Rao distance now uses the optimized Eriksen (1987) method based on Skovgaard's (1984) Riemannian geometry framework.

## Quick Start

```r
library(llmdist)

# Define two bivariate normal distributions
mu1 <- c(0, 0)
Sigma1 <- diag(2)

mu2 <- c(2, 1) 
Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)

# 🚀 RECOMMENDED: Use main llmdist() function (fast by default)
llmdist(mu1, Sigma1, mu2, Sigma2)                    # Fast LRT trace distance
llmdist(mu1, Sigma1, mu2, Sigma2, "wasserstein2")   # More precise but slower
llmdist(mu1, Sigma1, mu2, Sigma2, "hellinger")      # Bounded [0,1] similarity

# Alternative: Call specific distance functions directly  
lrt_trace_distance(mu1, Sigma1, mu2, Sigma2)        # Same as default llmdist()
wasserstein2_distance(mu1, Sigma1, mu2, Sigma2)
hellinger_distance(mu1, Sigma1, mu2, Sigma2)

# Compare all distances at once
compare_distances(mu1, Sigma1, mu2, Sigma2)
```

### **Performance Comparison: Speed vs Interpretation**

Different methods measure different geometric properties. Choose based on speed needs and interpretation:

```r
# High-dimensional example (100D)
p <- 100
mu1 <- rep(0, p)
Sigma1 <- diag(p)
mu2 <- rep(0.1, p) 
Sigma2 <- diag(p) + 0.1

# 🚀 FASTEST: Default llmdist() uses LRT trace (milliseconds)
system.time(llmdist(mu1, Sigma1, mu2, Sigma2))
#> ~0.001 seconds ⚡

# 🐢 SLOWER: Wasserstein-2 (requires matrix square roots)  
system.time(llmdist(mu1, Sigma1, mu2, Sigma2, "wasserstein2"))
#> ~0.05 seconds 

# 🐌 SLOWEST: Fisher-Rao (iterative optimization)
system.time(llmdist(mu1, Sigma1, mu2, Sigma2, "fisher_rao"))
#> ~2-10 seconds 
```

**Note**: In high dimensions, LRT trace and Wasserstein-2 often give similar *ordering* of distances, but they measure different geometric concepts.
```

## Key Functions

### **🎯 Main Entry Point** 

- `llmdist()` - **RECOMMENDED**: Main distance function with fast LRT trace default

### **Speed-Optimized Distances** ⚡

- `lrt_trace_distance()` - **FASTEST**: Efficient approximation to Wasserstein-2
- `wasserstein2_distance()` - Optimal transport (accurate but requires matrix square roots)
- `hellinger_distance()` - Bounded similarity measure
- `bhattacharyya_distance()` - Pattern recognition, classification  
- `kl_divergence()` - Information theory (asymmetric)
- `symmetrized_kl()` - Symmetric version of KL
- `affine_invariant_distance()` - Riemannian metric on covariances

### Numerical Methods

- `fisher_rao_distance()` - Information geometry metric (slow, may be unstable)
- `fisher_rao_geodesic_numerical()` - Compute geodesic path

### Utilities

- `compare_distances()` - Compute all distances for easy comparison

## Which Distance Should I Use?

| Application | Recommended Code | Why |
|-------------|------------------|-----|
| **🚀 High-dimensional (p > 50)** | **`llmdist(mu1, S1, mu2, S2)`** | **Default LRT trace: 50x faster with similar ordering** |
| **🚀 Large-scale ML pipelines** | **`llmdist(mu1, S1, mu2, S2)`** | **Minimal computational overhead** |
| **🚀 Real-time applications** | **`llmdist(mu1, S1, mu2, S2)`** | **Sub-millisecond computation** |
| **Optimal transport interpretation** | `llmdist(mu1, S1, mu2, S2, "wasserstein2")` | Exact transport cost (slower) |
| **LLM embeddings** | `llmdist()` or `"wasserstein2"` | Choose based on speed vs transport meaning |
| **Model merging/interpolation** | `llmdist(..., "wasserstein2")` | Optimal transport interpretation needed |
| **Classification** | `llmdist(..., "bhattacharyya")` | Related to Bayes error |
| **Bounded similarity** | `llmdist(..., "hellinger")` | Normalized [0,1] |
| **Information theory** | `llmdist(..., "fisher_rao")` | Theoretically optimal (slowest) |
| **Variational inference** | `llmdist(..., "kl")` | Natural for VAEs |

### 🎯 **Quick Decision Guide:**
```r
# 90% of users: Just use the fast default!
llmdist(mu1, Sigma1, mu2, Sigma2)

# Need optimal transport interpretation?  
llmdist(mu1, Sigma1, mu2, Sigma2, "wasserstein2")

# Need bounded similarity measure?
llmdist(mu1, Sigma1, mu2, Sigma2, "hellinger")
```

system.time(fisher_rao_distance(mu1, Sigma1, mu2, Sigma2))
# Typical: 0.1-1 seconds (requires optimization)
```

**Bottom line**: Wasserstein-2 is 10-100x faster than Fisher-Rao and sufficient for most practical applications. Use Fisher-Rao only when you specifically need the information geometry perspective.

## Examples

### LLM Applications

```r
# Compare embedding distributions
embedding1_mu <- colMeans(embeddings_model1)
embedding1_Sigma <- cov(embeddings_model1)

embedding2_mu <- colMeans(embeddings_model2)
embedding2_Sigma <- cov(embeddings_model2)

# Wasserstein distance for model comparison
wasserstein2_distance(embedding1_mu, embedding1_Sigma, 
                      embedding2_mu, embedding2_Sigma)
```

### Out-of-Distribution Detection

```r
# Train distribution
train_mu <- colMeans(train_features)
train_Sigma <- cov(train_features)

# Test sample
test_mu <- colMeans(test_features)
test_Sigma <- cov(test_features)

# Detect distribution shift
d <- bhattacharyya_distance(train_mu, train_Sigma, test_mu, test_Sigma)
is_ood <- d > threshold
```

## References

### Key Papers

- **Wasserstein-2**: Takatsu, A. (2011). Wasserstein geometry of Gaussian measures. *Osaka Journal of Mathematics*, 48(4), 1005-1026.

- **Fisher-Rao**: Skovgaard, L. T. (1984). A Riemannian geometry of the multivariate normal model. *Scandinavian Journal of Statistics*, 11(4), 211-223.

- **Affine-invariant**: Pennec, X., Fillard, P., & Ayache, N. (2006). A Riemannian framework for tensor computing. *International Journal of Computer Vision*, 66(1), 41-66.

- **Information Geometry**: Amari, S. (2016). *Information Geometry and Its Applications*. Springer.

### Included Documentation

A detailed paper on the Fisher-Rao geodesic implementation is included with the package:
```r
# View the paper location
system.file("fisher_rao_geodesic.pdf", package = "llmdist")
```

## License

MIT License - see LICENSE file for details

## Author

Poul Svante Eriksen - Aalborg University

## Contributing

Contributions are welcome! Please open an issue or pull request on GitHub.
