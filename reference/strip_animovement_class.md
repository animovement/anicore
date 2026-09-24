# Strip a frame back to its dplyr classes

Avoids dispatching into class-preserving methods and the `ungroup()`
"use with care" warning.

## Usage

``` r
strip_animovement_class(data)
```

## Arguments

- data:

  An aniframe or anievent object.

## Value

`data` with the animovement classes removed.
