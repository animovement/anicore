# Derive the sampling interval from the index

The median gap, robust to a few dropped frames.

## Usage

``` r
compute_sampling_interval(data)
```

## Arguments

- data:

  An anipoint object.

## Value

Numeric scalar, or `NA` when the frame has no gaps to measure.
