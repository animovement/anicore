# Standardize column types for anipoint

Identity/context columns become factor or integer; spatial become
numeric.

## Usage

``` r
standardise_anipoint_cols(
  data,
  variables_what,
  variables_when,
  variables_where,
  index = "time"
)
```

## Arguments

- data:

  Data frame to standardise.

- variables_what:

  Identity variable names.

- variables_when:

  Temporal variable names.

- variables_where:

  Spatial variable names.

- index:

  The index column, which stays numeric.

## Value

Data frame with standardised column types.
