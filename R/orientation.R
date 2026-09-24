#' Which way angles run
#'
#' @description
#' The sense of rotation from the `x` axis to the `y` axis, as seen from
#' where the recording was made. `atan2(y, x)` counts counter-clockwise, so
#' a frame stored the other way up reports the mirror of the angle a
#' `counter_clockwise` frame would give for the same physical heading.
#'
#' Derived from [get_axis_directions()] rather than recorded, so it cannot
#' go on claiming a sense the axes no longer have.
#'
#' @param data An aniframe or anievent object.
#'
#' @return `"clockwise"`, `"counter_clockwise"`, or `"unknown"` when the two
#'   axes are not both declared or do not span the view.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#'
#' # An image-plane frame counts angles clockwise
#' af <- set_axis_directions(af, c(x = "right", y = "down"))
#' get_angle_direction(af)
#'
#' @seealso [get_axis_directions()], [get_handedness()]
#' @export
get_angle_direction <- function(data) {
  ensure_is_aniframe(data)
  derive_angle_direction(get_axis_directions(data), get_handedness(data))
}


#' Whether the frame is right- or left-handed
#'
#' @description
#' Three declared axis directions determine it, and are read in preference to
#' anything recorded. A frame that states the convention without spelling the
#' axes out — most 3D recordings — declares it with
#' `set_metadata(data, handedness = "right")`.
#'
#' @param data An aniframe or anievent object.
#'
#' @return `"right"`, `"left"`, or `"unknown"` when neither the axes nor the
#'   frame itself says.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#'
#' # Two axes are not enough
#' af <- set_axis_directions(af, c(x = "right", y = "up"))
#' get_handedness(af)
#'
#' @seealso [get_axis_directions()], [get_angle_direction()]
#' @export
get_handedness <- function(data) {
  ensure_is_aniframe(data)
  md <- get_metadata(data)

  # Three declared directions take precedence over the stored field.
  derived <- derive_handedness(resolve_axis_directions(md))
  if (!identical(derived, "unknown")) {
    return(derived)
  }
  as.character(md_field(md, "handedness") %||% "unknown")
}


#' Work out the sense of rotation from the axis directions
#'
#' Seen from the side `z` points to; without `z`, from the viewer.
#'
#' @param directions Named character vector of axis directions.
#' @param handedness A stated handedness, used when no `z` is declared.
#'
#' @return One of `"clockwise"`, `"counter_clockwise"` or `"unknown"`.
#' @keywords internal
derive_angle_direction <- function(directions, handedness = "unknown") {
  if (!all(c("x", "y") %in% names(directions))) {
    return("unknown")
  }

  vectors <- list_direction_vectors()
  turn_axis <- cross_product(
    vectors[[directions[["x"]]]],
    vectors[[directions[["y"]]]]
  )

  # Right-handed z is x cross y; left-handed is its opposite.
  normal <- if ("z" %in% names(directions)) {
    vectors[[directions[["z"]]]]
  } else if (identical(handedness, "right")) {
    turn_axis
  } else if (identical(handedness, "left")) {
    -turn_axis
  } else {
    vectors[["back"]]
  }

  turn <- sum(turn_axis * normal)

  if (turn > 0) {
    "counter_clockwise"
  } else if (turn < 0) {
    "clockwise"
  } else {
    "unknown"
  }
}


#' Work out handedness from three axis directions (sign of the determinant)
#'
#' @param directions Named character vector of axis directions.
#'
#' @return One of `"right"`, `"left"` or `"unknown"`.
#' @keywords internal
derive_handedness <- function(directions) {
  if (!all(list_linear_axis_roles() %in% names(directions))) {
    return("unknown")
  }

  vectors <- list_direction_vectors()
  basis <- vapply(
    list_linear_axis_roles(),
    function(role) vectors[[directions[[role]]]],
    numeric(3)
  )

  orientation <- det(basis)
  if (orientation > 0) {
    "right"
  } else if (orientation < 0) {
    "left"
  } else {
    "unknown"
  }
}


#' Cross product of two 3-vectors
#'
#' @param a,b Numeric vectors of length 3.
#'
#' @return A numeric vector of length 3.
#' @keywords internal
cross_product <- function(a, b) {
  c(
    a[[2]] * b[[3]] - a[[3]] * b[[2]],
    a[[3]] * b[[1]] - a[[1]] * b[[3]],
    a[[1]] * b[[2]] - a[[2]] * b[[1]]
  )
}


#' Is this one of a permitted set of values?
#'
#' @param x Value to test.
#' @param permitted Character vector of permitted values.
#' @param arg Name of the argument it came from.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_is_one_of <- function(
  x,
  permitted,
  arg,
  call = rlang::caller_env()
) {
  if (!is.character(x) || length(x) != 1L || !x %in% permitted) {
    cli::cli_abort(
      "{.arg {arg}} must be one of {.val {permitted}}.",
      call = call
    )
  }
  invisible(TRUE)
}
