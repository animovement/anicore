# Check if object is an anievent

Check if object is an anievent

## Usage

``` r
is_anievent(x)
```

## Arguments

- x:

  An object to test.

## Value

Logical: `TRUE` if `x` inherits from `anievent`.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_anievent(af)
#> [1] FALSE
```
