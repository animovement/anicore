#' Convert the angular unit of an anipoint
#'
#' @description
#' Converts angular columns between radians and degrees and records the new
#' `unit_angle`. The spatial angular columns `phi` and `theta` and a declared
#' `yaw` are always converted; other angular columns are named in `cols`.
#'
#' To declare a unit without changing values, use
#' `set_metadata(data, unit_angle = "deg")`.
#'
#' @param data An anipoint, or an anijoint, whose `angle` is converted.
#' @param to_unit `"rad"` or `"deg"`.
#' @param cols Further numeric angular columns to convert.
#'
#' @return `data`, converted, with `unit_angle` updated.
#'
#' @examples
#' df <- data.frame(time = 1:3, rho = 1:3, phi = c(0, pi / 2, pi))
#' convert_unit_angle(as_anipoint(df), "deg")
#'
#' @export
convert_unit_angle <- function(data, to_unit, cols = NULL) {
  if (!is_anijoint(data)) {
    ensure_is_anipoint(data)
  }

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

  # Spatial angular columns and yaw are always converted (#21, #46).
  cols_to_convert <- if (is_anijoint(data)) {
    unique(c(get_variables(data, "where", "angle"), cols))
  } else {
    yaw <- get_variables(data, "where", "orientation")["yaw"]
    unique(c(
      intersect(c("phi", "theta"), names(data)),
      unname(yaw[!is.na(yaw)]),
      cols
    ))
  }

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
