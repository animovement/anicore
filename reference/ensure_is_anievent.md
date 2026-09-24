# Ensure object is an anievent

Ensure object is an anievent

## Usage

``` r
ensure_is_anievent(x)
```

## Arguments

- x:

  An object to test.

## Value

Errors if `x` is not an anievent; otherwise returns invisibly.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
try(ensure_is_anievent(af))
#> Error in ensure_is_anievent(af) : Data is not an anievent.
```
