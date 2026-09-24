# Say which way an axis points

Records the direction of one or more axes, keyed by axis role. Roles not
named keep the direction they had. This only declares: the values are
left alone. To turn an axis over and keep the data describing the same
scene, use
[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md).

## Usage

``` r
set_axis_directions(data, directions)
```

## Arguments

- data:

  An anipoint object.

- directions:

  Named character vector, axis role to direction — one of `right`,
  `left`, `up`, `down`, `back` or `forward`. `NA` clears an axis.

## Value

The anipoint, with the new directions recorded.

## Details

Directions are read from where the recording was made: `right`/`left`
across the view, `up`/`down` within it, `back`/`forward` toward and away
from the viewer. No two axes may point along the same pair. Three
declared directions fix the handedness, which is recorded too.

## See also

[`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md),
[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md),
[`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_axis_directions(af, c(x = "right", y = "down"))
get_axis_directions(af)
#>       x       y 
#> "right"  "down" 
get_angle_direction(af)
#> [1] "clockwise"
```
