# Convert the spatial unit of an anipoint

Rescales the columns carrying a length and records the new `unit_space`.
Those are the length axes of the coordinate system — `x`, `y`, `z` on a
Cartesian frame, `rho` (and `z`) on a polar, cylindrical or spherical
one. Angular axes are
[`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)'s.
Declared `axis_extents` are rescaled with them.

To declare a unit without changing values, use
`set_metadata(data, unit_space = "mm")`.

## Usage

``` r
convert_unit_space(data, to_unit, calibration_factor = NULL)
```

## Arguments

- data:

  An anipoint, or an anisegment, whose `length` is rescaled.

- to_unit:

  Target unit, one of the levels of `unit_space` in
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md).

- calibration_factor:

  Multiplier from the current unit to `to_unit`. Derived between metric
  units; required when converting from `"px"`.

## Value

`data`, rescaled, with `unit_space` updated.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

# 1 px = 0.5 mm
af_mm <- convert_unit_space(af, "mm", calibration_factor = 0.5)
convert_unit_space(af_mm, "cm")
#> # Individuals: 1
#> # Keypoints:   centroid
#> # Sessions:    1
#> # Trials:      1
#>   individual keypoint session trial  time       x        y confidence
#>        <int> <fct>      <int> <int> <int>   <dbl>    <dbl>      <dbl>
#> 1          1 centroid       1     1     1 -0.0317 -0.0236       0.243
#> 2          1 centroid       1     1     2  0.0408 -0.0263       0.862
#> 3          1 centroid       1     1     3  0.0151 -0.00476      0.724
```
