# Rebuild an aniframe after a dplyr verb

Rebuild an aniframe after a dplyr verb

## Usage

``` r
# S3 method for class 'aniframe'
dplyr_reconstruct(data, template)
```

## Arguments

- data:

  The verb's result.

- template:

  The frame the verb was given.

## Value

An aniframe, or a plain data frame when a key, the index or an interval
bound is gone.
