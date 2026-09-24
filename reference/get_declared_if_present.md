# A role the data already declares, when its columns are still there

A role the data already declares, when its columns are still there

## Usage

``` r
get_declared_if_present(data, field)
```

## Arguments

- data:

  Data frame, possibly carrying metadata.

- field:

  One of the `variables_*` metadata fields.

## Value

The declared column names, or `NULL` to detect instead.
