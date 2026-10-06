# Does a conversion compute frame numbers?

Converting to `"frame"` from any other unit, or rescaling frames by a
`calibration_factor`. Frames converted to frames are left as they are.

## Usage

``` r
computes_frames(data, to_unit, calibration_factor)
```

## Arguments

- data:

  An anipoint or anievent.

- to_unit:

  The unit being converted to.

- calibration_factor:

  As passed to
  [`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md).

## Value

Logical scalar.
