# Add a default identity variable when the data has none

Adds `keypoint = "centroid"` (kept over alternatives in \#77).

## Usage

``` r
add_default_identity(data)
```

## Arguments

- data:

  Data frame to complete.

## Value

`data`, with an identity column added if it had none.
