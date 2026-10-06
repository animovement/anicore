#' Convert the time unit of an anipoint or anievent
#'
#' @description
#' Rescales the temporal columns — the index of an anipoint, `start` and
#' `stop` of an anievent — and records the new `unit_time`. An anipoint's
#' `sampling_interval` is measured again in the new unit; `sampling_rate`
#' is in Hz and is left as it is. Between SI units the factor is derived; to
#' and from `"frame"` it is derived from the declared `sampling_rate`.
#'
#' Frames count from 0: the first frame is at time 0, so frames are seconds
#' multiplied by the rate, and seconds are frames divided by it. Converting
#' from frames to a time unit keeps nothing extra, as frames are evenly
#' spaced and multiplying by the rate gives them back.
#'
#' Converting back to frames is also how a wrong rate is put right: convert
#' to `"frame"` with the rate the frame declares, declare the right one, and
#' convert forward again (see the examples).
#'
#' To declare a unit without changing values, use
#' `set_metadata(data, unit_time = "s")`.
#'
#' @section Converting to frames:
#' Frame numbers that a file records are data; frame numbers computed from
#' a rate are only nominal. So converting to `"frame"` uses recorded frame
#' numbers when the frame has them, and computes them only from regular
#' sampling.
#'
#' * **Recorded frame numbers.** If an anipoint has a column named
#'   `frame` that is not its index, it holds the frame numbers recorded
#'   with the data, and converting to `"frame"` makes that column the index
#'   again rather than computing frames from the rate. The column it
#'   replaces stays in the frame as an ordinary column, so the times are
#'   not lost.
#' * **Computed frame numbers.** Otherwise each time is multiplied by the
#'   rate and rounded to the nearest whole frame. Rather than invent frame
#'   numbers, the conversion refuses when the sampling is irregular, with a
#'   gap between consecutive times of the same keys more than 1% (the
#'   margin [validate_anipoint()] allows by default) from a whole number of
#'   frames, or when rounding would put two different times of the same
#'   keys on the same frame. A timestamp log, or a `sampling_rate` that does
#'   not match the data, is refused this way.
#'
#' @param data An anipoint or anievent.
#' @param to_unit Target unit, one of the levels of `unit_time` in
#'   [list_default_metadata()] other than `"unknown"`.
#' @param calibration_factor Multiplier from the current unit to `to_unit`.
#'   Required when converting to or from `"frame"` without a
#'   `sampling_rate`, or from `"unknown"`. Refused when the frame numbers
#'   are taken from a `frame` column.
#'
#' @return `data`, rescaled, with `unit_time` and, for an anipoint,
#'   `sampling_interval` updated.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' af <- set_metadata(af, sampling_rate = 30)
#' in_seconds <- convert_unit_time(af, "s")
#' in_seconds
#'
#' # The camera was really 25 fps: back to frames, then forward at 25 fps
#' in_seconds |>
#'   convert_unit_time("frame") |>
#'   set_metadata(sampling_rate = 25) |>
#'   convert_unit_time("s")
#'
#' # Times off the frame grid by a little jitter round to whole frames
#' jittered <- dplyr::mutate(in_seconds, time = time + c(1e-4, -1e-4, 0))
#' convert_unit_time(jittered, "frame")$time
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
  if (has_recorded_frames(data, to_unit)) {
    return(index_by_recorded_frames(data, calibration_factor))
  }
  factor <- resolve_unit_time_calibration(data, to_unit, calibration_factor)
  to_frames <- computes_frames(data, to_unit, calibration_factor)

  index <- get_index(data)
  if (to_frames) {
    ensure_whole_frames(
      data[[index]] * factor,
      key_group_ids(data),
      index
    )
  }
  # `mutate()` measures the interval again, in the new unit (#185, #190).
  data <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(index),
        function(x) scale_time(x, factor, to_frames)
      )
    )
  set_metadata(data, unit_time = to_unit)
}

