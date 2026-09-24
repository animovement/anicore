# Changelog

## anicore (development version)

### Breaking changes

- The position frame is now `anipoint`, and `aniframe` is the abstract
  parent of every frame class: `anipoint`, `anisegment`, `anijoint` and
  `anievent`
  ([\#154](https://github.com/animovement/anicore/issues/154)).
  - [`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md),
    [`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md),
    [`example_anipoint()`](https://animovement.dev/anicore/reference/example_anipoint.md)
    and
    [`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
    replace the
    [`aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
    versions, which remain as soft-deprecated aliases for one release.
  - [`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md)
    is now `TRUE` for any frame, including an anievent. Test the grain
    with
    [`is_anipoint()`](https://animovement.dev/anicore/reference/is_anipoint.md)
    or
    [`ensure_is_anipoint()`](https://animovement.dev/anicore/reference/ensure_is_anipoint.md);
    functions that need coordinates now reject other grains.
  - Re-cast objects saved with earlier versions with
    [`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
    or
    [`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md).
- Metadata is grouped into categories — `recording`, `time`, `space`,
  `variables` and `structure` — and `spec_version` becomes 3.0.0 for
  anipoint frames and 1.0.0 for anievents
  ([\#118](https://github.com/animovement/anicore/issues/118)). Access
  stays flat: `get_metadata(x, "sampling_rate")`,
  `get_metadata(x)$sampling_rate` and
  `set_metadata(x, sampling_rate = 30)` work as before, and a category
  name returns the whole category. Reading `attr(x, "metadata")`
  directly no longer works. Objects in the old layout are migrated when
  read.
  - An anievent has no `space` category: its spatial fields read `NULL`,
    and spatial fields passed to
    [`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md)
    are dropped
    ([\#73](https://github.com/animovement/anicore/issues/73)).
  - [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)
    with several names returns a plain list, and setting a field to
    `NULL` errors (use `NA`).
- `set_*()` functions now only declare; operations that change values
  have their own verbs
  ([\#155](https://github.com/animovement/anicore/issues/155)).
  - [`get_variables()`](https://animovement.dev/anicore/reference/variables.md),
    [`set_variables()`](https://animovement.dev/anicore/reference/variables.md),
    [`add_variables()`](https://animovement.dev/anicore/reference/variables.md)
    and
    [`remove_variables()`](https://animovement.dev/anicore/reference/variables.md)
    replace the sixteen `*_variables_*()` functions and `set_axes()`.
    They take a role and a slot,
    e.g. `set_variables(x, when = list(keys = "trial"))`.
    `get_variables(x, "when")` now includes the index; the grouping
    columns are
    [`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md).
  - [`convert_unit_space()`](https://animovement.dev/anicore/reference/convert_unit_space.md),
    [`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md)
    and
    [`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)
    replace `set_unit_*()`. Converting from `px`, `frame` or `unknown`
    now needs a `calibration_factor`, or, from `frame`, a declared
    `sampling_rate`.
  - [`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md)
    only records directions;
    [`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
    turns an axis over and reflects the data.
  - The unit and sampling-rate getters and setters,
    `get_/set_axis_extents()`, `set_handedness()` and
    `set_angle_direction()` are removed; use
    [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)
    and
    [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md).
    `set_sampling_rate()` also converted frames to seconds: use
    `set_metadata(x, sampling_rate = r) |> convert_unit_time("s")`.
- Structures replace connections
  ([\#154](https://github.com/animovement/anicore/issues/154)). An
  [`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)
  holds points, segments with optional expected lengths, and joints:
  angles between two segments, with optional limits. A frame can hold
  several named structures, including several over one variable, through
  [`set_structure()`](https://animovement.dev/anicore/reference/structures.md),
  [`get_structure()`](https://animovement.dev/anicore/reference/structures.md)
  and
  [`remove_structure()`](https://animovement.dev/anicore/reference/structures.md).
  The `*_connections()` functions are removed; stored connection tables
  become structures.

### Added

- [`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md)
  gives one row per segment of a structure: its `length` and unit
  direction
  ([\#154](https://github.com/animovement/anicore/issues/154)).
  `as_anipoint(seg, root = )` rebuilds positions from segments, for
  example after holding lengths constant.

- [`as_anijoint()`](https://animovement.dev/anicore/reference/as_anijoint.md)
  gives one angle per joint of a structure
  ([\#154](https://github.com/animovement/anicore/issues/154)).
  [`angle_between()`](https://animovement.dev/anicore/reference/angle_between.md)
  is the underlying computation.

- Orientation can be declared alongside position: `yaw` in 2D, or a unit
  quaternion in 3D
  ([\#46](https://github.com/animovement/anicore/issues/46)).
  [`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
  and
  [`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)
  handle it, and `euler_sequence` and `euler_intrinsic` record the Euler
  convention a source uses.

- [`convert_inf_to_na()`](https://animovement.dev/anicore/reference/convert_inf_to_na.md),
  the sibling of
  [`convert_nan_to_na()`](https://animovement.dev/anicore/reference/convert_nan_to_na.md),
  for sources that mark a missing observation with an infinity rather
  than a `NaN`. TRex is one — its own documentation masks `np.inf` out
  before plotting, and its `missing` flag is 1 in exactly those frames.
  Left in place an `Inf` propagates through arithmetic silently, so one
  untracked frame turns a mean or a speed into `Inf` rather than into a
  missing value (animovement/aniread#116).

- A `source_format` metadata field, recording which export layout a file
  was read as (animovement/aniread#118). Tracking software changes its
  export layout between releases — FreeMoCap’s tidy CSV gained a
  `reprojection_error` column at v1.8.0, and its wide per-model CSVs are
  a different layout again — so `source` alone does not say what was
  parsed. Readers set it to a short layout name such as
  `"by_frame_9col"`.

  It is deliberately separate from `source_version`, which stays
  reserved for a version the file actually states. Most tracking formats
  record none, and a layout inferred from a column count must not be
  stored as though it had been read. Where both are known, both are set.

- Circular descriptive statistics, beside the existing angle utilities:
  [`circ_median()`](https://animovement.dev/anicore/reference/circ_median.md)
  (Fisher’s median),
  [`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md),
  [`circ_sd()`](https://animovement.dev/anicore/reference/circ_sd.md)
  and
  [`circ_mad()`](https://animovement.dev/anicore/reference/circ_mad.md).
  Where two directions tie for the median, they are averaged **on the
  circle**: averaging them arithmetically returns their antipode when
  the tie straddles zero, which is 180 degrees from the answer. Angles
  have no smallest or largest value, so the ordinary median and standard
  deviation do not apply — the mean of 350 and 10 degrees is 0, not 180
  ([\#147](https://github.com/animovement/anicore/issues/147)).

- [`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md)
  and
  [`circ_successive_difference()`](https://animovement.dev/anicore/reference/circ_successive_difference.md),
  moved here from anispace, where they were
  `calculate_angular_difference()` and `diff_angle()`. The first is the
  shortest signed distance between two angles you name; the second
  applies it along a series, comparing each angle with the one before
  it. Both are general-purpose primitives rather than spatial transforms
  —
  [`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md)
  is the one the circular summaries are built on — so anicore owns them
  alongside the rest of the angle utilities
  ([\#147](https://github.com/animovement/anicore/issues/147)).

  The rename follows the convention these settle on: `circ_*()` for
  functions that compute with the wraparound, where an ordinary mean or
  difference would give the wrong answer, and `*_angle()` or `x_to_y()`
  for manipulating how an angle is written.

### Changed

- The order of the identity keys (formerly `variables_what`) no longer
  asserts a hierarchy
  ([\#140](https://github.com/animovement/anicore/issues/140),
  [\#141](https://github.com/animovement/anicore/issues/141)). It was
  documented as coarse to fine, which reads naturally for the names that
  nest — a subject has tracks, a track has keypoints — but identity
  variables need not nest at all. `sex`, `treatment` and `genotype`
  partition a population without containing one another, and there is no
  sense in which one is finer than the next.

  The order is now documented as what auto-detection emits, not
  something a frame asserts. Nothing should read a position among the
  identity keys as meaning a level; a function that needs to know which
  variable to act on asks for it — `animetric::add_centroid()` takes
  `across`, `anispace::translate_coords()` takes `level`.

  No behaviour changes. Detection emits the same order, and the order
  still carries through to column order and grouping, which is
  presentation: grouping by `(a, b)` and `(b, a)` gives the same groups.

## anicore 0.8.0 (2026-08-28)

### Changed

- **The package is renamed from `aniframe` to `anicore`**
  ([\#84](https://github.com/animovement/anicore/issues/84)). It is no
  longer one class’s home: it declares `aniframe`, `anievent` and — as
  [\#84](https://github.com/animovement/anicore/issues/84) settles — the
  types the domain packages build on, while producing almost none of
  them. A package named after one of its entries was going to keep
  getting stranger as angles
  ([\#83](https://github.com/animovement/anicore/issues/83)),
  orientation ([\#46](https://github.com/animovement/anicore/issues/46))
  and masks ([\#11](https://github.com/animovement/anicore/issues/11))
  arrive.

  **The `aniframe` class keeps its name**, as do
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md),
  [`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md)
  and every other function. Only the package changes:
  [`library(anicore)`](https://animovement.dev/anicore/), `anicore::`,
  and `install.packages("anicore")`.

  Done now rather than at 1.0.0 because a rename only ever gets more
  expensive, and there are no external users yet to carry the cost.

- [`?aniframe`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  is the constructor again. The package documentation had claimed the
  same help topic, so the two were merged into one page; it is now
  [`?anicore`](https://animovement.dev/anicore/reference/anicore.md).

### Added

- An aniframe can be indexed by a column that is not called `time`
  ([\#109](https://github.com/animovement/anicore/issues/109)). A
  `variables_index` metadata field names the single column each row is
  positioned by;
  [`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
  reads it,
  [`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
  changes it and re-orders the frame, and
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  and
  [`aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  take an `index` argument. A frame has exactly one index, and it is
  never a grouping variable.

  `set_unit_time()`, `set_sampling_rate()` and
  [`to_anievent()`](https://animovement.dev/anicore/reference/to_anievent.md)
  act on the declared index rather than a column named `time`, and
  [`validate_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  checks it is present and numeric.

  An `anievent` has no index, since a bout is delimited by `start` and
  `stop`. Its `variables_index` is `NA` and
  [`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
  errors on it.

- [`get_sampling_interval()`](https://animovement.dev/anicore/reference/get_sampling_interval.md)
  reports the spacing of the index, derived from the data at
  construction rather than declared, and
  [`is_sampling_regular()`](https://animovement.dev/anicore/reference/is_sampling_regular.md)
  says whether that spacing is even
  ([\#114](https://github.com/animovement/anicore/issues/114)). Nothing
  in the stack could previously tell whether a frame was regularly
  sampled, which several downstream functions need — interpolating on
  row position rather than on time is only correct when it is.

  Measured per key, since the index restarts in each group and a frame
  regular within every track can look irregular pooled. Regularity is
  computed on demand rather than stored, because dropping rows changes
  the answer; its `tolerance` is an argument, and relative, so
  floating-point timestamps are not called irregular over the last
  decimal place.

  [`validate_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  warns when a declared `sampling_rate` disagrees with the measured
  spacing — the same shape as
  [\#98](https://github.com/animovement/anicore/issues/98), where the
  metadata claimed a unit the data was not in.

- `get_sampling_rate()`, `get_unit_space()`, `get_unit_time()` and
  `get_unit_angle()` read the fields that already had setters
  ([\#121](https://github.com/animovement/anicore/issues/121)). Every
  field with a dedicated setter now has a dedicated getter, so reading
  one no longer means naming it as a string. The factor-backed ones
  return a bare character vector, which is what callers were doing with
  [`as.character()`](https://rdrr.io/r/base/character.html) anyway.

- [`get_coordinate_system()`](https://animovement.dev/anicore/reference/get_coordinate_system.md)
  reads the coordinate system a frame is in
  ([\#109](https://github.com/animovement/anicore/issues/109)). There is
  deliberately no setter: the field is derived from the axis roles, so
  `set_axes()` says what the columns mean and `anispace`’s `map_to_*()`
  functions convert the coordinates.

- An `axes` metadata field records which column carries which axis role,
  so coordinates may be carried by columns of any name
  ([\#109](https://github.com/animovement/anicore/issues/109)).
  [`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md)
  reads it, `set_axes()` changes it, and
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  and `set_variables_where()` accept the same mapping —
  `c(x = "u", y = "v")`. `coordinate_system` follows from it, and
  `set_unit_space()` and the axis extents resolve through it. The roles
  are a closed set: `x`, `y`, `z`, `rho`, `phi`, `theta`, and one that
  forms no coordinate system is rejected by name at declaration.
  Declaring spatial columns without roles keeps its old meaning, the
  column name being the role.

- Axis directions and extents record how a frame is laid out, replacing
  `origin` and `y_height`
  ([\#124](https://github.com/animovement/anicore/issues/124)).
  `axis_directions` maps each axis role to one of `right`, `left`, `up`,
  `down`, `back` or `forward`, read from where the recording was made;
  `axis_extents` maps each to how far it runs.
  [`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md),
  [`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md),
  `get_axis_extents()` and `set_axis_extents()` read and write them.
  Turning an axis to its opposite reflects that column: around the axis
  extent where one is declared, around zero where none is. The column is
  found by role, so a frame whose vertical axis is called something else
  is handled, and an angular frame refuses rather than leaving every
  stored angle facing the wrong way.

- [`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)
  says which way angles run, derived from the axis directions rather
  than recorded
  ([\#124](https://github.com/animovement/anicore/issues/124)).
  `atan2(y, x)` counts counter-clockwise, so the same physical heading
  comes out mirrored between a y-down and a y-up frame; nothing said
  which convention a number was in.

- [`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md)
  and `set_handedness()` say whether a frame is right- or left-handed
  ([\#124](https://github.com/animovement/anicore/issues/124)). Three
  declared axis directions determine it and are read in preference to
  the `handedness` field, which carries the convention for a frame that
  states one without spelling the axes out. `set_handedness()` defaults
  to right-handed and completes the third axis when two are declared.

- `set_angle_direction()` asks for a sense of rotation and declares the
  axis directions that give it
  ([\#124](https://github.com/animovement/anicore/issues/124)), turning
  the vertical axis over when both are already declared.

- [`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)
  and
  [`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md)
  move here from `anispace`
  ([\#128](https://github.com/animovement/anicore/issues/128)). They are
  angle arithmetic rather than coordinate transformation, and belong
  beside
  [`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md)
  and
  [`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
  which were already here. `animetric` re-exported both from `anispace`,
  which is the sign of a primitive sitting one layer above the packages
  that need it.

- Turning an axis over on a frame that stores angles recomputes them,
  rather than refusing
  ([\#134](https://github.com/animovement/anicore/issues/134)). No
  column carries `x`, `y` or `z` on a polar, cylindrical or spherical
  frame, but the angles are measured from those axes: turning `x` over
  takes the supplement of `phi`, turning `y` over negates it, and
  turning `z` over takes the supplement of `theta`. The result comes
  back in the unit and range the frame keeps its angles in, and `rho`
  never moves. An axis with a declared extent still refuses, because
  reflecting around it would move every point’s distance from the
  origin.

- Every exported function now has a runnable example
  ([\#106](https://github.com/animovement/anicore/issues/106)).

### Changed

- Declaring an axis role that is carried by one column while a
  different, undeclared column has that role’s name now warns
  ([\#119](https://github.com/animovement/anicore/issues/119)). The
  frame is legal and the mapping is right, but `.data$x` then returns a
  column that is not the x axis. Silence it with
  `options(aniframe.quiet = TRUE)`.

- `coordinate_system` follows from which axis roles are declared rather
  than from column names
  ([\#109](https://github.com/animovement/anicore/issues/109)). A frame
  whose coordinates are named something else is now inferred correctly,
  where it degraded to `unknown` and was refused by every spatial
  function.

- [`is_cartesian()`](https://animovement.dev/anicore/reference/is_cartesian.md),
  [`is_polar()`](https://animovement.dev/anicore/reference/is_polar.md),
  [`is_cylindrical()`](https://animovement.dev/anicore/reference/is_cylindrical.md),
  [`is_spherical()`](https://animovement.dev/anicore/reference/is_spherical.md),
  the `is_cartesian_*d()` variants and their `ensure_` guards read
  `coordinate_system` rather than matching column names, and require an
  aniframe ([\#107](https://github.com/animovement/anicore/issues/107),
  [\#109](https://github.com/animovement/anicore/issues/109)). A frame
  whose coordinates are called something else now satisfies the
  predicate for the system it is in, and an undeclared column no longer
  decides the answer — a spherical frame that has dropped `rho` from its
  declaration is no longer reported as spherical. The guards say which
  system the frame is in and how to get to the one you need.

- `add_variables_where()` and `remove_variables_where()` carry the axis
  roles through
  ([\#109](https://github.com/animovement/anicore/issues/109)). They
  combined bare column names, so on a frame with declared roles every
  addition or removal reduced it to `unknown`. Removing an axis until
  the remainder forms no coordinate system warns rather than aborting;
  declaring such a set outright still aborts.

- [`validate_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  warns when identity, temporal context and the index together do not
  name one observation per row
  ([\#49](https://github.com/animovement/anicore/issues/49)). A repeat
  means some variable that tells the rows apart is undeclared, and every
  grouped operation folds them together.

- `variables_when` no longer names the column the frame is indexed by;
  read that from `variables_index`, via
  [`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
  ([\#109](https://github.com/animovement/anicore/issues/109)). It holds
  only the temporal context, so a frame with none has
  [`character()`](https://rdrr.io/r/base/character.html) where it had
  `c("time")`, as does
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md).
  `aniprocess::filter_across()` and `filter_na_across()` take
  `variables_when[1]` as the time column and must swap to
  `aniframe::get_index()`. Code reading the grouping columns is
  unaffected, and no longer has anything to exclude: they are
  `c(variables_what, variables_when)`.

- `default_metadata()` is renamed
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)
  ([\#121](https://github.com/animovement/anicore/issues/121)).

- `origin` and `y_height` are removed, along with `set_origin()` and
  `set_y_height()`
  ([\#124](https://github.com/animovement/anicore/issues/124)). Use
  [`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md)
  and `set_axis_extents()`. `origin` recorded a corner, but the origin
  is `(0, 0)` in both of its values — what differed was the direction y
  increases in, which is what is recorded now. It also had nothing to
  say for 3D data or for a recording with no frame corners at all. The
  deprecated `point_of_reference` alias goes with the field it aliased.

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  no longer fills in an axis extent from the data
  ([\#124](https://github.com/animovement/anicore/issues/124)).
  `y_height` fell back to `max(y)`, which is the highest tracked point
  rather than the frame height, so a frame that was never told its
  height reflected around the wrong place. A frame now declares no
  extent until given one, and an axis with no extent is negated when
  turned over rather than reflected around a guess. `aniread`’s readers
  supply the video height they know about.

- `spec_version` moves to `aniframe = "2.0.0"` and `anievent = "0.3.0"`
  ([\#109](https://github.com/animovement/anicore/issues/109)). Major
  for `aniframe`: `variables_when` no longer names the index, which
  breaks a consumer reading it from there. Minor for `anievent`, which
  gains `variables_index` as `NA`.

### Fixed

- `set_unit_space()` converts the axis extents along with the
  coordinates
  ([\#124](https://github.com/animovement/anicore/issues/124)). An
  extent is a length, so converting cm to m left the frame claiming a
  height in the unit it no longer used.

- `set_unit_space()` converts the length axes of the frame’s coordinate
  system rather than whichever of `x`, `y` and `z` are present
  ([\#98](https://github.com/animovement/anicore/issues/98)). `rho` is a
  length on polar, cylindrical and spherical frames and was never
  converted, while the metadata was updated to claim the new unit.
  Angular axes remain `set_unit_angle()`’s to convert. Where the
  coordinate system is `unknown` a length cannot be told from an angle,
  and the function now warns rather than silently converting nothing.

- `set_unit_space()`, `set_unit_angle()`, `set_unit_time()` and
  `set_sampling_rate()` no longer re-inject a `keypoint` column and
  overwrite `variables_what` with it
  ([\#96](https://github.com/animovement/anicore/issues/96)). A frame
  given a custom identity such as `id` was silently regrouped on a
  constant column.

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  keeps the roles a frame already declares rather than re-deriving them,
  so casting an aniframe is no longer destructive
  ([\#96](https://github.com/animovement/anicore/issues/96)). A
  declaration whose columns have since been dropped still falls through
  to detection, so a cast continues to repair a drifted frame.

## anicore 0.7.0 (2026-08-18, as aniframe)

### Added

- `set_variables_what()`, `set_variables_when()`,
  `set_variables_where()` and `set_variables_event()` declare the
  variable roles, each with `get_`, `add_` and `remove_` verbs
  ([\#82](https://github.com/animovement/anicore/issues/82)). They
  declare the role *and* restructure the frame to match, so the metadata
  and the frame cannot drift apart. `add_variables_*()` appends, so
  adding one identity column no longer means restating the others.

- [`validate_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  re-checks that the metadata still describes the frame: every declared
  column present, `time` and the spatial columns numeric
  ([\#79](https://github.com/animovement/anicore/issues/79)).
  Counterpart to
  [`validate_anievent()`](https://animovement.dev/anicore/reference/validate_anievent.md).

- [`is_spatial()`](https://animovement.dev/anicore/reference/is_spatial.md)
  and
  [`ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.md)
  test the columns named in `variables_where`, which the
  `is_cartesian*()` family does not — those look at column names only
  ([\#79](https://github.com/animovement/anicore/issues/79)).

### Changed

- [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  no longer writes the `variables_*` fields; use their dedicated setters
  ([\#82](https://github.com/animovement/anicore/issues/82)). Writing
  them as plain metadata left the frame typed, ordered and grouped as
  before, so operations silently integrated across identities. A
  complete metadata object can still be restored wholesale.

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  errors when `variables_what` names a column that is not in the data,
  as it already did for `variables_when` and `variables_where`
  ([\#77](https://github.com/animovement/anicore/issues/77)).

- `aniframe` and `anievent` recognise the same identity variables —
  `model`, `individual`, `subject`, `track`, `keypoint` — ordered coarse
  to fine ([\#77](https://github.com/animovement/anicore/issues/77)).

- `spec_version` moves to `aniframe = "1.1.0"` and `anievent = "0.2.0"`.

### Removed

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  no longer adds a `keypoint = "centroid"` column to data that already
  has an identity column
  ([\#77](https://github.com/animovement/anicore/issues/77)). Results
  are unaffected — the column was constant — but it no longer appears in
  the frame or the print header.

### Fixed

- Downstream subclasses survive the class-preserving methods
  ([\#81](https://github.com/animovement/anicore/issues/81)).
  `animetric`’s `aniframe_kin` was dropped by the first
  [`filter()`](https://rdrr.io/r/stats/filter.html), `mutate()` or `[`.
  Verbs that were never covered — `distinct()`, joins, `bind_rows()` —
  still drop it.

- An `anievent` no longer claims spatial properties it cannot have, such
  as a BORIS export announcing `origin: bottom_left`
  ([\#73](https://github.com/animovement/anicore/issues/73)).
  `unit_angle`, `origin` and `reference_frame` gain a `"none"` level.

## anicore 0.6.0 (2026-06-24, as aniframe)

### Added

- `anievent`, a class for behavioural events in long format — one row
  per bout (state event) or instant (point event)
  ([\#67](https://github.com/animovement/anicore/issues/67)). A sibling
  of `aniframe`: it shares the metadata substrate but does not inherit
  from it. Required columns are `channel`, `type`, `label`, `start` and
  `stop`, with identity columns travelling via `variables_what` and an
  optional `modifiers` list-column. `type` is derived per
  `(channel, label)` group at construction — a group is `"point"` only
  when all its bouts are instantaneous — and can be set explicitly where
  that misclassifies.

- [`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
  and
  [`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md)
  construct the class,
  [`is_anievent()`](https://animovement.dev/anicore/reference/is_anievent.md)
  and
  [`ensure_is_anievent()`](https://animovement.dev/anicore/reference/ensure_is_anievent.md)
  test it, and
  [`validate_anievent()`](https://animovement.dev/anicore/reference/validate_anievent.md)
  re-checks its invariants on demand
  ([\#68](https://github.com/animovement/anicore/issues/68)).
  Class-preserving dplyr and base-R methods keep the class through
  tidyverse pipelines.

- [`to_anievent()`](https://animovement.dev/anicore/reference/to_anievent.md)
  run-length-encodes per-frame data into bouts, as distinct from
  [`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md),
  which casts data that is already bout-shaped. Methods for `data.frame`
  and `aniframe`; the latter auto-detects each channel’s identity scope,
  so a label constant across keypoints does not produce a duplicate bout
  per keypoint.

- A `variables_event` metadata field — a named list `list(state, point)`
  declaring which columns hold per-frame event labels
  ([\#66](https://github.com/animovement/anicore/issues/66)). State
  columns are interval-valued, point columns instantaneous; both appear
  in the print header when populated.

- A `spec_version` metadata field, keyed by class, so each class’s data
  contract can evolve independently of the package version
  ([\#65](https://github.com/animovement/anicore/issues/65)). Older
  serialised objects without it continue to validate.

- `set_unit_time()` and `set_sampling_rate()` are S3 generics with
  `aniframe` and `anievent` methods. On an anievent the calibration
  factor applies to `start` and `stop` rather than `time`.

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  auto-detects `observation` as a temporal grouping column, alongside
  `session` and `trial`.

- New article, “The anievent data structure”, covering channels, state
  and point events, modifiers, validation and multi-observation data
  ([\#70](https://github.com/animovement/anicore/issues/70)).

### Changed

- [`validate_anievent()`](https://animovement.dev/anicore/reference/validate_anievent.md)
  warns when two bouts of the same `channel` overlap within a group. A
  warning rather than an error: overlap is normal BORIS output and the
  long format handles it natively.

- [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  accepts partial `variables_event` input — supplying only `state` or
  only `point` is fine, and `NA` or empty entries read as “none” rather
  than erroring
  ([\#76](https://github.com/animovement/anicore/issues/76)).

- The metadata print heading reads “animovement metadata”, since the
  substrate is shared by both classes
  ([\#69](https://github.com/animovement/anicore/issues/69)). The S3
  class name is unchanged.

## anicore 0.5.0 (2026-05-04, as aniframe)

### Added

- `set_origin()` converts between the `bottom_left` and `top_left`
  origin conventions, reflecting `y` around the recorded frame height
  ([\#52](https://github.com/animovement/anicore/issues/52)).

- `set_y_height()` sets the y-axis frame height that `set_origin()`
  uses, validated against the data range, and a `y_height` metadata
  field to hold it. Readers populate it from the source;
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  falls back to `max(y)` when missing, and never overwrites an existing
  value.

- A `connections` metadata field for skeletons and other variable-level
  networks ([\#6](https://github.com/animovement/anicore/issues/6)).
  Stored as a named list keyed by the relevant identity or temporal
  variable — typically `keypoint`, but `individual` for social networks
  — with each entry a 2-column `from`/`to` tibble whose order is
  preserved. Manage it with `set_connections()`, `get_connections()`,
  `add_connections()` and `remove_connections()`. Endpoints missing from
  the corresponding column warn but are kept.

- A “Time” row in the print summary showing the tracked interval as
  `HH:MM:SS to HH:MM:SS`, or as absolute datetimes when `start_datetime`
  is set ([\#50](https://github.com/animovement/anicore/issues/50)).
  Sub-second runs use millisecond precision.

- New articles introducing the data structure: “The aniframe data
  structure”, “Metadata on an aniframe” and “Connections”.

### Changed

- `set_unit_angle()` converts the spatial angular columns `phi` and
  `theta` whenever they are present, so polar, cylindrical and spherical
  coordinates stay consistent with the declared `unit_angle`
  ([\#21](https://github.com/animovement/anicore/issues/21)). These were
  previously assumed to be radians and left alone. The signature becomes
  `set_unit_angle(data, to_unit, cols = NULL)`, matching
  `set_unit_time()`; pass `cols` only for additional non-spatial angular
  columns. Positional callers need to swap their arguments.

- The print summary is driven by `variables_what` and `variables_when`
  rather than hard-coded column names
  ([\#51](https://github.com/animovement/anicore/issues/51)). Custom
  identity and temporal variables such as `track` and `model` now
  appear, rows are omitted when their column is absent, and single-track
  readers no longer emit “Unknown or uninitialised column:
  `individual`”.

- The metadata print renders as a single block with field names and
  values aligned in fixed-width columns
  ([\#48](https://github.com/animovement/anicore/issues/48)).

- The `filename` metadata field accepts a character vector of length one
  or more, for readers that load from multiple source files
  ([\#34](https://github.com/animovement/anicore/issues/34)).

- Renamed the `point_of_reference` metadata field to `origin`, with
  permitted values `"bottom_left"` and `"top_left"`.

### Deprecated

- `point_of_reference` as a metadata field name.
  [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  still accepts it, with a warning.

### Fixed

- [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  no longer mis-classifies cylindrical (`rho`, `phi`, `z`) and spherical
  (`rho`, `phi`, `theta`) data as Cartesian
  ([\#44](https://github.com/animovement/anicore/issues/44)). Detection
  recognises the `rho` + `phi` signature first, so cylindrical data is
  no longer reduced to `cartesian_1d` by its `z` column. Cylindrical
  spatial columns are now ordered `rho`, `phi`, `z`
  ([\#43](https://github.com/animovement/anicore/issues/43)).

## anicore 0.4.1 (as aniframe)

### Fixed

- Corrected metadata written by
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md).

## anicore 0.4.0 (as aniframe)

### Added

- `variables_what`, `variables_when` and `variables_where` arguments to
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  and
  [`example_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md),
  written into the frame’s metadata. These declare which columns carry
  identity, temporal position and spatial position, and are the basis
  for how the frame is typed, ordered and grouped.

### Changed

- Identity and temporal variables are coerced to integer, with the
  exception of `time`, which stays numeric.
- `time` is required. A frame without it is no longer a valid aniframe.
- An unrecognised set of spatial columns is accepted, with
  `coordinate_system` recorded as `"unknown"`, rather than refused.

## anicore 0.3.5 (as aniframe)

### Added

- A `NEWS.md` file, to track changes to the package.
- Smaller units: `ns` (nanosecond), `us` (microsecond), `nm` (nanometre)
  and `um` (micrometre).

### Removed

- `get_trackball_calibration_factor()`, following the move of trackball
  handling to aniread.

## anicore 0.3.4 (as aniframe)

### Removed

- Trackball calibration. It reads hardware output rather than describing
  a frame, and belongs with the readers in aniread.

## anicore 0.3.3 (as aniframe)

### Fixed

- `NA` and `NaN` handling in metadata and coercion.
- An `NA` datetime is no longer given a class, which had made empty
  `start_datetime` values print oddly.

## anicore 0.3.2 (as aniframe)

### Changed

- `"cartesian"` is no longer a permitted `coordinate_system` value; the
  dimensioned forms `cartesian_1d`, `cartesian_2d` and `cartesian_3d`
  replace it.
- Metadata printing and the `start_datetime` class were tidied.

## anicore 0.3.1 (as aniframe)

### Removed

- `add_centroid()`. Deriving a centroid is a metric rather than a
  property of the frame, and belongs in animetric.

## anicore 0.3.0 (as aniframe)

Spatial transformations leave aniframe for
[anispace](https://github.com/animovement/anispace). aniframe keeps the
coordinate *system* — what a frame is in, and how to test it — while
converting between systems becomes anispace’s job.

### Added

- [`ensure_is_cartesian()`](https://animovement.dev/anicore/reference/ensure_is_cartesian.md),
  with `_1d()`, `_2d()` and `_3d()` variants, and
  [`ensure_is_polar()`](https://animovement.dev/anicore/reference/ensure_is_polar.md),
  [`ensure_is_cylindrical()`](https://animovement.dev/anicore/reference/ensure_is_cylindrical.md)
  and
  [`ensure_is_spherical()`](https://animovement.dev/anicore/reference/ensure_is_spherical.md)
  — guards to sit at the top of a function that requires a particular
  coordinate system.
- [`convert_nan_to_na()`](https://animovement.dev/anicore/reference/convert_nan_to_na.md)
  is exported.

### Removed

- The coordinate transformations `map_to_cartesian()`, `map_to_polar()`,
  `map_to_cylindrical()` and `map_to_spherical()`, the component
  converters `cartesian_to_rho()`, `cartesian_to_phi()`,
  `cartesian_to_theta()`, `polar_to_x()`, `polar_to_y()` and
  `spherical_to_z()`, the rigid transforms `rotate_coords()`,
  `translate_coords()` and `transform_to_egocentric()`, and the angle
  helpers
  [`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md),
  [`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md),
  `diff_angle()` and
  [`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md).
  All are available from anispace.

## anicore 0.2.5 (as aniframe)

### Fixed

- `map_to_cartesian()` no longer adds a `z` column when converting from
  polar coordinates.

## anicore 0.2.4 (as aniframe)

### Changed

- [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  accepts a partial metadata list, rather than requiring every field.

## anicore 0.2.3 (as aniframe)

### Added

- [`is_cartesian()`](https://animovement.dev/anicore/reference/is_cartesian.md),
  with `_1d()`, `_2d()` and `_3d()` variants, and
  [`is_polar()`](https://animovement.dev/anicore/reference/is_polar.md),
  [`is_cylindrical()`](https://animovement.dev/anicore/reference/is_cylindrical.md)
  and
  [`is_spherical()`](https://animovement.dev/anicore/reference/is_spherical.md)
  to test a frame’s coordinate system.

### Changed

- `model` is recognised as an identity column, alongside `individual`
  and `keypoint`.

## anicore 0.2.2 (as aniframe)

### Added

- [`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md),
  the counterpart to
  [`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md).

### Changed

- `constrain_angles_radians()` is renamed
  [`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md).

## anicore 0.2.1 (as aniframe)

### Added

- Unit handling: `set_unit_space()`, `set_unit_angle()`,
  `set_unit_time()` and `set_sampling_rate()`.
- Coordinate transformations: `map_to_cartesian()`, `map_to_polar()`,
  `map_to_cylindrical()` and `map_to_spherical()`, with the component
  converters `cartesian_to_rho()`, `cartesian_to_phi()`,
  `cartesian_to_theta()`, `polar_to_x()`, `polar_to_y()` and
  `spherical_to_z()`.
- Rigid transformations: `rotate_coords()`, `translate_coords()` and
  `transform_to_egocentric()`.
- Angle handling:
  [`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md),
  [`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md),
  `constrain_angles_radians()`,
  [`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md)
  and `diff_angle()`.
- [`ensure_is_aniframe()`](https://animovement.dev/anicore/reference/ensure_is_aniframe.md),
  a guard for functions that require an aniframe.
- Trackball calibration, via `get_trackball_calibration_factor()`.

## anicore 0.2.0 (2025-10-23, as aniframe)

### Changed

- `tbl_sum.aniframe()` is registered as an S3 method rather than
  exported.

## anicore 0.1.0 (2025-10-13, as aniframe)

First release. aniframe provides the core data structure for the
animovement suite: a tibble subclass carrying metadata that says which
columns hold identity, time and position.

### Added

- [`aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  and
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  to construct a frame,
  [`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md)
  to test one, and
  [`example_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  to generate one.
- [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md),
  [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  and `default_metadata()` to read and write the metadata a frame
  carries.
