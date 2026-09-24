# Internal guard for spherical checks

Internal guard for spherical checks

## Usage

``` r
ensure_is_spherical(data)
```

## Arguments

- data:

  An anipoint.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
# Passes silently when the coordinate system matches
try(ensure_is_spherical(af))
#> Error in ensure_coordinate_system(data, "spherical", "spherical") : 
#>   This anipoint is not in a spherical coordinate system.
#> ℹ coordinate_system is "cartesian_2d".
#> ℹ Convert the coordinates first; anispace has the transformations.
```
