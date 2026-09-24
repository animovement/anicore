# Test whether an object is an anijoint

Test whether an object is an anijoint

## Usage

``` r
is_anijoint(x)

ensure_is_anijoint(x)
```

## Arguments

- x:

  An object.

## Value

`is_anijoint()`: logical. `ensure_is_anijoint()`: errors if not.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
  set_structure(example_structure())
is_anijoint(as_anijoint(af))
#> [1] TRUE
```
