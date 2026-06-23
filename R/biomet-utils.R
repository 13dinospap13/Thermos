biomet_extract_suffix <- function(filepath) {
  fname <- tools::file_path_sans_ext(basename(filepath))
  tail(strsplit(fname, "_")[[1]], 1)
}

biomet_list_suffixes <- function(dir_path, pattern = "\\.tif$") {
  if (is.null(dir_path) || !dir.exists(dir_path)) {
    return(character())
  }

  files <- list.files(dir_path, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) {
    return(character())
  }

  unique(vapply(files, biomet_extract_suffix, character(1)))
}

biomet_detect_common_suffixes <- function(dem_dir,
                                          dsm_dir = NULL,
                                          svf_dir = NULL,
                                          lc_dir = NULL) {
  suffix_sets <- list(
    DEM = biomet_list_suffixes(dem_dir),
    DSM = biomet_list_suffixes(dsm_dir),
    SVF = biomet_list_suffixes(svf_dir),
    LC = biomet_list_suffixes(lc_dir)
  )
  suffix_sets <- suffix_sets[lengths(suffix_sets) > 0]

  if (length(suffix_sets) == 0) {
    return(character())
  }

  sort(Reduce(intersect, suffix_sets))
}

biomet_detect_available_suffixes <- function(dem_dir,
                                             dsm_dir = NULL,
                                             svf_dir = NULL,
                                             lc_dir = NULL) {
  sort(unique(c(
    biomet_list_suffixes(dem_dir),
    biomet_list_suffixes(dsm_dir),
    biomet_list_suffixes(svf_dir),
    biomet_list_suffixes(lc_dir)
  )))
}

biomet_normalize_plot_suffix_input <- function(plot_suffix) {
  if (is.null(plot_suffix)) {
    return(character())
  }

  values <- as.character(plot_suffix)
  if (length(values) == 1 && grepl(",", values, fixed = TRUE)) {
    values <- strsplit(values, ",", fixed = TRUE)[[1]]
  }

  values <- trimws(values)
  values[nzchar(values)]
}

biomet_resolve_plot_suffixes <- function(plot_suffix,
                                         dem_dir,
                                         dsm_dir = NULL,
                                         svf_dir = NULL,
                                         lc_dir = NULL) {
  requested <- biomet_normalize_plot_suffix_input(plot_suffix)
  requested_lower <- tolower(requested)

  common_suffixes <- biomet_detect_common_suffixes(
    dem_dir = dem_dir,
    dsm_dir = dsm_dir,
    svf_dir = svf_dir,
    lc_dir = lc_dir
  )
  available_suffixes <- biomet_detect_available_suffixes(
    dem_dir = dem_dir,
    dsm_dir = dsm_dir,
    svf_dir = svf_dir,
    lc_dir = lc_dir
  )

  if (length(available_suffixes) == 0) {
    return(requested)
  }

  if (length(requested) == 0 || all(requested_lower %in% c("auto", "__auto__"))) {
    if (length(common_suffixes) == 1) {
      return(common_suffixes)
    }
    if (length(available_suffixes) == 1) {
      return(available_suffixes)
    }
    stop(
      "Multiple plot suffixes are available. Please select one plot or choose all. ",
      "Available suffixes: ", paste(available_suffixes, collapse = ", "),
      call. = FALSE
    )
  }

  if (length(requested) == 1 && requested_lower %in% c("all", "__all__")) {
    if (length(common_suffixes) > 0) {
      return(common_suffixes)
    }
    return(available_suffixes)
  }

  matched <- requested[requested %in% available_suffixes]
  missing <- setdiff(requested, available_suffixes)

  if (length(missing) == 0 && length(matched) > 0) {
    return(unique(matched))
  }

  if (length(requested) == 1 && length(common_suffixes) == 1) {
    message(
      "plot_suffix '", requested, "' not found; using detected suffix '",
      common_suffixes[[1]], "'."
    )
    return(common_suffixes[[1]])
  }

  stop(
    "plot_suffix '", paste(requested, collapse = ", "), "' does not match the available rasters. ",
    "Available suffixes: ", paste(available_suffixes, collapse = ", "),
    call. = FALSE
  )
}

biomet_resolve_plot_suffix <- function(plot_suffix,
                                       dem_dir,
                                       dsm_dir = NULL,
                                       svf_dir = NULL,
                                       lc_dir = NULL) {
  resolved <- biomet_resolve_plot_suffixes(
    plot_suffix = plot_suffix,
    dem_dir = dem_dir,
    dsm_dir = dsm_dir,
    svf_dir = svf_dir,
    lc_dir = lc_dir
  )

  if (length(resolved) != 1) {
    stop(
      "Expected one plot suffix but got: ",
      paste(resolved, collapse = ", "),
      call. = FALSE
    )
  }

  resolved[[1]]
}

biomet_rasterize_attr <- function(vec, ref, field) {
  r <- terra::rasterize(vec, ref, field = field, background = NA, touches = TRUE)
  terra::mask(r, ref)
}

biomet_fill_zero_in_mask <- function(r, dem) {
  dem_vals <- terra::values(dem, mat = FALSE)
  dem_vals[is.nan(dem_vals)] <- NA
  rv <- terra::values(r, mat = FALSE)
  rv[is.na(rv) & !is.na(dem_vals)] <- 0
  rv[is.na(dem_vals)] <- NA
  terra::values(r) <- rv
  r
}

biomet_fill_default_in_mask <- function(r, dem, default) {
  dem_vals <- terra::values(dem, mat = FALSE)
  dem_vals[is.nan(dem_vals)] <- NA
  rv <- terra::values(r, mat = FALSE)
  rv[is.nan(rv)] <- NA
  rv[is.na(rv) & !is.na(dem_vals)] <- default
  rv[is.na(dem_vals)] <- NA
  terra::values(r) <- rv
  r
}

biomet_make_const_rast <- function(ref, value) {
  r <- terra::rast(ref)
  vals <- rep(value, terra::ncell(r))
  ref_vals <- terra::values(ref, mat = FALSE)
  ref_vals[is.nan(ref_vals)] <- NA
  vals[is.na(ref_vals)] <- NA
  terra::values(r) <- vals
  r
}

biomet_first_match <- function(dir_path, pattern, label) {
  matches <- list.files(dir_path, pattern = pattern, full.names = TRUE)
  if (length(matches) == 0) {
    stop(label, " not found for pattern: ", pattern, call. = FALSE)
  }
  matches[1]
}

biomet_dir_must_exist <- function(path, label) {
  if (!dir.exists(path)) {
    stop(label, " directory not found: ", path, call. = FALSE)
  }
}
