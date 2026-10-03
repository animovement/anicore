#' Convert radians to degrees
#'
#' @param x Numeric vector of angles (radians).
#' @return Numeric vector of angles expressed in degrees.
#' @examples
#' rad_to_deg(pi)
#' rad_to_deg(c(0, pi / 2, pi))
#'
#' @family angle utilities
#' @export
rad_to_deg <- function(x) {
  (x * 180) / pi
}


#' Convert degrees to radians
#'
#' @param x Numeric vector of angles (degrees).
#' @return Numeric vector of angles expressed in radians.
#' @examples
#' deg_to_rad(180)
#' deg_to_rad(c(0, 90, 180))
#'
#' @family angle utilities
#' @export
deg_to_rad <- function(x) {
  (x * pi) / 180
}


#' Convert angles between radians and a frame's angular unit
#'
#' @description
#' Angular computations work in radians; a frame declares the unit its angles
#' are stored in (`unit_angle`). `angle_to_rad()` reads a frame's angles into
#' radians, and `angle_from_rad()` writes radians back out in the frame's
#' unit, so a function that computes new angles can return them in the unit
#' the frame declares.
#'
#' These convert values and leave the frame alone. To convert a frame's
#' columns and record the new unit, use [convert_unit_angle()]. Calling that on
#' new columns computed in radians would do nothing in a `"deg"` frame, since
#' it converts from the unit the frame already declares.
#'
#' @param x Numeric vector of angles, or of angular rates.
#' @param unit The angular unit: an aniframe or anievent, whose `unit_angle`
#'   is read, or one of `"rad"`, `"deg"` or `"none"`. Pass the unit as a
#'   string, read once with `get_metadata(data, "unit_angle")`, to convert
#'   inside [dplyr::mutate()].
#'
#' @details
#' A frame that declares no angular unit (`"none"`) is read as radians:
#' radians are the unit angles are computed in, and such a frame has no other
#' unit to return them in.
#'
#' @return Numeric vector, the same length as `x`.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_metadata(af, unit_angle = "deg")
#'
#' # Compute in radians, return in the frame's unit
#' angle_from_rad(pi / 2, af)
#'
#' # And read the frame's angles for computing
#' angle_to_rad(c(0, 90, 180), af)
#'
#' # With the unit read once, inside mutate()
#' angle_from_rad(c(0, pi), "deg")
#'
#' @family angle utilities
#' @export
angle_to_rad <- function(x, unit) {
  if (resolve_unit_angle(unit) == "deg") deg_to_rad(x) else x
}

#' @rdname angle_to_rad
#' @export
angle_from_rad <- function(x, unit) {
  if (resolve_unit_angle(unit) == "deg") rad_to_deg(x) else x
}

#' Resolve an angular unit given as a frame or a string
#'
#' @param unit An aniframe or anievent, or a unit string or factor.
#' @param call The calling environment, for error messages.
#'
#' @return `"rad"` or `"deg"`; `"none"` resolves to `"rad"`.
#' @keywords internal
resolve_unit_angle <- function(unit, call = rlang::caller_env()) {
  if (is_aniframe(unit)) {
    # An anievent has no spatial metadata, so no angular unit
    unit <- get_metadata(unit, "unit_angle") %||% "none"
  }
  allowed <- levels(list_default_metadata()[["unit_angle"]])
  if (is.factor(unit)) {
    unit <- as.character(unit)
  }
  if (!rlang::is_string(unit) || !unit %in% allowed) {
    cli::cli_abort(
      "{.arg unit} must be an aniframe or one of {.or {.val {allowed}}}.",
      call = call
    )
  }
  if (unit == "deg") "deg" else "rad"
}


#' Constrain angles to a standard range
#'
#' Wraps a vector of angles to a standard interval using modulo arithmetic.
#'
#' @param x A numeric vector of angles, in radians.
#' @param modulo A character string (default `"2pi"`) giving the target range:
#'   \describe{
#'     \item{`"2pi"`}{Wrap to `[0, 2*pi)`.}
#'     \item{`"pi"`}{Wrap to `(-pi, pi]`.}
#'     \item{`"asis"`}{Return unchanged.}
#'   }
#' @return A numeric vector the same length as `x`, wrapped to the chosen range.
#' @examples
#' angles <- c(-pi, 0, pi, 2 * pi, 3 * pi)
#'
#' wrap_angle(angles, "2pi")
#'
#' # The same angles on the signed interval
#' wrap_angle(angles, "pi")
#'
#' # "asis" is a no-op, useful when the range is chosen by a caller
#' wrap_angle(angles, "asis")
#'
#' @family angle utilities
#' @export
wrap_angle <- function(x, modulo = c("2pi", "pi", "asis")) {
  modulo <- match.arg(modulo)

  switch(
    modulo,
    "2pi" = x %% (2 * pi),
    "pi" = pi - ((pi - x) %% (2 * pi)),
    "asis" = x
  )
}


#' Remove wrapping from a sequence of angles
#'
#' Reverses the discontinuity introduced by wrapping, by accumulating the
#' shortest step between successive angles. A heading that crosses `2*pi`
#' therefore continues to increase rather than jumping back to zero, which is
#' what makes it differentiable. `NA` values are preserved in place.
#'
#' @param x A numeric vector of angles, in radians.
#' @return A numeric vector the same length as `x`, without wrapping
#'   discontinuities.
#' @examples
#' # A heading turning steadily past a full circle, wrapped to [0, 2*pi)
#' wrapped <- wrap_angle(seq(0, 3 * pi, length.out = 7), "2pi")
#' wrapped
#'
#' # Unwrapping restores the steady progression
#' unwrap_angle(wrapped)
#'
#' @family angle utilities
#' @export
unwrap_angle <- function(x) {
  if (length(x) == 0L) {
    return(x)
  }

  if (all(is.na(x))) {
    return(x)
  }

  result <- numeric(length(x))
  result[is.na(x)] <- NA_real_

  non_na_idx <- which(!is.na(x))
  x_clean <- x[non_na_idx]

  angle_diff <- diff(x_clean)
  angle_diff_wrapped <- wrap_angle(angle_diff, modulo = "pi")
  unwrapped_clean <- c(x_clean[1], x_clean[1] + cumsum(angle_diff_wrapped))

  result[non_na_idx] <- unwrapped_clean
  result
}
