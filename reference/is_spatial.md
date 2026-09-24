# Test whether the spatial columns match the metadata

Returns `TRUE` when `variables_where` declares at least one column and
every column it names is present and numeric.

## Usage

``` r
is_spatial(data)
```

## Arguments

- data:

  An anipoint object.

## Value

Logical scalar.

## Details

This is a different question from the one
[`is_cartesian()`](https://animovement.dev/anicore/reference/is_cartesian.md)
and its siblings answer: those test for the presence of particular
column *names* (`x`, `y`, `z`, …) and never consult the metadata or the
column types. A frame that has lost its `x` column still satisfies
[`is_cartesian_1d()`](https://animovement.dev/anicore/reference/is_cartesian_1d.md)
on the strength of `y` alone, while its `variables_where` still promises
both.

## See also

[`ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.md),
[`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md).

## Examples

``` r
af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
is_spatial(af)
#> [1] TRUE

# Dropping a declared column breaks the correspondence
is_spatial(dplyr::select(af, -x))
#> [1] FALSE
```
