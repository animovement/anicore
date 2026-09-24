# Convert a data frame to anipoint

Convert a data frame to anipoint

## Usage

``` r
as_anipoint(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  variables_where = NULL,
  index = NULL,
  root = NULL
)
```

## Arguments

- data:

  A data frame with movement data.

- metadata:

  A list of metadata to attach to the anipoint.

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

- root:

  For an
  [`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md)
  frame: an anipoint holding the root point's trajectory, such as the
  frame the segments came from. The other points are rebuilt by walking
  the structure's segments outward from it, so edits to the segments
  (such as constant lengths) carry into the positions.

## Value

An anipoint object

## Examples

``` r
df <- data.frame(
  time = 1:3, individual = 'a', keypoint = 'centroid',
  x = c(0, 1, 2), y = c(0, 1, 0)
)
as_anipoint(df)
#> # Individuals: a
#> # Keypoints:   centroid
#>   individual keypoint  time     x     y
#>   <fct>      <fct>    <int> <dbl> <dbl>
#> 1 a          centroid     1     0     0
#> 2 a          centroid     2     1     1
#> 3 a          centroid     3     2     0
```
