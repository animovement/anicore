# Sampling interval and regularity (#114). Only the interval is stored;
# regularity is computed on demand since row filtering would make it stale.

#' The gaps between consecutive index values, within each key
#'
#' Per key, because the index restarts in each group.
#'
#' @param data An anipoint object.
#'
#' @return Numeric vector of gaps, empty when there are none to take.
#' @keywords internal
compute_sampling_gaps <- function(data) {
  md <- get_metadata(data)
  measure_sampling_gaps(
    strip_animovement_class(data),
    resolve_index(md),
    c(md_what_keys(md), md_when_keys(md))
  )
}


#' The gaps between consecutive index values of a bare frame
#'
#' Sorts once by key and index and drops the gaps that cross from one key to
#' the next, rather than splitting the frame, so it is cheap enough to run
#' after every verb that changes rows.
#'
#' @param bare A data frame without the animovement classes.
#' @param index Name of the index column.
#' @param key Names of the identity and temporal key columns.
#'
#' @return Numeric vector of gaps, empty when there are none to take.
#' @keywords internal
measure_sampling_gaps <- function(bare, index, key) {
  if (!index %in% names(bare)) {
    return(numeric())
  }
  values <- .subset2(bare, index)
  # Runs during construction, before the index type is checked; don't abort.
  if (!is.numeric(values)) {
    return(numeric())
  }
  key <- intersect(key, names(bare))
  if (length(key) == 0L) {
    gaps <- diff(sort(values))
  } else {
    group <- group_ids(bare, key)
    ordered <- order(group, values, method = "radix")
    group <- group[ordered]
    within <- group[-1L] == group[-length(group)]
    gaps <- diff(values[ordered])[within]
  }
  gaps[is.finite(gaps)]
}


#' An integer naming each row's key
#'
#' A frame is grouped by its key, so the group indices dplyr already holds
#' are used when they are the key's; anything else is grouped afresh.
#'
#' @param bare A data frame.
#' @param key Names of the key columns, all present.
#'
#' @return Integer vector, one per row.
#' @keywords internal
group_ids <- function(bare, key) {
  if (!setequal(dplyr::group_vars(bare), key)) {
    bare <- dplyr::group_by(
      dplyr::ungroup(bare),
      dplyr::across(dplyr::all_of(key))
    )
  }
  dplyr::group_indices(bare)
}


#' Derive the sampling interval from the index
#'
#' The median gap, robust to a few dropped frames.
#'
#' @param gaps Numeric vector of gaps, from [measure_sampling_gaps()].
#'
#' @return Numeric scalar, or `NA` when there are no gaps to measure.
#' @keywords internal
compute_sampling_interval <- function(gaps) {
  if (length(gaps) == 0L) {
    return(as.numeric(NA))
  }
  # `median()` can return integer, which the metadata type check rejects.
  as.numeric(stats::median(gaps))
}


#' Keep the stored sampling interval in step with the index
#'
#' Run by every verb that rebuilds a frame. The interval is measured again
#' when the rows or the index have changed, and kept when they have not, so a
#' `mutate()` that leaves the index alone costs nothing.
#'
#' @param md Metadata for the result, in the category layout.
#' @param x The result.
#' @param before The frame the verb was given, or `NULL` to measure always.
#'
#' @return `md`, with `sampling_interval` up to date.
#' @keywords internal
refresh_sampling_interval <- function(md, x, before = NULL) {
  index <- md_variables(md)$when$index
  # An anievent has no index, so nothing to measure.
  if (length(index) != 1L) {
    return(md)
  }
  key <- c(md_what_keys(md), md_when_keys(md))
  if (has_same_timing(x, before, c(key, index))) {
    return(md)
  }
  gaps <- measure_sampling_gaps(strip_animovement_class(x), index, key)
  md_field_set(md, "sampling_interval", compute_sampling_interval(gaps))
}


#' Do two frames have the same index and keys, row for row?
#'
#' `identical()` returns at once for a column a verb has passed through
#' untouched, as it is the same vector.
#'
#' @param x,before Data frames; `before` may be `NULL`.
#' @param cols The index and key columns.
#'
#' @return Logical scalar.
#' @keywords internal
has_same_timing <- function(x, before, cols) {
  if (is.null(before) || nrow(before) != nrow(x)) {
    return(FALSE)
  }
  all(vapply(
    cols,
    function(col) identical(.subset2(x, col), .subset2(before, col)),
    logical(1)
  ))
}


#' The interval between consecutive observations
#'
#' Derived from the index rather than declared, in the unit the index is in
#' -- so a frame indexed by frame number has an interval in frames, and one
#' indexed by seconds has it in seconds.
#'
#' Measured per key: identity plus temporal context. The index restarts in
#' each group, so pooling them would measure the restarts rather than the
#' sampling.
#'
#' Measured again whenever the rows or the index change: by
#' [dplyr::filter()], [dplyr::slice()], `[`, a [dplyr::mutate()] of the
#' index or a key, and the other dplyr verbs anicore provides methods for.
#' A frame that keeps every third row of a 30 Hz recording then reports the
#' 10 Hz spacing it now has, and [validate_anipoint()] says that its
#' `sampling_rate` no longer matches.
#'
#' @param data An anipoint object.
#'
#' @return Numeric scalar, or `NA` when the frame is too short to measure.
#'
#' @examples
#' af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)
#' get_sampling_interval(af)
#'
#' @seealso [is_sampling_regular()]
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
#' Only checkable when the index is in a real time unit, not frames. The
#' measured spacing is the median gap, so a dropped frame does not move it,
#' and the comparison is relative: a timestamp log jitters, and a camera
#' logging at 30.11 Hz is a 30 Hz camera.
#'
#' @param data An anipoint object.
#' @param tolerance Relative tolerance, a single non-negative number.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_sampling_rate_mismatch <- function(data, tolerance = 0.01) {
  if (isTRUE(getOption("aniframe.quiet", FALSE))) {
    return(invisible(TRUE))
  }

  md <- get_metadata(data)
  rate <- md_field(md, "sampling_rate")
  interval <- get_sampling_interval(data)
  unit <- as.character(md_field(md, "unit_time"))

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
  if (!is.na(observed) && abs(observed - expected) > tolerance * expected) {
    cli::cli_warn(c(
      "{.field sampling_rate} says {.val {rate}} Hz, but the index is spaced {.val {signif(1 / observed, 4)}} Hz.",
      "i" = "The interval is derived from the data; the rate is declared. They differ by more than {format(signif(100 * tolerance, 3), scientific = FALSE)}%.",
      "i" = "Read the measured spacing with {.fn get_sampling_interval}."
    ))
  }

  invisible(TRUE)
}
