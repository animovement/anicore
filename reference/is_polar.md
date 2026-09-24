# Test whether an anipoint uses a polar coordinate system

Test whether an anipoint uses a polar coordinate system

## Usage

``` r
is_polar(data)
```

## Arguments

- data:

  An anipoint.

## Value

A logical value.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_polar(af)
#> [1] FALSE
```
