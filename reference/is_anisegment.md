# Test whether an object is an anisegment

Test whether an object is an anisegment

## Usage

``` r
is_anisegment(x)

ensure_is_anisegment(x)
```

## Arguments

- x:

  An object.

## Value

`is_anisegment()`: logical. `ensure_is_anisegment()`: errors if not.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
  set_structure(example_structure())
is_anisegment(as_anisegment(af))
#> [1] TRUE
```
