# Validate a recorded sampling rate

A positive number, `NA` (not declared yet) or `NaN` (declared as having
no fixed rate).

## Usage

``` r
ensure_valid_source_sampling_rate(x)
```

## Arguments

- x:

  The value of `source_sampling_rate`, or `NULL` when the metadata
  predates the field.

## Value

`TRUE`, invisibly.
