# Predicates read the `coordinate_system` field, not column names (#109).

#' The coordinate system an anipoint is in
#'
#' Derived from the axis roles rather than declared: [set_variables()] says
#' which column carries which role, and the system follows from the set of
#' roles present. It is therefore not writable — see [set_variables()] to say
#' what the columns mean, or `anispace`'s `map_to_*()` functions to convert
#' the coordinates themselves.
#'
#' @param data An anipoint or anievent object.
#'
#' @return Length-one character vector: one of `"cartesian_1d"`,
#'   `"cartesian_2d"`, `"cartesian_3d"`, `"polar"`, `"cylindrical"`,
#'   `"spherical"` or `"unknown"`.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_coordinate_system(af)
#'
#' @seealso [get_axes()], [is_cartesian()], [is_polar()]
#' @export
get_coordinate_system <- function(data) {
  ensure_is_aniframe(data)
  as.character(get_metadata(data, "coordinate_system") %||% NA_character_)
}


#' Test whether an anipoint uses a Cartesian coordinate system
#'
#' Returns `TRUE` if the data frame satisfies *any* of the 1-D, 2-D or 3-D
#' Cartesian checks.
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_cartesian(af)
#' @export
is_cartesian <- function(data) {
  get_coordinate_system(data) %in% list_cartesian_systems()
}


#' Internal guard for Cartesian checks
#'
#' Stops with a clear error message if `data` is not Cartesian.
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently when the coordinate system matches
#' ensure_is_cartesian(af)
#' @export
ensure_is_cartesian <- function(data) {
  ensure_coordinate_system(data, list_cartesian_systems(), "Cartesian")
}


#' Test for a 1-D Cartesian coordinate system
#'
#' @param data An anipoint.
#' @param stop Unused, and kept only so the signature does not change.
#'   It has no effect.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_cartesian_1d(af)
#' @export
is_cartesian_1d <- function(data, stop = FALSE) {
  identical(get_coordinate_system(data), "cartesian_1d")
}


#' Internal guard for 1-D Cartesian checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' try(ensure_is_cartesian_1d(af))
#' @export
ensure_is_cartesian_1d <- function(data) {
  ensure_coordinate_system(data, "cartesian_1d", "1D Cartesian")
}


#' Test for a 2-D Cartesian coordinate system
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_cartesian_2d(af)
#' @export
is_cartesian_2d <- function(data) {
  identical(get_coordinate_system(data), "cartesian_2d")
}


#' Internal guard for 2-D Cartesian checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' ensure_is_cartesian_2d(af)
#' @export
ensure_is_cartesian_2d <- function(data) {
  ensure_coordinate_system(data, "cartesian_2d", "2D Cartesian")
}


#' Test for a 3-D Cartesian coordinate system
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_cartesian_3d(af)
#' @export
is_cartesian_3d <- function(data) {
  identical(get_coordinate_system(data), "cartesian_3d")
}


#' Internal guard for 3-D Cartesian checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' try(ensure_is_cartesian_3d(af))
#' @export
ensure_is_cartesian_3d <- function(data) {
  ensure_coordinate_system(data, "cartesian_3d", "3D Cartesian")
}


#' Test whether an anipoint uses a polar coordinate system
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_polar(af)
#' @export
is_polar <- function(data) {
  identical(get_coordinate_system(data), "polar")
}


#' Internal guard for polar checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently when the coordinate system matches
#' try(ensure_is_polar(af))
#' @export
ensure_is_polar <- function(data) {
  ensure_coordinate_system(data, "polar", "polar")
}


#' Test whether an anipoint uses a cylindrical coordinate system
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_cylindrical(af)
#' @export
is_cylindrical <- function(data) {
  identical(get_coordinate_system(data), "cylindrical")
}


#' Internal guard for cylindrical checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently when the coordinate system matches
#' try(ensure_is_cylindrical(af))
#' @export
ensure_is_cylindrical <- function(data) {
  ensure_coordinate_system(data, "cylindrical", "cylindrical")
}


#' Test whether an anipoint uses a spherical coordinate system
#'
#' @param data An anipoint.
#' @return A logical value.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_spherical(af)
#' @export
is_spherical <- function(data) {
  identical(get_coordinate_system(data), "spherical")
}


#' Internal guard for spherical checks
#'
#' @param data An anipoint.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently when the coordinate system matches
#' try(ensure_is_spherical(af))
#' @export
ensure_is_spherical <- function(data) {
  ensure_coordinate_system(data, "spherical", "spherical")
}


#' The Cartesian coordinate systems
#'
#' @return Character vector of `coordinate_system` values.
#' @keywords internal
list_cartesian_systems <- function() {
  c("cartesian_1d", "cartesian_2d", "cartesian_3d")
}


#' Ensure the frame is in one of the coordinate systems a caller needs
#'
#' @param data An anipoint object.
#' @param permitted Coordinate systems that satisfy the caller.
#' @param wanted Human-readable name of the required coordinate system.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_coordinate_system <- function(data, permitted, wanted) {
  if (get_coordinate_system(data) %in% permitted) {
    return(invisible(TRUE))
  }

  actual <- get_coordinate_system(data)
  hint <- if (identical(actual, "unknown")) {
    "Declare which axis each spatial column carries with {.code set_variables(data, where = )}."
  } else {
    "Convert the coordinates first; {.pkg anispace} has the transformations."
  }

  cli::cli_abort(c(
    "This anipoint is not in a {wanted} coordinate system.",
    "i" = "{.field coordinate_system} is {.val {actual}}.",
    "i" = hint
  ))
}


#' Infer coordinate system from spatial variables
#'
#' @param variables_where Character vector of spatial variable names.
#' @return Character string naming the coordinate system.
#' @keywords internal
infer_coordinate_system <- function(variables_where) {
  roles <- names(normalise_axes(variables_where))
  key <- paste(sort(roles), collapse = ",")

  coord_map <- list_axis_role_sets()
  if (key %in% names(coord_map)) {
    return(coord_map[[key]])
  }

  # Known roles not forming a system need converting; unknown names declaring.
  hint <- if (length(roles) > 0L && all(roles %in% list_axis_roles())) {
    "Convert the coordinates to a system these axes do form; {.pkg anispace} has the transformations."
  } else {
    "To keep the coordinate system, say which axis each column carries with {.code set_variables(data, where = )}."
  }

  cli::cli_warn(
    c(
      "Could not infer coordinate system from spatial variables: {.val {unname(variables_where)}}.",
      "i" = "Setting coordinate system to {.val unknown}.",
      "i" = hint
    )
  )
  "unknown"
}
