# Refuse writes addressed to a category

Field names are unique across categories, so flat writes suffice (#118).

## Usage

``` r
ensure_no_category_fields(user_md)
```

## Arguments

- user_md:

  The metadata the caller supplied.

## Value

`TRUE`, invisibly.