#' @rdname convert_unit_time
#' @export
convert_unit_time.anisegment <- convert_unit_time.anipoint

#' @rdname convert_unit_time
#' @export
convert_unit_time.anijoint <- convert_unit_time.anipoint

#' @rdname convert_unit_time
#' @export
convert_unit_time.anievent <- function(
  data,
  to_unit,
  calibration_factor = NULL
) {
  factor <- resolve_unit_time_calibration(data, to_unit, calibration_factor)
  to_frames <- computes_frames(data, to_unit, calibration_factor)

  if (to_frames) {
    group <- key_group_ids(data)
    ensure_whole_frames(
      c(data$start, data$stop) * factor,
      c(group, group),
      c("start", "stop")
    )
  }
  data <- data |>
    dplyr::mutate(
      start = scale_time(.data$start, factor, to_frames),
      stop = scale_time(.data$stop, factor, to_frames)
    ) |>
    as_anievent() |>
    set_metadata(unit_time = to_unit)
  data
}

#' The multiplier for a unit_time conversion
#'
#' Through seconds, with the declared `sampling_rate` standing in for
#' `"frame"` at either end.
#'
#' @keywords internal
resolve_unit_time_calibration <- function(data, to_unit, calibration_factor) {
  permitted <- setdiff(
    levels(list_default_metadata()[["unit_time"]]),
    "unknown"
  )
  if (!to_unit %in% permitted) {
    cli::cli_abort(
      "Time can only be converted to {.val {permitted}}, not {.val {to_unit}}."
    )
  }
  if (!is.null(calibration_factor)) {
    return(calibration_factor)
  }

  from <- as.character(get_metadata(data, "unit_time"))
  if (identical(from, to_unit)) {
    return(1)
  }
  rate <- get_metadata(data, "sampling_rate")
  uses_frames <- "frame" %in% c(from, to_unit)
  if (identical(from, "unknown") || (uses_frames && !isTRUE(rate > 0))) {
    cli::cli_abort(c(
      "Cannot convert from {.val {from}} to {.val {to_unit}} without a {.arg calibration_factor}.",
      "i" = "Declare the frame rate with {.code set_metadata(data, sampling_rate = )}, or pass {.arg calibration_factor}."
    ))
  }

  factor <- get_conversion_factor_time(
    from_unit = if (identical(from, "frame")) "s" else from,
    to_unit = if (identical(to_unit, "frame")) "s" else to_unit
  )
  if (identical(from, "frame")) {
    factor <- factor / rate
  }
  if (identical(to_unit, "frame")) {
    factor <- factor * rate
  }
  factor
}


#' Does a conversion compute frame numbers?
#'
#' Converting to `"frame"` from any other unit, or rescaling frames by a
#' `calibration_factor`. Frames converted to frames are left as they are.
#'
#' @param data An anipoint or anievent.
#' @param to_unit The unit being converted to.
#' @param calibration_factor As passed to [convert_unit_time()].
#'
#' @return Logical scalar.
#' @keywords internal
computes_frames <- function(data, to_unit, calibration_factor) {
  if (!identical(to_unit, "frame")) {
    return(FALSE)
  }
  from <- as.character(get_metadata(data, "unit_time"))
  !identical(from, "frame") || !is.null(calibration_factor)
}


#' Does an anipoint carry recorded frame numbers to convert to?
#'
#' A column named `frame` that is not the index, on a frame whose index is
#' in another unit.
#'
#' @param data An anipoint.
#' @param to_unit The unit being converted to.
#'
#' @return Logical scalar.
#' @keywords internal
has_recorded_frames <- function(data, to_unit) {
  identical(to_unit, "frame") &&
    !identical(as.character(get_metadata(data, "unit_time")), "frame") &&
    "frame" %in% names(data) &&
    !identical(get_index(data), "frame")
}


