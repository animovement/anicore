# Test whether an anipoint uses a spherical coordinate system

Test whether an anipoint uses a spherical coordinate system

## Usage

``` r
is_spherical(data)
```

## Arguments

- data:

  An anipoint.

## Value

A logical value.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_spherical(af)
#> [1] FALSE
```
