# Resolve an angular unit given as a frame or a string

Resolve an angular unit given as a frame or a string

## Usage

``` r
resolve_unit_angle(unit, call = rlang::caller_env())
```

## Arguments

- unit:

  An aniframe or anievent, or a unit string or factor.

- call:

  The calling environment, for error messages.

## Value

`"rad"` or `"deg"`; `"none"` resolves to `"rad"`.
