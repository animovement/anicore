# Encode per-frame data into an anievent

Run-length-encodes per-frame state and point variables into the
long-format
[`anievent()`](https://animovement.dev/anicore/reference/anievent.md).
Works on a data frame (with bare-name selection of the event columns and
explicit `time` / identity) or on an
[`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md)
(where everything is read from metadata).

## Usage

``` r
to_anievent(data, ...)

# S3 method for class 'anievent'
to_anievent(data, ...)

# S3 method for class 'data.frame'
to_anievent(
  data,
  time,
  state = NULL,
  point = NULL,
  variables_what = NULL,
  variables_when = NULL,
  metadata = list(),
  ...
)

# S3 method for class 'anipoint'
to_anievent(
  data,
  variables_what = NULL,
  variables_when = NULL,
  metadata = list(),
  ...
)
```

## Arguments

- data:

  A data frame or an
  [`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md).

- ...:

  Passed to methods.

- time:

  For data-frame input, the column holding per-frame times. Bare name
  (tidyselect). Required.

- state:

  For data-frame input, columns to run-length-encode as state bouts.
  Bare names (tidyselect). Logical columns produce bouts on TRUE-runs,
  labelled by the column name; factor or character columns produce one
  bout per contiguous non-`NA` run of the same value.

- point:

  For data-frame input, columns to encode as point bouts. Bare names
  (tidyselect). Logical columns produce one point bout per TRUE frame,
  labelled by the column name; factor or character columns produce one
  bout per non-`NA` frame.

- variables_what:

  For data-frame input, identity columns (e.g. `individual`). Bare names
  (tidyselect). Bouts are isolated per identity group.

- variables_when:

  For data-frame input, additional temporal- grouping columns (e.g.
  `observation`, `session`, `trial`). Bare names (tidyselect). Like
  identity, these isolate bouts.

- metadata:

  Optional list of metadata attached to the result. For an anipoint
  input, fields like `unit_time` and `sampling_rate` are propagated
  automatically; `metadata` overrides those.

## Value

An
[`anievent()`](https://animovement.dev/anicore/reference/anievent.md).

## Details

Distinct from
[`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md):
that one is a strict cast — the input must already be in canonical
anievent shape (one row per bout, with `channel` / `type` / `label` /
`start` / `stop`). `to_anievent()` is the encoding verb that *produces*
that shape from per-frame data.

## Examples

``` r
if (FALSE) { # \dontrun{
library(tibble)
df <- tibble(
  individual = 1L,
  time = 1:8,
  behaviour = factor(c("REM", "REM", "REM", "wake", "wake", "REM", "REM", NA)),
  woke_up = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  call = c(NA, "alarm", NA, NA, NA, NA, NA, NA)
)
to_anievent(
  df,
  time = time,
  state = c(behaviour, woke_up),
  point = call,
  variables_what = individual
)
} # }
```
