# Read and write a frame's metadata as JSON

`get_metadata_json()` gives a frame's metadata as JSON, which any
language can read. `set_metadata_json()` restores metadata from that
JSON, so that the round trip gives back exactly what
[`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)
gave.

This is how the metadata travels outside R, for instance in the
key-value metadata of a Parquet file written by aniread.

## Usage

``` r
get_metadata_json(data)

set_metadata_json(data, json)
```

## Arguments

- data:

  An aniframe. For `set_metadata_json()`, a frame of the class the
  metadata belongs to: its class decides which categories and slots are
  valid.

- json:

  A JSON string from `get_metadata_json()`. Or that JSON already parsed
  with `jsonlite::fromJSON(simplifyVector = FALSE)`, for when it is
  embedded in a larger document.

## Value

`get_metadata_json()`: a JSON string. `set_metadata_json()`: `data` with
the metadata from `json`.

## Layout

The JSON has the categories of
[`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)
as objects, in the same order, with `spec_version` saying which version
of the layout it follows:

- A field with a fixed set of values (`unit_time`, `unit_space`,
  `coordinate_system`, ...) is its value as a string.

- `NA` is `null`. `source_sampling_rate` can also be the string `"NaN"`:
  a device with no fixed rate, which JSON has no number for.

- `start_datetime` is an ISO 8601 time in UTC, to the microsecond, with
  its time zone beside it as `start_timezone` (an IANA name, or `""` for
  the session's own).

- `axis_directions` and `axis_extents` are objects from axis role to
  value.

- In `variables`, each role is an object of slots. A slot that maps axis
  roles to columns (`where$position`) is an object; one that lists
  columns (`what$keys`) is an array, even with one column.

- `structure` is an object of structures. Each has `points` (an array),
  `segments` and `joints` (arrays of row objects), and `root`, `source`,
  `citation`, `license` and `variable`.

Numbers are written with as few digits as read back exactly. `Inf` and
`-Inf`, which JSON also has no number for, are strings like `"NaN"`.

## See also

[`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md),
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)

## Examples

``` r
x <- example_anipoint(n_obs = 2, n_individuals = 1)
json <- get_metadata_json(x)
json
#> [1] "{\"spec_version\":{\"aniframe\":\"3.0.0\",\"anievent\":\"1.0.0\"},\"recording\":{\"source\":null,\"source_version\":null,\"source_format\":null,\"source_sampling_rate\":null,\"filename\":null},\"time\":{\"unit_time\":\"frame\",\"sampling_rate\":null,\"sampling_interval\":1,\"start_datetime\":null,\"start_timezone\":\"\"},\"space\":{\"coordinate_system\":\"cartesian_2d\",\"reference_frame\":\"allocentric\",\"handedness\":\"unknown\",\"axis_directions\":{},\"axis_extents\":{},\"unit_space\":\"px\",\"unit_angle\":\"rad\",\"euler_sequence\":null,\"euler_intrinsic\":null},\"variables\":{\"what\":{\"keys\":[\"individual\",\"keypoint\"]},\"when\":{\"index\":[\"time\"],\"keys\":[\"session\",\"trial\"]},\"where\":{\"position\":{\"x\":\"x\",\"y\":\"y\"}},\"event\":{\"state\":[],\"point\":[]}},\"structure\":{}}"

y <- set_metadata_json(x, json)
identical(get_metadata(y), get_metadata(x))
#> [1] TRUE
```
