# Index an anipoint by its recorded frame numbers again

Index an anipoint by its recorded frame numbers again

## Usage

``` r
index_by_recorded_frames(data, calibration_factor)
```

## Arguments

- data:

  An anipoint with a `frame` column that is not its index.

- calibration_factor:

  As passed to
  [`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md);
  must be `NULL`, as nothing is computed.

## Value

`data`, indexed by `frame`, with `unit_time = "frame"`.
