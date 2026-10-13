# Ensure an anipoint uses a 3-D Cartesian coordinate system

Stops with an informative error if `data` is not in a 3-D Cartesian
coordinate system.

## Usage

``` r
ensure_is_cartesian_3d(data)
```

## Arguments

- data:

  An anipoint.

## Value

`TRUE`, invisibly, if the coordinate system matches; otherwise an error.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
try(ensure_is_cartesian_3d(af))
#> Error in ensure_coordinate_system(data, "cartesian_3d", "3D Cartesian") : 
#>   This anipoint is not in a 3D Cartesian coordinate system.
#> ℹ coordinate_system is "cartesian_2d".
#> ℹ Convert the coordinates first; anispace has the transformations.
```
