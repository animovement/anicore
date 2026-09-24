# Convert the angular unit of an anipoint

Converts angular columns between radians and degrees and records the new
`unit_angle`. The spatial angular columns `phi` and `theta` and a
declared `yaw` are always converted; other angular columns are named in
`cols`.

To declare a unit without changing values, use
`set_metadata(data, unit_angle = "deg")`.

## Usage

``` r
convert_unit_angle(data, to_unit, cols = NULL)
```

## Arguments

- data:

  An anipoint, or an anijoint, whose `angle` is converted.

- to_unit:

  `"rad"` or `"deg"`.

- cols:

  Further numeric angular columns to convert.

## Value

`data`, converted, with `unit_angle` updated.

## Examples

``` r
df <- data.frame(time = 1:3, rho = 1:3, phi = c(0, pi / 2, pi))
convert_unit_angle(as_anipoint(df), "deg")
#> # Keypoints: centroid
#>   keypoint  time   rho   phi
#>   <fct>    <int> <dbl> <dbl>
#> 1 centroid     1     1     0
#> 2 centroid     2     2    90
#> 3 centroid     3     3   180
```
