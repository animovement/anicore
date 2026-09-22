# Axis roles (#109)
#
# The coordinate system used to be inferred by matching `variables_where`
# against a fixed list of names. The name *was* the role, so a frame whose
# coordinates were called anything else degraded to `unknown` and every
# spatial function refused it.
#
# The `axes` field maps role to column instead: `c(x = "u", y = "v")`. The
# set of roles stays closed — that is what makes `map_to_polar()` and unit
# conversion meaningful — while the spelling of the columns is free.
#
# It is a field of its own rather than names on `variables_where`, which
# stays a plain vector. A named character vector is a *rename instruction*
# to tidyselect, and `variables_where` is read raw and passed to
# `dplyr::all_of()` downstream, where names would silently rename the
# columns. `axes` will move into the spatial category in #118.

#' The axis role sets that define each coordinate system
#'
#' Closed by design. A transformation between coordinate systems is only
#' well defined because the roles on each side are known, so an
#' unrecognised role is rejected rather than accommodated.
#'
#' @return Named list mapping a comma-separated sorted role set to the
#'   coordinate system it defines.
#' @keywords internal
list_axis_role_sets <- function() {
  list(
    "x" = "cartesian_1d",
    "y" = "cartesian_1d",
    "z" = "cartesian_1d",
    "x,y" = "cartesian_2d",
    "x,z" = "cartesian_2d",
    "y,z" = "cartesian_2d",
    "x,y,z" = "cartesian_3d",
    "phi,rho" = "polar",
    "phi,rho,z" = "cylindrical",
    "phi,rho,theta" = "spherical"
  )
}


#' Every role any coordinate system recognises
#'
#' @return Character vector of role names.
#' @keywords internal
list_axis_roles <- function() {
  c("x", "y", "z", "rho", "phi", "theta")
}


#' Normalise a `variables_where` declaration into a role-to-column mapping
#'
#' An unnamed vector is the historical form, where the column name *is*
#' the role; it is read that way, which is what keeps every existing frame
#' and every reader's output working untouched.
#'
#' @param variables_where Character vector, optionally named by axis role.
#'
#' @return Named character vector: names are roles, values are columns.
#' @keywords internal
normalise_axes <- function(variables_where) {
  if (length(variables_where) == 0L) {
    return(stats::setNames(character(), character()))
  }
  nms <- names(variables_where)
  if (is.null(nms) || any(nms == "" | is.na(nms))) {
    # Unnamed, or partially named — the historical reading applies.
    return(stats::setNames(
      as.character(variables_where),
      as.character(variables_where)
    ))
  }
  stats::setNames(as.character(variables_where), nms)
}


#' Was this declaration written as an explicit role mapping?
#'
#' Explicit roles are validated strictly and an unrecognised one aborts.
#' A bare vector of column names keeps the older, lenient behaviour of
#' warning and falling back to `"unknown"`, because that is what readers
#' and existing frames rely on.
#'
#' @param variables_where The declaration as supplied.
#'
#' @return `TRUE` when every element carries a role name.
#' @keywords internal
has_axis_roles <- function(variables_where) {
  nms <- names(variables_where)
  length(variables_where) > 0L &&
    !is.null(nms) &&
    !any(nms == "" | is.na(nms))
}


#' Reject roles that no coordinate system defines
#'
#' Named by the offending role, at the point of declaration — as opposed
#' to silently degrading the frame to `"unknown"` and failing later in
#' whichever spatial function the user reaches for first.
#'
#' @param axes A normalised role-to-column mapping.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_axis_roles <- function(axes) {
  roles <- names(axes)

  unknown <- setdiff(roles, list_axis_roles())
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "{cli::qty(unknown)}{?Axis role/Axis roles} {.val {unknown}} {?is/are} not recognised.",
      "i" = "Roles are {.val {list_axis_roles()}}.",
      "i" = "The role set is closed so that transformations between coordinate systems stay well defined; the column names are free."
    ))
  }

  if (anyDuplicated(roles) > 0L) {
    dupes <- unique(roles[duplicated(roles)])
    cli::cli_abort(
      "{cli::qty(dupes)}{?Axis role/Axis roles} {.val {dupes}} {?is/are} declared more than once."
    )
  }

  if (!paste(sort(roles), collapse = ",") %in% names(list_axis_role_sets())) {
    cli::cli_abort(c(
      "Axis roles {.val {roles}} do not form a coordinate system.",
      "i" = "Recognised combinations are {.val {names(list_axis_role_sets())}}."
    ))
  }

  invisible(TRUE)
}


