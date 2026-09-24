# Convert an anipoint to segments: a length and a direction per segment

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
#>    individual segment       session trial  time length     ux      uy confidence
#>         <int> <fct>           <int> <int> <int>  <dbl>  <dbl>   <dbl>      <dbl>
#>  1          1 spine               1     1     1  3.79  -0.770 -0.638       0.555
#>  2          1 spine               1     1     2  2.34  -0.970 -0.242       0.550
#>  3          1 spine               1     1     3  2.20  -0.903 -0.429       0.463
#>  4          1 head                1     1     1  2.89   0.534  0.846       0.555
#>  5          1 head                1     1     2  0.583  0.974  0.228       0.550
#>  6          1 head                1     1     3  2.08  -0.176  0.984       0.473
#>  7          1 shoulder_rig…       1     1     1  1.60   0.993  0.114       0.555
#>  8          1 shoulder_rig…       1     1     2  1.46   0.827  0.563       0.550
#>  9          1 shoulder_rig…       1     1     3  1.63   0.599  0.801       0.473
#> 10          1 shoulder_left       1     1     1  0.839  0.997 -0.0811      0.555
#> # ℹ 20 more rows

# Hold each segment's length constant, then rebuild the positions
rigid <- seg |>
  dplyr::mutate(length = stats::median(length))
rebuilt <- as_anipoint(rigid, root = af)
```
