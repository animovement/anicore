#' The directions an axis can point, as seen from the recording viewpoint
#'
#' @return Character vector of the permitted directions.
#' @keywords internal
list_axis_directions <- function() {
  c("right", "left", "up", "down", "back", "forward")
}


#' The axis roles that can point somewhere (the Cartesian ones)
#'
#' @return Character vector of axis roles.
#' @keywords internal
list_linear_axis_roles <- function() {
  c("x", "y", "z")
}


#' Which opposed pair each direction belongs to
#'
#' @return Named character vector, direction to pair.
#' @keywords internal
list_direction_pairs <- function() {
  c(
    right = "horizontal",
    left = "horizontal",
    up = "vertical",
    down = "vertical",
    back = "depth",
    forward = "depth"
  )
}


#' The direction opposite each direction
#'
#' @return Named character vector, direction to its opposite.
#' @keywords internal
list_direction_opposites <- function() {
  c(
    right = "left",
    left = "right",
    up = "down",
    down = "up",
    back = "forward",
    forward = "back"
  )
}


#' Each direction as a unit vector
#'
#' Right-handed basis; `right`, `up` and `back` (toward viewer) are positive.
#'
#' @return Named list of length-3 numeric vectors.
#' @keywords internal
list_direction_vectors <- function() {
  list(
    right = c(1, 0, 0),
    left = c(-1, 0, 0),
    up = c(0, 1, 0),
    down = c(0, -1, 0),
    back = c(0, 0, 1),
    forward = c(0, 0, -1)
  )
}


#' Get the direction each axis points
#'
#' @param data An aniframe or anievent object.
#'
#' @return Named character vector, axis role to direction. Empty when the
#'   frame declares none.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_axis_directions(af, c(x = "right", y = "up"))
#' get_axis_directions(af)
#'
#' @seealso [set_axis_directions()], [reflect_axis()]
#' @export
get_axis_directions <- function(data) {
  ensure_is_aniframe(data)
  resolve_axis_directions(get_metadata(data))
}


#' Read the axis directions out of metadata
#'
#' @param md A metadata list.
#'
#' @return Named character vector, empty when nothing is declared.
#' @keywords internal
resolve_axis_directions <- function(md) {
  declared <- md_field(md, "axis_directions")
  if (is.null(declared) || length(declared) == 0L) {
    return(stats::setNames(character(), character()))
  }
  declared <- declared[!is.na(declared)]
  stats::setNames(as.character(declared), names(declared))
}


#' Say which way an axis points
#'
#' @description
#' Records the direction of one or more axes, keyed by axis role. Roles not
#' named keep the direction they had. This only declares: the values are left
#' alone. To turn an axis over and keep the data describing the same scene,
#' use [reflect_axis()].
#'
#' @param data An anipoint object.
#' @param directions Named character vector, axis role to direction — one of
#'   `right`, `left`, `up`, `down`, `back` or `forward`. `NA` clears an axis.
#'
#' @return The anipoint, with the new directions recorded.
#'
#' @details
#' Directions are read from where the recording was made: `right`/`left`
#' across the view, `up`/`down` within it, `back`/`forward` toward and away
#' from the viewer. No two axes may point along the same pair. Three declared
#' directions fix the handedness, which is recorded too.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_axis_directions(af, c(x = "right", y = "down"))
#' get_axis_directions(af)
#' get_angle_direction(af)
#'
#' @seealso [get_axis_directions()], [reflect_axis()],
#'   [get_angle_direction()]
#' @export
set_axis_directions <- function(data, directions) {
  ensure_is_anipoint(data)
  ensure_valid_axis_directions(directions)
  set_metadata(
    data,
    axis_directions = merge_axis_map(get_axis_directions(data), directions)
  )
}


