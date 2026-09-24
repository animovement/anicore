#' Set the spatial unit of an anipoint object
#'
#' @description
#' Converts the spatial coordinates of an anipoint object to a different unit
#' of measurement. The function handles both automatic unit conversion between
#' standard units and custom calibration from pixel or arbitrary units.
#'
#' The columns converted are the axes of the frame's `coordinate_system` that
#' carry a **length** — `x`, `y` and `z` on a Cartesian frame, but `rho` on a
#' polar or spherical one and `rho` and `z` on a cylindrical one. The angular
#' axes (`phi`, `theta`) are left alone; they are [set_unit_angle()]'s to
#' convert.
#'
#' @param data An anipoint object containing spatial coordinate data.
#' @param to_unit Character string specifying the target spatial unit. Must be
#'   one of the permitted units defined in `list_default_metadata()$unit_space`.
#' @param calibration_factor Numeric value for scaling spatial coordinates.
#'   Default is 1. When converting from standard units (mm, cm, m), this is
#'   ignored and the appropriate conversion factor is calculated automatically.
#'   When converting from "px" or "unknown", you must provide a calibration factor
#'   to define the relationship between the current units and the target unit.
#'
#' @return An anipoint object with spatial coordinates converted to the specified
#'   unit and updated metadata reflecting the new unit_space.
#'
#' @details
#' The function performs the following operations:
#' * Validates that `to_unit` is a permitted spatial unit
#' * Determines the current spatial unit from the object's metadata
#' * If converting from standard units (mm, cm, m) to another standard unit,
#'   automatically calculates the conversion factor
#' * If converting from "px" or "unknown" units with `calibration_factor = 1`,
#'   issues an informational message and returns data unchanged
#' * Applies the calibration factor to the length axes of the frame's
#'   coordinate system
#' * Updates the object's unit_space metadata
#'
#' @examples
#' \dontrun{
#' # Convert from millimeters to centimeters (automatic conversion)
#' data_cm <- set_unit_space(data, to_unit = "cm")
#'
#' # Convert from pixels to millimeters with custom calibration
#' # (e.g., 1 pixel = 0.5 mm)
#' data_mm <- set_unit_space(data, to_unit = "mm", calibration_factor = 0.5)
#' }
#'
#' @export
set_unit_space <- function(data, to_unit, calibration_factor = 1) {
  ensure_is_anipoint(data)

  # Check that to_unit is permitted
  if (!to_unit %in% levels(list_default_metadata()[["unit_space"]])) {
    cli::cli_abort(
      "Space unit can only be {levels(list_default_metadata()[[\"unit_space\"]])}, not {to_unit}."
    )
  }

  current_unit_space <- get_metadata(data, "unit_space")
  if (calibration_factor == 1 && current_unit_space %in% c("px", "none")) {
    cli::cli_alert_info(
      "calibration_factor is not set, data remains unchanged."
    )
  } else if (calibration_factor == 1) {
    calibration_factor <- get_conversion_factor_space(
      from_unit = as.character(current_unit_space),
      to_unit = to_unit
    )
  }

  # Calibrate the axes that carry a length. Picking them by name would
  # convert x/y/z and silently leave rho — a length — in the old unit while
  # the metadata claimed the new one (#98). `get_system_axes()` names roles, so
  # they are resolved to columns through the frame's own mapping (#109).
  axes <- get_axes(data)
  space_cols <- unname(
    axes[intersect(
      get_system_axes(get_metadata(data, "coordinate_system")),
      names(axes)
    )]
  )

  if (length(space_cols) == 0L) {
    cli::cli_warn(c(
      "No length axes found for coordinate system {.val {as.character(get_metadata(data, 'coordinate_system'))}}.",
      "i" = "{.field unit_space} is being set to {.val {to_unit}} but no columns were converted.",
      "i" = "Declare the spatial columns with {.fn set_variables_where} if this frame has any."
    ))
  }

  data <- data |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::any_of(space_cols),
        .fns = ~ .x * calibration_factor,
        .names = "{.col}" # keep the original column names
      )
    )

  # An extent is a length, so it is in the unit being converted from.
  extents <- get_axis_extents(data)
  if (length(extents) > 0L) {
    data <- set_metadata(data, axis_extents = extents * calibration_factor)
  }

  set_metadata(data, unit_space = to_unit)
}


#' The axes of a coordinate system that carry a length
#'
#' The complement of the angular axes that [set_unit_angle()] converts. A
#' spatial unit applies to these and to nothing else: on a cylindrical frame
#' `rho` and `z` are both lengths while `phi` is an angle, so converting by
#' column name rather than by role leaves one of them behind (#98).
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

  # Attach row‑ and column‑names
  permitted_units <- c("mm", "cm", "m")
  rownames(m) <- permitted_units
  colnames(m) <- permitted_units
  m
}
