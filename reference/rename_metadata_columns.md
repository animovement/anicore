# Carry a renaming of columns into the metadata

Every column name the metadata records — keys, index, interval, declared
variables, and the identity variable each structure spans — follows the
rename, so the frame still describes itself (#178).

## Usage

``` r
rename_metadata_columns(md, from, to)
```

## Arguments

- md:

  A metadata list.

- from, to:

  Column names before and after, position by position.

## Value

`md`, with the renamed columns.
