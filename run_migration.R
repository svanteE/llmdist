# Migrate packages from R 4.5.0 to R 4.5.2

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install devtools if not available (needed for GitHub packages)
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools", dependencies = TRUE)
}

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
    
    # Function to check if package is available on CRAN
    is_on_cran <- function(pkg_name) {
      tryCatch({
        available.packages(repos = getOption("repos"))
        pkg_name %in% rownames(available.packages(repos = getOption("repos")))
      }, error = function(e) FALSE)
    }
    
    # Function to get GitHub repo from package info
    get_github_repo <- function(pkg_name, old_lib_path) {
      desc_file <- file.path(old_lib_path, pkg_name, "DESCRIPTION")
      if (file.exists(desc_file)) {
        desc_content <- readLines(desc_file)
        
        # Look for RemoteType: github
        remote_type <- grep("^RemoteType:", desc_content, value = TRUE)
        if (length(remote_type) > 0 && grepl("github", remote_type, ignore.case = TRUE)) {
          # Look for RemoteUsername and RemoteRepo
          username <- grep("^RemoteUsername:", desc_content, value = TRUE)
          repo <- grep("^RemoteRepo:", desc_content, value = TRUE)
          
          if (length(username) > 0 && length(repo) > 0) {
            username <- sub("^RemoteUsername:\\s*", "", username)
            repo <- sub("^RemoteRepo:\\s*", "", repo)
            return(paste0(username, "/", repo))
          }
        }
        
        # Look for URL field with github.com
        url_lines <- grep("^URL:", desc_content, value = TRUE)
        for (url_line in url_lines) {
          if (grepl("github.com", url_line)) {
            # Extract github repo from URL
            github_match <- regmatches(url_line, regexpr("github\\.com/[^/]+/[^/,\\s]+", url_line))
            if (length(github_match) > 0) {
              return(sub("github\\.com/", "", github_match))
            }
          }
        }
      }
      return(NULL)
    }
    
    # Separate CRAN and GitHub packages
    cran_packages <- c()
    github_packages <- c()
    
    for (pkg in to_install) {
      cat("Checking", pkg, "... ")
      if (is_on_cran(pkg)) {
        cat("CRAN\n")
        cran_packages <- c(cran_packages, pkg)
      } else {
        github_repo <- get_github_repo(pkg, old_lib)
        if (!is.null(github_repo)) {
          cat("GitHub:", github_repo, "\n")
          github_packages <- c(github_packages, github_repo)
        } else {
          cat("Unknown source, trying CRAN\n")
          cran_packages <- c(cran_packages, pkg)
        }
      }
    }
    
    # Install CRAN packages
    if (length(cran_packages) > 0) {
      cat("\nInstalling", length(cran_packages), "CRAN packages...\n")
      install.packages(cran_packages, dependencies = TRUE)
    }
    
    # Install GitHub packages
    if (length(github_packages) > 0) {
      cat("\nInstalling", length(github_packages), "GitHub packages...\n")
      library(devtools)
      for (github_pkg in github_packages) {
        cat("Installing", github_pkg, "from GitHub...\n")
        tryCatch({
          install_github(github_pkg, dependencies = TRUE, upgrade = "never")
        }, error = function(e) {
          cat("Failed to install", github_pkg, "- Error:", e$message, "\n")
        })
      }
    }
    
    cat("Installation complete!\n")
  } else {
    cat("All packages are already available.\n")
  }
  
} else {
  cat("Old R library not found. Installing common development packages instead.\n")
  
  # Install essential CRAN packages
  essential_packages <- c("devtools", "roxygen2", "testthat", "usethis", "pkgdown",
                         "knitr", "rmarkdown", "dplyr", "ggplot2", "MASS")
  install.packages(essential_packages, dependencies = TRUE)
  
  # Install common GitHub packages for development
  library(devtools)
  github_packages <- c(
    "r-lib/covr",           # Code coverage
    "hadley/emo",           # Emoji support
    "thomasp85/patchwork"   # Combining ggplot2 plots
  )
  
  cat("Installing common GitHub development packages...\n")
  for (github_pkg in github_packages) {
    cat("Installing", github_pkg, "from GitHub...\n")
    tryCatch({
      install_github(github_pkg, dependencies = TRUE, upgrade = "never")
    }, error = function(e) {
      cat("Failed to install", github_pkg, "- Error:", e$message, "\n")
    })
  }
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