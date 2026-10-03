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

  A result that has lost a column the frame is keyed, indexed or bounded
  by is no longer that frame: it comes back as the plain data frame,
  without metadata that would describe columns it does not have (#178).

## Value

`x` with the animovement classes and metadata restored, or `x` without
them when it lacks a column from
[`list_frame_columns()`](https://animovement.dev/anicore/reference/list_frame_columns.md).