#' Turn an axis over
#'
#' @description
#' Reflects the column carrying an axis role and flips its declared
#' direction, so the data describes the same scene with the axis pointing
#' the other way — for example converting image coordinates, where `y` runs
#' down, to a `y` that runs up.
#'
#' An axis runs from zero to its extent, so turning it over gives
#' `new = extent - old`. An axis with no declared `axis_extents` is centred
#' on its origin, and turning it over negates it. On a frame that stores
#' angles there is no column to reflect, and `phi` and `theta` are
#' recomputed instead.
#'
#' A declared handedness flips with any linear axis.
#'
#' @param data An anipoint object.
#' @param axis An axis role: `"x"`, `"y"` or `"z"`.
#'
#' @return The anipoint, reflected, with its orientation metadata updated.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_metadata(af, axis_extents = c(y = 1080))
#' af <- set_axis_directions(af, c(x = "right", y = "down"))
#'
#' af <- reflect_axis(af, "y")
#' get_axis_directions(af)
#'
#' @seealso [set_axis_directions()], [get_handedness()]
#' @export
reflect_axis <- function(data, axis) {
  ensure_is_anipoint(data)
  ensure_is_one_of(axis, list_linear_axis_roles(), "axis")

  handedness <- get_handedness(data)
  data <- reflect_axis_role(data, axis)
  data <- reflect_orientation(data, axis)

  directions <- get_axis_directions(data)
  if (axis %in% names(directions)) {
    directions[[axis]] <- unname(list_direction_opposites()[directions[[axis]]])
    data <- set_metadata(data, axis_directions = directions)
  }
  if (handedness %in% c("right", "left")) {
    flipped <- setdiff(c("right", "left"), handedness)
    data <- set_metadata(data, handedness = flipped)
  }
  data
}


#' Reflect the column carrying an axis role around its extent
#'
#' @param data An anipoint object.
#' @param role An axis role.
#'
#' @return `data`, with that column reflected.
#' @keywords internal
reflect_axis_role <- function(data, role) {
  axes <- get_axes(data)
  if (!role %in% names(axes)) {
    # No column carries the role, but stored angles need recomputing (#134).
    return(reflect_angular_axis(data, role))
  }

  # Mirror is `extent - v`; without a declared extent, reflect about the origin.
  extents <- resolve_axis_extents(get_metadata(data))
  reference <- if (role %in% names(extents)) extents[[role]] else 0

  column <- axes[[role]]
  ensure_has_column(data, column)
  reflect_column(data, axis = column, reference = reference)
}


#' Combine a partial axis map into the one already declared
#'
#' @param current,update Named vectors of the same type.
#'
#' @return `current` with `update` written over it, `NA` entries dropped.
#' @keywords internal
merge_axis_map <- function(current, update) {
  merged <- current
  for (role in names(update)) {
    merged[[role]] <- update[[role]]
  }
  merged <- merged[!is.na(merged)]
  merged[order(match(names(merged), list_linear_axis_roles()))]
}


#' Is this a usable map of axis roles to directions?
#'
#' @param directions Value supplied to [set_axis_directions()].
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_axis_directions <- function(directions) {
  ensure_named_axis_map(directions, "directions", 'c(x = "right", y = "up")')
  # An all-`NA` vector (clearing axes) arrives as logical.
  if (!is.character(directions) && !all(is.na(directions))) {
    cli::cli_abort(c(
      "{.arg directions} must be a character vector.",
      "i" = "One of {.val {list_axis_directions()}} for each axis."
    ))
  }

  given <- directions[!is.na(directions)]
  unknown <- setdiff(given, list_axis_directions())
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "{.val {unknown}} {?is/are} not {?a/} direction{?s}.",
      "i" = "An axis points {.val {list_axis_directions()}}."
    ))
  }

  ensure_unopposed_axis_directions(given)
}


#' Do these axes point along different pairs?
#'
#' @param directions Named character vector of directions.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_unopposed_axis_directions <- function(directions) {
  pairs <- list_direction_pairs()[directions]
  clashing <- unique(pairs[duplicated(pairs)])
  if (length(clashing) > 0L) {
    offending <- names(directions)[pairs %in% clashing]
    cli::cli_abort(c(
      "Axes {.val {offending}} point along the same line.",
      "i" = "{.val {directions[offending]}} {?is/are} all {clashing}.",
      "i" = "Two axes of one frame cannot be parallel."
    ))
  }
  invisible(TRUE)
}


