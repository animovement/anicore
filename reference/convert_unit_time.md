# Convert the time unit of an anipoint or anievent

Rescales the temporal columns — the index of an anipoint, `start` and
`stop` of an anievent — and records the new `unit_time`. Between SI
units the factor is derived; from `"frame"` it is derived from the
declared `sampling_rate`.

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
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md).

- calibration_factor:

  Multiplier from the current unit to `to_unit`. Required when
  converting from `"frame"` without a `sampling_rate`, or from
  `"unknown"`.

## Value

`data`, rescaled, with `unit_time` updated.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_metadata(af, sampling_rate = 30)
convert_unit_time(af, "s")
#> # Individuals:   1
#> # Keypoints:     centroid
#> # Sessions:      1
#> # Trials:        1
#> # Sampling rate: 30 Hz
#> # Time:          00:00:00.033 to 00:00:00.100
#>   individual keypoint session trial   time      x      y confidence
#>        <int> <fct>      <int> <int>  <dbl>  <dbl>  <dbl>      <dbl>
#> 1          1 centroid       1     1 0.0333 -2.50  -0.515      0.347
#> 2          1 centroid       1     1 0.0667  0.167  1.52       0.534
#> 3          1 centroid       1     1 0.1     0.350 -0.328      0.741
```
