# R Package Migration Script
# Run this in RStudio after switching to the new R version

# Check current R version
cat("Current R version:", R.version.string, "\n")

# Method 1: If you saved your package list
if (file.exists("my_packages.csv")) {
  old_packages <- read.csv("my_packages.csv", stringsAsFactors = FALSE)$Package
  cat("Found saved package list with", length(old_packages), "packages\n")
} else {
  # Method 2: Common packages for your R package development workflow
  cat("Using common package development packages\n")
  old_packages <- c(
    # Essential development packages
    "devtools", "roxygen2", "testthat", "usethis", "pkgdown",
    
    # Documentation and reporting
    "knitr", "rmarkdown", "bookdown",
    
    # Data manipulation and visualization  
    "dplyr", "ggplot2", "tidyr", "readr", "stringr",
    
    # Statistical packages
    "MASS", "lattice", "Matrix", "mgcv",
    
    # Your specific domain (geodesics/distances)
    "pracma", "numDeriv", "optimx"
  )
}

# Check which packages are already installed
installed <- installed.packages()[,"Package"]
to_install <- setdiff(old_packages, installed)

cat("Packages to install:", length(to_install), "\n")
if (length(to_install) > 0) {
  cat("Installing packages:\n")
  print(to_install)
  
  # Install packages
  install.packages(to_install, dependencies = TRUE)
  
  cat("\nInstallation complete!\n")
} else {
  cat("All packages are already installed.\n")
}

# Verify installation
cat("\nVerifying key development packages:\n")
key_packages <- c("devtools", "roxygen2", "testthat")
for (pkg in key_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "is available\n")
  } else {
    cat("✗", pkg, "is NOT available\n")
  }
}

# Display session info
cat("\nSession info:\n")
sessionInfo()