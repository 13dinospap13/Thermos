# Thermos Manual

## Purpose

Thermos is an `R` package and GUI for a reduced local workflow in outdoor
bioclimatic preprocessing and thermal-comfort mapping.

The package is organized around three scientific steps:

1. Rasterize land-cover and obstacle attributes to the DEM grid.
2. Compute Sky View Factor (`SVF`) from `DEM` and `DSM`.
3. Compute thermal outputs such as `Tmrt`, `PET`, `mPET`, `PMV`, `SET`, `UTCI`,
   and `UTCI_class`.

The GUI is only an interface. The scientific logic lives in the package
functions.

## What Is Inside The Package

### Core functions

- `thermos_rasterize_landcover()`
- `thermos_calculate_svf()`
- `thermos_thermal_comfort()`
- `thermos_run_pipeline()`

### Validation and helpers

- `thermos_check_inputs()`
- internal utility functions in `R/thermos-utils.R`

### GUI

- `thermos_gui()`

### Repository documentation

- [README.md](../README.md)
- [input_requirements.md](input_requirements.md)
- [install_and_run.md](install_and_run.md)

## Workflow Summary

### Step 1: Rasterization

Function:

```r
thermos_rasterize_landcover(
  lc_path,
  obs_path,
  dem_dir,
  out_dir,
  veg_types = c("tree", "shrub", "hedge")
)
```

What it does:

- reads the land-cover vector and obstacle vector
- aligns them to each DEM raster
- creates modeling rasters for each detected plot suffix

Outputs written per plot:

- `landcover_<plot>.tif`
- `albedo_<plot>.tif`
- `emis_<plot>.tif`
- `z0_<plot>.tif`
- `et_scale_<plot>.tif`
- `lai_<plot>.tif`
- `canopy_cover_<plot>.tif`
- `k_ext_<plot>.tif`
- `gai_<plot>.tif`
- `wall_albedo_<plot>.tif`
- `wall_emis_<plot>.tif`

### Step 2: SVF

Function:

```r
thermos_calculate_svf(
  dem_dir,
  dsm_dir,
  svf_dir,
  num_directions = 72,
  max_distance = 30,
  observer_height = 1.5
)
```

What it does:

- matches DEM and DSM rasters by filename suffix
- estimates sky obstruction in multiple directions
- computes `SVF` as a raster for each detected plot

Outputs written per plot:

- `svf_<plot>.tif`
- `svf_batch_summary.csv`

### Step 3: Thermal comfort

Function:

```r
thermos_thermal_comfort(
  dem_dir,
  dsm_dir,
  svf_dir,
  lc_dir,
  out_dir,
  plot_suffix,
  met_xlsx,
  alpha_k = 0.70,
  eps_p = 0.97,
  Met = 80,
  Clo = 0.9,
  ht = 1.75,
  mbody = 75
)
```

What it does:

- loads one or more plots
- combines meteorology, topography, shading, SVF, and surface properties
- calculates thermal rasters and a summary table for each time step

Main outputs written per plot and time step:

- `Tmrt_<plot>_<timestamp>.tif`
- `PET_<plot>_<timestamp>.tif`
- `mPET_<plot>_<timestamp>.tif`
- `PMV_<plot>_<timestamp>.tif`
- `SET_<plot>_<timestamp>.tif`
- `UTCI_<plot>_<timestamp>.tif`
- `UTCI_class_<plot>_<timestamp>.tif`
- `summary_<plot>.csv`

If multiple plots are selected:

- `summary_all_plots.csv`

## Required Inputs

### 1. Land-cover GeoPackage

Required fields:

- `lc_class`
- `albedo`
- `emissivity`
- `z0`
- `et_scale`

Meaning of the fields:

- `lc_class`: categorical land-cover code used for the land-cover raster
- `albedo`: shortwave reflectivity of the surface
- `emissivity`: longwave emissivity of the surface
- `z0`: aerodynamic roughness length
- `et_scale`: scaling factor used for evaporative cooling

### 2. Obstacles GeoPackage

Required fields:

- `obs_type`
- `lai`
- `canopy_cover`
- `k_ext`
- `wall_albedo`
- `wall_emissivity`

Meaning of the fields:

