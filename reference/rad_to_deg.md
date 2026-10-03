# Convert radians to degrees

Convert radians to degrees

## Usage

``` r
rad_to_deg(x)
```

## Arguments

- x:

  Numeric vector of angles (radians).

## Value

Numeric vector of angles expressed in degrees.

## See also

Other angle utilities:
[`angle_to_rad()`](https://animovement.dev/anicore/reference/angle_to_rad.md),
[`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
[`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md),
[`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)

## Examples

``` r
rad_to_deg(pi)
#> [1] 180
rad_to_deg(c(0, pi / 2, pi))
#> [1]   0  90 180
```
