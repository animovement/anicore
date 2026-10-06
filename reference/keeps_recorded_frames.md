# Should the old index be kept as the recorded frame numbers?

When it counts frames and the new index is another column, it is renamed
`frame`, unless it already is, or the new index takes that name. Another
column named `frame` is in the way, so that is refused.

## Usage

``` r
keeps_recorded_frames(data, column, old, call = rlang::caller_env())
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

Logical scalar: whether to rename `old` to `frame`.
