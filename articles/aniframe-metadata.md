# Metadata on an aniframe

``` r

library(anicore)
```

## Why an attribute, not columns?

Every `anipoint` carries a metadata list as an R attribute alongside the
data columns. The metadata records the things that are true of the
recording as a whole rather than of any single observation: the source
software, the sampling rate, what units the spatial coordinates are in,
which way its axes point, and so on.

Keeping this information attached to the object — rather than living in
a separate file or being passed around as extra arguments — is what lets
the rest of the *animovement* ecosystem stay loosely coupled. A reader
(in *aniread*) populates the metadata at load time, and any downstream
tool can read it back without a hand-off.

This article covers the metadata attribute and the functions that read
and update it. For the data-column structure see [The aniframe data
structure](https://animovement.dev/anicore/articles/aniframe-structure.md);
for connections, which live in the `structure` category, see
[Structures](https://animovement.dev/anicore/articles/structures.md);
for axis directions and orientation, see
[Orientation](https://animovement.dev/anicore/articles/orientation.md).

## The metadata attribute

You can see the full metadata by printing it directly:

``` r

data <- example_anipoint()
get_metadata(data)
#> ── animovement metadata ────────────────────────────────────────────────────────
#> spec_version: aniframe 3.0.0, anievent 1.0.0
#> 
#> ── recording 
#> source         (character) : <NA>
#> source_version (character) : <NA>
#> source_format  (character) : <NA>
#> filename       (character) : <NA>
#> 
#> ── time 
#> unit_time         (factor)  : "frame"
#>                               [levels: unknown, frame, ns, us, ms, s, m, h]
#> sampling_rate     (numeric) : <NA>
#> sampling_interval (numeric) : 1
#> start_datetime    (POSIXct) : <NA>
#> 
#> ── space 
#> coordinate_system (factor)    : "cartesian_2d"
#>                                 [levels: unknown, cartesian_1d, cartesian_2d, cartesian_3d, polar, cylindrical, spherical]
#> reference_frame   (factor)    : "allocentric"
#>                                 [levels: allocentric, egocentric, none]
#> handedness        (factor)    : "unknown"
#>                                 [levels: right, left, unknown]
#> axis_directions   (character) : 
#> axis_extents      (numeric)   : 
#> unit_space        (factor)    : "px"
#>                                 [levels: px, none, nm, um, mm, cm, m, km]
#> unit_angle        (factor)    : "rad"
#>                                 [levels: rad, deg, none]
#> euler_sequence    (character) : <NA>
#> euler_intrinsic   (logical)   : <NA>
#> 
#> ── variables 
#> what   keys: individual, keypoint
#> when   index: time | keys: session, trial
#> where  position: x = x, y = y
#> event  state: - | point: -
#> 
#> ── structure 
#> (empty)
```

The fields and their defaults are defined in one place,
[`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)
— that’s the canonical source of truth for what an `anipoint`’s metadata
looks like.

``` r

str(list_default_metadata(), max.level = 2)
#> List of 6
#>  $ spec_version:List of 2
#>   ..$ aniframe: chr "3.0.0"
#>   ..$ anievent: chr "1.0.0"
#>  $ recording   :List of 4
#>   ..$ source        : chr NA
#>   ..$ source_version: chr NA
#>   ..$ source_format : chr NA
#>   ..$ filename      : chr NA
#>  $ time        :List of 4
#>   ..$ unit_time        : Factor w/ 8 levels "unknown","frame",..: 2
#>   ..$ sampling_rate    : num NA
#>   ..$ sampling_interval: num NA
#>   ..$ start_datetime   : POSIXct[1:1], format: NA
#>  $ space       :List of 9
#>   ..$ coordinate_system: Factor w/ 7 levels "unknown","cartesian_1d",..: 3
#>   ..$ reference_frame  : Factor w/ 3 levels "allocentric",..: 1
#>   ..$ handedness       : Factor w/ 3 levels "right","left",..: 3
#>   ..$ axis_directions  : Named chr(0) 
#>   .. ..- attr(*, "names")= chr(0) 
#>   ..$ axis_extents     : Named num(0) 
#>   .. ..- attr(*, "names")= chr(0) 
#>   ..$ unit_space       : Factor w/ 8 levels "px","none","nm",..: 1
#>   ..$ unit_angle       : Factor w/ 3 levels "rad","deg","none": 1
#>   ..$ euler_sequence   : chr NA
#>   ..$ euler_intrinsic  : logi NA
#>  $ variables   :List of 4
#>   ..$ what :List of 1
#>   ..$ when :List of 2
#>   ..$ where:List of 1
#>   ..$ event:List of 2
#>  $ structure   : list()
#>  - attr(*, "class")= chr "aniframe_metadata"
```

The fields are grouped into **categories**, each answering one kind of
question:

| Category | Fields |
|----|----|
| `recording` | provenance: `source`, `source_version`, `source_format`, `filename` |
| `time` | `unit_time`, `sampling_rate`, `sampling_interval`, `start_datetime` |
| `space` | `coordinate_system`, `reference_frame`, `handedness`, `axis_directions`, `axis_extents`, `unit_space`, `unit_angle`, `euler_sequence`, `euler_intrinsic` |
| `variables` | which columns play which role: `what`, `when`, `where`, `event`, each a list of named slots |
| `structure` | relationships between levels of a variable — today’s connections |

`spec_version` sits above the categories: it is metadata about the
metadata, versioning the contract they describe. `space` is the one
category a class can lack — an `anievent` has no spatial component, so
its metadata simply has no `space` rather than a set of “none” values.

`filename` accepts a character vector — readers like
`aniread::read_trackball()` populate it with all source paths.

## Reading and writing metadata

[`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)
and
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
are the workhorses. The categories group the storage, but access stays
**flat**: a field is found and written by its own name wherever it
lives, and a category name returns the whole category.

``` r

get_metadata(data, "sampling_rate")
#> [1] NA

data <- set_metadata(data, sampling_rate = 30, source = "deeplabcut")
get_metadata(data, "sampling_rate")
#> [1] 30
get_metadata(data, "source")
#> [1] "deeplabcut"

names(get_metadata(data, "space"))
#> [1] "coordinate_system" "reference_frame"   "handedness"       
#> [4] "axis_directions"   "axis_extents"      "unit_space"       
#> [7] "unit_angle"        "euler_sequence"    "euler_intrinsic"
```

[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
validates the input — factor fields are checked against their permitted
levels, and unknown fields are rejected.

`set_*` functions only declare: they record a fact about the data and
never change a value. Operations that change values have their own verbs
and update the metadata to match:

| Function | Does |
|----|----|
| [`convert_unit_space()`](https://animovement.dev/anicore/reference/convert_unit_space.md) | rescales the length axes to another unit |
| [`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md) | rescales the index to another unit, using `sampling_rate` from frames |
| [`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md) | converts `phi`/`theta` (and any `cols`) between rad and deg |
| [`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md) | turns an axis over, reflecting its column |

[`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md)
follows the frame’s own index rather than a column called `time` — see
[the
index](https://animovement.dev/anicore/articles/aniframe-structure.html#the-index).

## Declaring the slot vocabulary

The `variables` category is a special case: its roles name columns
rather than describing values, so a name that matches nothing is a
promise the frame can’t keep. All but the `event` role go further — they
are not a description of the frame, they *are* its structure.
[`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
uses them to coerce column types, order columns and rows, group the
frame, and derive `coordinate_system`. Writing them without redoing that
work would leave the frame and its own metadata disagreeing — the print
header would update while the grouping still reflected the old
declaration.

The category holds one list per role, each with named slots: `what$keys`
(identity), `when$index` and `when$keys` (the position within a context,
and the context itself — an `anievent` has `when$interval` instead of an
index), `where$position` (the axis-role mapping), and `event$state` /
`event$point`. The frame groups by `c(what$keys, when$keys)` and nothing
else.

[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
refuses the whole category, and points you at the setters that do the
whole job:

``` r

data |> set_metadata(variables_what = "id")
#> Error in `ensure_no_declaration_fields()`:
#> ! `set_metadata()` cannot write variables_what directly.
#> ℹ This entry declares which columns carry identity, time, position and events,
#>   or how levels connect. Writing it here would leave the metadata naming
#>   columns the frame may not have, and the frame ordered and grouped as it was
#>   before.
#> ℹ Use `set_variables()` instead, which validate the columns exist and
#>   restructure the frame to match.
#> ℹ A complete metadata object can still be restored wholesale, as in
#>   `set_metadata(data, metadata = get_metadata(x))`.
```

The category has one family of verbs:
[`get_variables()`](https://animovement.dev/anicore/reference/variables.md),
[`set_variables()`](https://animovement.dev/anicore/reference/variables.md),
[`add_variables()`](https://animovement.dev/anicore/reference/variables.md)
and
[`remove_variables()`](https://animovement.dev/anicore/reference/variables.md),
each taking a role and, for the setters, a list of slots or a character
vector for the role’s main slot.
[`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
and
[`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md)
are shorthands. The column has to exist before it can be declared, so
the order is always create-then-declare:

``` r

tagged <- data |>
  dplyr::mutate(id = "trial_1") |>
  add_variables(what = "id")

get_variables(tagged, "what")
#> [1] "individual" "keypoint"   "id"
dplyr::group_vars(tagged)
#> [1] "individual" "keypoint"   "id"         "session"    "trial"
```

[`add_variables()`](https://animovement.dev/anicore/reference/variables.md)
appends to the declaration, so you don’t have to restate what is already
there — forgetting to would quietly demote an existing identity variable
and regroup the frame without it.

Declaring a spatial column refreshes the fields derived from it:

``` r

data |>
  dplyr::mutate(z = 0) |>
  add_variables(where = "z") |>
  get_metadata("coordinate_system")
#> [1] cartesian_3d
#> 7 Levels: unknown cartesian_1d cartesian_2d cartesian_3d polar ... spherical
```

`event` is the fourth role, and the one that doesn’t change the frame’s
shape: it declares which columns carry per-frame event labels, split
into interval-valued `state` columns and instantaneous `point` columns.
[`to_anievent()`](https://animovement.dev/anicore/reference/to_anievent.md)
reads it to know what to encode.

``` r

data |>
  dplyr::mutate(behaviour = factor("rest")) |>
  set_variables(event = list(state = "behaviour")) |>
  get_variables("event", "state")
#> [1] "behaviour"
```

## Which way the axes point

`axis_directions` records which way each axis points, read from where
the recording was made — `right`/`left`, `up`/`down`, `back`/`forward` —
and `axis_extents` how far it runs.
[`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md)
declares the directions;
[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
turns an axis over and changes the data to match. The sense of rotation
and the handedness are derived from them by
[`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)
and
[`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md).

``` r

data |>
  set_axis_directions(c(x = "right", y = "down")) |>
  get_angle_direction()
#> [1] "clockwise"
```

[Orientation](https://animovement.dev/anicore/articles/orientation.md)
sets out the model, including why the depth axis matters even for 2D
data.

## Units

Declare a unit with
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md);
convert values with `convert_unit_*()`. Factors between standard units
are derived; converting from `px` or `unknown` needs a
`calibration_factor`, and from `frame` a declared `sampling_rate`.

``` r

data <- example_anipoint(n_dims = 2) |>
  set_metadata(unit_space = "mm")

data_cm <- convert_unit_space(data, to_unit = "cm")
get_metadata(data_cm, "unit_space")
#> [1] cm
#> Levels: px none nm um mm cm m km
```

``` r

data <- example_anipoint() |> # default unit_time = "frame"
  set_metadata(sampling_rate = 30)
data_s <- convert_unit_time(data, "s")
range(data_s$time) # frames divided by fps
#> [1] 0.03333333 1.66666667
```

Spatial angular columns (`phi`, `theta`) are converted automatically by
[`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)
whenever they’re present. Pass `cols` only for non-spatial angular
columns (e.g. heading direction).

``` r

pol <- anipoint(
  individual = 1L, time = 1:3,
  rho = c(1, 1, 1), phi = c(0, pi / 2, pi)
)
pol$phi
#> [1] 0.000000 1.570796 3.141593
pol_deg <- convert_unit_angle(pol, to_unit = "deg")
pol_deg$phi
#> [1]   0  90 180
```
