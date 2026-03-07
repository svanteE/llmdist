setwd('c:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist')
devtools::load_all(quiet = TRUE)
p <- 2
n_sims <- 200
res <- simulate_fisher_rao_vs_lrt_trace(p, n_sims, seed = 321)
frA <- res$fisher_rao_from_A
lrt <- res$lrt_trace_distance
mu1 <- rep(0, p)
S1 <- diag(p)
fr_true <- numeric(n_sims)
for (i in 1:n_sims) {
  De <- res$De_from_expA[[i]]
  de <- res$de_from_expA[[i]]
  if (is.null(De) || any(is.na(De)) || any(!is.finite(De))) {
    fr_true[i] <- NA_real_
    next
  }
  Sig <- tryCatch(solve(De), error = function(e) NULL)
  if (is.null(Sig)) {
    fr_true[i] <- NA_real_
    next
  }
  mu2 <- Sig %*% de
  fr_true[i] <- tryCatch(fisher_rao_distance(mu1, S1, as.vector(mu2), Sig), error = function(e) NA_real_)
}
cat('n valid', sum(is.finite(fr_true)), '\n')
cat('ratio using FR_A mean', mean(lrt / frA, na.rm = TRUE), '\n')
cat('ratio using FR_true mean', mean(lrt / fr_true, na.rm = TRUE), '\n')
cat('mean FR_A', mean(frA, na.rm = TRUE), 'FR_true', mean(fr_true, na.rm = TRUE), 'LRT', mean(lrt, na.rm = TRUE), '\n')