- `obs_type`: obstacle type such as `tree`, `shrub`, `hedge`, or `building`
- `lai`: leaf area index
- `canopy_cover`: canopy fraction or cover ratio
- `k_ext`: canopy extinction coefficient for radiation attenuation
- `wall_albedo`: wall reflectivity for built obstacles
- `wall_emissivity`: wall longwave emissivity

### 3. DEM folder

Expected:

- one or more `.tif` files
- these rasters define the base analysis grid and valid mask

### 4. DSM folder

Expected:

- one or more `.tif` files
- filenames must correspond to DEM plots by suffix

### 5. Meteorological Excel

Required columns:

- `date`
- `hour_utc`
- `Ta`
- `Td`
- `u10`
- `v10`
- `ssrd`
- `strd`
- `slhf`

Meaning of the columns:

- `date`: simulation date
- `hour_utc`: simulation hour in UTC
- `Ta`: air temperature
- `Td`: dew point temperature
- `u10`, `v10`: wind components at 10 m
- `ssrd`: shortwave surface radiation downwards
- `strd`: longwave surface radiation downwards
- `slhf`: surface latent heat flux

## GUI Fields And Parameters

### Input files

- `Land cover GeoPackage`: polygon layer with land-cover properties
- `Obstacles GeoPackage`: vegetation and building obstacle layer
- `DEM folder`: folder with one or more DEM rasters
- `DSM folder`: folder with one or more DSM rasters
- `Meteorological Excel`: time-step forcing table
- `Parent output folder`: chosen parent folder; Thermos creates
  `Thermos_outputs` inside it automatically

### Plot selection

The GUI does not require manual typing of suffixes anymore.

Options:

- `Auto-detect (recommended)`: use the only common plot if exactly one is found
- `All detected plots`: run all detected common plot suffixes
- `Plot: <suffix>`: run one specific plot

This matters only when more than one plot is present across the DEM, DSM, SVF,
and rasterized land-cover folders.

### SVF parameters

- `num_directions`
  - default: `72`
  - meaning: number of angular directions used to estimate sky obstruction
  - effect: higher values are slower but can represent angular variability more
    finely

- `max_distance`
  - default: `30`
  - meaning: maximum search distance in meters for obstacle detection during SVF
    estimation
  - effect: larger values consider more distant obstacles but increase runtime

- `observer_height`
  - default: `1.5`
  - meaning: analysis height above ground for SVF estimation
  - effect: approximates the effective observation height of a person

### Thermal / human parameters

- `Met`
  - default: `80`
  - meaning: metabolic rate in watts
  - effect: higher values represent more active subjects and change heat-balance
    results

- `Clo`
  - default: `0.9`
  - meaning: clothing insulation in clo
  - effect: higher values imply more insulation

- `height`
  - default: `1.75`
  - meaning: body height in meters

- `body mass`
  - default: `75`
  - meaning: body mass in kilograms

### Internal thermal constants

These are currently defined in code, not exposed in the GUI:

- `alpha_k = 0.70`
  - shortwave absorptivity of the human body

- `eps_p = 0.97`
  - longwave emissivity of the human body

## Output Folder Structure

If the user selects a parent folder such as:

```text
C:/Users/your_name/Documents/MyRun
```

Thermos creates:

```text
MyRun/
`-- Thermos_outputs/
    |-- rasters_for_modeling/
    |-- svf/
    `-- results/
```

This keeps the project outputs grouped in one clean place.

## Interpretation Of The Main Outputs

### SVF

- `SVF` is the sky view factor
- value range is approximately `0` to `1`
- values near `1` mean more open sky exposure
- lower values mean stronger enclosure by buildings, trees, or other obstacles

### Tmrt

- `Tmrt` is mean radiant temperature
- it summarizes the net radiative environment experienced by the body
- it is a key driver for outdoor thermal stress

This is consistent with the RayMan literature, where mean radiant temperature is
treated as the main radiation-derived variable required for human energy-balance
assessment.

### PET

- `PET` is Physiologically Equivalent Temperature
- unit: degrees Celsius
- interpretation: an equivalent thermal environment translated into a
  temperature-like scale that is easier to understand than raw flux terms

### mPET

- `mPET` is modified PET
- it is a more recent extension of PET discussed in successor biometeorological
  libraries

### PMV