#' Is this a named map keyed by axis role?
#'
#' @param x Value to test.
#' @param arg Name of the argument it came from.
#' @param example A well-formed value, shown when `x` is not one.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_named_axis_map <- function(x, arg, example, call = rlang::caller_env()) {
  nms <- names(x)
  if (length(x) == 0L || is.null(nms) || any(nms == "" | is.na(nms))) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must name an axis role for every value.",
        "i" = "For example {.code {example}}."
      ),
      call = call
    )
  }

  unknown <- setdiff(nms, list_linear_axis_roles())
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.val {unknown}} {?is/are} not {?an/} axis{?/es} that points anywhere.",
        "i" = "Only {.val {list_linear_axis_roles()}} have a direction and an extent."
      ),
      call = call
    )
  }
  invisible(TRUE)
}


#' Reflect a spatial axis around a reference value
#'
#' @param data A data frame (typically an anipoint) containing `axis`.
#' @param axis Name of the column to reflect.
#' @param reference A single finite value to reflect around.
#'
#' @return The data with `axis` replaced by `reference - data[[axis]]`.
#' @keywords internal
reflect_column <- function(data, axis, reference) {
  if (!is.character(axis) || length(axis) != 1) {
    cli::cli_abort("{.arg axis} must be a single column name.")
  }
  ensure_has_column(data, axis)
  if (
    !is.numeric(reference) ||
      length(reference) != 1 ||
      !is.finite(reference)
  ) {
    cli::cli_abort(
      "{.arg reference} must be a single finite numeric value."
    )
  }
  data[[axis]] <- reference - data[[axis]]
  data
}


#' The angular column an axis role is measured against
#'
#' @return Named character vector, axis role to angular role.
#' @keywords internal
list_angular_axis_dependencies <- function() {
  c(x = "phi", y = "phi", z = "theta")
}


#' Turn an axis over on a frame that stores angles
#'
#' `x` reflects `phi` about the vertical, `y` about the horizontal, `z`
#' reflects `theta` about the equator; anything else leaves the data alone.
#'
#' @param data An anipoint object.
#' @param role An axis role.
#'
#' @return `data`, with the angles it stores measured the other way.
#' @keywords internal
reflect_angular_axis <- function(data, role) {
  axes <- get_axes(data)
  angular <- list_angular_axis_dependencies()[[role]]

  if (is.na(angular) || !angular %in% names(axes)) {
    return(data)
  }

  # A mirror off the origin changes `rho`, which no angle change can express.
  extents <- resolve_axis_extents(get_metadata(data))
  if (role %in% names(extents) && extents[[role]] != 0) {
    cli::cli_abort(c(
      "Cannot turn the {.field {role}} axis over around an extent on a {.val {get_coordinate_system(data)}} frame.",
      "i" = "Reflecting around {.val {extents[[role]]}} would move every point's distance from the origin, which {.field rho} would have to change to express.",
      "i" = "Clear the extent from {.field axis_extents} with {.fn set_metadata} to turn the axis over about the origin."
    ))
  }

  column <- axes[[angular]]
  ensure_has_column(data, column)

  # A supplemented `theta` stays in [0, pi]; `phi` must be rewrapped.
  is_colatitude <- identical(angular, "theta")

  data[[column]] <- reflect_angle(
    data[[column]],
    about = if (is_colatitude || identical(role, "x")) "half_turn" else "zero",
    unit = as.character(get_metadata(data, "unit_angle")),
    wrap = !is_colatitude,
    signed = any(data[[column]] < 0, na.rm = TRUE)
  )
  data
}


#' Reflect a vector of angles
#'
#' @param x Numeric vector of angles.
#' @param about `"zero"` to negate, `"half_turn"` to take the supplement.
#' @param unit The frame's `unit_angle`.
#' @param wrap Whether the result is a bearing, and so has to come back onto
#'   a full turn.
#' @param signed Whether that range is the signed one rather than `[0, 2pi)`.
#'
#' @return The reflected angles, in the same unit and range.
#' @keywords internal
reflect_angle <- function(x, about, unit, wrap = TRUE, signed = FALSE) {
  radians <- if (identical(unit, "deg")) deg_to_rad(x) else x

  reflected <- if (identical(about, "half_turn")) pi - radians else -radians

  if (wrap) {
    reflected <- wrap_angle(reflected, modulo = if (signed) "pi" else "2pi")
  }

  if (identical(unit, "deg")) rad_to_deg(reflected) else reflected
}
