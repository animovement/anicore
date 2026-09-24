# Restructure an anipoint

Shared by construction and re-declaration so they cannot drift apart.

## Usage

``` r
restructure_anipoint(
  data,
  variables_what,
  variables_when,
  variables_where,
  orientation = NULL,
  strict = TRUE
)
```

## Arguments

- data:

  An anipoint object.

- variables_what, variables_when, variables_where:

  The declaration to apply.

- orientation:

  `where$orientation`; `NULL` keeps the current one.

## Value

`data`, restructured, with the declaration recorded.
