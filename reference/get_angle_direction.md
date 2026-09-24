# Which way angles run

The sense of rotation from the `x` axis to the `y` axis, as seen from
where the recording was made. `atan2(y, x)` counts counter-clockwise, so
a frame stored the other way up reports the mirror of the angle a
`counter_clockwise` frame would give for the same physical heading.

Derived from
[`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md)
rather than recorded, so it cannot go on claiming a sense the axes no
longer have.

## Usage

``` r
get_angle_direction(data)
```

## Arguments

- data:

  An aniframe or anievent object.

## Value

`"clockwise"`, `"counter_clockwise"`, or `"unknown"` when the two axes
are not both declared or do not span the view.

## See also

[`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md),
[`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

# An image-plane frame counts angles clockwise
af <- set_axis_directions(af, c(x = "right", y = "down"))
get_angle_direction(af)
#> [1] "clockwise"
```
