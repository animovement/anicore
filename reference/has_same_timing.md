# Do two frames have the same index and keys, row for row?

[`identical()`](https://rdrr.io/r/base/identical.html) returns at once
for a column a verb has passed through untouched, as it is the same
vector.

## Usage

``` r
has_same_timing(x, before, cols)
```

## Arguments

- x, before:

  Data frames; `before` may be `NULL`.

- cols:

  The index and key columns.

## Value

Logical scalar.
