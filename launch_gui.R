if (!requireNamespace("Thermos", quietly = TRUE)) {
  stop("The Thermos package is not installed yet. Run source('install.R') first.", call. = FALSE)
}

library(Thermos)
thermos_gui()
