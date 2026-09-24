# Whether the frame is right- or left-handed

Three declared axis directions determine it, and are read in preference
to anything recorded. A frame that states the convention without
spelling the axes out — most 3D recordings — declares it with
`set_metadata(data, handedness = "right")`.

## Usage

``` r
get_handedness(data)
```

## Arguments

- data:

  An aniframe or anievent object.

## Value

`"right"`, `"left"`, or `"unknown"` when neither the axes nor the frame
itself says.

## See also

[`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md),
[`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

# Two axes are not enough
af <- set_axis_directions(af, c(x = "right", y = "up"))
get_handedness(af)
#> [1] "unknown"
```
