# Ensure a declared index names exactly one column

Otherwise
[`resolve_index()`](https://animovement.dev/anicore/reference/resolve_index.md)
would silently answer `"time"`.

## Usage

``` r
ensure_index_name(index, arg = "index")
```

## Arguments

- index:

  The proposed index.

- arg:

  Name of the caller's argument, for the message.

## Value

`TRUE`, invisibly.
