# Remove wrapping from a sequence of angles

Reverses the discontinuity introduced by wrapping, by accumulating the
shortest step between successive angles. A heading that crosses the end
of its range, `pi` in the signed range
[`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)
gives, therefore continues to increase rather than jumping back to
`-pi`, which is what makes it differentiable. `NA` values are preserved
in place.

## Usage

``` r
unwrap_angle(x)
```

## Arguments

- x:

  A numeric vector of angles, in radians, in any range.

## Value

A numeric vector the same length as `x`, without wrapping
discontinuities. It starts at the first non-missing angle of `x` and is
not confined to any range.

## See also

Other angle utilities:
[`angle_to_rad()`](https://animovement.dev/anicore/reference/angle_to_rad.md),
[`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
[`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
[`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)

## Examples

``` r
# A heading turning steadily past a full circle, wrapped to (-pi, pi]
wrapped <- wrap_angle(seq(0, 3 * pi, length.out = 7))
wrapped
#> [1]  0.000000  1.570796  3.141593 -1.570796  0.000000  1.570796  3.141593

# Unwrapping restores the steady progression
unwrap_angle(wrapped)
#> [1] 0.000000 1.570796 3.141593 4.712389 6.283185 7.853982 9.424778
```
