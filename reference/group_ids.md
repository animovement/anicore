# An integer naming each row's key

A frame is grouped by its key, so the group indices dplyr already holds
are used when they are the key's; anything else is grouped afresh.

## Usage

``` r
group_ids(bare, key)
```

## Arguments

- bare:

  A data frame.

- key:

  Names of the key columns, all present.

## Value

Integer vector, one per row.
