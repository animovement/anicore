# Upgrade a structure category holding connection tables

Before \#154 the category held one `from`/`to` table per variable; each
becomes a segments-only structure named after its variable. Built
without validation so malformed old tables still read.

## Usage

``` r
migrate_structure_category(structures)
```

## Arguments

- structures:

  The `structure` category.

## Value

A named list of `anistructure`s.
