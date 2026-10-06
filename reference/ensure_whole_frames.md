# Ensure times convert to whole frames without inventing any

Within each key, the gaps between consecutive distinct times must each
be a whole number of frames, to within `tolerance` of the gap, and
rounding must not put two different times on the same frame.

## Usage

``` r
ensure_whole_frames(
  frames,
  group,
  columns,
  tolerance = 0.01,
  call = rlang::caller_env()
)
```

## Arguments

- frames:

  Times multiplied by the rate, in frames.

- group:

  Integer key of each value, from
  [`key_group_ids()`](https://animovement.dev/anicore/reference/key_group_ids.md).

- columns:

  The columns converted, for the message.

- tolerance:

  Relative tolerance on each gap; the margin
  [`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
  allows by default.

- call:

  The caller's environment, for the error.

## Value

`TRUE`, invisibly.
