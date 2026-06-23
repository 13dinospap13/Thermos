# Input Requirements

## 1. Land-cover vector

Expected attributes:

- `lc_class`
- `albedo`
- `emissivity`
- `z0`
- `et_scale`

## 2. Obstacles vector

Expected attributes:

- `obs_type`
- `lai`
- `canopy_cover`
- `k_ext`
- `wall_albedo`
- `wall_emissivity`

Common vegetation values expected by the default workflow:

- `tree`
- `shrub`
- `hedge`

Building features are expected to use:

- `building`

## 3. DEM folder

Expected contents:

- one or more `.tif` raster files used as the base analysis grid

## 4. DSM folder

Expected contents:

- one or more `.tif` raster files matched to the DEM files by filename suffix

## 5. Meteorological Excel

Expected columns:

- `date`
- `hour_utc`
- `Ta`
- `Td`
- `u10`
- `v10`
- `ssrd`
- `strd`
- `slhf`

## 6. Output folders

The workflow writes outputs to user-provided directories such as:

- rasterized land-cover outputs
- SVF outputs
- thermal-comfort outputs

