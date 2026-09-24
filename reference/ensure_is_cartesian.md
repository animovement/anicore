# Internal guard for Cartesian checks

Stops with a clear error message if `data` is not Cartesian.

## Usage

``` r
ensure_is_cartesian(data)
```

## Arguments

- data:

  An anipoint.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
# Passes silently when the coordinate system matches
ensure_is_cartesian(af)
```
