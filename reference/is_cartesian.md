# Test whether an anipoint uses a Cartesian coordinate system

Returns `TRUE` if the data frame satisfies *any* of the 1-D, 2-D or 3-D
Cartesian checks.

## Usage

``` r
is_cartesian(data)
```

## Arguments

- data:

  An anipoint.

## Value

A logical value.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_cartesian(af)
#> [1] TRUE
```
