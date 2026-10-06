# Warn when a declared sampling rate disagrees with the index

Only checkable when the index is in a real time unit, not frames. The
measured spacing is the median gap, so a dropped frame does not move it,
and the comparison is relative: a timestamp log jitters, and a camera
logging at 30.11 Hz is a 30 Hz camera.

## Usage

``` r
warn_sampling_rate_mismatch(data, tolerance = 0.01)
```

## Arguments

- data:

  An anipoint object.

- tolerance:

  Relative tolerance, a single non-negative number.

## Value

`TRUE`, invisibly.
