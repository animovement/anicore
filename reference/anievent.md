# Create an anievent data frame

Creates a specialised data frame for behavioural events in long format:
one row per bout (state event) or instant (point event). Like
[`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md),
the class inherits the shared `aniframe` substrate — metadata,
accessors, dplyr methods — but holds event-bout records rather than
per-frame movement data.

## Usage

``` r
anievent(
  ...,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  .rows = NULL,
  .name_repair = c("check_unique", "unique", "universal", "minimal")
)
```

## Arguments

- ...:

  Name-value pairs to create columns in the data frame.

- metadata:

  Optional list of metadata.

- variables_what:

  Character vector of identity columns that together define a unique
  entity. When `NULL` (default), auto-detected from a known list
  (`model`, `individual`, `subject`, `track`, `keypoint`).

- variables_when:

  Character vector of temporal columns. When `NULL` (default),
  auto-detected from a known grouping list (`observation`, `session`,
  `trial`) and concatenated with the required temporal endpoints
  `c("start", "stop")`.

- .rows:

  Number of rows (passed to tibble).

- .name_repair:

  How to repair column names (passed to tibble).

## Value

An anievent object.

## Details

Mandatory columns: `channel`, `type`, `label`, `start`, `stop`. A
"channel" is one mutually-exclusive categorical track of behaviour — at
any moment, a subject can only have one `label` active per channel.
`type` is `"state"` (durative, `stop > start`) or `"point"` (instant,
`start == stop`). Identity columns (e.g. `individual`, `subject`,
`track`) are optional and declared via `variables_what`. A `modifiers`
list-column may carry per-event modifier values — each cell a character
vector (matching the BORIS export format, where one event can have zero
or more modifier values selected from the ethogram).

## Examples

``` r
anievent(
  individual = c(1L, 1L, 1L),
  channel = c("behaviour", "behaviour", "call"),
  label = c("REM", "wake", "alarm"),
  start = c(3, 14, 4.5),
  stop = c(9, 19, 4.5)
)
#> # anievent:       3 × 6
#> # Individuals:    1
#> # Event channels: behaviour, call
#> # Event types:    2 state, 1 point
#>   individual start  stop channel   type  label
#>        <int> <dbl> <dbl> <chr>     <fct> <fct>
#> 1          1   3     9   behaviour state REM  
#> 2          1   4.5   4.5 call      point alarm
#> 3          1  14    19   behaviour state wake 
```
