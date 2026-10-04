# Circular standard deviation

Computed from the mean resultant length as `sqrt(-2 * log(R))`, so it
grows without bound as the angles spread out rather than saturating at
`pi`.

## Usage

``` r
circ_sd(x, na_rm = TRUE)
```

## Arguments

- x:

  A numeric vector of angles, in radians, in any range.

- na_rm:

  A logical value (default `TRUE`) determining whether missing values
  are removed before computing. When `FALSE`, any `NA` gives `NA`.

## Value

A single non-negative number in radians, `0` when every angle is the
same, or `NA_real_` when there is nothing to summarise.

## See also

Other circular statistics:
[`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md),
[`circ_mad()`](https://animovement.dev/anicore/reference/circ_mad.md),
[`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md),
[`circ_median()`](https://animovement.dev/anicore/reference/circ_median.md),
[`circ_successive_difference()`](https://animovement.dev/anicore/reference/circ_successive_difference.md)

## Examples

``` r
circ_sd(c(0.1, 0.2, 0.15))
#> [1] 0.04082908

# identical angles have no spread
circ_sd(rep(1.3, 5))
#> [1] 0
```
