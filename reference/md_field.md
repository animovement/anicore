# Read one flat-addressable field from a metadata list

Legacy flat metadata is read directly; a missing category gives `NULL`.

## Usage

``` r
md_field(md, field)
```

## Arguments

- md:

  A metadata list.

- field:

  Length-one character.

## Value

The field's value, or `NULL`.