- `PMV` is Predicted Mean Vote
- it represents the expected average thermal sensation vote of a group
- it is often interpreted on a cold-to-hot comfort scale

### SET

- `SET` is Standard Effective Temperature
- it is another human energy-balance index expressed as a temperature-like
  result

### UTCI

- `UTCI` is Universal Thermal Climate Index
- it is widely used for thermal stress assessment in outdoor environments

### UTCI_class

`UTCI_class` is a categorized raster based on `UTCI`.

The current Thermos class mapping is:

- `1`: below `-40`
- `2`: `-40` to `-27`
- `3`: `-27` to `-13`
- `4`: `-13` to `0`
- `5`: `0` to `9`
- `6`: `9` to `26`
- `7`: `26` to `32`
- `8`: `32` to `38`
- `9`: `38` to `46`
- `10`: above `46`

In practice, class `6` corresponds to the no-thermal-stress range in the
current implementation.

## Default Fallback Values For Missing Surface Data

The workflow does not use local means or interpolation when required land-cover
or obstacle properties are missing inside the valid DEM area.

Instead, it fills missing cells with fixed fallback assumptions inside the DEM
mask:

- ground albedo: `0.15`
- ground emissivity: `0.95`
- aerodynamic roughness `z0`: `0.5`
- evaporative cooling scale `et_scale`: `0.0`
- `GAI`: `0.0`
- canopy extinction `k_ext`: `0.5`
- wall emissivity: `0.92`
- wall albedo: `0.0`
- if vegetation fields are absent locally, vegetation is treated as:
  - `LAI = 0`
  - `canopy_cover = 0`

This means Thermos uses explicit default physical assumptions, not averaged
values from neighboring cells.

## Practical Meaning Of Those Fallbacks

- if vegetation variables are missing, the model behaves as if that cell has no
  vegetation effect
- if wall properties are missing, the model uses neutral default wall behavior
- if ground radiative properties are missing, the model uses generic
  ground-like defaults

These defaults are useful to avoid `NA` propagation, but they also mean that
results in poorly attributed areas are less data-driven.

## Notes On Runtime

- `Rasterization` is usually fast
- `SVF` is typically the slowest spatial step
- `Thermal comfort` may also take time because it loops over each meteorological
  time step and writes multiple rasters

The GUI currently supports:

- running steps individually
- running the full pipeline
- stopping the current run with `Stop current run`

If a run is stopped, partial files may remain in the output folder.

## Recommended Reading Of Results

For most analyses, the key products are:

- `SVF` maps for openness / enclosure
- `Tmrt` maps for radiative loading
- `UTCI` or `PET` maps for interpretable outdoor thermal stress
- summary CSV files for comparing time steps or plots

If the scientific question is about spatial comfort hotspots, `Tmrt`, `UTCI`,
`PET`, and `UTCI_class` are usually the most directly useful outputs.

## Known Limitations

- the quality of results depends strongly on the quality of land-cover and
  obstacle attributes
- a wrong or incomplete `obs_type` classification changes vegetation and wall
  behavior
- `SVF` depends on the resolution and consistency of DEM/DSM pairing
- fallback defaults can prevent missing-data crashes, but they cannot replace
  real field-based or well-curated input properties
- thermal outputs are only as good as the forcing meteorology provided in the
  Excel file

## Minimal User Workflow

1. Install the package.
2. Run `library(Thermos)` and `thermos_gui()`.
3. Select the vector files, DEM folder, DSM folder, meteorological Excel, and a
   parent output folder.
4. Use `Check inputs`.
5. Run:
   - `Run rasterization`
   - `Run SVF`
   - `Run thermal comfort`
   or simply `Run full pipeline`
6. Inspect:
   - summary table in the GUI
   - preview rasters in the Visualization panel
   - written files in `Thermos_outputs`

## References

- Chen, Y.-C. (2023). *Thermal indices for human biometeorology based on
  Python*. Scientific Reports, 13, 20825.
  DOI: `10.1038/s41598-023-47388-y`
- Matzarakis, A., and Rutz, F. (2007). *RayMan: A tool for tourism and applied
  climatology*.

These references are useful for understanding:

- why `Tmrt` is central in outdoor human biometeorology
- how radiation-driven thermal indices are used in practice
- how RayMan-style workflows relate to modern successors such as `biometeo`
