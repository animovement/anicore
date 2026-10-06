# The gaps between consecutive index values of a bare frame

Sorts once by key and index and drops the gaps that cross from one key
to the next, rather than splitting the frame, so it is cheap enough to
run after every verb that changes rows.

## Usage

``` r
measure_sampling_gaps(bare, index, key)
```

## Arguments

- bare:

  A data frame without the animovement classes.

- index:

  Name of the index column.

- key:

  Names of the identity and temporal key columns.

## Value

Numeric vector of gaps, empty when there are none to take.
