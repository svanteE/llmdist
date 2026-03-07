# Test the LRT vs Fisher-Rao comparison plot

# Set working directory to package root
setwd("C:/Users/svante/OneDrive - Aalborg Universitet/geodesic/llmdist")

# Load the package
devtools::load_all(".")

# Run the example
plot_distance_comparison_example(n_steps = 50)
