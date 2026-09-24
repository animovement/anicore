# Create an anipoint data frame

Creates a specialized data frame for movement data with columns defining
entity identity, timepoints, and spatial position.

## Usage

``` r
anipoint(
  ...,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  variables_where = NULL,
  index = NULL,
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
  entity, and which the frame is grouped by. If `NULL` (the default),
  detected from the data: whichever of `model`, `individual`, `subject`,
  `track` and `keypoint` are present, in the order
  [`list_recognised_variables_what()`](https://animovement.dev/anicore/reference/list_recognised_variables_what.md)
  lists them. Order carries no meaning of its own — see its
  documentation. An anipoint needs at least one identity variable, so if
  none of them is found, a `keypoint` column is added with the value
  `"centroid"`. Pass `character(0)` to declare no identity variables at
  all — a deliberate opt-out, which leaves the frame ungrouped. Every
  column named here must exist in `data`.

- variables_when:

  Character vector of temporal columns that together define a unique
  timepoint. If `NULL` (the default), detected from the data: whichever
  of `observation`, `session`, `trial` and `time` are present, minus the
  index. These are the temporal *context* — which session, which trial —
  and, together with `variables_what`, they are what the frame is
  grouped by. The index itself is declared separately and is never one
  of them.

- variables_where:

  The spatial columns that together define position. Either a plain
  character vector of column names, in which case the name is taken to
  be the axis role, or a vector named by axis role —
  `c(x = "u", y = "v")` — which lets the columns be called anything. The
  roles themselves are a closed set (`x`, `y`, `z`, `rho`, `phi`,
  `theta`), so that transformations between coordinate systems stay well
  defined; an unrecognised role is rejected by name. If `NULL` (the
  default), detected from the data.

- index:

  Length-one character vector naming the column the frame is indexed by
  — the position of each row within its temporal context. It is never a
  grouping variable. If `NULL` (the default), the frame's existing
  declaration is kept, or `"time"` for a frame that has none. The column
  must exist and be numeric; it may be called anything.

- .rows:

  Number of rows (passed to tibble).

- .name_repair:

  How to repair column names (passed to tibble).

## Value

An anipoint object (tibble with anipoint class).

## Examples

``` r
anipoint(
  individual = rep(1:2, each = 25),
  time = rep(1:10, 5),
  x = rnorm(50),
  y = rnorm(50)
)
#> # Individuals: 1, 2
#>    individual  time      x      y
#>         <int> <int>  <dbl>  <dbl>
#>  1          1     1 -0.387  0.429
#>  2          1     1 -0.209 -1.90 
#>  3          1     1  2.04  -0.103
#>  4          1     2 -0.785  0.122
#>  5          1     2 -1.40   0.936
#>  6          1     2  0.449 -0.974
#>  7          1     3 -1.06  -1.14 
#>  8          1     3  0.259 -0.309
#>  9          1     3  1.39   1.27 
#> 10          1     4 -0.796 -0.558
#> # ℹ 40 more rows

# Custom variables
anipoint(
  track = rep(1:3, each = 10),
  trial = 1,
  time = rep(1:10, 3),
  x = rnorm(30),
  y = rnorm(30),
  variables_what = "track",
  variables_when = "trial"
)
#> # Tracks: 1, 2, 3
#> # Trials: 1
#>    track trial  time       x      y
#>    <int> <int> <int>   <dbl>  <dbl>
#>  1     1     1     1  0.150  -0.174
#>  2     1     1     2 -1.43   -0.222
#>  3     1     1     3 -0.0103 -1.01 
#>  4     1     1     4 -0.212   0.481
#>  5     1     1     5 -0.906   1.60 
#>  6     1     1     6 -2.10   -1.52 
#>  7     1     1     7  1.89   -1.42 
#>  8     1     1     8 -0.968   0.877
#>  9     1     1     9 -0.103   0.624
#> 10     1     1    10  0.240   2.11 
#> # ℹ 20 more rows

# Indexed by a column that isn't called `time`
anipoint(
  individual = 1L,
  frame = 1:10,
  x = rnorm(10),
  y = rnorm(10),
  index = "frame"
)
#> # Individuals: 1
#>    individual frame       x      y
#>         <int> <int>   <dbl>  <dbl>
#>  1          1     1 -0.234  -0.579
#>  2          1     2  2.09   -0.145
#>  3          1     3 -0.111   0.526
#>  4          1     4 -1.39    1.73 
#>  5          1     5 -1.14    1.45 
#>  6          1     6  1.70    1.52 
#>  7          1     7 -0.0801 -0.384
#>  8          1     8 -0.437   1.83 
#>  9          1     9 -0.119  -0.551
#> 10          1    10  0.786  -0.866
```
