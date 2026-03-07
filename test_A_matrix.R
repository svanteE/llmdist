devtools::load_all()

mu1 <- c(0, 0, 0)
Sigma1 <- diag(1, 3)
mu2 <- c(1, 1, 1)
Sigma2 <- matrix(c(1, 0.1, 0.1, .1, 1, .1, .1, .1, 1), 3, 3)

U <- chol(solve(Sigma1))
mu_transformed <- U %*% (mu2 - mu1)
Sigma_transformed <- U %*% Sigma2 %*% t(U)
De <- solve(Sigma_transformed)
de <- De %*% mu_transformed

p <- length(de)
Dei <- solve(De)
mu <- Dei %*% de
tau <- as.numeric(t(mu) %*% de)

cat("mu =", mu, "\n")
cat("tau =", tau, "\n")

Phi_0 <- -de %*% t(mu) / 2
gamma_0 <- -(1 + tau/2) * mu
Gamma_0 <- Dei + (1 + tau/4) * mu %*% t(mu)

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

cat("Lambda_0 eigenvalues:", eigen(Lambda_0)$values, "\n")
cat("Is Lambda_0 symmetric?", isSymmetric(Lambda_0), "\n")

# Try computing logm
A <- expm::logm(Lambda_0)
cat("A matrix:\n")
print(A)

# Compute distance
distance <- sqrt(sum(A^2) / 2)
cat("Distance:", distance, "\n")
