#' Default metadata structure
#'
#' @description
#' Returns the default metadata tree. Fields are grouped into categories
#' (#118) — `recording`, `time`, `space`, `variables`, `structure` — with
#' `spec_version` at the top level. Access stays flat: a field is read
#' with `get_metadata(data, "sampling_rate")` and written with
#' `set_metadata(data, sampling_rate = 30)` regardless of its category,
#' and a category name returns the whole category.
#'
#' The categories:
#'
#' * `recording` — provenance: `source`, `source_version`,
#'   `source_format`, `filename`.
#' * `time` — `unit_time`, `sampling_rate` (declared), `sampling_interval`
#'   (derived from the index; read it with [get_sampling_interval()]),
#'   `start_datetime`.
#' * `space` — `coordinate_system`, `reference_frame`, `handedness`,
#'   `axis_directions`, `axis_extents`, `unit_space`, `unit_angle`. The
#'   one category a class can lack: an [anievent()] has no spatial
#'   component, so its metadata simply has no `space` (#73).
#' * `variables` — which columns play which role, as a list of roles each
#'   holding named slots: `what$keys` (identity), `when$index` +
#'   `when$keys` (temporal; an anievent has `when$interval` instead of an
#'   index), `where$position` (the axis-role mapping; names are roles,
#'   values are columns), `event$state` + `event$point`. The frame groups
#'   by `c(what$keys, when$keys)` and nothing else. These slots are
#'   reached through the `*_variables_*()` accessors, [get_index()] and
#'   [get_axes()], never by flat name — `keys` appears under two roles.
#' * `structure` — relationships between levels of a variable, keyed by
#'   that variable (typically `keypoint` for skeletons). Today this holds
#'   the connection tables managed via [set_connections()]; it is where
#'   an `anistructure` will live.
#' * `spec_version` — named list of semantic version strings, one per
#'   class, versioning the full data contract independently of the
#'   package version.
#'
#' @param class Which class's tree to return: `"anipoint"` (the default)
#'   or `"anievent"`. An anievent's tree has no `space` category, and its
#'   `when` role carries `interval = c("start", "stop")` instead of an
#'   index.
#'
#' @return A named list: the categories above plus `spec_version`.
#'
#' @seealso [set_metadata()], [get_metadata()]
#'
#' @examples
#' names(list_default_metadata())
#' names(list_default_metadata("anievent"))
#' @export
list_default_metadata <- function(class = c("anipoint", "anievent")) {
  class <- rlang::arg_match(class)

  metadata <- list(
    spec_version = list(
      aniframe = "3.0.0",
      anievent = "1.0.0"
    ),
    recording = list(
      source = as.character(NA),
      source_version = as.character(NA),
      source_format = as.character(NA),
      filename = as.character(NA)
    ),
    time = list(
      unit_time = factor(
        "frame",
        levels = c("unknown", "frame", "ns", "us", "ms", "s", "m", "h")
      ),
      sampling_rate = as.numeric(NA),
      sampling_interval = as.numeric(NA),
      start_datetime = as.POSIXct(NA)
    ),
    space = list(
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
      reference_frame = factor(
        "allocentric",
        levels = c("allocentric", "egocentric", "none")
      ),
      handedness = factor(
        "unknown",
        levels = c("right", "left", "unknown")
      ),
      axis_directions = stats::setNames(character(), character()),
      axis_extents = stats::setNames(numeric(), character()),
      unit_space = factor(
        "px",
        levels = c("px", "none", "nm", "um", "mm", "cm", "m", "km")
      ),
      unit_angle = factor(
        "rad",
        levels = c("rad", "deg", "none")
      )
    ),
    variables = list(
      what = list(keys = c("individual", "keypoint")),
      when = list(index = "time", keys = character()),
      where = list(position = c(x = "x", y = "y")),
      event = list(state = character(), point = character())
    ),
    structure = list()
  )

  if (identical(class, "anievent")) {
    metadata$space <- NULL
    metadata$variables <- list(
      what = list(keys = character()),
      when = list(interval = c("start", "stop"), keys = character())
    )
  }

  class(metadata) <- "aniframe_metadata"
  metadata
}


#' The default value of one flat-addressable metadata field
#'
#' @param field Length-one character.
#'
#' @return The field's default value, or `NULL` for an unknown field.
#' @keywords internal
default_metadata_leaf <- function(field) {
  md_field(unclass(list_default_metadata()), field)
}
