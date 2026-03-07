# Set working directory to package root
setwd("c:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist")

# Remove old package
try(remove.packages("llmdist"), silent = TRUE)

# Document and install
devtools::document()
devtools::install()

cat("\n=== Package installation complete ===\n")
