# Apply a function to each group of an aniframe

Apply a function to each group of an aniframe

## Usage

``` r
# S3 method for class 'aniframe'
group_modify(.data, .f, ..., .keep = FALSE)
```

## Arguments

- .data:

  An aniframe.

- .f, ..., .keep:

  Passed to
  [`dplyr::group_modify()`](https://dplyr.tidyverse.org/reference/group_map.html).

## Value

An aniframe, or a plain data frame when `.f` drops a key, the index or
an interval bound.
