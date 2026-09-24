# The axis roles of an anipoint, and the columns carrying them

The `where$position` slot. Index by role to write a transformation that
does not care what the columns are called:
`data[[get_axes(data)[["x"]]]]`.

## Usage

``` r
get_axes(data)
```

## Arguments

- data:

  An anipoint object.

## Value

Named character vector: names are axis roles (`x`, `y`, `z`, `rho`,
`phi`, `theta`), values are the columns carrying them. Empty for a frame
whose coordinate system is `"unknown"`.

## See also

[`set_variables()`](https://animovement.dev/anicore/reference/variables.md)
to change it.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
get_axes(af)
#>   x   y 
#> "x" "y" 

df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))
renamed <- as_anipoint(df, variables_where = c(x = "u", y = "v"))
get_axes(renamed)
#>   x   y 
#> "u" "v" 
get_metadata(renamed, "coordinate_system")
#> [1] cartesian_2d
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical
```
