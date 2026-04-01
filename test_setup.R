# Test R Package Development Workflow
# Run this to verify everything is working

# Load essential packages
library(devtools)
library(roxygen2)
library(testthat)

# Test package operations in your current package
cat("Testing package development tools...\n")

# Check if we're in a package directory
if (file.exists("DESCRIPTION")) {
  cat("✓ Found DESCRIPTION file - this is an R package\n")
  
  # Test documentation
  tryCatch({
    document()
    cat("✓ roxygen2::document() works\n")
  }, error = function(e) {
    cat("✗ Error with document():", e$message, "\n")
  })
  
  # Test package check
  tryCatch({
    check(manual = FALSE, cran = FALSE)
    cat("✓ devtools::check() works\n")
  }, error = function(e) {
    cat("✗ Error with check():", e$message, "\n")
  })
  
  # Test tests
  if (dir.exists("tests")) {
    tryCatch({
      test()
      cat("✓ testthat::test() works\n")
    }, error = function(e) {
      cat("✗ Error with test():", e$message, "\n")
    })
  }
  
} else {
  cat("ℹ Not in a package directory, skipping package-specific tests\n")
}

cat("\nSetup complete! Your R package development environment is ready.\n")