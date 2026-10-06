# Convert the time unit of an anipoint or anievent

Rescales the temporal columns — the index of an anipoint, `start` and
`stop` of an anievent — and records the new `unit_time`. An anipoint's
`sampling_interval` is measured again in the new unit; `sampling_rate`
is in Hz and is left as it is. Between SI units the factor is derived;
to and from `"frame"` it is derived from the declared `sampling_rate`.

Frames count from 0: the first frame is at time 0, so frames are seconds
multiplied by the rate, and seconds are frames divided by it. Converting
from frames to a time unit keeps nothing extra, as frames are evenly
spaced and multiplying by the rate gives them back.

Converting back to frames is also how a wrong rate is put right: convert
to `"frame"` with the rate the frame declares, declare the right one,
and convert forward again (see the examples). When it is the camera's
rate that was wrong, declare it as `source_sampling_rate` too, which
records the rate the device recorded at (see
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)).

To declare a unit without changing values, use
`set_metadata(data, unit_time = "s")`.

## Usage

``` r
convert_unit_time(data, to_unit, calibration_factor = NULL)

# S3 method for class 'anipoint'
convert_unit_time(data, to_unit, calibration_factor = NULL)

# S3 method for class 'anisegment'
convert_unit_time(data, to_unit, calibration_factor = NULL)

# S3 method for class 'anijoint'
convert_unit_time(data, to_unit, calibration_factor = NULL)

# S3 method for class 'anievent'
convert_unit_time(data, to_unit, calibration_factor = NULL)
```

## Arguments

- data:

  An anipoint or anievent.

- to_unit:

  Target unit, one of the levels of `unit_time` in
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)
  other than `"unknown"`.

- calibration_factor:

  Multiplier from the current unit to `to_unit`. Required when
  converting to or from `"frame"` without a `sampling_rate`, or from
  `"unknown"`. Refused when the frame numbers are taken from a `frame`
  column.

## Value

`data`, rescaled, with `unit_time` and, for an anipoint,
`sampling_interval` updated.

## Converting to frames

Frame numbers that a file records are data; frame numbers computed from
a rate are only nominal. So converting to `"frame"` uses recorded frame
numbers when the frame has them, and computes them only from regular
sampling.

- **Recorded frame numbers.** If an anipoint has a column named `frame`
  that is not its index, it holds the frame numbers recorded with the
  data, and converting to `"frame"` makes that column the index again
  rather than computing frames from the rate. The column it replaces
  stays in the frame as an ordinary column, so the times are not lost.
  [`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
  puts the frame numbers there when it moves the index from frames to
  another column, such as recorded timestamps.

- **Computed frame numbers.** Otherwise each time is multiplied by the
  rate and rounded to the nearest whole frame. Rather than invent frame
  numbers, the conversion refuses when the sampling is irregular, with a
  gap between consecutive times of the same keys more than 1% (the
  margin
  [`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
  allows by default) from a whole number of frames, or when rounding
  would put two different times of the same keys on the same frame. A
  timestamp log, or a `sampling_rate` that does not match the data, is
  refused this way.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_metadata(af, sampling_rate = 30)
in_seconds <- convert_unit_time(af, "s")
in_seconds
#> # Individuals:   1
#> # Keypoints:     centroid
#> # Sessions:      1
#> # Trials:        1
#> # Sampling rate: 30 Hz
#> # Time:          00:00:00.033 to 00:00:00.100
#>   individual keypoint session trial   time       x      y confidence
#>        <int> <fct>      <int> <int>  <dbl>   <dbl>  <dbl>      <dbl>
#> 1          1 centroid       1     1 0.0333  1.52   -0.561      0.815
#> 2          1 centroid       1     1 0.0667 -0.328   0.188      0.842
#> 3          1 centroid       1     1 0.1    -0.0537  0.749      0.736

# The camera was really 25 fps: back to frames, then forward at 25 fps
in_seconds |>
  convert_unit_time("frame") |>
  set_metadata(sampling_rate = 25, source_sampling_rate = 25) |>
  convert_unit_time("s")
#> # Individuals:   1
#> # Keypoints:     centroid
#> # Sessions:      1
#> # Trials:        1
#> # Sampling rate: 25 Hz
#> # Time:          00:00:00.040 to 00:00:00.120
#>   individual keypoint session trial  time       x      y confidence
#>        <int> <fct>      <int> <int> <dbl>   <dbl>  <dbl>      <dbl>
#> 1          1 centroid       1     1  0.04  1.52   -0.561      0.815
#> 2          1 centroid       1     1  0.08 -0.328   0.188      0.842
#> 3          1 centroid       1     1  0.12 -0.0537  0.749      0.736

# Times off the frame grid by a little jitter round to whole frames
jittered <- dplyr::mutate(in_seconds, time = time + c(1e-4, -1e-4, 0))
convert_unit_time(jittered, "frame")$time
#> [1] 1 2 3
```
