# Migrate a legacy flat metadata list to the category layout

Migrate a legacy flat metadata list to the category layout

## Usage

``` r
migrate_metadata_layout(md, anievent = NULL)
```

## Arguments

- md:

  A metadata list, flat or nested.

- anievent:

  Whether the metadata belongs to an anievent. `NULL` infers it from a
  `start`/`stop` interval in `variables_when`.

## Value

The metadata in the nested layout.
