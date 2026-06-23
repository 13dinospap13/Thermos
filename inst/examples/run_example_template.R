library(BIOMET)

lc_path <- "path/to/landcover.gpkg"
obs_path <- "path/to/obstacles.gpkg"
dem_dir <- "path/to/dem_folder"
dsm_dir <- "path/to/dsm_folder"
met_xlsx <- "path/to/met_inputs.xlsx"
lc_dir <- "path/to/output/rasters_for_modeling"
svf_dir <- "path/to/output/svf"
out_dir <- "path/to/output/results"

checks <- biomet_check_inputs(
  lc_path = lc_path,
  obs_path = obs_path,
  dem_dir = dem_dir,
  dsm_dir = dsm_dir,
  met_xlsx = met_xlsx
)

print(checks)

if (isTRUE(checks$ok)) {
  raster_summary <- biomet_rasterize_landcover(
    lc_path = lc_path,
    obs_path = obs_path,
    dem_dir = dem_dir,
    out_dir = lc_dir
  )
  print(raster_summary)

  svf_summary <- biomet_calculate_svf(
    dem_dir = dem_dir,
    dsm_dir = dsm_dir,
    svf_dir = svf_dir
  )
  print(svf_summary)

  thermal_summary <- biomet_thermal_comfort(
    dem_dir = dem_dir,
    dsm_dir = dsm_dir,
    svf_dir = svf_dir,
    lc_dir = lc_dir,
    out_dir = out_dir,
    plot_suffix = "plot01",
    met_xlsx = met_xlsx
  )
  print(thermal_summary)
}

