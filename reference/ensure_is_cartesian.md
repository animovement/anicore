# Ensure an anipoint uses a Cartesian coordinate system

Stops with an informative error if `data` is not in a Cartesian
coordinate system.

## Usage

``` r
ensure_is_cartesian(data)
```

## Arguments

- data:

  An anipoint.

## Value

`TRUE`, invisibly, if the coordinate system matches; otherwise an error.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
# Passes silently when the coordinate system matches
ensure_is_cartesian(af)
```
