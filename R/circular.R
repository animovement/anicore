# Circular descriptive statistics, kept here to avoid a dependency.

#' Circular median
#'
#' Fisher's circular median: the direction minimising the summed angular
#' distance to every observation. Where two directions tie, their mean
#' direction is returned.
#'
#' @param x A numeric vector of angles, in radians.
#' @param na_rm A logical value (default `TRUE`) determining whether missing
#'   values are removed before computing. When `FALSE`, any `NA` gives `NA`.
#' @return A single angle in `[0, 2*pi)`, or `NA_real_` when there is nothing to
#'   summarise.
#' @examples
#' circ_median(c(0.1, 0.2, 6.2))
#'
#' # unaffected by where the circle is cut
#' circ_median(c(0.1, 0.2, 6.2) + pi)
#'
#' @family circular statistics
#' @export
circ_median <- function(x, na_rm = TRUE) {
  x <- circ_drop_na(x, na_rm)
  if (!length(x) || anyNA(x)) {
    return(NA_real_)
  }

  x <- wrap_angle(x)

  # The minimiser is an observation or its antipode, so the search is exact.
  candidates <- wrap_angle(c(x, x + pi))
  distance <- vapply(
    candidates,
    function(theta) sum(pi - abs(pi - abs(x - theta))),
    numeric(1)
  )

  circ_mean(candidates[distance <= min(distance) + .Machine$double.eps^0.5])
}


#' Circular mean
#'
#' The mean direction: the angle of the vector sum of the unit vectors pointing
#' along each observation.
#'
#' @inheritParams circ_median
#' @return A single angle in `[0, 2*pi)`, or `NA_real_` when there is nothing to
#'   summarise.
#' @examples
#' # 10 degrees; an arithmetic mean would say 190
#' rad_to_deg(circ_mean(deg_to_rad(c(350, 30))))
#'
#' @family circular statistics
#' @export
circ_mean <- function(x, na_rm = TRUE) {
  x <- circ_drop_na(x, na_rm)
  if (!length(x) || anyNA(x)) {
    return(NA_real_)
  }

  wrap_angle(atan2(mean(sin(x)), mean(cos(x))))
}


#' Circular standard deviation
#'
#' Computed from the mean resultant length as `sqrt(-2 * log(R))`, so it grows
#' without bound as the angles spread out rather than saturating at `pi`.
#'
#' @inheritParams circ_median
#' @return A single non-negative number in radians, `0` when every angle is the
#'   same, or `NA_real_` when there is nothing to summarise.
#' @examples
#' circ_sd(c(0.1, 0.2, 0.15))
#'
#' # identical angles have no spread
#' circ_sd(rep(1.3, 5))
#'
#' @family circular statistics
#' @export
circ_sd <- function(x, na_rm = TRUE) {
  x <- circ_drop_na(x, na_rm)
  if (!length(x) || anyNA(x)) {
    return(NA_real_)
  }

  # Clamp: floating point can put R a hair above 1, making the root NaN.
  resultant <- min(sqrt(mean(cos(x))^2 + mean(sin(x))^2), 1)
  sqrt(max(-2 * log(resultant), 0))
}


#' Circular median absolute deviation
#'
#' The median of the angular distances from the circular median.
#'
#' @inheritParams circ_median
#' @return A single non-negative number in radians, or `NA_real_` when there is
#'   nothing to summarise.
#' @examples
#' circ_mad(c(0.1, 0.2, 6.2))
#'
#' @family circular statistics
#' @export
circ_mad <- function(x, na_rm = TRUE) {
  x <- circ_drop_na(x, na_rm)
  if (!length(x) || anyNA(x)) {
    return(NA_real_)
  }

  stats::median(abs(circ_difference(circ_median(x), x)))
}


#' @noRd
circ_drop_na <- function(x, na_rm) {
  if (isTRUE(na_rm)) x[!is.na(x)] else x
}


#' Shortest signed distance between two angles
#'
#' The difference `to_angle - from_angle`, wrapped to `(-pi, pi]` so that it is
#' the shorter way round the circle rather than the arithmetic difference. This
#' is the primitive the circular summaries are built on.
#'
#' @param from_angle A numeric vector of angles, in radians.
#' @param to_angle A numeric vector of angles, in radians.
#' @return Numeric vector of signed angular differences in `(-pi, pi]`, positive
#'   anticlockwise.
#' @examples
#' # a tenth of a turn, not nine tenths
#' circ_difference(0.1, 6.1)
#'
#' circ_difference(c(0, pi / 2), c(pi / 2, 0))
#'
#' @family circular statistics
#' @export
circ_difference <- function(from_angle, to_angle) {
  wrap_angle(to_angle - from_angle, modulo = "pi")
}


#' Differences between successive angles in a series
#'
#' Applies [circ_difference()] along a vector, comparing each angle with the one
#' `lag` positions before it — the turn from one heading to the next, rather
#' than the difference between two angles you name. Unlike [base::diff()] the
#' result is the same length as `x`, padded with `NA` at the start, so it can be
#' used inside [dplyr::mutate()].
#'
#' @param x A numeric vector of angles, in radians.
#' @param lag A positive integer (default `1L`) giving the lag to difference at.
#' @return A numeric vector the same length as `x`, in radians. The first `lag`
#'   entries are `NA`; the rest are angular differences in `(-pi, pi]`.
#' @examples
#' circ_successive_difference(c(0, pi / 2, pi, 3 * pi / 2))
#'
#' # crossing zero is a small step, not a large one
#' circ_successive_difference(c(6.2, 0.1))
#'
#' @family circular statistics
#' @export
circ_successive_difference <- function(x, lag = 1L) {
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be a numeric vector of angles, in radians.")
  }
  if (!rlang::is_scalar_integerish(lag) || lag < 1L) {
    cli::cli_abort("{.arg lag} must be a single positive integer.")
  }

  if (length(x) <= lag) {
    return(numeric(0))
  }

  n <- length(x)
  c(
    rep(NA_real_, lag),
    circ_difference(x[seq_len(n - lag)], x[(lag + 1):n])
  )
}
