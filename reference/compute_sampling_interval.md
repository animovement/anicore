# Derive the sampling interval from the index

The median gap, robust to a few dropped frames.

## Usage

``` r
compute_sampling_interval(gaps)
```

## Arguments

- gaps:

  Numeric vector of gaps, from
  [`measure_sampling_gaps()`](https://animovement.dev/anicore/reference/measure_sampling_gaps.md).

## Value

Numeric scalar, or `NA` when there are no gaps to measure.
