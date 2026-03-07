source('c:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist/R/simulate_geodesic.R')
source('c:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist/R/distances.R')
library(expm)

set.seed(108)
p <- 100

# First simulation
B <- matrix(rnorm(p*p), p, p)
x <- rnorm(p)

A <- matrix(0, 2*p+1, 2*p+1)
A[1:p, (p+2):(2*p+1)] <- B
A[1:p, p+1] <- x
A[p+1, (p+2):(2*p+1)] <- -x
A[(p+2):(2*p+1), 1:p] <- 0
A[(p+2):(2*p+1), p+1] <- -x
A[(p+2):(2*p+1), (p+2):(2*p+1)] <- -B

cat("A matrix condition number:", kappa(A), "\n")
cat("A eigenvalues (min, max):", min(abs(eigen(A, only.values=TRUE)$values)), 
    max(abs(eigen(A, only.values=TRUE)$values)), "\n")

expA <- expm(A)
De <- expA[1:p, (p+2):(2*p+1)]

cat("De before symmetrize - is symmetric?", isTRUE(all.equal(De, t(De))), "\n")
De <- 0.5*(De + t(De))

evals_De <- eigen(De, symmetric = TRUE, only.values = TRUE)$values
cat("De eigenvalues (min, max):", min(evals_De), max(evals_De), "\n")
cat("Number of negative eigenvalues:", sum(evals_De < 0), "\n")
cat("Number of near-zero eigenvalues (<1e-8):", sum(evals_De < 1e-8), "\n")

# Test SPD check
.is_spd <- function(M, tol = 1e-8) {
  if (!is.matrix(M)) return(FALSE)
  if (!isTRUE(all.equal(M, t(M)))) return(FALSE)
  vals <- tryCatch(eigen(M, symmetric = TRUE, only.values = TRUE)$values,
                   error = function(e) return(NULL))
  if (is.null(vals)) return(FALSE)
  all(is.finite(vals)) && all(vals > tol)
}

cat("De is SPD (tol=1e-8)?", .is_spd(De, tol=1e-8), "\n")
cat("De is SPD (tol=1e-10)?", .is_spd(De, tol=1e-10), "\n")
