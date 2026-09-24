#' Convert the time unit of an anipoint or anievent
#'
#' @description
#' Rescales the temporal columns — the index of an anipoint, `start` and
#' `stop` of an anievent — and records the new `unit_time`. Between SI units
#' the factor is derived; from `"frame"` it is derived from the declared
#' `sampling_rate`.
#'
#' To declare a unit without changing values, use
#' `set_metadata(data, unit_time = "s")`.
#'
#' @param data An anipoint or anievent.
#' @param to_unit Target unit, one of the levels of `unit_time` in
#'   [list_default_metadata()].
#' @param calibration_factor Multiplier from the current unit to `to_unit`.
#'   Required when converting from `"frame"` without a `sampling_rate`, or
#'   from `"unknown"`.
#'
#' @return `data`, rescaled, with `unit_time` updated.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_metadata(af, sampling_rate = 30)
#' convert_unit_time(af, "s")
#'
#' @export
convert_unit_time <- function(data, to_unit, calibration_factor = NULL) {
  UseMethod("convert_unit_time")
}

#' @rdname convert_unit_time
#' @export
convert_unit_time.anipoint <- function(
  data,
  to_unit,
  calibration_factor = NULL
) {
  factor <- resolve_unit_time_calibration(data, to_unit, calibration_factor)

  index <- get_index(data)

  data <- data |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(index), function(x) x * factor)
    ) |>
    set_metadata(unit_time = to_unit)
  data
}

#' @rdname convert_unit_time
#' @export
convert_unit_time.anisegment <- convert_unit_time.anipoint

#' @rdname convert_unit_time
#' @export
convert_unit_time.anievent <- function(
  data,
  to_unit,
  calibration_factor = NULL
) {
  factor <- resolve_unit_time_calibration(data, to_unit, calibration_factor)

  data <- data |>
    dplyr::mutate(
      start = .data$start * factor,
      stop = .data$stop * factor
    ) |>
    as_anievent() |>
    set_metadata(unit_time = to_unit)
  data
}

#' The multiplier for a unit_time conversion
#'
#' @keywords internal
resolve_unit_time_calibration <- function(data, to_unit, calibration_factor) {
  permitted <- levels(list_default_metadata()[["unit_time"]])
  if (!to_unit %in% setdiff(permitted, c("frame", "unknown"))) {
    cli::cli_abort(
      "Time can only be converted to {.val {setdiff(permitted, c('frame', 'unknown'))}}, not {.val {to_unit}}."
    )
  }
  if (!is.null(calibration_factor)) {
    return(calibration_factor)
  }

  from <- as.character(get_metadata(data, "unit_time"))
  rate <- get_metadata(data, "sampling_rate")
  if (identical(from, "frame") && isTRUE(rate > 0)) {
    return(get_conversion_factor_time("s", to_unit) / rate)
  }
  if (from %in% c("frame", "unknown")) {
    cli::cli_abort(c(
      "Cannot convert from {.val {from}} without a {.arg calibration_factor}.",
      "i" = "Declare the frame rate with {.code set_metadata(data, sampling_rate = )}, or pass {.arg calibration_factor}."
    ))
  }
  get_conversion_factor_time(from_unit = from, to_unit = to_unit)
}

#' @keywords internal
get_conversion_factor_time <- function(from_unit, to_unit) {
  compute_seconds_per_time_unit(from_unit, NULL) /
    compute_seconds_per_time_unit(to_unit, NULL)
}
