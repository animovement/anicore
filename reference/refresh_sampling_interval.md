# Keep the stored sampling interval in step with the index

Run by every verb that rebuilds a frame. The interval is measured again
when the rows or the index have changed, and kept when they have not, so
a `mutate()` that leaves the index alone costs nothing.

## Usage

``` r
refresh_sampling_interval(md, x, before = NULL)
```

## Arguments

- md:

  Metadata for the result, in the category layout.

- x:

  The result.

- before:

  The frame the verb was given, or `NULL` to measure always.

## Value

`md`, with `sampling_interval` up to date.
