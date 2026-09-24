# Validate a complete metadata list and attach it

No field-level policy; migrates legacy flat metadata on write.

## Usage

``` r
write_metadata(data, metadata)
```

## Arguments

- data:

  An aniframe or anievent object.

- metadata:

  A complete metadata list.

## Value

`data`, with `metadata` attached.
