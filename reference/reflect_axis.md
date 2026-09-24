# Turn an axis over

Reflects the column carrying an axis role and flips its declared
direction, so the data describes the same scene with the axis pointing
the other way — for example converting image coordinates, where `y` runs
down, to a `y` that runs up.

An axis runs from zero to its extent, so turning it over gives
`new = extent - old`. An axis with no declared `axis_extents` is centred
on its origin, and turning it over negates it. On a frame that stores
angles there is no column to reflect, and `phi` and `theta` are
recomputed instead.

A declared handedness flips with any linear axis.

## Usage

``` r
reflect_axis(data, axis)
```

## Arguments

- data:

  An anipoint object.

- axis:

  An axis role: `"x"`, `"y"` or `"z"`.

## Value

The anipoint, reflected, with its orientation metadata updated.

## See also

[`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md),
[`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_metadata(af, axis_extents = c(y = 1080))
af <- set_axis_directions(af, c(x = "right", y = "down"))

af <- reflect_axis(af, "y")
get_axis_directions(af)
#>       x       y 
#> "right"    "up" 
```
