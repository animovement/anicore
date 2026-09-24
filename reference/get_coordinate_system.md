# The coordinate system an anipoint is in

Derived from the axis roles rather than declared:
[`set_variables()`](https://animovement.dev/anicore/reference/variables.md)
says which column carries which role, and the system follows from the
set of roles present. It is therefore not writable — see
[`set_variables()`](https://animovement.dev/anicore/reference/variables.md)
to say what the columns mean, or `anispace`'s `map_to_*()` functions to
convert the coordinates themselves.

## Usage

``` r
get_coordinate_system(data)
```

## Arguments

- data:

  An anipoint or anievent object.

## Value

Length-one character vector: one of `"cartesian_1d"`, `"cartesian_2d"`,
`"cartesian_3d"`, `"polar"`, `"cylindrical"`, `"spherical"` or
`"unknown"`.

## See also

[`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md),
[`is_cartesian()`](https://animovement.dev/anicore/reference/is_cartesian.md),
[`is_polar()`](https://animovement.dev/anicore/reference/is_polar.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
get_coordinate_system(af)
#> [1] "cartesian_2d"
```
