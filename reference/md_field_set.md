# Write one flat-addressable field into a metadata list

Refuses a category the object lacks (e.g. `space` on an anievent, \#73).

## Usage

``` r
md_field_set(md, field, value, call = rlang::caller_env())
```

## Arguments

- md:

  A metadata list in the nested layout.

- field:

  Length-one character.

- value:

  The value to store.

## Value

`md`, with the field written.
