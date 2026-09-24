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
#' axes out — most 3D recordings — has it from the field
#' [set_handedness()] writes.
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


#' Say whether the frame is right- or left-handed
#'
#' @description
#' Handedness is what 3D data is usually described by, so this says it
#' directly rather than through three separate axis directions.
#'
#' With two axes declared the third follows, and is recorded. With all three
#' declared, turning the handedness over reverses the **depth** axis — the one
#' pointing `back` or `forward` — and reflects that column, which is the
#' conventional way to convert between the two.
#'
#' Right-handed is the convention across the suite, so `set_handedness(data)`
#' completes a frame the standard way. It is not assumed of a frame that has
#' not been asked: which side a recording was made from is a fact about the
#' recording, and [get_handedness()] reports `"unknown"` until it is told.
#'
#' @param data An anipoint object.
#' @param handedness Either `"right"` or `"left"`. Right-handed is the
#'   convention across the suite and the default here; a frame is only
#'   left-handed if it is told to be.
#'
#' @return The anipoint, with the axis directions that give this handedness
#'   and the depth axis reflected if it had to turn over.
#'
#' @details
#' Two axes cannot fix a handedness, so at least two must already be declared
#' for the third to follow from this one. Declare them with
#' [set_axis_directions()].
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_axis_directions(af, c(x = "right", y = "up"))
#'
#' # z follows from the handedness, which defaults to right
#' af <- set_handedness(af)
#' get_axis_directions(af)
#'
#' @seealso [get_handedness()], [set_axis_directions()]
#' @export
set_handedness <- function(data, handedness = "right") {
  ensure_is_anipoint(data)
  ensure_is_one_of(handedness, c("right", "left"), "handedness")

  # Recorded even without declared axes: a frame may state only the convention.
  data <- set_derived_orientation(
    data,
    wanted = handedness,
    derive = derive_handedness,
    roles = list_linear_axis_roles(),
    turning = "depth",
    what = "handedness",
    required = FALSE
  )
  set_metadata(data, handedness = handedness)
}


#' Say which way angles run
#'
#' @description
#' With one of the two axes declared the other follows, and is recorded. With
#' both declared, turning the sense over reverses the **vertical** axis and
#' reflects that column — the image-plane flip, stated as what it does to the
#' angles rather than to a corner.
#'
#' @param data An anipoint object.
#' @param angle_direction Either `"clockwise"` or `"counter_clockwise"`.
#'
#' @return The anipoint, with the axis directions that give this sense and the
#'   vertical axis reflected if it had to turn over.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_axis_directions(af, c(x = "right"))
#'
#' # y follows from the sense of rotation
#' af <- set_angle_direction(af, "counter_clockwise")
#' get_axis_directions(af)
#'
#' @seealso [get_angle_direction()], [set_axis_directions()]
#' @export
set_angle_direction <- function(data, angle_direction) {
  ensure_is_anipoint(data)
  ensure_is_one_of(
    angle_direction,
    c("clockwise", "counter_clockwise"),
    "angle_direction"
  )

  set_derived_orientation(
    data,
    wanted = angle_direction,
    derive = derive_angle_direction,
    roles = c("x", "y"),
    turning = "vertical",
    what = "angle direction"
  )
}


#' Declare axis directions by the answer they should give
#'
#' Shared by [set_handedness()] and [set_angle_direction()].
#'
#' @param data An anipoint object.
#' @param wanted The value the derivation should give.
#' @param derive The derivation to invert.
#' @param roles The axis roles it reads.
#' @param turning Which opposed pair to reverse when every role is declared.
#' @param what Name of the quantity, for messages.
#' @param required Whether too few declared axes is an error. `FALSE` for a
#'   quantity that can be stated on its own.
#'
#' @return `data`, with directions declared through [set_axis_directions()].
#' @keywords internal
set_derived_orientation <- function(
  data,
  wanted,
  derive,
  roles,
  turning,
  what,
  required = TRUE
) {
  current <- get_axis_directions(data)
  declared <- intersect(roles, names(current))

  if (length(declared) < length(roles) - 1L) {
    if (!required) {
      return(data)
    }
    cli::cli_abort(c(
      "Not enough axes are declared to fix the {what}.",
      "i" = "{.val {roles}} would fix it, and {?none/only {.val {declared}}} {?is/are} declared.",
      "i" = "Declare them with {.fn set_axis_directions}."
    ))
  }

  if (identical(derive(current), wanted)) {
    return(data)
  }

  # One role short: solve for it; nothing to reflect.
  undeclared <- setdiff(roles, declared)
  if (length(undeclared) == 1L) {
    return(set_axis_directions(
      data,
      solve_axis_direction(current, undeclared, wanted, derive)
    ))
  }

  # All declared and wrong: reverse the conventional axis for this quantity.
  role <- names(current)[list_direction_pairs()[current] == turning]
  set_axis_directions(
    data,
    stats::setNames(unname(list_direction_opposites()[current[role]]), role)
  )
}


#' Find the direction of one axis from the answer the whole set should give
#'
#' @param current Directions already declared.
#' @param role The axis with no direction yet.
#' @param wanted The value the derivation should give.
#' @param derive The derivation to invert.
#'
#' @return A length-one named character vector.
#' @keywords internal
solve_axis_direction <- function(current, role, wanted, derive) {
  taken <- list_direction_pairs()[current]
  candidates <- setdiff(
    list_axis_directions(),
    names(list_direction_pairs())[list_direction_pairs() %in% taken]
  )

  for (direction in candidates) {
    if (
      identical(derive(c(current, stats::setNames(direction, role))), wanted)
    ) {
      return(stats::setNames(direction, role))
    }
  }

  cli::cli_abort(
    "No direction for the {.field {role}} axis gives {.val {wanted}}."
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
