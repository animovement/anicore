# Re-clothe a dispatched result with its animovement classes and metadata

Restores the incoming class stack, so downstream subclasses survive
without registering their own methods.

## Usage

``` r
preserve_animovement_class(x, cls, md)
```

## Arguments

- x:

  The bare result returned by
  [`NextMethod()`](https://rdrr.io/r/base/UseMethod.html).

- cls:

  Class vector of the original input, captured before dispatch.

- md:

  Metadata captured before dispatch via
  [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md).

## Value

`x` with the animovement classes and metadata restored.
