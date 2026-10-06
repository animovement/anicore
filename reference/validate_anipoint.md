# Validate an anipoint

Re-checks, on demand, that an `anipoint`'s metadata still describes the
frame it is attached to. The two drift apart silently under ordinary
dplyr work:
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
drops a column without touching the metadata that names it, and
assignment can change a column's type. The invariants are therefore
checked rather than assumed:

## Usage

``` r
validate_anipoint(data, rate_tolerance = 0.01)
```

## Arguments

- data:

  An anipoint object.

- rate_tolerance:

  How far the declared `sampling_rate` may be from the rate the index is
  spaced at before it warns, relative to the declared rate. The default,
  `0.01`, lets real timestamps through: a camera log that averages 30.11
  Hz agrees with a declared 30 Hz. Lower it for a strict check, such as
  `1e-6` for an index computed from the rate.

## Value

The input `data`, invisibly.

## Details

- the index column is present and numeric — hard error;

- every declared column is present in the data — hard error;

- every position column is numeric — hard error;

- `coordinate_system` agrees with the axis roles — **warning** only. The
  frame is still usable, and the field is derived rather than declared,
  so it can be refreshed;

- identity, temporal context and the index together name one observation
  per row — **warning** only (#49);

- a declared `sampling_rate` agrees with the spacing of the index, to
  within `rate_tolerance` — **warning** only (#114). The spacing is the
  median gap, so a few dropped frames do not count against it.

## See also

[`ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.md)
for the spatial subset of these checks, which is the part downstream
filters need on every call;
[`validate_anievent()`](https://animovement.dev/anicore/reference/validate_anievent.md)
for the `anievent` equivalent.

## Examples

``` r
af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
validate_anipoint(af)
```
