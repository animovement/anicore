# Ensure object is an anipoint

Ensure object is an anipoint

## Usage

``` r
ensure_is_anipoint(x)
```

## Arguments

- x:

  An object to test

## Value

Error if not an anipoint

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
# Passes silently, and errors otherwise
ensure_is_anipoint(af)

try(ensure_is_anipoint(data.frame(x = 1)))
#> Error in ensure_is_anipoint(data.frame(x = 1)) : 
#>   Data is not an anipoint.
```
