# Constrain angles to a standard range

Wraps a vector of angles to a standard interval using modulo arithmetic.

## Usage

``` r
wrap_angle(x, modulo = c("2pi", "pi", "asis"))
```

## Arguments

- x:

  A numeric vector of angles, in radians.

- modulo:

  A character string (default `"2pi"`) giving the target range:

  `"2pi"`

  :   Wrap to `[0, 2*pi)`.

  `"pi"`

  :   Wrap to `(-pi, pi]`.

  `"asis"`

  :   Return unchanged.

  \[0, 2*pi)`.} \item{`"pi"`}{Wrap to `(-pi, pi\]:
  R:0,%202*pi)%60.%7D%0A%20%20%5C%5Citem%7B%60%22pi%22%60%7D%7BWrap%20to%20%60(-pi,%20pi

## Value

A numeric vector the same length as `x`, wrapped to the chosen range.

## See also

Other angle utilities:
[`angle_to_rad()`](https://animovement.dev/anicore/reference/angle_to_rad.md),
[`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
[`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
[`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md)

## Examples

``` r
angles <- c(-pi, 0, pi, 2 * pi, 3 * pi)

wrap_angle(angles, "2pi")
#> [1] 3.141593 0.000000 3.141593 0.000000 3.141593

# The same angles on the signed interval
wrap_angle(angles, "pi")
#> [1] 3.141593 0.000000 3.141593 0.000000 3.141593

# "asis" is a no-op, useful when the range is chosen by a caller
wrap_angle(angles, "asis")
#> [1] -3.141593  0.000000  3.141593  6.283185  9.424778
```
