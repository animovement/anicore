# Custom tibble summary for anipoint

One row per key column (see
[`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md)),
plus event variables, sampling rate and the time interval.

## Usage

``` r
# S3 method for class 'anipoint'
tbl_sum(x, ...)
```

## Arguments

- x:

  An anipoint object

- ...:

  Additional arguments (unused)

## Value

Named character vector with summary information
