# Scale time values, rounding computed frames to whole ones

Scale time values, rounding computed frames to whole ones

## Usage

``` r
scale_time(x, factor, to_frames)
```

## Arguments

- x:

  Numeric vector.

- factor:

  Multiplier.

- to_frames:

  Whether the result is in frames, computed by
  [`computes_frames()`](https://animovement.dev/anicore/reference/computes_frames.md).

## Value

`x * factor`, rounded to whole numbers when `to_frames`.
