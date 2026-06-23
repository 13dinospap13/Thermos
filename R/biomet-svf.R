biomet_compute_svf_matrix <- function(dsm_r,
                                      dem_r,
                                      num_directions,
                                      max_distance,
                                      observer_height) {
  r <- terra::res(dsm_r)[1]
  dsm_mat <- as.matrix(dsm_r, wide = TRUE)
  dem_mat <- as.matrix(dem_r, wide = TRUE)
  nr <- nrow(dsm_mat)
  nc <- ncol(dsm_mat)
  svf_mat <- matrix(NA_real_, nrow = nr, ncol = nc)
  max_steps <- ceiling(max_distance / r)
  angles <- seq(0, 2 * pi, length.out = num_directions + 1)[-(num_directions + 1)]
  angle_step <- 2 * pi / num_directions

  for (row in seq_len(nr)) {
    for (col in seq_len(nc)) {
      dem_h <- dem_mat[row, col]
      if (is.na(dem_h)) {
        next
      }
      h0 <- dem_h + observer_height
      max_angle <- 0
      jitter <- stats::runif(1, 0, angle_step)
      angles_px <- angles + jitter

      for (az in angles_px) {
        dx <- sin(az)
        dy <- -cos(az)

        for (s in seq_len(max_steps)) {
          cr <- round(row + dy * s)
          cc <- round(col + dx * s)
          if (cr < 1 || cr > nr || cc < 1 || cc > nc) {
            break
          }
          h_obs <- dsm_mat[cr, cc]
          if (is.na(h_obs)) {
            break
          }
          elev_angle <- atan2(h_obs - h0, r * s)
          if (elev_angle > max_angle) {
            max_angle <- elev_angle
          }
        }
      }
      svf_mat[row, col] <- 1 - sin(max_angle)
    }
  }

  out <- terra::setValues(terra::rast(dsm_r), as.vector(t(svf_mat)))
  terra::mask(out, dem_r)
}

#' Calculate Sky View Factor rasters
#'
#' Matches DEM and DSM rasters by suffix and computes one SVF raster per plot.
#'
#' @param dem_dir Directory with DEM rasters.
#' @param dsm_dir Directory with DSM rasters.
#' @param svf_dir Output directory for SVF rasters.
#' @param num_directions Number of ray directions.
#' @param max_distance Maximum search distance in meters.
#' @param observer_height Observer height above ground in meters.
#'
#' @return A summary data frame with plot status and SVF statistics.
#' @export
biomet_calculate_svf <- function(dem_dir,
                                 dsm_dir,
                                 svf_dir,
                                 num_directions = 72,
                                 max_distance = 30,
                                 observer_height = 1.5) {
  biomet_dir_must_exist(dem_dir, "DEM")
  biomet_dir_must_exist(dsm_dir, "DSM")
  dir.create(svf_dir, showWarnings = FALSE, recursive = TRUE)

  dem_files <- list.files(dem_dir, pattern = "\\.tif$", full.names = TRUE)
  if (length(dem_files) == 0) {
    stop("No DEM files found in: ", dem_dir, call. = FALSE)
  }

  results <- data.frame(
    plot = character(),
    status = character(),
    svf_min = numeric(),
    svf_mean = numeric(),
    svf_max = numeric(),
    stringsAsFactors = FALSE
  )

  for (dem_path in dem_files) {
    suffix <- biomet_extract_suffix(dem_path)
    dsm_candidates <- list.files(
      dsm_dir,
      pattern = paste0(suffix, "\\.tif$"),
      full.names = TRUE
    )

    if (length(dsm_candidates) == 0) {
      results <- rbind(
        results,
        data.frame(
          plot = suffix,
          status = "skipped - no DSM match",
          svf_min = NA_real_,
          svf_mean = NA_real_,
          svf_max = NA_real_,
          stringsAsFactors = FALSE
        )
      )
      next
    }

    dem <- terra::rast(dem_path)
    dsm <- terra::rast(dsm_candidates[1])

    if (!all(terra::res(dsm) == terra::res(dem)) ||
        !all(dim(dsm)[1:2] == dim(dem)[1:2])) {
      dsm <- terra::resample(dsm, dem, method = "bilinear")
    }

    svf <- biomet_compute_svf_matrix(
      dsm_r = dsm,
      dem_r = dem,
      num_directions = num_directions,
      max_distance = max_distance,
      observer_height = observer_height
    )

    out_path <- file.path(svf_dir, paste0("svf_", suffix, ".tif"))
    terra::writeRaster(svf, out_path, overwrite = TRUE)
    stats <- terra::global(svf, c("min", "mean", "max"), na.rm = TRUE)

    results <- rbind(
      results,
      data.frame(
        plot = suffix,
        status = "ok",
        svf_min = round(stats[1, "min"], 3),
        svf_mean = round(stats[1, "mean"], 3),
        svf_max = round(stats[1, "max"], 3),
        stringsAsFactors = FALSE
      )
    )
  }

  utils::write.csv(results, file.path(svf_dir, "svf_batch_summary.csv"), row.names = FALSE)
  results
}

