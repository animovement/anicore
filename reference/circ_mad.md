# Circular median absolute deviation

The median of the angular distances from the circular median.

## Usage

``` r
circ_mad(x, na_rm = TRUE)
```

## Arguments

- x:

  A numeric vector of angles, in radians, in any range.

- na_rm:

  A logical value (default `TRUE`) determining whether missing values
  are removed before computing. When `FALSE`, any `NA` gives `NA`.

## Value

A single number in radians, in `[0, pi]`, or `NA_real_` when there is
nothing to summarise.

## See also

Other circular statistics:
[`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md),
[`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md),
[`circ_median()`](https://animovement.dev/anicore/reference/circ_median.md),
[`circ_sd()`](https://animovement.dev/anicore/reference/circ_sd.md),
[`circ_successive_difference()`](https://animovement.dev/anicore/reference/circ_successive_difference.md)

## Examples

``` r
circ_mad(c(0.1, 0.2, 6.2))
#> [1] 0.1
```
