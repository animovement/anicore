# Convert an anipoint to segments: a length and a direction per segment

**\[experimental\]**

Re-expresses the positions of a structure's points as its segments. Each
row is one segment at one time: its `length` and the unit vector `ux`,
`uy` (and `uz` in 3D) pointing from the segment's `from` point to its
`to` point, in the frame's axes and units.

The structure's variable (usually `keypoint`) is replaced by a `segment`
key. Structures over that variable other than `structure` are dropped;
those over the remaining keys are kept. A `confidence` column becomes
the lower of the two endpoints' values; other undeclared columns are
dropped.

[`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
rebuilds positions from the segments, anchored at the root point's
trajectory. That is useful after editing the segments — for example
holding each segment's length constant — since every point but the root
then moves to agree with them.

## Usage

``` r
as_anisegment(data, structure = NULL)
```

## Arguments

- data:

  A Cartesian 2D or 3D anipoint.

- structure:

  Name of the structure to use. May be omitted when only one structure
  has segments.

## Value

An `anisegment`.

## See also

[`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md),
[`set_structure()`](https://animovement.dev/anicore/reference/structures.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
  set_structure(example_structure())
seg <- as_anisegment(af)
seg
#> # anisegment: 30 × 9
#> # Groups:     individual, segment, session, trial [10]
#> # Structure:  keypoint
#>    individual segment        session trial  time length     ux     uy confidence
#>         <int> <fct>            <int> <int> <int>  <dbl>  <dbl>  <dbl>      <dbl>
#>  1          1 spine                1     1     1  1.65   0.357 -0.934      0.703
#>  2          1 spine                1     1     2  2.19   0.463  0.887      0.497
#>  3          1 spine                1     1     3  2.46   0.546  0.838      0.698
#>  4          1 head                 1     1     1  1.59  -0.105  0.994      0.745
#>  5          1 head                 1     1     2  3.24  -0.642 -0.767      0.497
#>  6          1 head                 1     1     3  1.62  -0.715 -0.699      0.698
#>  7          1 shoulder_right       1     1     1  1.47   0.568  0.823      0.862
#>  8          1 shoulder_right       1     1     2  2.96  -0.476 -0.879      0.463
#>  9          1 shoulder_right       1     1     3  0.434 -0.828 -0.561      0.698
#> 10          1 shoulder_left        1     1     1  0.627  0.151  0.989      0.751
#> # ℹ 20 more rows

# Hold each segment's length constant, then rebuild the positions
rigid <- seg |>
  dplyr::mutate(length = stats::median(length))
rebuilt <- as_anipoint(rigid, root = af)
```
