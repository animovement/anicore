# Convert segments to joints: one angle per joint

**\[experimental\]**

Computes the angle of each joint of a structure from the directions of
its two segments `a` and `b`, with
[`angle_between()`](https://animovement.dev/anicore/reference/angle_between.md):

- In 2D, the signed angle turning from `a` to `b`, in `[-pi, pi]`,
  positive from `x` toward `y`.
  [`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)
  says how that looks on screen.

- In 3D with no joint `axis`, the included angle, in `[0, pi]`.

- In 3D with an `axis` (`"x"`, `"y"`, `"z"` or a segment name), the
  signed angle about it after projecting both segments onto the plane
  perpendicular to it.

The angle is 0 when the two segments point the same way. The segment key
is replaced by a `joint` key, the angle is in the frame's `unit_angle`,
and `confidence` is the lower of the two segments'.

A joint frame cannot be converted back: it keeps no lengths and, in 3D,
no rotation about the segments themselves.

## Usage

``` r
as_anijoint(data, structure = NULL)
```

## Arguments

- data:

  An
  [`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md)
  frame, or an anipoint, which is converted to segments first.

- structure:

  For an anipoint, the structure to use; see
  [`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md).

## Value

An `anijoint`.

## See also

[`angle_between()`](https://animovement.dev/anicore/reference/angle_between.md),
[`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
  set_structure(example_structure())
as_anijoint(af)
#> # anijoint:  9 × 7
#> # Groups:    individual, joint, session, trial [3]
#> # Structure: keypoint
#>   individual joint      session trial  time angle confidence
#>        <int> <fct>        <int> <int> <int> <dbl>      <dbl>
#> 1          1 neck             1     1     1 -2.99      0.379
#> 2          1 neck             1     1     2  1.59      0.568
#> 3          1 neck             1     1     3  2.51      0.547
#> 4          1 knee_right       1     1     1 -1.45      0.427
#> 5          1 knee_right       1     1     2 -2.15      0.843
#> 6          1 knee_right       1     1     3  2.26      0.549
#> 7          1 knee_left        1     1     1 -2.58      0.614
#> 8          1 knee_left        1     1     2  1.10      0.783
#> 9          1 knee_left        1     1     3 -3.13      0.586
```
