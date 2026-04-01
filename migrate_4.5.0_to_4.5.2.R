# Migrate packages from R 4.5.0 to R 4.5.2
# Run this in RStudio after switching to R 4.5.2

# Check current R version
cat("Current R version:", R.version.string, "\n")

# Path to old library (R 4.5.0)
old_lib <- "C:/Users/svante/AppData/Local/Programs/R/R-4.5.0/library"

# Path to new library (R 4.5.2) 
new_lib <- .libPaths()[1]

cat("Old library:", old_lib, "\n")
cat("New library:", new_lib, "\n")

# Check if old library exists
if (dir.exists(old_lib)) {
  # Get packages from old installation (excluding base packages)
  old_packages <- list.files(old_lib)
  base_packages <- c("base", "boot", "class", "cluster", "codetools", "compiler",
                     "datasets", "foreign", "graphics", "grDevices", "grid",
                     "KernSmooth", "lattice", "MASS", "Matrix", "methods", "mgcv",
                     "nlme", "nnet", "parallel", "rpart", "spatial", "splines",
                     "stats", "stats4", "survival", "tcltk", "tools", "translations",
                     "utils")
  
  # Filter out base packages  
  user_packages <- setdiff(old_packages, base_packages)
  
  cat("Found", length(user_packages), "user packages to migrate:\n")
  print(user_packages)
  
  # Check which are already installed
  currently_installed <- installed.packages()[,"Package"]
  to_install <- setdiff(user_packages, currently_installed)
  
  cat("\nPackages that need to be installed:", length(to_install), "\n")
  
  if (length(to_install) > 0) {
    cat("Installing packages...\n")
    install.packages(to_install, dependencies = TRUE)
    cat("Installation complete!\n")
  } else {
    cat("All packages are already available.\n")
  }
  
} else {
  cat("Old R library not found. Installing common development packages instead.\n")
  # Install essential packages
  essential_packages <- c("devtools", "roxygen2", "testthat", "usethis", "pkgdown",
                         "knitr", "rmarkdown", "dplyr", "ggplot2", "MASS")
  install.packages(essential_packages, dependencies = TRUE)
}

# Verify key packages are available
key_packages <- c("devtools", "roxygen2", "testthat")
cat("\nVerifying key development packages:\n")
for (pkg in key_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "is available\n")
  } else {
    cat("✗", pkg, "needs to be installed\n")
    install.packages(pkg)
  }
}

cat("\nMigration complete! R version:", R.version.string, "\n")