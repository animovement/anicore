# The anipoint data structure

``` r

library(anicore)
```

## What is an `anipoint`?

The *anicore* package defines `anipoint` — the foundational data
structure of the *animovement* ecosystem: one row per point per
timepoint, with coordinate columns. Every sister package (*aniread* for
I/O, *animetric* for kinematics, …) is built around consuming and
producing `anipoint` objects, so the shape that an `anipoint` takes is
what holds the ecosystem together. (`aniframe` names the abstract parent
class that `anipoint` shares with `anievent` — the substrate of
metadata, accessors and dplyr methods.)

The shape itself follows the principles of *tidy movement data* (laid
out in an upcoming paper). The short version: every row records one
entity at one timepoint at one position, and the columns split into
three semantic slots that answer **what** is moving, **when**, and
**where**.

This article covers the data shape. Companion articles cover the
[metadata
attribute](https://animovement.dev/anicore/articles/aniframe-metadata.md)
and the
[structures](https://animovement.dev/anicore/articles/structures.md) for
skeletons and networks.

## Anatomy at a glance

The cheapest way to see an `anipoint` is to print one.

``` r

data <- example_anipoint(
  n_obs = 5,
  n_individuals = 2,
  n_keypoints = 3,
  n_dims = 2
)
data
#> # Individuals: 1, 2
#> # Keypoints:   head, neck, shoulder_right
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x       y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>   <dbl>      <dbl>
#>  1          1 head           1     1     1  2.10   0.556       0.760
#>  2          1 head           1     1     2 -0.720  0.162       0.535
#>  3          1 head           1     1     3 -2.02   0.0281      0.583
#>  4          1 head           1     1     4  1.19   1.01        0.931
#>  5          1 head           1     1     5 -1.64  -0.643       0.801
#>  6          1 neck           1     1     1 -1.29   0.336       0.944
#>  7          1 neck           1     1     2 -0.449 -1.20        0.789
#>  8          1 neck           1     1     3 -0.848 -1.19        0.604
#>  9          1 neck           1     1     4  0.557 -1.45        0.771
#> 10          1 neck           1     1     5 -0.559 -0.368       0.597
#> # ℹ 20 more rows
```

Two things to spot:

1.  The **header rows** prefixed with `#` come from the metadata
    attribute and summarise what the object contains — individuals,
    keypoints, recording duration when known, sampling rate, etc.
2.  The **data columns** form a tidy table where every row records one
    entity at one timepoint at one position.

`anipoint` inherits from `tbl_df` and `data.frame`, so dplyr verbs,
ggplot2, and base subsetting all work on it directly.

The rest of this article unpacks the columns.

## The three slots: what / when / where

Every row of an `anipoint` answers three questions:

| Question | Slot | Resolves | Default columns |
|----|----|----|----|
| **What** is moving? | Identity (`what$keys`) | An entity | `individual`, `keypoint` |
| **When**? | Temporal context (`when$keys`) | A context — which session, which trial | `session`, `trial` |
| **Where**? | Spatial (`where$position`) | A position | `x`, `y` |

“When” is really two questions, and only the first is answered here:
which recording session this row belongs to, and where it sits inside
it. The first is context the row shares with its neighbours, and it is
what the frame groups by; the second is what tells the row apart from
them, and it orders rather than groups. That second half is the
**index**, declared in its own slot (`when$index`) and covered in [its
own section](#the-index) below.

The combination of all identity and temporal columns forms a composite
key that uniquely identifies each row; the spatial columns are what that
row *records* about that entity at that timepoint.

`anipoint` stores which columns play which role in the metadata, so
downstream code can introspect:

``` r

get_index(data)
#> [1] "time"
get_variables(data, "what")
#> [1] "individual" "keypoint"
get_variables(data, "when")
#> [1] "time"    "session" "trial"
get_variables(data, "where")
#> [1] "x" "y"
get_keys(data)
#> [1] "individual" "keypoint"   "session"    "trial"
```

### Customising the slots

Most readers populate these from the source data, but you can override
them when constructing manually. By default,
[`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
recognises `c("model", "individual", "track", "keypoint")` as identity
columns and `c("session", "trial")` as temporal context. Pass the slot
arguments explicitly to use other names:

``` r

df <- data.frame(
  track = rep(c("A", "B", "C"), each = 4),
  trial = rep(1:2, each = 6),
  time = rep(1:2, 6),
  x = runif(12),
  y = runif(12)
)

custom <- as_anipoint(
  df,
  variables_what = "track",
  variables_when = "trial"
)
custom
#> # Tracks: A, B, C
#> # Trials: 1, 2
#>    track trial  time     x       y
#>    <fct> <int> <int> <dbl>   <dbl>
#>  1 A         1     1 0.659 0.253  
#>  2 A         1     1 0.608 0.528  
#>  3 A         1     2 0.877 0.451  
#>  4 A         1     2 0.950 0.445  
#>  5 B         1     1 0.228 0.430  
#>  6 B         1     2 0.291 0.797  
#>  7 B         2     1 0.455 0.00328
#>  8 B         2     2 0.706 0.307  
#>  9 C         2     1 0.615 0.199  
#> 10 C         2     1 0.176 0.261  
#> 11 C         2     2 0.454 0.570  
#> 12 C         2     2 0.888 0.218
```

## The index

One column has a status of its own: the **index**, which gives each row
its position within its temporal context. Read it with
[`get_index()`](https://animovement.dev/anicore/reference/get_index.md):

``` r

get_index(data)
#> [1] "time"
```

It defaults to `time`, but nothing requires that name. A frame straight
off a camera is often indexed by frame number, and can say so:

``` r

frames <- data.frame(
  individual = 1L,
  frame = 1:6,
  x = runif(6),
  y = runif(6)
)

af <- as_anipoint(frames, index = "frame")
get_index(af)
#> [1] "frame"
```

No column called `time` is involved, and none is required:

``` r

names(af)
#> [1] "individual" "frame"      "x"          "y"
```

Two rules follow from what the index *is*, and both are worth knowing.

**A frame has exactly one.** The index is where a row sits within its
context, so a second one would have nothing left to mean. Declaring more
than one is an error rather than a silent pick between them:

``` r

as_anipoint(frames, index = c("frame", "individual"))
#> Error in `ensure_index_name()`:
#> ! `index` must be a single column name.
#> ℹ A frame has exactly one index.
```

**It is never a grouping variable.** The frame is grouped by identity
plus temporal *context*; the index orders rows inside each of those
groups. Grouping by it as well would put every row in a group of its
own, so it stays out:

``` r

dplyr::group_vars(data)
#> [1] "individual" "keypoint"   "session"    "trial"
```

[`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
changes it, re-ordering the frame to match. The column that was
previously the index becomes an ordinary, undeclared one — it is not
promoted to temporal context, for the reason just given:

``` r

timestamped <- data |>
  dplyr::mutate(timestamp = time / 30) |>
  set_index("timestamp")

get_index(timestamped)
#> [1] "timestamp"
get_variables(timestamped, "when", "keys")
#> [1] "session" "trial"
dplyr::group_vars(timestamped)
#> [1] "individual" "keypoint"   "session"    "trial"
```

`time` is still there as a column; it is simply no longer declared as
anything.

Downstream operations (smoothing, derivatives) assume the index is
monotonically ordered within each entity, which is how
[`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
arranges the frame.

## Coordinate systems

The set of spatial columns determines the coordinate system. `anipoint`
recognises four families:

| System      | Columns                  |
|-------------|--------------------------|
| Cartesian   | `x`, `y`, optionally `z` |
| Polar       | `rho`, `phi`             |
| Cylindrical | `rho`, `phi`, `z`        |
| Spherical   | `rho`, `phi`, `theta`    |

The number of Cartesian columns picks the dimensionality
(`cartesian_1d`, `cartesian_2d`, `cartesian_3d`):

``` r

cart <- anipoint(
  individual = 1L, time = 1:3,
  x = c(0, 1, 2), y = c(0, 1, 4), z = c(0, 0, 1)
)
get_metadata(cart, "coordinate_system")
#> [1] cartesian_3d
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical
```

`rho` + `phi` indicates a polar-family system; the third column (if any)
distinguishes the variant:

``` r

pol <- anipoint(
  individual = 1L, time = 1:3,
  rho = c(1, 1, 1), phi = c(0, pi / 2, pi)
)
get_metadata(pol, "coordinate_system")
#> [1] polar
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical

cyl <- anipoint(
  individual = 1L, time = 1:3,
  rho = c(1, 1, 1), phi = c(0, pi / 2, pi), z = c(0, 1, 2)
)
get_metadata(cyl, "coordinate_system")
#> [1] cylindrical
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical

sph <- anipoint(
  individual = 1L, time = 1:3,
  rho = c(1, 1, 1), phi = c(0, pi / 2, pi), theta = c(0, pi / 4, pi / 2)
)
get_metadata(sph, "coordinate_system")
#> [1] spherical
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical
```

For programmatic checks, every coordinate system has both an
`is_<system>()` predicate (returns logical) and an
`ensure_is_<system>()` guard (errors otherwise):

``` r

is_polar(pol)
#> [1] TRUE
is_cartesian_2d(cart)
#> [1] FALSE
```

## Orientation

Position says where an entity is; orientation says which way it faces.
It is declared next to position, in the `where` role’s `orientation`
slot: `yaw` for a 2D frame, a unit quaternion (`qw`, `qx`, `qy`, `qz`)
for a 3D one.

``` r

fly <- example_anipoint(n_keypoints = 1, n_individuals = 1, n_obs = 3) |>
  dplyr::mutate(heading = c(0, 0.1, 0.2)) |>
  set_variables(where = list(orientation = c(yaw = "heading")))

get_variables(fly, "where", "orientation")
#>       yaw 
#> "heading"
```

[Orientation](https://animovement.dev/anicore/articles/orientation.md)
covers the conventions, how orientation follows the frame’s axes, and
why it is not the direction of travel.

## Where to next?

- [The metadata
  attribute](https://animovement.dev/anicore/articles/aniframe-metadata.md)
  — units, sampling rate, and the setters that keep them consistent with
  the data.
- [Orientation](https://animovement.dev/anicore/articles/orientation.md)
  — which way the axes point, and which way an entity faces.
- [Structures](https://animovement.dev/anicore/articles/structures.md) —
  skeletons, teams and other relationships between values of an identity
  variable.
