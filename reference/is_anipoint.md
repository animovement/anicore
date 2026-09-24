# Check if object is an anipoint

An anipoint is the position-grain frame: one row per point per
timepoint, with coordinate columns. Use
[`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md)
to test for the whole animovement frame family instead.

## Usage

``` r
is_anipoint(x)
```

## Arguments

- x:

  An object to test

## Value

Logical: TRUE if x inherits from anipoint

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_anipoint(af)
#> [1] TRUE

# A plain data frame is not one
is_anipoint(data.frame(x = 1))
#> [1] FALSE
```
