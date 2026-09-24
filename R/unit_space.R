#' Convert the spatial unit of an anipoint
#'
#' @description
#' Rescales the columns carrying a length and records the new `unit_space`.
#' Those are the length axes of the coordinate system — `x`, `y`, `z` on a
#' Cartesian frame, `rho` (and `z`) on a polar, cylindrical or spherical one.
#' Angular axes are [convert_unit_angle()]'s. Declared `axis_extents` are
#' rescaled with them.
#'
#' To declare a unit without changing values, use
#' `set_metadata(data, unit_space = "mm")`.
#'
#' @param data An anipoint, or an anisegment, whose `length` is rescaled.
#' @param to_unit Target unit, one of the levels of `unit_space` in
#'   [list_default_metadata()].
#' @param calibration_factor Multiplier from the current unit to `to_unit`.
#'   Derived between metric units; required when converting from `"px"`.
#'
#' @return `data`, rescaled, with `unit_space` updated.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#'
#' # 1 px = 0.5 mm
#' af_mm <- convert_unit_space(af, "mm", calibration_factor = 0.5)
#' convert_unit_space(af_mm, "cm")
#'
#' @export
convert_unit_space <- function(data, to_unit, calibration_factor = NULL) {
  if (!is_anisegment(data)) {
    ensure_is_anipoint(data)
  }

  if (!to_unit %in% levels(list_default_metadata()[["unit_space"]])) {
    cli::cli_abort(
      "Space unit can only be {levels(list_default_metadata()[[\"unit_space\"]])}, not {to_unit}."
    )
  }

  from <- as.character(get_metadata(data, "unit_space"))
  if (is.null(calibration_factor)) {
    if (any(c(from, to_unit) %in% c("px", "none"))) {
      cli::cli_abort(c(
        "Cannot convert from {.val {from}} to {.val {to_unit}} without a {.arg calibration_factor}.",
        "i" = "To declare the unit without converting, use {.code set_metadata(data, unit_space = \"{to_unit}\")}."
      ))
    }
    calibration_factor <- get_conversion_factor_space(
      from_unit = from,
      to_unit = to_unit
    )
  }

  space_cols <- if (is_anisegment(data)) {
    get_variables(data, "where", "length")
  } else {
    # Select length axes by role, not name, so `rho` is converted too (#98).
    axes <- get_axes(data)
    unname(axes[intersect(
      get_system_axes(get_metadata(data, "coordinate_system")),
      names(axes)
    )])
  }

  if (length(space_cols) == 0L) {
    cli::cli_warn(c(
      "No length axes found for coordinate system {.val {as.character(get_metadata(data, 'coordinate_system'))}}.",
      "i" = "{.field unit_space} is being set to {.val {to_unit}} but no columns were converted.",
      "i" = "Declare the spatial columns with {.fn set_variables} if this frame has any."
    ))
  }

  data <- data |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::any_of(space_cols),
        .fns = ~ .x * calibration_factor,
        .names = "{.col}"
      )
    )

  # An extent is a length, so it is in the unit being converted from.
  extents <- resolve_axis_extents(get_metadata(data))
  if (length(extents) > 0L) {
    data <- set_metadata(data, axis_extents = extents * calibration_factor)
  }

  set_metadata(data, unit_space = to_unit)
}


#' The axes of a coordinate system that carry a length (#98)
#'
#' @param coordinate_system A `coordinate_system` metadata value.
#'
#' @return Character vector of axis names, empty when the coordinate system
#'   is `"unknown"` or `"none"`.
#' @keywords internal
get_system_axes <- function(coordinate_system) {
  switch(
    as.character(coordinate_system),
    cartesian_1d = ,
    cartesian_2d = ,
    cartesian_3d = c("x", "y", "z"),
    polar = "rho",
    cylindrical = c("rho", "z"),
    spherical = "rho",
    character()
  )
}

#' @keywords internal
get_conversion_factor_space <- function(from_unit, to_unit) {
  conv <- list_conversion_factors_space()
  conv[to_unit, from_unit]
}

#' @keywords internal
list_conversion_factors_space <- function() {
  m <- matrix(
    c(1, 1 / 10, 1 / 1000, 10, 1, 1 / 100, 1000, 100, 1),
    nrow = 3,
    byrow = FALSE
  )

  permitted_units <- c("mm", "cm", "m")
  rownames(m) <- permitted_units
  colnames(m) <- permitted_units
  m
}
