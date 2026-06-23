# BIOMET

BIOMET is a private `R` package for bioclimatic preprocessing and thermal
comfort simulations.

It is designed so the scientific workflow lives in reusable functions, while
the GUI acts only as an interface for selecting inputs and launching the
workflow.

## Package structure

```text
BIOMET/
|-- DESCRIPTION
|-- LICENSE
|-- NAMESPACE
|-- R/
|   |-- biomet-rasterize.R
|   |-- biomet-svf.R
|   |-- biomet-thermal.R
|   |-- biomet-validation.R
|   |-- biomet-utils.R
|   `-- biomet-gui.R
|-- inst/
|   |-- examples/
|   `-- extdata/
`-- docs/
```

## Main exported functions

- `biomet_rasterize_landcover()`
- `biomet_calculate_svf()`
- `biomet_thermal_comfort()`
- `biomet_check_inputs()`
- `biomet_run_pipeline()`
- `biomet_gui()`

## Workflow

1. Rasterize land-cover and obstacle attributes to the DEM grid.
2. Compute Sky View Factor from DEM and DSM.
3. Compute thermal-comfort outputs such as `Tmrt`, `PET`, `mPET`, `PMV`,
   `SET`, `UTCI`, and `UTCI class`.

## Data policy

Sample and test datasets are intentionally not included in this repository.

Users must provide their own:

- land-cover vector file
- obstacles vector file
- DEM raster folder
- DSM raster folder
- meteorological Excel file

See [inst/extdata/README.md](inst/extdata/README.md) and
[docs/input_requirements.md](docs/input_requirements.md) for the expected input
structure.

## Documentation

- [BIOMET manual](docs/BIOMET_manual.md)
- [Input requirements](docs/input_requirements.md)
- [Install and run](docs/install_and_run.md)

## Installation

### Option 1: install from GitHub

```r
install.packages("remotes")
remotes::install_github("your-org-or-username/BIOMET", dependencies = TRUE)
```

### Option 2: install from a local folder

```r
install.packages("remotes")
remotes::install_local("path/to/BIOMET", dependencies = TRUE)
```

### Quick local install helper

If the user has downloaded or cloned the repository, they can also run:

```r
source("install.R")
```

## Launch GUI

After installation:

```r
library(BIOMET)
biomet_gui()
```

Or from the repository folder:

```r
source("launch_gui.R")
```

## Example usage in R

```r
library(BIOMET)

checks <- biomet_check_inputs(
  lc_path = "path/to/landcover.gpkg",
  obs_path = "path/to/obstacles.gpkg",
  dem_dir = "path/to/dem_folder",
  dsm_dir = "path/to/dsm_folder",
  met_xlsx = "path/to/met_inputs.xlsx"
)

print(checks)
```
