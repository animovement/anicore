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


#' Is this a usable map of axis roles to extents?
#'
#' @param extents A proposed `axis_extents` value.
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
