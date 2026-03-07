setwd('c:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist')
devtools::load_all(quiet = TRUE)
p <- 2
n_sims <- 200
res <- simulate_fisher_rao_vs_lrt_trace(p, n_sims, seed = 321)
mu1 <- rep(0, p)
S1 <- diag(p)
ratios_trace <- numeric(n_sims)
ratios_det <- numeric(n_sims)
for (i in 1:n_sims) {
  De <- res$De_from_expA[[i]]
  de <- res$de_from_expA[[i]]
  if (is.null(De)) next
  Sig <- tryCatch(solve(De), error = function(e) NULL)
  if (is.null(Sig)) next
  mu2 <- Sig %*% de
  fr <- tryCatch(fisher_rao_distance(mu1, S1, as.vector(mu2), Sig), error = function(e) NA_real_)
  if (is.na(fr)) next
  ratios_trace[i] <- lrt_trace_distance(mu1, S1, as.vector(mu2), Sig) / fr
  ratios_det[i] <- lrt_distance(mu1, S1, as.vector(mu2), Sig) / fr
}
cat('ratio trace mean', mean(ratios_trace, na.rm = TRUE), '\n')
cat('ratio det mean', mean(ratios_det, na.rm = TRUE), '\n')
