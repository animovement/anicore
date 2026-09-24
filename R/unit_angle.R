#' Set the angular unit of an anipoint object
#'
#' @description
#' Converts angular columns in an anipoint between degrees (`"deg"`) and
#' radians (`"rad"`), and updates the `unit_angle` metadata to match.
#'
#' Spatial angular columns (`phi`, `theta`) are converted automatically
#' whenever they are present in the data, so polar/cylindrical/spherical
#' coordinates always stay consistent with the declared unit. Additional
#' angular columns (e.g. heading or orientation columns named outside the
#' polar family) can be supplied via `cols`.
#'
#' @param data An anipoint object containing angular data.
#' @param to_unit Character string specifying the target angular unit. Must
#'   be one of `c("rad", "deg")` (the levels of
#'   `list_default_metadata()$unit_angle`).
#' @param cols Optional character vector of additional angular column names
#'   to convert. The spatial angular columns `phi` and `theta` are detected
#'   automatically and need not be listed; pass `cols` only for non-spatial
#'   angular columns (e.g. `"heading"`). All listed columns must be present
#'   and numeric.
#'
#' @return An anipoint object with the relevant angular columns converted to
#'   the specified unit and `unit_angle` metadata updated accordingly.
#'
#' @details
#' If the current `unit_angle` already matches `to_unit`, an informational
#' message is shown and the data are returned unchanged (apart from the
#' metadata round-trip).
#'
#' @examples
#' \dontrun{
#' # Polar data: phi is converted automatically
#' df <- data.frame(time = 1:3, rho = 1:3, phi = c(0, pi / 2, pi))
#' anif <- as_anipoint(df)
#' anif_deg <- set_unit_angle(anif, to_unit = "deg")
#'
#' # Custom angular columns alongside the spatial ones
#' anif2 <- set_unit_angle(anif, to_unit = "deg", cols = "heading")
#' }
#'
#' @export
set_unit_angle <- function(data, to_unit, cols = NULL) {
  ensure_is_anipoint(data)

  if (!to_unit %in% levels(list_default_metadata()[["unit_angle"]])) {
    cli::cli_abort(
      "Angular unit can only be {levels(list_default_metadata()[[\"unit_angle\"]])}, not {to_unit}."
    )
  }

  if (!is.null(cols)) {
    if (!all(cols %in% names(data))) {
      cli::cli_abort("All provided columns must be in the data.")
    }
    if (!all(vapply(data[, cols, drop = FALSE], is.numeric, logical(1)))) {
      cli::cli_abort("All provided columns must be numeric.")
    }
  }

  # Auto-include spatial angular columns whenever present (#21).
  spatial_angular <- intersect(c("phi", "theta"), names(data))
  cols_to_convert <- unique(c(spatial_angular, cols))

  current_unit_angle <- get_metadata(data, "unit_angle")
  if (identical(as.character(current_unit_angle), to_unit)) {
    cli::cli_alert_info("Angular unit is already {to_unit}.")
  } else if (length(cols_to_convert) > 0) {
    converter <- if (to_unit == "deg") rad_to_deg else deg_to_rad
    data <- dplyr::mutate(
      data,
      dplyr::across(
        .cols = dplyr::any_of(cols_to_convert),
        .fns = ~ converter(.x)
      )
    )
  }

  data <- set_metadata(data, unit_angle = to_unit)

  data
}
