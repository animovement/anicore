# Rebuild point positions from an anisegment

Walks the structure's segments outward from its root; segments that
close a cycle are not needed and are ignored.

## Usage

``` r
anisegment_to_anipoint(data, root)
```

## Arguments

- data:

  An anisegment.

- root:

  An anipoint holding the root point's trajectory, such as the frame the
  segments came from.

## Value

An anipoint.
