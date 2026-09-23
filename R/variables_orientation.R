#' The orientation role sets
#'
#' `yaw` for a 2D frame; a unit quaternion (Hamilton, scalar first) for a 3D
#' one (#46).
#'
#' @return Named list, kind to roles.
#' @keywords internal
list_orientation_role_sets <- function() {
  list(yaw = "yaw", quaternion = c("qw", "qx", "qy", "qz"))
}


#' Check a `where$orientation` declaration against the frame
#'
#' @param data A plain data frame holding the columns.
#' @param orientation Named character vector, role to column.
#' @param coordinate_system The frame's coordinate system.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_orientation <- function(data, orientation, coordinate_system) {
  roles <- names(orientation)
  kind <- names(Filter(
    function(set) setequal(set, roles %||% character()),
    list_orientation_role_sets()
  ))
  if (length(kind) == 0L || anyDuplicated(roles)) {
    cli::cli_abort(c(
      "{.field where$orientation} must map the roles {.val yaw} (2D) or {.val {list_orientation_role_sets()$quaternion}} (3D) to columns.",
      "i" = "Got roles {.val {roles}}."
    ))
  }

  dims <- switch(kind, yaw = "2D", quaternion = "3D")
  systems <- switch(
    kind,
    yaw = c("cartesian_2d", "polar"),
    quaternion = c("cartesian_3d", "cylindrical", "spherical")
  )
  if (!coordinate_system %in% c(systems, "unknown")) {
    cli::cli_abort(c(
      "{.val {kind}} orientation needs a {dims} frame, not a {.val {coordinate_system}} one.",
      "i" = "Use {.val yaw} for 2D frames and {.val {list_orientation_role_sets()$quaternion}} for 3D ones."
    ))
  }

  ensure_has_declared_cols(data, unname(orientation), "where")
  non_numeric <- orientation[
    !vapply(
      orientation,
      function(col) is.numeric(data[[col]]),
      logical(1)
    )
  ]
  if (length(non_numeric) > 0L) {
    cli::cli_abort(
      "Orientation column{?s} {.val {non_numeric}} must be numeric."
    )
  }

  if (identical(kind, "quaternion")) {
    q <- as.matrix(as.data.frame(data)[, orientation[c(
      "qw",
      "qx",
      "qy",
      "qz"
    )]])
    norm <- sqrt(rowSums(q^2))
    off <- sum(abs(norm - 1) > 1e-3, na.rm = TRUE)
    if (off > 0L) {
      cli::cli_abort(c(
        "Orientation quaternions must have unit norm; {off} row{?s} do{?es/} not.",
        "i" = "Divide each by its norm before declaring it."
      ))
    }
  }
  invisible(TRUE)
}


#' Turn the orientation over with an axis
#'
#' `yaw` is measured from `x` toward `y`, so it reflects like `phi`. A
#' reflection conjugates a rotation and reverses its sense: across the plane
#' normal to `axis`, a quaternion keeps `w` and that axis's component and
#' negates the other two.
#'
#' @param data An anipoint object.
#' @param axis `"x"`, `"y"` or `"z"`.
#'
#' @return `data`, with the orientation columns reflected.
#' @keywords internal
reflect_orientation <- function(data, axis) {
  orientation <- get_variables(data, "where", "orientation")
  if (length(orientation) == 0L) {
    return(data)
  }
  if ("yaw" %in% names(orientation)) {
    if (identical(axis, "z")) {
      return(data)
    }
    column <- orientation[["yaw"]]
    data[[column]] <- reflect_angle(
      data[[column]],
      about = if (identical(axis, "x")) "half_turn" else "zero",
      unit = as.character(get_metadata(data, "unit_angle")),
      signed = any(data[[column]] < 0, na.rm = TRUE)
    )
    return(data)
  }
  for (role in setdiff(c("qx", "qy", "qz"), paste0("q", axis))) {
    column <- orientation[[role]]
    data[[column]] <- -data[[column]]
  }
  data
}
