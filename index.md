---
layout: default
---

# llmdist: Fast Distance Computation for Multivariate Normal Distributions

Fast and comprehensive distance computation between multivariate normal distributions with a 50x speedup over traditional methods.

## 🎯 Why llmdist?

- **⚡ 50x faster** than traditional Wasserstein-2 distance
- **🔬 First implementation** of Fisher-Rao distance for multivariate normals  
- **📊 8 different distance measures** for comprehensive analysis
- **🎛️ Simple API** - one function for all methods

## Installation

```r
# Install from GitHub
devtools::install_github("svanteE/llmdist")
library(llmdist)
```

## Quick Start

```r
# Define two distributions
mu1 <- c(0, 0); Sigma1 <- diag(2)
mu2 <- c(1, 1); Sigma2 <- matrix(c(2, 0.5, 0.5, 1), 2, 2)

# Fast default (LRT trace)
llmdist(mu1, Sigma1, mu2, Sigma2)

# Compare all methods
compare_distances(mu1, Sigma1, mu2, Sigma2)
```

## Latest Posts

{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }}) - {{ post.date | date: "%B %d, %Y" }}
{% endfor %}