# The grouping columns of a frame

The frame is grouped by its identity keys and temporal context keys:
`c(what$keys, when$keys)`. The index and an anievent's interval are
never grouping columns.

## Usage

``` r
get_keys(data)
```

## Arguments

- data:

  An aniframe.

## Value

Character vector of column names.

## See also

[`get_variables()`](https://animovement.dev/anicore/reference/variables.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
get_keys(af)
#> [1] "individual" "keypoint"   "session"    "trial"     
```
