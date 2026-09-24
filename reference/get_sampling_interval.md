# The interval between consecutive observations

Derived from the index at construction rather than declared, in the unit
the index is in – so a frame indexed by frame number has an interval in
frames, and one indexed by seconds has it in seconds.

## Usage

``` r
get_sampling_interval(data)
```

## Arguments

- data:

  An anipoint object.

  Refreshed whenever the frame is re-declared, so like
  `coordinate_system` it can lag raw dplyr edits.
  [`is_sampling_regular()`](https://animovement.dev/anicore/reference/is_sampling_regular.md)
  reads the data directly and is always current.

## Value

Numeric scalar, or `NA` when the frame is too short to measure.

## Details

Measured per key: identity plus temporal context. The index restarts in
each group, so pooling them would measure the restarts rather than the
sampling.

## See also

[`is_sampling_regular()`](https://animovement.dev/anicore/reference/is_sampling_regular.md)

## Examples

``` r
af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
get_sampling_interval(af)
#> [1] 1
```
