# Group an aniframe

A frame grouped by its keys, one trajectory per group, stays grouped by
them: the levels asked for are added after the keys rather than
replacing them, so a group is one trajectory or one stretch of it
(#208). To group by something else instead,
[`dplyr::ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html)
first.

## Usage

``` r
# S3 method for class 'aniframe'
group_by(.data, ...)
```

## Arguments

- .data:

  An aniframe object

- ...:

  Variables to group by

## Value

A grouped aniframe
