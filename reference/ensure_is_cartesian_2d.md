# Ensure an anipoint uses a 2-D Cartesian coordinate system

Stops with an informative error if `data` is not in a 2-D Cartesian
coordinate system.

## Usage

``` r
ensure_is_cartesian_2d(data)
```

## Arguments

- data:

  An anipoint.

## Value

`TRUE`, invisibly, if the coordinate system matches; otherwise an error.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
ensure_is_cartesian_2d(af)
```
