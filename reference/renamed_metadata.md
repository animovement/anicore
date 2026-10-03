# The metadata for a verb's result

`rename()` and `select()` rename through `names<-`, whose method has
already carried the new names into the result's metadata; take it from
there rather than restoring the stale copy captured before dispatch.

## Usage

``` r
renamed_metadata(x, md)
```

## Arguments

- x:

  The result returned by
  [`NextMethod()`](https://rdrr.io/r/base/UseMethod.html).

- md:

  Metadata captured before dispatch.

## Value

Metadata list.
