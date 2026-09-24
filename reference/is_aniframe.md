# Check if object is an aniframe

`aniframe` is the abstract parent of every animovement frame class, so
this tests for the whole family: an
[anipoint](https://animovement.dev/anicore/reference/is_anipoint.md), an
[anievent](https://animovement.dev/anicore/reference/is_anievent.md),
and any subclass built on them all pass. Use
[`is_anipoint()`](https://animovement.dev/anicore/reference/is_anipoint.md)
to test for the position grain specifically.

## Usage

``` r
is_aniframe(x)
```

## Arguments

- x:

  An object to test

## Value

Logical: TRUE if x inherits from aniframe

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
is_aniframe(af)
#> [1] TRUE

# A plain data frame is not one
is_aniframe(data.frame(x = 1))
#> [1] FALSE
```
