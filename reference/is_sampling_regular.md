# Is the frame regularly sampled?

Every gap between consecutive observations equal, within `tolerance`.
Computed from the data each time it is asked rather than recorded,
because dropping rows changes the answer and a stored logical would go
on claiming the old one.

## Usage

``` r
is_sampling_regular(data, tolerance = 1e-06)
```

## Arguments

- data:

  An anipoint object.

- tolerance:

  Relative tolerance: a gap counts as equal to the interval when it
  differs by no more than `tolerance * interval`. Timestamps are rarely
  exactly equal, so comparing them with `==` says "irregular" for data
  that is regular to any precision that matters. Raise it for noisy
  timestamps, lower it to be strict.

## Value

`TRUE`, `FALSE`, or `NA` when the frame is too short to tell.

## See also

[`get_sampling_interval()`](https://animovement.dev/anicore/reference/get_sampling_interval.md)

## Examples

``` r
af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
is_sampling_regular(af)
#> [1] TRUE

# A gap in the recording
irregular <- af |> dplyr::filter(time != 3)
is_sampling_regular(irregular)
#> [1] FALSE
```
