# The interval between consecutive observations

Derived from the index rather than declared, in the unit the index is in
– so a frame indexed by frame number has an interval in frames, and one
indexed by seconds has it in seconds.

## Usage

``` r
get_sampling_interval(data)
```

## Arguments

- data:

  An anipoint object.

## Value

Numeric scalar, or `NA` when the frame is too short to measure.

## Details

Measured per key: identity plus temporal context. The index restarts in
each group, so pooling them would measure the restarts rather than the
sampling.

Measured again whenever the rows or the index change: by
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`dplyr::slice()`](https://dplyr.tidyverse.org/reference/slice.html),
`[`, a
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
of the index or a key, and the other dplyr verbs anicore provides
methods for. A frame that keeps every third row of a 30 Hz recording
then reports the 10 Hz spacing it now has, and
[`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
says that its `sampling_rate` no longer matches.

## See also

[`is_sampling_regular()`](https://animovement.dev/anicore/reference/is_sampling_regular.md)

## Examples

``` r
af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
get_sampling_interval(af)
#> [1] 1
```
