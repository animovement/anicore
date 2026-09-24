# Ensure object is an aniframe

Guard form of
[`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md),
passed by any animovement frame class. Functions that need coordinates
should guard with
[`ensure_is_anipoint()`](https://animovement.dev/anicore/reference/ensure_is_anipoint.md)
instead.

## Usage

``` r
ensure_is_aniframe(x)
```

## Arguments

- x:

  An object to test

## Value

Error if not an aniframe

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
# Passes silently, and errors otherwise
ensure_is_aniframe(af)

try(ensure_is_aniframe(data.frame(x = 1)))
#> Error in ensure_is_aniframe(data.frame(x = 1)) : 
#>   Data is not an aniframe.
```
