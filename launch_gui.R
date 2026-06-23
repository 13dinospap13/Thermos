if (!requireNamespace("BIOMET", quietly = TRUE)) {
  stop("The BIOMET package is not installed yet. Run source('install.R') first.", call. = FALSE)
}

library(BIOMET)
biomet_gui()

