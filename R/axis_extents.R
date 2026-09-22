#' Get how far each axis runs
#'
#' @param data An aniframe or anievent object.
#'
#' @return Named numeric vector, axis role to extent. Empty when the frame
#'   declares none.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_axis_extents(af)
#'
#' @seealso [set_axis_extents()], [get_axis_directions()]
#' @export
get_axis_extents <- function(data) {
  ensure_is_aniframe(data)
  resolve_axis_extents(get_metadata(data))
}


#' Read the axis extents out of metadata
#'
#' @param md A metadata list.
#'
#' @return Named numeric vector, empty when nothing is declared.
#' @keywords internal
resolve_axis_extents <- function(md) {
  declared <- md_field(md, "axis_extents")
  if (is.null(declared) || length(declared) == 0L) {
    return(stats::setNames(numeric(), character()))
  }
  declared <- declared[!is.na(declared)]
  stats::setNames(as.numeric(declared), names(declared))
}


#' Say how far each axis runs
#'
#' @description
#' Records the extent of one or more axes, keyed by axis role — the height of
#' the video frame for `y`, its width for `x`. Roles not named keep the extent
#' they had.
#'
#' The extent is what [set_axis_directions()] reflects around when an axis is
#' turned over: `new = extent - old`.
#'
#' @param data An anipoint object.
#' @param extents Named numeric vector, axis role to extent. Each must be
#'   positive and finite; `NA` clears an axis.
#'
#' @return The anipoint with updated `axis_extents` metadata.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_axis_extents(af, c(x = 1920, y = 1080))
#' get_axis_extents(af)
#'
#' @seealso [get_axis_extents()], [set_axis_directions()]
#' @export
set_axis_extents <- function(data, extents) {
  ensure_is_anipoint(data)
  ensure_valid_axis_extents(extents)

  wanted <- merge_axis_map(get_axis_extents(data), extents)
  warn_short_axis_extents(data, wanted)

  set_metadata(data, axis_extents = wanted)
}


#' Is this a usable map of axis roles to extents?
#'
#' @param extents Value supplied to [set_axis_extents()].
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_axis_extents <- function(extents) {
  ensure_named_axis_map(extents, "extents", "c(x = 1920, y = 1080)")
  if (!is.numeric(extents) && !all(is.na(extents))) {
    cli::cli_abort("{.arg extents} must be a numeric vector.")
  }

  given <- extents[!is.na(extents)]
  bad <- names(given)[!is.finite(given) | given <= 0]
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "The extent of {?axis/axes} {.val {bad}} must be positive and finite.",
      "i" = "Got {.val {unname(given[bad])}}."
    ))
  }
  invisible(TRUE)
}


#' Warn about an extent the data runs past
#'
#' Reflecting around it would put the axis below zero, which usually means
#' the extent belongs to a different recording.
#'
#' @param data An anipoint object.
#' @param extents Named numeric vector of extents.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_short_axis_extents <- function(data, extents) {
  if (isTRUE(getOption("aniframe.quiet", FALSE))) {
    return(invisible(TRUE))
  }

  axes <- get_axes(data)
  for (role in intersect(names(extents), names(axes))) {
    column <- axes[[role]]
    if (!column %in% names(data) || !is.numeric(data[[column]])) {
      next
    }
    observed <- suppressWarnings(max(data[[column]], na.rm = TRUE))
    if (is.finite(observed) && extents[[role]] < observed) {
      cli::cli_warn(c(
        "The {.field {role}} extent ({extents[[role]]}) is less than the largest {.val {column}} ({observed}).",
        "i" = "Turning the axis over would give negative values."
      ))
    }
  }
  invisible(TRUE)
}
