# anicore (development version)

## Breaking changes

* Structures replace connections (#154). An `anistructure()` holds points, the segments between them (with optional expected lengths) and joints as pairs of segments with per-degree-of-freedom limits, plus a `root`, a 3D twist convention and provenance fields. A frame can carry several named structures, including several over the same variable — a `team`, `defence` and `left_flank` over `individual` alongside a `skeleton` over `keypoint` — through `set_structure()`, `get_structure()` and `remove_structure()`. `get_/set_/add_/remove_connections()` are removed; connection tables in existing objects become segments-only structures named after their variable.

* The accessor API is rebuilt around one rule: `set_*` declares and never changes a value (#155).

  * `get_variables()`, `set_variables()`, `add_variables()` and `remove_variables()` replace the sixteen `*_variables_what/when/where/event()` functions. They take a role and slot — `get_variables(x, "when", "index")`, `set_variables(x, when = list(keys = "trial"))` — or a character vector for a role's main slot (`add_variables(x, what = "id")`). `get_variables(x, "when")` is now the union of the role's slots, index included; the grouping set is the new `get_keys()`. `set_axes()` is gone too: use `set_variables(x, where = c(x = "u", y = "v"))`.
  * `convert_unit_space()`, `convert_unit_time()` and `convert_unit_angle()` replace `set_unit_space()`, `set_unit_time()` and `set_unit_angle()`. Converting from `px`, `frame` or `unknown` without a `calibration_factor` now errors instead of relabelling the unit, except from `frame` with a declared `sampling_rate`. `convert_unit_time()` also handles `ns` and `us`.
  * `set_axis_directions()` only records directions. The new `reflect_axis()` turns an axis over: it reflects the column, flips the declared direction and a known handedness.
  * Removed in favour of `get_metadata()` / `set_metadata()`: `get_/set_unit_space()`, `get_/set_unit_time()`, `get_/set_unit_angle()`, `get_/set_sampling_rate()`, `get_/set_axis_extents()`, `set_handedness()` and `set_angle_direction()`. `set_sampling_rate()` used to convert frames to seconds as well; declare the rate, then call `convert_unit_time(x, "s")`. `set_metadata()` validates `axis_directions` and `axis_extents` and keeps `handedness` in step with three declared directions.

* The metadata list becomes a category tree (#118): `recording` (`source`, `source_version`, `source_format`, `filename`), `time` (`unit_time`, `sampling_rate`, `sampling_interval`, `start_datetime`), `space` (`coordinate_system`, `reference_frame`, `handedness`, `axis_directions`, `axis_extents`, `unit_space`, `unit_angle`), `variables`, and `structure` (which now holds what `connections` held), with `spec_version` at the top level. This is a `spec_version` major bump: `aniframe` moves to 3.0.0 and `anievent` to 1.0.0.

  Access stays flat, so most code needs no change: `get_metadata(data, "sampling_rate")` finds the field wherever it lives, `set_metadata(data, sampling_rate = 30)` writes it there, and a category name returns the whole category (`get_metadata(data, "space")`). The object `get_metadata()` returns also resolves `$` and `[[` flat, so `get_metadata(data)$sampling_rate` keeps working over the nested storage. What breaks is anything reaching into the raw attribute — `attr(x, "metadata")$sampling_rate` — and the old flat names for the variable declaration: `get_metadata(x, "variables_what")` and friends are refused with a pointer to `get_variables_what()`, `get_index()`, `get_axes()` and `get_connections()`.

  The variable roles become lists of named slots — `what$keys`, `when$index` + `when$keys`, `where$position` (the axis-role mapping, absorbing the separate `axes` field), `event$state` + `event$point` — and the frame groups by `c(what$keys, when$keys)`. An anievent's `start`/`stop` get the slot the flat vector could never express, `when$interval`, which is why `get_index()` had to refuse anievents by string comparison before.

  An anievent's spatial "not applicable" is now spelled as an absent `space` category instead of five neutral values (#73): its spatial fields read as `NULL` (`NA` through `get_coordinate_system()`), and writing one errors. Spatial fields passed to `as_anievent()` are dropped silently, so readers written against the flat layout keep working.

  Objects serialised with the flat layout are migrated to the tree, with `spec_version` bumped, whenever their metadata is read or written.

  Assigning through the metadata object writes into the tree too, so `md$sampling_rate <- 30; set_metadata(x, metadata = md)` works; an unknown name errors. `names(get_metadata(x))` lists the categories, not the fields. `get_metadata()` with several names returns a plain named list. Setting a field to `NULL` errors; use `NA` for unknown.

* The position-grain frame class is renamed from `aniframe` to `anipoint`, and `aniframe` becomes the abstract parent class shared by every animovement frame (#154). The class vectors are now `c("anipoint", "aniframe", ...)` and `c("anievent", "aniframe", ...)`, so the shared substrate — metadata accessors, dplyr methods, printing — is written once on the parent. The renamed structural-frame family (`anisegment`, `anijoint`) will join it as siblings of `anipoint`.

  Concretely:

  * `anipoint()`, `as_anipoint()`, `example_anipoint()` and `validate_anipoint()` replace `aniframe()`, `as_aniframe()`, `example_aniframe()` and `validate_aniframe()`. The old names remain as soft-deprecated aliases, and will be removed after one release cycle.
  * `is_aniframe()` now answers "is this any animovement frame?" — an anievent passes it too. Code that means the position grain should test with the new `is_anipoint()` / `ensure_is_anipoint()` instead.
  * Functions that need coordinates (axes, units of space and angle, connections, orientation columns, the index, event declarations) now guard with `ensure_is_anipoint()`, so a wrong-grain input fails at the door rather than deep inside.
  * Objects serialised before this release lack the new classes in their class vector; re-cast them with `as_anipoint()` (or `as_anievent()`), which repairs the class vector from the stored metadata.

## Added

* A segment frame, `anisegment` (#154): `as_anisegment()` turns an anipoint into one row per segment of a structure, with its `length` and a unit direction (`ux`, `uy`, `uz`), a `segment` key in place of the structure's variable, and a `confidence` that is the lower of the two endpoints'. `as_anipoint(seg, root = )` rebuilds the positions from the root point's trajectory, so edits made in segment space, such as constant segment lengths, carry into the positions. Metadata, variables, structures, dplyr verbs, `convert_unit_space()` (which rescales `length`) and `convert_unit_time()` all work on it.

* Orientation can be declared alongside position (#46): `set_variables(x, where = list(orientation = c(yaw = "heading")))` for a 2D frame, or the roles `qw`, `qx`, `qy`, `qz` of a unit quaternion for a 3D one. The roles are checked against the frame's dimensionality, quaternions must have unit norm, `reflect_axis()` reflects orientation with the positions, and `convert_unit_angle()` converts `yaw`.

* `convert_inf_to_na()`, the sibling of `convert_nan_to_na()`, for sources that mark a missing observation with an infinity rather than a `NaN`. TRex is one — its own documentation masks `np.inf` out before plotting, and its `missing` flag is 1 in exactly those frames. Left in place an `Inf` propagates through arithmetic silently, so one untracked frame turns a mean or a speed into `Inf` rather than into a missing value (animovement/aniread#116).

## Added

* A `source_format` metadata field, recording which export layout a file was read as (animovement/aniread#118). Tracking software changes its export layout between releases — FreeMoCap's tidy CSV gained a `reprojection_error` column at v1.8.0, and its wide per-model CSVs are a different layout again — so `source` alone does not say what was parsed. Readers set it to a short layout name such as `"by_frame_9col"`.

  It is deliberately separate from `source_version`, which stays reserved for a version the file actually states. Most tracking formats record none, and a layout inferred from a column count must not be stored as though it had been read. Where both are known, both are set.

* Circular descriptive statistics, beside the existing angle utilities: `circ_median()` (Fisher's median), `circ_mean()`, `circ_sd()` and `circ_mad()`. Where two directions tie for the median, they are averaged **on the circle**: averaging them arithmetically returns their antipode when the tie straddles zero, which is 180 degrees from the answer. Angles have no smallest or largest value, so the ordinary median and standard deviation do not apply — the mean of 350 and 10 degrees is 0, not 180 (#147).

* `circ_difference()` and `circ_successive_difference()`, moved here from anispace, where they were `calculate_angular_difference()` and `diff_angle()`. The first is the shortest signed distance between two angles you name; the second applies it along a series, comparing each angle with the one before it. Both are general-purpose primitives rather than spatial transforms — `circ_difference()` is the one the circular summaries are built on — so anicore owns them alongside the rest of the angle utilities (#147).

  The rename follows the convention these settle on: `circ_*()` for functions that compute with the wraparound, where an ordinary mean or difference would give the wrong answer, and `*_angle()` or `x_to_y()` for manipulating how an angle is written.

## Changed

* `spec_version` moves to `aniframe = "2.1.0"` and `anievent = "0.4.0"`. Minor for both: each gains `source_format` as `NA`. Objects serialised before the field existed continue to validate.

* The order of `variables_what` no longer asserts a hierarchy (#140, #141). It was documented as coarse to fine, which reads naturally for the names that nest — a subject has tracks, a track has keypoints — but identity variables need not nest at all. `sex`, `treatment` and `genotype` partition a population without containing one another, and there is no sense in which one is finer than the next.

  The order is now documented as what auto-detection emits, not something a frame asserts. Nothing should read a position in `variables_what` as meaning a level; a function that needs to know which variable to act on asks for it — `animetric::add_centroid()` takes `across`, `anispace::translate_coords()` takes `level`.

  No behaviour changes. Detection emits the same order, and the order still carries through to column order and grouping, which is presentation: grouping by `(a, b)` and `(b, a)` gives the same groups.

# anicore 0.8.0 (2026-08-28)

## Changed

* **The package is renamed from `aniframe` to `anicore`** (#84). It is no longer one class's home: it declares `aniframe`, `anievent` and — as #84 settles — the types the domain packages build on, while producing almost none of them. A package named after one of its entries was going to keep getting stranger as angles (#83), orientation (#46) and masks (#11) arrive.

  **The `aniframe` class keeps its name**, as do `as_aniframe()`, `is_aniframe()` and every other function. Only the package changes: `library(anicore)`, `anicore::`, and `install.packages("anicore")`.

  Done now rather than at 1.0.0 because a rename only ever gets more expensive, and there are no external users yet to carry the cost.

* `?aniframe` is the constructor again. The package documentation had claimed the same help topic, so the two were merged into one page; it is now `?anicore`.


## Added

* An aniframe can be indexed by a column that is not called `time` (#109). A `variables_index` metadata field names the single column each row is positioned by; `get_index()` reads it, `set_index()` changes it and re-orders the frame, and `as_aniframe()` and `aniframe()` take an `index` argument. A frame has exactly one index, and it is never a grouping variable.

  `set_unit_time()`, `set_sampling_rate()` and `to_anievent()` act on the declared index rather than a column named `time`, and `validate_aniframe()` checks it is present and numeric.

  An `anievent` has no index, since a bout is delimited by `start` and `stop`. Its `variables_index` is `NA` and `get_index()` errors on it.

* `get_sampling_interval()` reports the spacing of the index, derived from the data at construction rather than declared, and `is_sampling_regular()` says whether that spacing is even (#114). Nothing in the stack could previously tell whether a frame was regularly sampled, which several downstream functions need — interpolating on row position rather than on time is only correct when it is.

  Measured per key, since the index restarts in each group and a frame regular within every track can look irregular pooled. Regularity is computed on demand rather than stored, because dropping rows changes the answer; its `tolerance` is an argument, and relative, so floating-point timestamps are not called irregular over the last decimal place.

  `validate_aniframe()` warns when a declared `sampling_rate` disagrees with the measured spacing — the same shape as #98, where the metadata claimed a unit the data was not in.

* `get_sampling_rate()`, `get_unit_space()`, `get_unit_time()` and `get_unit_angle()` read the fields that already had setters (#121). Every field with a dedicated setter now has a dedicated getter, so reading one no longer means naming it as a string. The factor-backed ones return a bare character vector, which is what callers were doing with `as.character()` anyway.

* `get_coordinate_system()` reads the coordinate system a frame is in (#109). There is deliberately no setter: the field is derived from the axis roles, so `set_axes()` says what the columns mean and `anispace`'s `map_to_*()` functions convert the coordinates.

* An `axes` metadata field records which column carries which axis role, so coordinates may be carried by columns of any name (#109). `get_axes()` reads it, `set_axes()` changes it, and `as_aniframe()` and `set_variables_where()` accept the same mapping — `c(x = "u", y = "v")`. `coordinate_system` follows from it, and `set_unit_space()` and the axis extents resolve through it. The roles are a closed set: `x`, `y`, `z`, `rho`, `phi`, `theta`, and one that forms no coordinate system is rejected by name at declaration. Declaring spatial columns without roles keeps its old meaning, the column name being the role.

* Axis directions and extents record how a frame is laid out, replacing `origin` and `y_height` (#124). `axis_directions` maps each axis role to one of `right`, `left`, `up`, `down`, `back` or `forward`, read from where the recording was made; `axis_extents` maps each to how far it runs. `get_axis_directions()`, `set_axis_directions()`, `get_axis_extents()` and `set_axis_extents()` read and write them. Turning an axis to its opposite reflects that column: around the axis extent where one is declared, around zero where none is. The column is found by role, so a frame whose vertical axis is called something else is handled, and an angular frame refuses rather than leaving every stored angle facing the wrong way.

* `get_angle_direction()` says which way angles run, derived from the axis directions rather than recorded (#124). `atan2(y, x)` counts counter-clockwise, so the same physical heading comes out mirrored between a y-down and a y-up frame; nothing said which convention a number was in.

* `get_handedness()` and `set_handedness()` say whether a frame is right- or left-handed (#124). Three declared axis directions determine it and are read in preference to the `handedness` field, which carries the convention for a frame that states one without spelling the axes out. `set_handedness()` defaults to right-handed and completes the third axis when two are declared.

* `set_angle_direction()` asks for a sense of rotation and declares the axis directions that give it (#124), turning the vertical axis over when both are already declared.

* `wrap_angle()` and `unwrap_angle()` move here from `anispace` (#128). They are angle arithmetic rather than coordinate transformation, and belong beside `deg_to_rad()` and `rad_to_deg()`, which were already here. `animetric` re-exported both from `anispace`, which is the sign of a primitive sitting one layer above the packages that need it.

* Turning an axis over on a frame that stores angles recomputes them, rather than refusing (#134). No column carries `x`, `y` or `z` on a polar, cylindrical or spherical frame, but the angles are measured from those axes: turning `x` over takes the supplement of `phi`, turning `y` over negates it, and turning `z` over takes the supplement of `theta`. The result comes back in the unit and range the frame keeps its angles in, and `rho` never moves. An axis with a declared extent still refuses, because reflecting around it would move every point's distance from the origin.

* Every exported function now has a runnable example (#106).

## Changed

* Declaring an axis role that is carried by one column while a different, undeclared column has that role's name now warns (#119). The frame is legal and the mapping is right, but `.data$x` then returns a column that is not the x axis. Silence it with `options(aniframe.quiet = TRUE)`.

* `coordinate_system` follows from which axis roles are declared rather than from column names (#109). A frame whose coordinates are named something else is now inferred correctly, where it degraded to `unknown` and was refused by every spatial function.

* `is_cartesian()`, `is_polar()`, `is_cylindrical()`, `is_spherical()`, the `is_cartesian_*d()` variants and their `ensure_` guards read `coordinate_system` rather than matching column names, and require an aniframe (#107, #109). A frame whose coordinates are called something else now satisfies the predicate for the system it is in, and an undeclared column no longer decides the answer — a spherical frame that has dropped `rho` from its declaration is no longer reported as spherical. The guards say which system the frame is in and how to get to the one you need.

* `add_variables_where()` and `remove_variables_where()` carry the axis roles through (#109). They combined bare column names, so on a frame with declared roles every addition or removal reduced it to `unknown`. Removing an axis until the remainder forms no coordinate system warns rather than aborting; declaring such a set outright still aborts.

* `validate_aniframe()` warns when identity, temporal context and the index together do not name one observation per row (#49). A repeat means some variable that tells the rows apart is undeclared, and every grouped operation folds them together.

* `variables_when` no longer names the column the frame is indexed by; read that from `variables_index`, via `get_index()` (#109). It holds only the temporal context, so a frame with none has `character()` where it had `c("time")`, as does `list_default_metadata()`. `aniprocess::filter_across()` and `filter_na_across()` take `variables_when[1]` as the time column and must swap to `aniframe::get_index()`. Code reading the grouping columns is unaffected, and no longer has anything to exclude: they are `c(variables_what, variables_when)`.

* `default_metadata()` is renamed `list_default_metadata()` (#121).

* `origin` and `y_height` are removed, along with `set_origin()` and `set_y_height()` (#124). Use `set_axis_directions()` and `set_axis_extents()`. `origin` recorded a corner, but the origin is `(0, 0)` in both of its values — what differed was the direction y increases in, which is what is recorded now. It also had nothing to say for 3D data or for a recording with no frame corners at all. The deprecated `point_of_reference` alias goes with the field it aliased.

* `as_aniframe()` no longer fills in an axis extent from the data (#124). `y_height` fell back to `max(y)`, which is the highest tracked point rather than the frame height, so a frame that was never told its height reflected around the wrong place. A frame now declares no extent until given one, and an axis with no extent is negated when turned over rather than reflected around a guess. `aniread`'s readers supply the video height they know about.

* `spec_version` moves to `aniframe = "2.0.0"` and `anievent = "0.3.0"` (#109). Major for `aniframe`: `variables_when` no longer names the index, which breaks a consumer reading it from there. Minor for `anievent`, which gains `variables_index` as `NA`.

## Fixed

* `set_unit_space()` converts the axis extents along with the coordinates (#124). An extent is a length, so converting cm to m left the frame claiming a height in the unit it no longer used.

* `set_unit_space()` converts the length axes of the frame's coordinate system rather than whichever of `x`, `y` and `z` are present (#98). `rho` is a length on polar, cylindrical and spherical frames and was never converted, while the metadata was updated to claim the new unit. Angular axes remain `set_unit_angle()`'s to convert. Where the coordinate system is `unknown` a length cannot be told from an angle, and the function now warns rather than silently converting nothing.

* `set_unit_space()`, `set_unit_angle()`, `set_unit_time()` and `set_sampling_rate()` no longer re-inject a `keypoint` column and overwrite `variables_what` with it (#96). A frame given a custom identity such as `id` was silently regrouped on a constant column.

* `as_aniframe()` keeps the roles a frame already declares rather than re-deriving them, so casting an aniframe is no longer destructive (#96). A declaration whose columns have since been dropped still falls through to detection, so a cast continues to repair a drifted frame.

# anicore 0.7.0 (2026-08-18, as aniframe)

## Added

* `set_variables_what()`, `set_variables_when()`, `set_variables_where()` and `set_variables_event()` declare the variable roles, each with `get_`, `add_` and `remove_` verbs (#82). They declare the role *and* restructure the frame to match, so the metadata and the frame cannot drift apart. `add_variables_*()` appends, so adding one identity column no longer means restating the others.

* `validate_aniframe()` re-checks that the metadata still describes the frame: every declared column present, `time` and the spatial columns numeric (#79). Counterpart to `validate_anievent()`.

* `is_spatial()` and `ensure_is_spatial()` test the columns named in `variables_where`, which the `is_cartesian*()` family does not — those look at column names only (#79).

## Changed

* `set_metadata()` no longer writes the `variables_*` fields; use their dedicated setters (#82). Writing them as plain metadata left the frame typed, ordered and grouped as before, so operations silently integrated across identities. A complete metadata object can still be restored wholesale.

* `as_aniframe()` errors when `variables_what` names a column that is not in the data, as it already did for `variables_when` and `variables_where` (#77).

* `aniframe` and `anievent` recognise the same identity variables — `model`, `individual`, `subject`, `track`, `keypoint` — ordered coarse to fine (#77).

* `spec_version` moves to `aniframe = "1.1.0"` and `anievent = "0.2.0"`.

## Removed

* `as_aniframe()` no longer adds a `keypoint = "centroid"` column to data that already has an identity column (#77). Results are unaffected — the column was constant — but it no longer appears in the frame or the print header.

## Fixed

* Downstream subclasses survive the class-preserving methods (#81). `animetric`'s `aniframe_kin` was dropped by the first `filter()`, `mutate()` or `[`. Verbs that were never covered — `distinct()`, joins, `bind_rows()` — still drop it.

* An `anievent` no longer claims spatial properties it cannot have, such as a BORIS export announcing `origin: bottom_left` (#73). `unit_angle`, `origin` and `reference_frame` gain a `"none"` level.

# anicore 0.6.0 (2026-06-24, as aniframe)

## Added

* `anievent`, a class for behavioural events in long format — one row per bout (state event) or instant (point event) (#67). A sibling of `aniframe`: it shares the metadata substrate but does not inherit from it. Required columns are `channel`, `type`, `label`, `start` and `stop`, with identity columns travelling via `variables_what` and an optional `modifiers` list-column. `type` is derived per `(channel, label)` group at construction — a group is `"point"` only when all its bouts are instantaneous — and can be set explicitly where that misclassifies.

* `anievent()` and `as_anievent()` construct the class, `is_anievent()` and `ensure_is_anievent()` test it, and `validate_anievent()` re-checks its invariants on demand (#68). Class-preserving dplyr and base-R methods keep the class through tidyverse pipelines.

* `to_anievent()` run-length-encodes per-frame data into bouts, as distinct from `as_anievent()`, which casts data that is already bout-shaped. Methods for `data.frame` and `aniframe`; the latter auto-detects each channel's identity scope, so a label constant across keypoints does not produce a duplicate bout per keypoint.

* A `variables_event` metadata field — a named list `list(state, point)` declaring which columns hold per-frame event labels (#66). State columns are interval-valued, point columns instantaneous; both appear in the print header when populated.

* A `spec_version` metadata field, keyed by class, so each class's data contract can evolve independently of the package version (#65). Older serialised objects without it continue to validate.

* `set_unit_time()` and `set_sampling_rate()` are S3 generics with `aniframe` and `anievent` methods. On an anievent the calibration factor applies to `start` and `stop` rather than `time`.

* `as_aniframe()` auto-detects `observation` as a temporal grouping column, alongside `session` and `trial`.

* New article, "The anievent data structure", covering channels, state and point events, modifiers, validation and multi-observation data (#70).

## Changed

* `validate_anievent()` warns when two bouts of the same `channel` overlap within a group. A warning rather than an error: overlap is normal BORIS output and the long format handles it natively.

* `set_metadata()` accepts partial `variables_event` input — supplying only `state` or only `point` is fine, and `NA` or empty entries read as "none" rather than erroring (#76).

* The metadata print heading reads "animovement metadata", since the substrate is shared by both classes (#69). The S3 class name is unchanged.

# anicore 0.5.0 (2026-05-04, as aniframe)

## Added

* `set_origin()` converts between the `bottom_left` and `top_left` origin conventions, reflecting `y` around the recorded frame height (#52).

* `set_y_height()` sets the y-axis frame height that `set_origin()` uses, validated against the data range, and a `y_height` metadata field to hold it. Readers populate it from the source; `as_aniframe()` falls back to `max(y)` when missing, and never overwrites an existing value.

* A `connections` metadata field for skeletons and other variable-level networks (#6). Stored as a named list keyed by the relevant identity or temporal variable — typically `keypoint`, but `individual` for social networks — with each entry a 2-column `from`/`to` tibble whose order is preserved. Manage it with `set_connections()`, `get_connections()`, `add_connections()` and `remove_connections()`. Endpoints missing from the corresponding column warn but are kept.

* A "Time" row in the print summary showing the tracked interval as `HH:MM:SS to HH:MM:SS`, or as absolute datetimes when `start_datetime` is set (#50). Sub-second runs use millisecond precision.

* New articles introducing the data structure: "The aniframe data structure", "Metadata on an aniframe" and "Connections".

## Changed

* `set_unit_angle()` converts the spatial angular columns `phi` and `theta` whenever they are present, so polar, cylindrical and spherical coordinates stay consistent with the declared `unit_angle` (#21). These were previously assumed to be radians and left alone. The signature becomes `set_unit_angle(data, to_unit, cols = NULL)`, matching `set_unit_time()`; pass `cols` only for additional non-spatial angular columns. Positional callers need to swap their arguments.

* The print summary is driven by `variables_what` and `variables_when` rather than hard-coded column names (#51). Custom identity and temporal variables such as `track` and `model` now appear, rows are omitted when their column is absent, and single-track readers no longer emit "Unknown or uninitialised column: `individual`".

* The metadata print renders as a single block with field names and values aligned in fixed-width columns (#48).

* The `filename` metadata field accepts a character vector of length one or more, for readers that load from multiple source files (#34).

* Renamed the `point_of_reference` metadata field to `origin`, with permitted values `"bottom_left"` and `"top_left"`.

## Deprecated

* `point_of_reference` as a metadata field name. `set_metadata()` still accepts it, with a warning.

## Fixed

* `as_aniframe()` no longer mis-classifies cylindrical (`rho`, `phi`, `z`) and spherical (`rho`, `phi`, `theta`) data as Cartesian (#44). Detection recognises the `rho` + `phi` signature first, so cylindrical data is no longer reduced to `cartesian_1d` by its `z` column. Cylindrical spatial columns are now ordered `rho`, `phi`, `z` (#43).

# anicore 0.4.1 (as aniframe)

## Fixed

* Corrected metadata written by `as_aniframe()`.

# anicore 0.4.0 (as aniframe)

## Added

* `variables_what`, `variables_when` and `variables_where` arguments to `as_aniframe()` and `example_aniframe()`, written into the frame's metadata. These declare which columns carry identity, temporal position and spatial position, and are the basis for how the frame is typed, ordered and grouped.

## Changed

* Identity and temporal variables are coerced to integer, with the exception of `time`, which stays numeric.
* `time` is required. A frame without it is no longer a valid aniframe.
* An unrecognised set of spatial columns is accepted, with `coordinate_system` recorded as `"unknown"`, rather than refused.

# anicore 0.3.5 (as aniframe)

## Added

* A `NEWS.md` file, to track changes to the package.
* Smaller units: `ns` (nanosecond), `us` (microsecond), `nm` (nanometre) and `um` (micrometre).

## Removed

* `get_trackball_calibration_factor()`, following the move of trackball handling to aniread.

# anicore 0.3.4 (as aniframe)

## Removed

* Trackball calibration. It reads hardware output rather than describing a frame, and belongs with the readers in aniread.

# anicore 0.3.3 (as aniframe)

## Fixed

* `NA` and `NaN` handling in metadata and coercion.
* An `NA` datetime is no longer given a class, which had made empty `start_datetime` values print oddly.

# anicore 0.3.2 (as aniframe)

## Changed

* `"cartesian"` is no longer a permitted `coordinate_system` value; the dimensioned forms `cartesian_1d`, `cartesian_2d` and `cartesian_3d` replace it.
* Metadata printing and the `start_datetime` class were tidied.

# anicore 0.3.1 (as aniframe)

## Removed

* `add_centroid()`. Deriving a centroid is a metric rather than a property of the frame, and belongs in animetric.

# anicore 0.3.0 (as aniframe)

Spatial transformations leave aniframe for [anispace](https://github.com/animovement/anispace). aniframe keeps the coordinate *system* — what a frame is in, and how to test it — while converting between systems becomes anispace's job.

## Added

* `ensure_is_cartesian()`, with `_1d()`, `_2d()` and `_3d()` variants, and `ensure_is_polar()`, `ensure_is_cylindrical()` and `ensure_is_spherical()` — guards to sit at the top of a function that requires a particular coordinate system.
* `convert_nan_to_na()` is exported.

## Removed

* The coordinate transformations `map_to_cartesian()`, `map_to_polar()`, `map_to_cylindrical()` and `map_to_spherical()`, the component converters `cartesian_to_rho()`, `cartesian_to_phi()`, `cartesian_to_theta()`, `polar_to_x()`, `polar_to_y()` and `spherical_to_z()`, the rigid transforms `rotate_coords()`, `translate_coords()` and `transform_to_egocentric()`, and the angle helpers `wrap_angle()`, `unwrap_angle()`, `diff_angle()` and `circ_difference()`. All are available from anispace.

# anicore 0.2.5 (as aniframe)

## Fixed

* `map_to_cartesian()` no longer adds a `z` column when converting from polar coordinates.

# anicore 0.2.4 (as aniframe)

## Changed

* `set_metadata()` accepts a partial metadata list, rather than requiring every field.

# anicore 0.2.3 (as aniframe)

## Added

* `is_cartesian()`, with `_1d()`, `_2d()` and `_3d()` variants, and `is_polar()`, `is_cylindrical()` and `is_spherical()` to test a frame's coordinate system.

## Changed

* `model` is recognised as an identity column, alongside `individual` and `keypoint`.

# anicore 0.2.2 (as aniframe)

## Added

* `unwrap_angle()`, the counterpart to `wrap_angle()`.

## Changed

* `constrain_angles_radians()` is renamed `wrap_angle()`.

# anicore 0.2.1 (as aniframe)

## Added

* Unit handling: `set_unit_space()`, `set_unit_angle()`, `set_unit_time()` and `set_sampling_rate()`.
* Coordinate transformations: `map_to_cartesian()`, `map_to_polar()`, `map_to_cylindrical()` and `map_to_spherical()`, with the component converters `cartesian_to_rho()`, `cartesian_to_phi()`, `cartesian_to_theta()`, `polar_to_x()`, `polar_to_y()` and `spherical_to_z()`.
* Rigid transformations: `rotate_coords()`, `translate_coords()` and `transform_to_egocentric()`.
* Angle handling: `deg_to_rad()`, `rad_to_deg()`, `constrain_angles_radians()`, `circ_difference()` and `diff_angle()`.
* `ensure_is_aniframe()`, a guard for functions that require an aniframe.
* Trackball calibration, via `get_trackball_calibration_factor()`.

# anicore 0.2.0 (2025-10-23, as aniframe)

## Changed

* `tbl_sum.aniframe()` is registered as an S3 method rather than exported.

# anicore 0.1.0 (2025-10-13, as aniframe)

First release. aniframe provides the core data structure for the animovement suite: a tibble subclass carrying metadata that says which columns hold identity, time and position.

## Added

* `aniframe()` and `as_aniframe()` to construct a frame, `is_aniframe()` to test one, and `example_aniframe()` to generate one.
* `get_metadata()`, `set_metadata()` and `default_metadata()` to read and write the metadata a frame carries.
