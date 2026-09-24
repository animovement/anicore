# Declare which column an anipoint is indexed by

Shorthand for `set_variables(data, when = list(index = column))`. The
frame is re-sorted. A column that was a `when` key stops being one; the
previous index becomes an undeclared column rather than a key.

## Usage

``` r
set_index(data, column)
```

## Arguments

- data:

  An anipoint object.

- column:

  Length-one character vector naming the index column. It must exist in
  `data` and be numeric.

## Value

`data`, re-indexed and restructured.

## See also

[`get_index()`](https://animovement.dev/anicore/reference/get_index.md)

## Examples

``` r
df <- data.frame(frame = 1:3, individual = "a", x = c(1, 2, 3), y = c(0, 1, 0))
af <- as_anipoint(df, index = "frame")
get_index(af)
#> [1] "frame"
```
