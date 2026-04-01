# llmdist 🚀

**Fast and comprehensive distance computation between multivariate normal distributions**

[![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)](https://www.r-project.org/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/svanteE/llmdist)
[![Blog](https://img.shields.io/badge/Blog-FF6B6B?style=flat&logo=rss&logoColor=white)](https://svanteE.github.io/llmdist/)

## 🎯 Why llmdist?

- **⚡ 50x faster** than traditional Wasserstein-2 distance
- **🔬 First implementation** of Fisher-Rao distance for multivariate normals  
- **📊 8 different distance measures** for comprehensive analysis
- **🎛️ Simple API** - one function for all methods

## 📋 Distance Methods

| Method | Speed | Use Case | Bounded |
|--------|-------|----------|---------|
| **LRT Trace** ⚡ | Fastest | High-dimensional, clustering | No |
| **Wasserstein-2** 🎯 | Moderate | Optimal transport, precise | No |
| **Fisher-Rao** 📐 | Slowest | Information geometry | No |
| **Hellinger** 📏 | Fast | Similarity [0,1] | Yes |
| **Bhattacharyya** 🎲 | Fast | Classification error | Yes |
| **KL Divergence** 📈 | Fast | Information theory | No |

## 🚀 Installation

```r
# Install from GitHub
if (!require(devtools)) install.packages("devtools")
devtools::install_github("svanteE/llmdist")

# Load the package
library(llmdist)
```

## ⚡ Quick Start

```r
# Define two distributions
mu1 <- c(0, 0)
Sigma1 <- diag(2)
mu2 <- c(1, 1)
Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)

# Fast default (LRT trace)
llmdist(mu1, Sigma1, mu2, Sigma2)
#> 1.361

# Specify method
llmdist(mu1, Sigma1, mu2, Sigma2, method = "wasserstein2")
#> 1.499

# Compare all methods
compare_distances(mu1, Sigma1, mu2, Sigma2)
```

## 📊 Performance Comparison

**High-dimensional example (100D):**

```r
p <- 100
mu1 <- rep(0, p); Sigma1 <- diag(p)
mu2 <- rep(0.1, p); Sigma2 <- diag(p) + 0.1

# Speed comparison (approximate times)
system.time(llmdist(mu1, Sigma1, mu2, Sigma2))           # ~0.001s ⚡
system.time(llmdist(mu1, Sigma1, mu2, Sigma2, "wasserstein2"))  # ~0.05s  
system.time(llmdist(mu1, Sigma1, mu2, Sigma2, "fisher_rao"))    # ~2-10s 
```

**Result: 50x speedup for large-scale applications!**

## 🎯 When to Use Each Method

| **Speed Priority** | **Accuracy Priority** | **Bounded Similarity** |
|-------------------|----------------------|----------------------|
| `llmdist()` (default) | `"wasserstein2"` | `"hellinger"` |
| High-dimensional | Optimal transport | Similarity ∈ [0,1] |
| Real-time apps | Theoretical work | Pattern recognition |

## 🧰 Main Functions

- **`llmdist()`** - Main function (fast LRT trace default)
- **`compare_distances()`** - Compare all methods at once
- **Individual methods**: `wasserstein2_distance()`, `hellinger_distance()`, `fisher_rao_distance()`, etc.

## 🔬 Real-World Applications

### 1. LLM Embedding Analysis
```r
# Compare fine-tuned model embeddings  
embedding_dist <- llmdist(model1_stats$mu, model1_stats$Sigma,
                         model2_stats$mu, model2_stats$Sigma)
```

### 2. High-Dimensional Clustering
```r
# Fast pairwise distances for 50 distributions
distances <- matrix(0, n_dists, n_dists)
for(i in 1:(n_dists-1)) {
  for(j in (i+1):n_dists) {
    distances[i,j] <- llmdist(dists[[i]]$mu, dists[[i]]$Sigma,
                             dists[[j]]$mu, dists[[j]]$Sigma)
  }
}
hc <- hclust(as.dist(distances))
```

### 3. Model Parameter Comparison
```r
# Compare neural network layer statistics
layer_similarity <- llmdist(layer1_mu, layer1_cov, layer2_mu, layer2_cov)
```

## 📖 Learn More

- **📝 [Blog Post](https://svanteE.github.io/llmdist/)** - Detailed introduction and examples
- **📚 Documentation** - `?llmdist` for function help
- **🐛 Issues** - [GitHub Issues](https://github.com/svanteE/llmdist/issues)

## 🤝 Citation

If you use llmdist in your research, please cite:

```bibtex
@misc{llmdist2026,
  title = {llmdist: Fast Distance Computation for Multivariate Normal Distributions},
  author = {Svante Eriksen},
  year = {2026},
  url = {https://github.com/svanteE/llmdist}
}
```

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
