#' Validate Thermos inputs
#'
#' Checks whether required files, folders, and expected vector fields exist.
#'
#' @param lc_path Path to land-cover GeoPackage.
#' @param obs_path Path to obstacles GeoPackage.
#' @param dem_dir Directory with DEM rasters.
#' @param dsm_dir Optional directory with DSM rasters.
#' @param svf_dir Optional directory with SVF rasters.
#' @param lc_dir Optional directory with rasterized land-cover outputs.
#' @param met_xlsx Optional meteorological Excel file.
#'
#' @return A list with `ok`, `messages`, and `details`.
#' @export
thermos_check_inputs <- function(lc_path = NULL,
                                obs_path = NULL,
                                dem_dir = NULL,
                                dsm_dir = NULL,
                                svf_dir = NULL,
                                lc_dir = NULL,
                                met_xlsx = NULL) {
  messages <- character()
  details <- list()
  ok <- TRUE

  add_message <- function(msg, is_ok = TRUE) {
    if (!is_ok) {
      ok <<- FALSE
    }
    messages <<- c(messages, msg)
  }

  if (!is.null(lc_path)) {
    if (!file.exists(lc_path)) {
      add_message(paste("Missing land-cover vector:", lc_path), FALSE)
    } else {
      lc_vec <- terra::vect(lc_path)
      required <- c("lc_class", "albedo", "emissivity", "z0", "et_scale")
      missing <- setdiff(required, names(lc_vec))
      details$landcover_fields <- names(lc_vec)
      if (length(missing) > 0) {
        add_message(
          paste("Land-cover vector is missing fields:", paste(missing, collapse = ", ")),
          FALSE
        )
      } else {
        add_message("Land-cover vector looks valid.")
      }
    }
  }

  if (!is.null(obs_path)) {
    if (!file.exists(obs_path)) {
      add_message(paste("Missing obstacles vector:", obs_path), FALSE)
    } else {
      obs_vec <- terra::vect(obs_path)
      required <- c(
        "obs_type", "lai", "canopy_cover", "k_ext",
        "wall_albedo", "wall_emissivity"
      )
      missing <- setdiff(required, names(obs_vec))
      details$obstacle_fields <- names(obs_vec)
      if (length(missing) > 0) {
        add_message(
          paste("Obstacles vector is missing fields:", paste(missing, collapse = ", ")),
          FALSE
        )
      } else {
        add_message("Obstacles vector looks valid.")
      }
    }
  }

  for (entry in list(
    list(path = dem_dir, label = "DEM", pattern = "\\.tif$"),
    list(path = dsm_dir, label = "DSM", pattern = "\\.tif$"),
    list(path = svf_dir, label = "SVF", pattern = "\\.tif$")
  )) {
    if (is.null(entry$path)) {
      next
    }
    if (!dir.exists(entry$path)) {
      add_message(paste(entry$label, "directory not found:", entry$path), FALSE)
      next
    }
    count <- length(list.files(entry$path, pattern = entry$pattern, full.names = TRUE))
    details[[paste0(tolower(entry$label), "_file_count")]] <- count
    if (count == 0) {
      add_message(paste("No", entry$label, "rasters found in:", entry$path), FALSE)
    } else {
      add_message(paste(entry$label, "directory contains", count, "raster(s)."))
    }
  }

  if (!is.null(lc_dir)) {
    required_layers <- c(
      "albedo", "emis", "z0", "et_scale", "gai",
      "k_ext", "wall_emis", "wall_albedo"
    )
    if (!dir.exists(lc_dir)) {
      add_message(paste("Rasterized land-cover directory not found:", lc_dir), FALSE)
    } else {
      available <- list.files(lc_dir, pattern = "\\.tif$", full.names = FALSE)
      details$lc_raster_files <- available
      missing_prefixes <- required_layers[
        !vapply(required_layers, function(prefix) {
          any(startsWith(available, paste0(prefix, "_")))
        }, logical(1))
      ]
      if (length(missing_prefixes) > 0) {
        add_message(
          paste(
            "Rasterized land-cover directory is missing expected layers:",
            paste(missing_prefixes, collapse = ", ")
          ),
          FALSE
        )
      } else {
        add_message("Rasterized land-cover directory looks valid.")
      }
    }
  }

  if (!is.null(met_xlsx)) {
    if (!file.exists(met_xlsx)) {
      add_message(paste("Meteorological Excel file not found:", met_xlsx), FALSE)
    } else {
      cols <- names(readxl::read_xlsx(met_xlsx, n_max = 0))
      required <- c("date", "hour_utc", "Ta", "Td", "u10", "v10", "ssrd", "strd", "slhf")
      missing <- setdiff(required, cols)
      details$meteo_columns <- cols
      if (length(missing) > 0) {
        add_message(
          paste("Meteorological Excel is missing columns:", paste(missing, collapse = ", ")),
          FALSE
        )
      } else {
        add_message("Meteorological Excel looks valid.")
      }
    }
  }

  list(ok = ok, messages = messages, details = details)
}
