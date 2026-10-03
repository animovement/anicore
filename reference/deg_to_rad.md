# Convert degrees to radians

Convert degrees to radians

## Usage

``` r
deg_to_rad(x)
```

## Arguments

- x:

  Numeric vector of angles (degrees).

## Value

Numeric vector of angles expressed in radians.

## See also

Other angle utilities:
[`angle_to_rad()`](https://animovement.dev/anicore/reference/angle_to_rad.md),
[`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
[`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md),
[`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)

## Examples

``` r
deg_to_rad(180)
#> [1] 3.141593
deg_to_rad(c(0, 90, 180))
#> [1] 0.000000 1.570796 3.141593
```