#' The axis roles of an anipoint, and the columns carrying them
#'
#' Where [get_variables_where()] gives the column names, this gives what
#' each of them *means*. Index by role to write a transformation that does
#' not care what the columns are called:
#' `data[[get_axes(data)[["x"]]]]`.
#'
#' @param data An anipoint object.
#'
#' @return Named character vector: names are axis roles (`x`, `y`, `z`,
#'   `rho`, `phi`, `theta`), values are the columns carrying them. Empty
#'   for a frame whose coordinate system is `"unknown"`.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_axes(af)
#'
#' df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))
#' renamed <- as_anipoint(df, variables_where = c(x = "u", y = "v"))
#' get_axes(renamed)
#' get_metadata(renamed, "coordinate_system")
#'
#' @seealso [set_axes()] to change it, [get_variables_where()] for the
#'   columns without their roles.
#' @export
get_axes <- function(data) {
  ensure_is_anipoint(data)
  resolve_axes(get_metadata(data))
}


#' Resolve the axis mapping from a metadata list
#'
#' Objects serialised before the field existed have no `axes`, but their
#' `variables_where` was matched against the role names to infer a
#' coordinate system, so the column name *was* the role. Reading it that
#' way here keeps those frames working untouched.
#'
#' @param md A metadata list.
#'
#' @return Named character vector, empty when no role set applies.
#' @keywords internal
resolve_axes <- function(md) {
  empty <- stats::setNames(character(), character())
  position <- md_where_position(md)

  if (length(position) == 0L) {
    return(empty)
  }

  if (is.null(names(position))) {
    # Columns whose roles are unknown: usable as axes only when their
    # names themselves name a coordinate system.
    axes <- normalise_axes(position)
    if (identical(infer_coordinate_system(axes), "unknown")) {
      return(empty)
    }
    return(axes)
  }

  position
}


#' Warn when an axis role is carried by one column while another has its name
#'
#' `get_axes(af)[["x"]]` may be `"u"` while the frame also has a column
#' literally called `x`. The frame is not malformed and the mapping is
#' right, but `.data$x` then returns a real column of real numbers that is
#' not the x axis — plausible wrong answers rather than an error, and the
#' habit axis roles exist to replace (#119).
#'
#' A warning, not an error: the state is legal, and a column named `x` may
#' honestly mean something else. Silence it for a whole loop with
#' `options(aniframe.quiet = TRUE)`.
#'
#' @param axes A normalised role-to-column mapping.
#' @param columns The frame's column names.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_shadowed_axis_roles <- function(axes, columns) {
  if (isTRUE(getOption("aniframe.quiet", FALSE)) || length(axes) == 0L) {
    return(invisible(TRUE))
  }

  roles <- names(axes)
  shadowed <- roles[roles != axes & roles %in% columns]
  if (length(shadowed) > 0L) {
    carried_by <- unname(axes[shadowed])
    cli::cli_warn(c(
      "{cli::qty(shadowed)}Axis role{?s} {.val {shadowed}} {?is/are} carried by {.val {carried_by}}, but the frame also has {cli::qty(shadowed)}{?a column/columns} of {?that/those} name{?s}.",
      "i" = "{.val {shadowed}} {?is/are} not {?a coordinate column/coordinate columns} here; read the axes with {.fn get_axes}.",
      "i" = "Silence this with {.code options(aniframe.quiet = TRUE)}."
    ))
  }

  invisible(TRUE)
}


#' Declare which column carries which axis role
#'
#' The mapping decides the `coordinate_system` and is what spatial
#' transformations index by, so — like the `variables_*` declarations — it
#' is not reachable through [set_metadata()] and has its own setter, which
#' restructures the frame too.
#'
#' The direction is role to column, the same way round as [get_axes()]
#' returns it and as [dplyr::rename()] reads, so `set_axes(af, get_axes(af))`
#' does nothing.
#'
#' @param data An anipoint object.
#' @param axes Named character vector: names are axis roles, values are the
#'   columns carrying them. The roles must form a coordinate system, and
#'   every column must exist in `data`.
#'
#' @return `data`, re-declared and restructured.
#'
#' @examples
#' df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))
#' af <- as_anipoint(df, variables_where = c("u", "v"))
#' get_metadata(af, "coordinate_system")
#'
#' af <- set_axes(af, c(x = "u", y = "v"))
#' get_axes(af)
#' get_metadata(af, "coordinate_system")
#'
#' @seealso [get_axes()]
#' @export
set_axes <- function(data, axes) {
  ensure_is_anipoint(data)
  ensure_variables_character(axes)
  if (!has_axis_roles(axes)) {
    cli::cli_abort(c(
      "{.arg axes} must name an axis role for every column.",
      "i" = "For example {.code c(x = \"u\", y = \"v\")}.",
      "i" = "To declare spatial columns without roles, use {.fn set_variables_where}."
    ))
  }
  declare_variables(data, "where", axes)
}
