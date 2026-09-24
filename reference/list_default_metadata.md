# Default metadata structure

Returns the default metadata tree. Fields are grouped into categories
(#118) — `recording`, `time`, `space`, `variables`, `structure` — with
`spec_version` at the top level. Access stays flat: a field is read with
`get_metadata(data, "sampling_rate")` and written with
`set_metadata(data, sampling_rate = 30)` regardless of its category, and
a category name returns the whole category.

The categories:

- `recording` — provenance: `source`, `source_version`, `source_format`,
  `filename`.

- `time` — `unit_time`, `sampling_rate` (declared), `sampling_interval`
  (derived from the index; read it with
  [`get_sampling_interval()`](https://animovement.dev/anicore/reference/get_sampling_interval.md)),
  `start_datetime`.

- `space` — `coordinate_system`, `reference_frame`, `handedness`,
  `axis_directions`, `axis_extents`, `unit_space`, `unit_angle`, and
  `euler_sequence` / `euler_intrinsic`: the Euler convention the data's
  source uses, for showing and entering a quaternion orientation. The
  one category a class can lack: an
  [`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
  has no spatial component, so its metadata simply has no `space` (#73).

- `variables` — which columns play which role, as a list of roles each
  holding named slots: `what$keys` (identity), `when$index` +
  `when$keys` (temporal; an anievent has `when$interval` instead of an
  index), `where$position` (the axis-role mapping; names are roles,
  values are columns), `event$state` + `event$point`. The frame groups
  by `c(what$keys, when$keys)` and nothing else. These slots are reached
  through
  [`get_variables()`](https://animovement.dev/anicore/reference/variables.md),
  [`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
  and
  [`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md),
  never by flat name — `keys` appears under two roles.

- `structure` — named
  [`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)s,
  each relating the levels of one variable; see
  [`set_structure()`](https://animovement.dev/anicore/reference/structures.md).

- `spec_version` — named list of semantic version strings, one per
  class, versioning the full data contract independently of the package
  version.

## Usage

``` r
list_default_metadata(class = c("anipoint", "anievent"))
```

## Arguments

- class:

  Which class's tree to return: `"anipoint"` (the default) or
  `"anievent"`. An anievent's tree has no `space` category, and its
  `when` role carries `interval = c("start", "stop")` instead of an
  index.

## Value

A named list: the categories above plus `spec_version`.

## See also

[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md),
[`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)

## Examples

``` r
names(list_default_metadata())
#> [1] "spec_version" "recording"    "time"         "space"        "variables"   
#> [6] "structure"   
names(list_default_metadata("anievent"))
#> [1] "spec_version" "recording"    "time"         "variables"    "structure"   
```
