# Refuse the metadata fields that have their own setters

Complete metadata objects bypass this check, so wholesale restores still
work (used internally and downstream, e.g. `animetric`).

## Usage

``` r
ensure_no_declaration_fields(user_md)
```

## Arguments

- user_md:

  The metadata the caller supplied.

## Value

`TRUE`, invisibly.