#' Index an anipoint by its recorded frame numbers again
#'
#' @param data An anipoint with a `frame` column that is not its index.
#' @param calibration_factor As passed to [convert_unit_time()]; must be
#'   `NULL`, as nothing is computed.
#'
#' @return `data`, indexed by `frame`, with `unit_time = "frame"`.
#' @keywords internal
index_by_recorded_frames <- function(data, calibration_factor) {
  if (!is.null(calibration_factor)) {
    cli::cli_abort(c(
      "{.arg calibration_factor} is not used: the frame numbers recorded in {.field frame} are.",
      "i" = "To compute frames from {.field {get_index(data)}} instead, rename or drop {.field frame} first."
    ))
  }
  ensure_valid_index(data, "frame")
  # The old index stays as an ordinary column.
  data <- set_variables(data, when = list(index = "frame"))
  set_metadata(data, unit_time = "frame")
}


#' An integer naming each row's identity and temporal context
#'
#' @param data An anipoint or anievent.
#'
#' @return Integer vector, one per row.
#' @keywords internal
key_group_ids <- function(data) {
  key <- intersect(get_keys(data), names(data))
  group_ids(strip_animovement_class(data), key)
}


#' Ensure times convert to whole frames without inventing any
#'
#' Within each key, the gaps between consecutive distinct times must each
#' be a whole number of frames, to within `tolerance` of the gap, and
#' rounding must not put two different times on the same frame.
#'
#' @param frames Times multiplied by the rate, in frames.
#' @param group Integer key of each value, from [key_group_ids()].
#' @param columns The columns converted, for the message.
#' @param tolerance Relative tolerance on each gap; the margin
#'   [validate_anipoint()] allows by default.
#' @param call The caller's environment, for the error.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_whole_frames <- function(
  frames,
  group,
  columns,
  tolerance = 0.01,
  call = rlang::caller_env()
) {
  keep <- !is.na(frames)
  frames <- frames[keep]
  group <- group[keep]
  ordered <- order(group, frames, method = "radix")
  frames <- frames[ordered]
  group <- group[ordered]
  within <- group[-1L] == group[-length(group)]
  gaps <- diff(frames)[within]

  whole <- round(gaps)
  off <- abs(gaps - whole) > tolerance * pmax(whole, 1)
  if (any(off)) {
    cli::cli_abort(
      c(
        "Cannot convert {.field {columns}} to frames: the sampling is irregular.",
        "x" = "A gap of {signif(gaps[off][[1]], 3)} frames is more than {format(100 * tolerance)}% from a whole number of frames.",
        "i" = "Frame numbers are computed only from regular sampling, so none are invented. Check that {.field sampling_rate} matches the data.",
        "i" = "For times logged with the data, keep the recorded frame numbers in a column named {.field frame}, and converting to {.val frame} uses it."
      ),
      call = call
    )
  }
  merged <- diff(round(frames))[within] == 0 & gaps > 0
  if (any(merged)) {
    at <- round(frames)[-1L][within][merged][[1]]
    cli::cli_abort(
      c(
        "Cannot convert {.field {columns}} to frames: two different times of the same keys round to frame {at}.",
        "i" = "Their spacing drifts from {.field sampling_rate}, or they are less than a frame apart.",
        "i" = "For times logged with the data, keep the recorded frame numbers in a column named {.field frame}, and converting to {.val frame} uses it."
      ),
      call = call
    )
  }
  invisible(TRUE)
}


#' Scale time values, rounding computed frames to whole ones
#'
#' @param x Numeric vector.
#' @param factor Multiplier.
#' @param to_frames Whether the result is in frames, computed by
#'   [computes_frames()].
#'
#' @return `x * factor`, rounded to whole numbers when `to_frames`.
#' @keywords internal
scale_time <- function(x, factor, to_frames) {
  x <- x * factor
  if (to_frames) {
    x <- round(x)
  }
  x
}

#' @keywords internal
get_conversion_factor_time <- function(from_unit, to_unit) {
  compute_seconds_per_time_unit(from_unit, NULL) /
    compute_seconds_per_time_unit(to_unit, NULL)
}
