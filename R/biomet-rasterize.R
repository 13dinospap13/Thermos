#' Rasterize land-cover and obstacle attributes
#'
#' Converts vector attributes into modeling rasters aligned to DEM grids.
#'
#' @param lc_path Path to land-cover GeoPackage.
#' @param obs_path Path to obstacles GeoPackage.
#' @param dem_dir Directory with DEM rasters.
#' @param out_dir Output directory for rasterized layers.
#' @param veg_types Obstacle types treated as vegetation.
#'
#' @return A data frame summarizing written rasters by plot suffix.
#' @export
biomet_rasterize_landcover <- function(lc_path,
                                       obs_path,
                                       dem_dir,
                                       out_dir,
                                       veg_types = c("tree", "shrub", "hedge")) {
  biomet_dir_must_exist(dem_dir, "DEM")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  lc_vec <- terra::vect(lc_path)
  obs_vec <- terra::vect(obs_path)
  obs_vec$gai <- obs_vec$lai * obs_vec$canopy_cover

  veg_vec <- obs_vec[obs_vec$obs_type %in% veg_types, ]
  bldg_vec <- obs_vec[obs_vec$obs_type == "building", ]

  dem_files <- list.files(dem_dir, pattern = "\\.tif$", full.names = TRUE)
  if (length(dem_files) == 0) {
    stop("No DEM files found in: ", dem_dir, call. = FALSE)
  }

  results <- data.frame(
    plot = character(),
    status = character(),
    rasters_written = integer(),
    stringsAsFactors = FALSE
  )

  for (dem_path in dem_files) {
    suffix <- biomet_extract_suffix(dem_path)
    dem <- terra::rast(dem_path)

    if (terra::crs(lc_vec) != terra::crs(dem)) {
      lc_r <- terra::project(lc_vec, terra::crs(dem))
      veg_r <- terra::project(veg_vec, terra::crs(dem))
      bldg_r <- terra::project(bldg_vec, terra::crs(dem))
    } else {
      lc_r <- lc_vec
      veg_r <- veg_vec
      bldg_r <- bldg_vec
    }

    terra::writeRaster(
      biomet_rasterize_attr(lc_r, dem, "lc_class"),
      file.path(out_dir, paste0("landcover_", suffix, ".tif")),
      overwrite = TRUE,
      datatype = "INT1U"
    )
    terra::writeRaster(
      biomet_rasterize_attr(lc_r, dem, "albedo"),
      file.path(out_dir, paste0("albedo_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_rasterize_attr(lc_r, dem, "emissivity"),
      file.path(out_dir, paste0("emis_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_rasterize_attr(lc_r, dem, "z0"),
      file.path(out_dir, paste0("z0_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_rasterize_attr(lc_r, dem, "et_scale"),
      file.path(out_dir, paste0("et_scale_", suffix, ".tif")),
      overwrite = TRUE
    )

    lai_r <- biomet_fill_zero_in_mask(biomet_rasterize_attr(veg_r, dem, "lai"), dem)
    cc_r <- biomet_fill_zero_in_mask(biomet_rasterize_attr(veg_r, dem, "canopy_cover"), dem)

    terra::writeRaster(
      lai_r,
      file.path(out_dir, paste0("lai_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      cc_r,
      file.path(out_dir, paste0("canopy_cover_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_fill_zero_in_mask(biomet_rasterize_attr(veg_r, dem, "k_ext"), dem),
      file.path(out_dir, paste0("k_ext_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_fill_zero_in_mask(biomet_rasterize_attr(veg_r, dem, "gai"), dem),
      file.path(out_dir, paste0("gai_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_rasterize_attr(bldg_r, dem, "wall_albedo"),
      file.path(out_dir, paste0("wall_albedo_", suffix, ".tif")),
      overwrite = TRUE
    )
    terra::writeRaster(
      biomet_rasterize_attr(bldg_r, dem, "wall_emissivity"),
      file.path(out_dir, paste0("wall_emis_", suffix, ".tif")),
      overwrite = TRUE
    )

    results <- rbind(
      results,
      data.frame(
        plot = suffix,
        status = "ok",
        rasters_written = 11L,
        stringsAsFactors = FALSE
      )
    )
  }

  results
}

