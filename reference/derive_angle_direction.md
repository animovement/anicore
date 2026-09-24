# Work out the sense of rotation from the axis directions

Seen from the side `z` points to; without `z`, from the viewer.

## Usage

``` r
derive_angle_direction(directions, handedness = "unknown")
```

## Arguments

- directions:

  Named character vector of axis directions.

- handedness:

  A stated handedness, used when no `z` is declared.

## Value

One of `"clockwise"`, `"counter_clockwise"` or `"unknown"`.
