#' Set the temporal unit of an anipoint or anievent
#'
#' @description
#' Converts the temporal columns of an `anipoint` (its index column) or
#' `anievent` (the `start` and `stop` columns) to a different unit of
#' measurement. Handles automatic conversion between standard SI time
#' units and custom calibration from frame or arbitrary units.
#'
#' @param data An [anipoint()] or [anievent()] object.
#' @param to_unit Character string specifying the target time unit. Must be
#'   one of the permitted units defined in `list_default_metadata()$unit_time`
#'   (typically `"ms"`, `"s"`, `"m"`, `"h"`).
#' @param calibration_factor Numeric value for scaling time values.
#'   Default is 1. When converting from standard time units (`ms`, `s`,
#'   `m`, `h`), this is ignored and the appropriate conversion factor is
#'   calculated automatically. When converting from `"frame"` or
#'   `"unknown"` units, you must provide a calibration factor to define
#'   the relationship between the current and target units.
#'
#' @return The input object with temporal columns converted to `to_unit`
#'   and `unit_time` metadata updated accordingly.
#'
#' @details
#' For an `anipoint` the column [get_index()] names is multiplied by the
#' calibration factor; for an `anievent` both `start` and `stop` are. In
#' either case:
#' * the function validates `to_unit` against the permitted levels;
#' * if converting from a standard unit (`ms`, `s`, `m`, `h`) to another
#'   standard unit, the calibration factor is auto-computed;
#' * if converting from `"frame"` or `"unknown"` with
#'   `calibration_factor = 1`, an informational message is emitted and the
#'   data values are left unchanged (the metadata still flips to `to_unit`);
#' * the object's `unit_time` metadata is updated.
#'
#' @examples
#' \dontrun{
#' # anipoint: convert milliseconds to seconds (automatic)
#' data_s <- set_unit_time(data, to_unit = "s")
#'
#' # anipoint: convert frames to seconds at 30 fps
#' data_s <- set_unit_time(data, to_unit = "s", calibration_factor = 1 / 30)
#'
#' # anievent: same call shape; mutates start/stop instead of the index
#' ae_s <- set_unit_time(ae, to_unit = "s", calibration_factor = 1 / 30)
#' }
#'
#' @export
set_unit_time <- function(data, to_unit, calibration_factor = 1) {
  UseMethod("set_unit_time")
}

#' @rdname set_unit_time
#' @export
set_unit_time.anipoint <- function(data, to_unit, calibration_factor = 1) {
  factor <- resolve_unit_time_calibration(data, to_unit, calibration_factor)

  index <- get_index(data)

  data <- data |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(index), function(x) x * factor)
    ) |>
    set_metadata(unit_time = to_unit)
  data
}

#' @rdname set_unit_time
#' @export
set_unit_time.anievent <- function(data, to_unit, calibration_factor = 1) {
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

#' Resolve the multiplicative factor for a unit_time conversion
#'
#' Returns 1 (values unchanged) when converting from `"frame"` or
#' `"unknown"` without a calibration factor.
#'
#' @keywords internal
resolve_unit_time_calibration <- function(data, to_unit, calibration_factor) {
  if (!to_unit %in% levels(list_default_metadata()[["unit_time"]])) {
    cli::cli_abort(
      "Time unit can only be {levels(list_default_metadata()[[\"unit_time\"]])}, not {to_unit}."
    )
  }

  current_unit_time <- get_metadata(data, "unit_time")

  if (calibration_factor == 1 && current_unit_time %in% c("frame", "unknown")) {
    cli::cli_alert_info(
      "calibration_factor is not set, data remains unchanged."
    )
  } else if (calibration_factor == 1) {
    calibration_factor <- get_conversion_factor_time(
      from_unit = as.character(current_unit_time),
      to_unit = to_unit
    )
  }

  calibration_factor
}

#' Set the sampling rate of an anipoint or anievent
#'
#' @description
#' Sets the sampling rate (in Hz) on an [anipoint()] or [anievent()] and,
#' if the object's `unit_time` is currently `"frame"` or `"unknown"`,
#' converts the temporal columns from frames to seconds using
#' `1 / sampling_rate`. If `unit_time` is already an SI unit, only the
#' metadata is updated.
#'
#' @param data An anipoint or anievent.
#' @param sampling_rate Numeric value in Hz (samples per second).
#'
#' @return The input object with `sampling_rate` metadata updated and,
#'   where applicable, temporal columns converted to seconds.
#'
#' @examples
#' \dontrun{
#' # anipoint in frames -> seconds at 30 fps
#' data_s <- set_sampling_rate(data, sampling_rate = 30)
#'
#' # anievent: same call shape
#' ae_s <- set_sampling_rate(ae, sampling_rate = 30)
#' }
#'
#' @export
set_sampling_rate <- function(data, sampling_rate) {
  UseMethod("set_sampling_rate")
}

#' @rdname set_sampling_rate
#' @export
set_sampling_rate.aniframe <- function(data, sampling_rate) {
  if (!get_metadata(data, "unit_time") %in% c("frame", "unknown")) {
    cli::cli_alert_info(
      "unit_time is already set to a SI unit (not {c(\"frame\", \"unknown\")}). Data remains unchanged, but sampling_rate has been changed in the metadata"
    )
  } else {
    data <- set_unit_time(data, "s", calibration_factor = 1 / sampling_rate)
  }
  set_metadata(data, sampling_rate = sampling_rate)
}

#' @keywords internal
get_conversion_factor_time <- function(from_unit, to_unit) {
  conv <- list_conversion_factors_time()
  conv[to_unit, from_unit]
}

#' @keywords internal
list_conversion_factors_time <- function() {
  m <- matrix(
    c(
      1,
      1 / 1000,
      1 / (1000 * 60),
      1 / (1000 * 60 * 60),
      1000,
      1,
      1 / 60,
      1 / (60 * 60),
      1000 * 60,
      60,
      1,
      1 / 60,
      1000 * 60 * 60,
      60 * 60,
      60,
      1
    ),
    nrow = 4,
    byrow = FALSE
  )

  permitted_units <- c("ms", "s", "m", "h")
  rownames(m) <- permitted_units
  colnames(m) <- permitted_units
  m
}
