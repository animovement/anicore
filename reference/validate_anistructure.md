# Check that a structure is internally consistent

**\[experimental\]**

Checks the rules a structure has to satisfy:

- points are unique and not `NA`;

- every segment joins two known, different points, and any expected
  `length` is positive;

- every joint pairs two different, defined segments, about an `axis`
  that is `"x"`, `"y"`, `"z"` or a segment name;

- a joint's `min` is not above its `max`, and its `rest` lies between
  them;

- `root` is one of the points, or `NA`.

[`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)
and
[`set_structure()`](https://animovement.dev/anicore/reference/structures.md)
call it, so a structure built there is already valid; call it yourself
after editing a structure's parts by hand.

## Usage

``` r
validate_anistructure(x)
```

## Arguments

- x:

  An `anistructure`.

## Value

`x`, invisibly; errors naming the first problem otherwise.

## Examples

``` r
validate_anistructure(example_structure())
```
