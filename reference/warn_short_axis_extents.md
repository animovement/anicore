# Warn about an extent the data runs past

Reflecting around it would put the axis below zero, which usually means
the extent belongs to a different recording.

## Usage

``` r
warn_short_axis_extents(data, extents)
```

## Arguments

- data:

  An anipoint object.

- extents:

  Named numeric vector of extents.

## Value

`TRUE`, invisibly.
