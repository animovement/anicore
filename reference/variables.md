# Read and declare which columns carry identity, time, position and events

The `variables` metadata category says which columns play which role.
Each role is a list of named slots:

- `what`: `keys`, the identity columns.

- `when`: `keys`, the temporal context (session, trial), plus `index` on
  an anipoint or `interval` (`start`, `stop`) on an anievent.

- `where`: `position`, axis role to column, and optionally
  `orientation`: `yaw` in 2D or a unit quaternion `qw`, `qx`, `qy`, `qz`
  in 3D (anipoint only).

- `event`: `state` and `point`, the per-frame event columns (anipoint
  only).

The frame is grouped by the `keys` of `what` and `when`; see
[`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md).

Declaring restructures the frame to match — columns are retyped,
reordered and regrouped, and `coordinate_system` is re-derived — so the
metadata and the frame cannot drift apart. A column must exist before it
is declared.

- `set_variables()` replaces the slots it is given and leaves the rest.

- `add_variables()` appends to them.

- `remove_variables()` drops columns from them.

Each role argument takes a named list of slots, or a character vector
for the role's main slot: `keys` for `what` and `when`, `position` for
`where`. In `remove_variables()` a character vector drops the columns
from every slot of the role.

## Usage

``` r
get_variables(data, role = NULL, slot = NULL)

set_variables(data, what = NULL, when = NULL, where = NULL, event = NULL)

add_variables(data, what = NULL, when = NULL, where = NULL, event = NULL)

remove_variables(data, what = NULL, when = NULL, where = NULL, event = NULL)
```

## Arguments

- data:

  An aniframe.

- role:

  Role to read, or `NULL` for the whole category.

- slot:

  Slot within `role`, or `NULL` for the union of its slots.

- what, when, where, event:

  A named list of slots, or a character vector for the role's main slot.

## Value

`get_variables()`: the whole category; the columns of a role, unnamed;
or one slot as stored. The setters: `data`, restructured.

## See also

[`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md),
[`get_index()`](https://animovement.dev/anicore/reference/get_index.md),
[`set_index()`](https://animovement.dev/anicore/reference/set_index.md),
[`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
get_variables(af, "what")
#> [1] "individual" "keypoint"  
get_variables(af, "where", "position")
#>   x   y 
#> "x" "y" 

# Declaring an identity column groups the frame by it
af |>
  dplyr::mutate(id = "a") |>
  add_variables(what = "id") |>
  dplyr::group_vars()
#> [1] "individual" "keypoint"   "id"         "session"    "trial"     

# Axis roles map to columns of any name
df <- data.frame(time = 1:3, u = c(1, 2, 3), v = c(0, 1, 0))
as_anipoint(df, variables_where = c("u", "v")) |>
  set_variables(where = c(x = "u", y = "v")) |>
  get_metadata("coordinate_system")
#> Warning: Could not infer coordinate system from spatial variables: "u" and "v".
#> ℹ Setting coordinate system to "unknown".
#> ℹ To keep the coordinate system, say which axis each column carries with
#>   `set_variables(data, where = )`.
#> [1] cartesian_2d
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical
```
