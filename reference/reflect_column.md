# Reflect a spatial axis around a reference value

Reflect a spatial axis around a reference value

## Usage

``` r
reflect_column(data, axis, reference)
```

## Arguments

- data:

  A data frame (typically an anipoint) containing `axis`.

- axis:

  Name of the column to reflect.

- reference:

  A single finite value to reflect around.

## Value

The data with `axis` replaced by `reference - data[[axis]]`.
