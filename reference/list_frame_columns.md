# The columns a frame cannot lose

Its identity and temporal keys, its index, and an anievent's interval
bounds. Dropping a declared value column (a position, an orientation)
leaves a frame that can still be re-declared, so those are not listed.

## Usage

``` r
list_frame_columns(md)
```

## Arguments

- md:

  A metadata list, or `NULL`.

## Value

Character vector of column names.
