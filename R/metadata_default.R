#' Default metadata structure
#'
#' @description
#' Returns a list containing the default metadata fields and their initial
#' values. The same metadata substrate is shared by both [anipoint()] and
#' [anievent()] objects; per-class data contracts are versioned via
#' `spec_version`. Most fields are initialized as `NA` and should be set
#' appropriately for your data.
#'
#' @return A named list with the following fields:
#' * `source`: Data source identifier (character, NA)
#' * `source_version`: Version of the software that wrote the file
#'   (character, NA). Set only when the file states it — most tracking
#'   formats record no version, and an inferred one must not be stored
#'   here.
#' * `source_format`: The export layout the file was read as (character,
#'   NA), e.g. `"by_frame_9col"`. Software changes its export layout
#'   between releases, so knowing which variant was parsed is what makes
#'   drift visible. Unlike `source_version` this is normally derived from
#'   the file's structure rather than read from a version string.
#' * `filename`: Original filename(s) (character vector, NA). Accepts a
#'   vector of length 1 or more — readers that load from multiple files
#'   (e.g. `aniread::read_trackball()`) populate this with all source paths.
#' * `sampling_rate`: Sampling rate in Hz (numeric, NA). Declared, not
#'   derived — set it with [set_sampling_rate()].
#' * `sampling_interval`: The interval between consecutive observations
#'   (numeric, NA), in the unit the index is in. Derived from the index at
#'   construction and refreshed on every re-declaration, so it describes
#'   the data rather than a claim about it. Read it with
#'   [get_sampling_interval()]; ask whether the spacing is even with
#'   [is_sampling_regular()], which is computed on demand because dropping
#'   rows changes the answer.
#' * `start_datetime`: Start date and time of recording (POSIXct, NA)
#' * `variables_index`: The single column the frame is indexed by (character,
#'   `"time"`). Exactly one column, and it may be called anything — the
#'   constructor requires *that* column rather than a column literally
#'   named `time`. It is never one of the `variables_when`, which holds
#'   the surrounding temporal context and is what the frame is grouped by;
#'   the index positions each row *within* its context and so is never a
#'   grouping variable. Read it with [get_index()], change it with
#'   [set_index()]. Absent from objects serialised before the field
#'   existed, where it reads back as `"time"` — the value they were built
#'   with.
#' * `variables_what`, `variables_when`, `variables_where`: The columns
#'   that carry, respectively, entity identity, temporal context and
#'   spatial position. These are the structural fields — [as_anipoint()]
#'   uses them to coerce column types, order columns and rows, group the
#'   frame, and derive `coordinate_system`. The values here are a
#'   placeholder skeleton for an object with no data attached; every
#'   constructor overwrites them from the data or from its arguments.
#'   In particular `variables_what` is **not** a requirement that a frame
#'   carry `individual` and `keypoint` columns — the rule is that a frame
#'   has at least one identity variable, whichever it happens to be. Nor
#'   does the order of `variables_what` assert a hierarchy: identity
#'   variables need not nest, and a position in the vector does not mean a
#'   level. See [list_recognised_variables_what()].
#' * `axes`: Which column carries which axis role (named character,
#'   `c(x = "x", y = "y")`). Names are roles — `x`, `y`, `z`, `rho`,
#'   `phi`, `theta` — and values are the columns carrying them, so a frame
#'   whose coordinates are called something else still has a usable
#'   `coordinate_system`. The role set is closed, which is what keeps
#'   transformations between coordinate systems well defined; the column
#'   names are free. Empty when the roles are unknown. Read it with
#'   [get_axes()], change it with [set_axes()]. `variables_where` names the
#'   same columns without their roles, and is derived from this.
#' * `reference_frame`: Reference frame (factor, "allocentric").
#'   Permitted values: "allocentric", "egocentric", "none".
#' * `coordinate_system`: Coordinate system (factor, "cartesian_2d")
#' * `axis_directions`: Which way each axis points, keyed by axis role
#'   (named character, empty). One of "right", "left", "up", "down",
#'   "back" or "forward", read from where the recording was made. Read it
#'   with [get_axis_directions()], change it with [set_axis_directions()],
#'   which reflects an axis turned over. [get_angle_direction()] and
#'   [get_handedness()] follow from it.
#' * `axis_extents`: How far each axis runs, keyed by axis role (named
#'   numeric, empty) — the video frame height for `y`. Read it with
#'   [get_axis_extents()], change it with [set_axis_extents()]. It is what
#'   an axis is reflected around.
#' * `handedness`: Whether the frame is right- or left-handed (factor,
#'   "unknown"). Three declared axis directions determine it and are read
#'   in preference; the field carries the convention on its own for a frame
#'   that states one without spelling the axes out. Read it with
#'   [get_handedness()], change it with [set_handedness()].
#'
#' The spatial fields all have a way of saying "not applicable", because
#' the metadata substrate is shared with [anievent()], which has no
#' spatial component at all: `unit_space`, `unit_angle` and
#' `reference_frame` take "none", `coordinate_system` takes "unknown", and
#' `axes`, `axis_directions` and `axis_extents` are empty. An anievent is
#' constructed with those values rather than inheriting movement defaults
#' it cannot honour (#73).
#' * `connections`: Named list of connection tables, one per identity or
#'   temporal variable (typically `keypoint` for skeletons; could also be
#'   `individual` for social networks). Each entry is a 2-column tibble of
#'   `from`/`to` pairs. Default is an empty list. Manage via
#'   [set_connections()], [get_connections()], [add_connections()] and
#'   [remove_connections()].
#' * `variables_event`: Named list with two entries, `state` and `point`,
#'   each a character vector naming columns that carry per-frame
#'   categorical event labels. `state` columns are interval-valued
#'   (durative behaviours, listed coarse to fine where they nest);
#'   `point` columns are instantaneous (zero-duration events). Foundation
#'   for the `anievent` class and downstream event-handling utilities.
#'   Default is an empty list for each.
#' * `spec_version`: Named list of semantic version strings, one per class
#'   in the animovement ecosystem (currently `aniframe` and `anievent`).
#'   Versions the full data contract of each class (mandatory columns,
#'   validator, and the metadata fields the class uses), independently of
#'   the package version. Objects serialised before this field existed are
#'   tolerated by the metadata validator; new objects always get it.
#'
#' @seealso [set_metadata()], [get_metadata()]
#'
#' @examples
#' names(list_default_metadata())
#' @export
list_default_metadata <- function() {
  metadata <- list(
    source = as.character(NA),
    source_version = as.character(NA),
    source_format = as.character(NA),
    filename = as.character(NA),
    sampling_rate = as.numeric(NA),
    sampling_interval = as.numeric(NA),
    start_datetime = as.POSIXct(NA),
    variables_index = "time",
    variables_what = c("individual", "keypoint"),
    variables_when = character(),
    variables_where = c("x", "y"),
    variables_event = list(
      state = character(),
      point = character()
    ),
    axes = c(x = "x", y = "y"),
    unit_space = factor(
      "px",
      levels = c(
        "px",
        "none",
        "nm",
        "um",
        "mm",
        "cm",
        "m",
        "km"
      )
    ),
    unit_angle = factor(
      "rad",
      levels = c(
        "rad",
        "deg",
        "none"
      )
    ),
    unit_time = factor(
      "frame",
      levels = c(
        "unknown",
        "frame",
        "ns",
        "us",
        "ms",
        "s",
        "m",
        "h"
      )
    ),
    reference_frame = factor(
      "allocentric",
      levels = c(
        "allocentric",
        "egocentric",
        "none"
      )
    ),
    coordinate_system = factor(
      "cartesian_2d",
      levels = c(
        "unknown",
        "cartesian_1d",
        "cartesian_2d",
        "cartesian_3d",
        "polar",
        "cylindrical",
        "spherical"
      )
    ),
    axis_directions = stats::setNames(character(), character()),
    axis_extents = stats::setNames(numeric(), character()),
    handedness = factor(
      "unknown",
      levels = c(
        "right",
        "left",
        "unknown"
      )
    ),
    connections = list(),
    spec_version = list(
      aniframe = "2.1.0",
      anievent = "0.4.0"
    )
  )

  class(metadata) <- "aniframe_metadata"
  metadata
}
