# Constrain angles to a standard range

Wraps a vector of angles to a standard interval using modulo arithmetic.
By default that is the signed range `(-pi, pi]`, which the suite uses
for every direction; see the section below.

## Usage

``` r
wrap_angle(x, modulo = c("pi", "2pi", "asis"))
```

## Arguments

- x:

  A numeric vector of angles, in radians.

- modulo:

  A character string (default `"pi"`) giving the target range:

  `"pi"`

  :   Wrap to `(-pi, pi]`.

  `"2pi"`

  :   Wrap to `[0, 2*pi)`.

  `"asis"`

  :   Return unchanged.

## Value

A numeric vector the same length as `x`, wrapped to the chosen range.

## The range of a direction

Directions throughout the animovement suite are signed, in `(-pi, pi]`
(`(-180, 180]` in degrees). It is the range
[`atan2()`](https://rdrr.io/r/base/Trig.html) returns, so per-row
directions such as a course or a heading come out in it already, and the
circular summaries
[`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md)
and
[`circ_median()`](https://animovement.dev/anicore/reference/circ_median.md)
return it too, so a summary can be compared with the values it
summarises. `0` points along `x`, and the sign says which side of `x` a
direction lies on: positive toward `y`, negative away from it. Which way
that turns on screen is the frame's angle direction,
[`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md).

The range does not change what a direction means: `-pi / 2` and
`3 * pi / 2` are the same direction, and every `circ_*()` function
treats them alike. To report directions in `[0, 2*pi)` instead, wrap at
the end with `wrap_angle(x, "2pi")`. Differences
([`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md))
are signed in `(-pi, pi]` as well, while unwrapped and cumulative angles
([`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md))
are not confined to any range. The [orientation
article](https://animovement.dev/anicore/articles/orientation.html#the-range-of-a-direction)
covers the convention alongside the frame's axis directions.

## See also

Other angle utilities:
[`angle_to_rad()`](https://animovement.dev/anicore/reference/angle_to_rad.md),
[`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
[`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
[`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md)

## Examples

``` r
angles <- c(-pi, 0, pi, 3 * pi / 2, 2 * pi, 3 * pi)

# The signed range, which directions use throughout the suite
wrap_angle(angles)
#> [1]  3.141593  0.000000  3.141593 -1.570796  0.000000  3.141593

# The same angles on [0, 2*pi)
wrap_angle(angles, "2pi")
#> [1] 3.141593 0.000000 3.141593 4.712389 0.000000 3.141593

# "asis" is a no-op, useful when the range is chosen by a caller
wrap_angle(angles, "asis")
#> [1] -3.141593  0.000000  3.141593  4.712389  6.283185  9.424778
```
