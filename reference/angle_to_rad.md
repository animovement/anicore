# Convert angles between radians and a frame's angular unit

Angular computations work in radians; a frame declares the unit its
angles are stored in (`unit_angle`). `angle_to_rad()` reads a frame's
angles into radians, and `angle_from_rad()` writes radians back out in
the frame's unit, so a function that computes new angles can return them
in the unit the frame declares.

These convert values and leave the frame alone. To convert a frame's
columns and record the new unit, use
[`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md).
Calling that on new columns computed in radians would do nothing in a
`"deg"` frame, since it converts from the unit the frame already
declares.

## Usage

``` r
angle_to_rad(x, unit)

angle_from_rad(x, unit)
```

## Arguments

- x:

  Numeric vector of angles, or of angular rates.

- unit:

  The angular unit: an aniframe or anievent, whose `unit_angle` is read,
  or one of `"rad"`, `"deg"` or `"none"`. Pass the unit as a string,
  read once with `get_metadata(data, "unit_angle")`, to convert inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Value

Numeric vector, the same length as `x`.

## Details

A frame that declares no angular unit (`"none"`) is read as radians:
radians are the unit angles are computed in, and such a frame has no
other unit to return them in.

## See also

Other angle utilities:
[`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
[`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
[`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md),
[`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_metadata(af, unit_angle = "deg")

# Compute in radians, return in the frame's unit
angle_from_rad(pi / 2, af)
#> [1] 90

# And read the frame's angles for computing
angle_to_rad(c(0, 90, 180), af)
#> [1] 0.000000 1.570796 3.141593

# With the unit read once, inside mutate()
angle_from_rad(c(0, pi), "deg")
#> [1]   0 180
```
