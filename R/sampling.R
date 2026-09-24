# Sampling interval and regularity (#114)
#
# Nothing in the stack knew whether a frame was regularly sampled, or at
# what interval. `sampling_rate` is set by hand, so it is often absent and
# never checked against the data. That matters because several downstream
# functions behave differently depending on the answer -- interpolating on
# row position rather than on time is only correct when sampling is
# regular -- and none of them could ask.
#
# The interval is derived from the index, which #109 made explicit, so
# there is now a well-defined column to derive it *from*.
#
# Only the interval is stored. Regularity is computed on demand, because a
# stored logical goes stale the moment somebody filters rows out, and
# because the tolerance that decides it belongs to the caller rather than
# to the frame.

#' The gaps between consecutive index values, within each key
#'
#' Diffed per key -- identity plus temporal context -- because the index
#' restarts in each group. A frame that is perfectly regular within every
#' track looks wildly irregular pooled.
#'
#' @param data An anipoint object.
#'
#' @return Numeric vector of gaps, empty when there are none to take.
#' @keywords internal
compute_sampling_gaps <- function(data) {
  md <- get_metadata(data)
  index <- resolve_index(md)
  if (!index %in% names(data)) {
    return(numeric())
  }

  bare <- dplyr::as_tibble(data)
  # The index is required to be numeric, but this runs during construction --
  # before that is checked, and on frames a reader may hand over empty or
  # untyped. Deriving an interval is not worth aborting a constructor over.
  if (!is.numeric(bare[[index]])) {
    return(numeric())
  }
  key <- intersect(c(md$variables_what, md$variables_when), names(bare))
  values <- if (length(key) == 0L) {
    list(bare[[index]])
  } else {
    split(bare[[index]], bare[key], drop = TRUE)
  }

  gaps <- unlist(lapply(values, function(v) diff(sort(v))), use.names = FALSE)
  gaps[is.finite(gaps)]
}


#' Derive the sampling interval from the index
#'
#' The median gap, which is unmoved by a few dropped frames in a way the
#' mean is not.
#'
#' @param data An anipoint object.
#'
#' @return Numeric scalar, or `NA` when the frame has no gaps to measure.
#' @keywords internal
compute_sampling_interval <- function(data) {
  gaps <- compute_sampling_gaps(data)
  if (length(gaps) == 0L) {
    return(as.numeric(NA))
  }
  # `median()` of an odd-length integer vector returns an integer, which
  # the metadata type check rejects against a numeric field.
  as.numeric(stats::median(gaps))
}


#' The interval between consecutive observations
#'
#' Derived from the index at construction rather than declared, in the unit
#' the index is in -- so a frame indexed by frame number has an interval in
#' frames, and one indexed by seconds has it in seconds.
#'
#' Measured per key: identity plus temporal context. The index restarts in
#' each group, so pooling them would measure the restarts rather than the
#' sampling.
#'
#' @param data An anipoint object.
#'
#' Refreshed whenever the frame is re-declared, so like
#' `coordinate_system` it can lag raw dplyr edits. [is_sampling_regular()]
#' reads the data directly and is always current.
#'
#' @return Numeric scalar, or `NA` when the frame is too short to measure.
#'
#' @examples
#' af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
#' get_sampling_interval(af)
#'
#' @seealso [is_sampling_regular()], [get_sampling_rate()]
#' @export
get_sampling_interval <- function(data) {
  ensure_is_aniframe(data)
  interval <- get_metadata(data, "sampling_interval")
  if (is.null(interval)) {
    return(as.numeric(NA))
  }
  as.numeric(interval)
}


#' Is the frame regularly sampled?
#'
#' Every gap between consecutive observations equal, within `tolerance`.
#' Computed from the data each time it is asked rather than recorded,
#' because dropping rows changes the answer and a stored logical would go
#' on claiming the old one.
#'
#' @param data An anipoint object.
#' @param tolerance Relative tolerance: a gap counts as equal to the
#'   interval when it differs by no more than `tolerance * interval`.
#'   Timestamps are rarely exactly equal, so comparing them with `==` says
#'   "irregular" for data that is regular to any precision that matters.
#'   Raise it for noisy timestamps, lower it to be strict.
#'
#' @return `TRUE`, `FALSE`, or `NA` when the frame is too short to tell.
#'
#' @examples
#' af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
#' is_sampling_regular(af)
#'
#' # A gap in the recording
#' irregular <- af |> dplyr::filter(time != 3)
#' is_sampling_regular(irregular)
#'
#' @seealso [get_sampling_interval()]
#' @export
is_sampling_regular <- function(data, tolerance = 1e-6) {
  ensure_is_aniframe(data)
  if (!is.numeric(tolerance) || length(tolerance) != 1L || is.na(tolerance)) {
    cli::cli_abort("{.arg tolerance} must be a single number.")
  }

  gaps <- compute_sampling_gaps(data)
  if (length(gaps) == 0L) {
    return(NA)
  }

  interval <- stats::median(gaps)
  if (!is.finite(interval) || interval == 0) {
    return(NA)
  }
  all(abs(gaps - interval) <= tolerance * abs(interval))
}


#' Warn when a declared sampling rate disagrees with the index
#'
#' A frame declaring 50 Hz whose timestamps say otherwise is worth
#' knowing about: it is the same shape as #98, where the metadata claimed
#' a unit the data was not in. Only checkable when the index is in a real
#' time unit -- on a frame-indexed recording the rate is the conversion
#' rather than a claim the gaps can contradict.
#'
#' @param data An anipoint object.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_sampling_rate_mismatch <- function(data) {
  if (isTRUE(getOption("aniframe.quiet", FALSE))) {
    return(invisible(TRUE))
  }

  md <- get_metadata(data)
  rate <- md$sampling_rate
  interval <- get_sampling_interval(data)
  unit <- as.character(md$unit_time)

  if (
    is.null(rate) ||
      length(rate) != 1L ||
      is.na(rate) ||
      rate <= 0 ||
      is.na(interval) ||
      identical(unit, "frame") ||
      identical(unit, "unknown")
  ) {
    return(invisible(TRUE))
  }

  observed <- interval * compute_seconds_per_time_unit(unit, rate)
  expected <- 1 / rate
  if (!is.na(observed) && abs(observed - expected) > 1e-6 * expected) {
    cli::cli_warn(c(
      "{.field sampling_rate} says {.val {rate}} Hz, but the index is spaced {.val {signif(1 / observed, 4)}} Hz.",
      "i" = "The interval is derived from the data; the rate is declared.",
      "i" = "Read the measured spacing with {.fn get_sampling_interval}."
    ))
  }

  invisible(TRUE)
}
