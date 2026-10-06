# Ensure a new index keeps the rows in order

Within each group of keys, wherever the old index increases, the new one
must increase too. Rows that share a value of the old index are already
duplicates, which
[`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
reports, so their order is not checked.

## Usage

``` r
ensure_index_increases(data, column, old, call = rlang::caller_env())
```

## Arguments

- data:

  An anipoint object.

- column:

  The proposed index column.

- old:

  The current index column.

- call:

  The caller's environment, for the error.

## Value

`TRUE`, invisibly.
