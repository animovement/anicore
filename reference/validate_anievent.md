# Validate an anievent

Re-runs the structural invariants of an `anievent` object on demand:

- required columns (`channel`, `type`, `label`, `start`, `stop`) are
  present with the expected types — hard errors;

- `type` is a factor with levels `c("state", "point")` — hard error;

- `stop >= start` for every row — hard error;

- `modifiers`, if present, is a list-column whose cells are character
  vectors — hard error;

- within each `(identity + temporal-grouping)` group, two bouts of the
  same `channel` should not overlap — **warning** only. Overlapping
  bouts within a channel are permitted on the `anievent` side; this is
  the form the data takes from coding tools that allow
  non-mutually-exclusive coding (e.g. BORIS without strict ethogram).

## Usage

``` r
validate_anievent(data)
```

## Arguments

- data:

  An anievent object.

## Value

The input `data`, invisibly.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
try(validate_anievent(af))
#> Error in ensure_is_anievent(data) : Data is not an anievent.
```
