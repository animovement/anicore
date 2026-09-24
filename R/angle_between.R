#' The angle between two vectors
#'
#' @description
#' Row-wise angle between direction vectors, as used for joint angles.
#'
#' * With no `axis`, the included angle `acos(u . v / |u||v|)`, in
#'   `[0, pi]`.
#' * With an `axis`, both vectors are projected onto the plane perpendicular
#'   to it, and the angle turns from `u` to `v` about the axis by the
#'   right-hand rule, in `[-pi, pi]`. For 2D vectors, `c(0, 0, 1)` gives the
#'   signed angle from `x` toward `y`.
#'
#' Vectors need not be unit length. A zero vector, or one parallel to the
#' axis, gives `NA`.
#'
#' @param u,v Numeric vectors of length 2 or 3, or matrices or data frames
#'   with 2 or 3 columns and one row per vector. A single vector is recycled.
#' @param axis `NULL`, or a vector (or one per row) of length 3.
#'
#' @return Numeric vector of angles in radians.
#'
#' @examples
#' angle_between(c(1, 0), c(0, 1))
#' angle_between(c(1, 0), c(0, 1), axis = c(0, 0, 1))
#' angle_between(c(1, 0), c(0, 1), axis = c(0, 0, -1))
#'
#' # One angle per row
#' angle_between(rbind(c(1, 0, 0), c(0, 1, 0)), c(0, 0, 1))
#' @export
angle_between <- function(u, v, axis = NULL) {
  u <- as_vector_rows(u, "u")
  v <- as_vector_rows(v, "v")
  if (ncol(u) != ncol(v)) {
    cli::cli_abort(
      "{.arg u} and {.arg v} must have the same number of dimensions."
    )
  }
  if (!is.null(axis)) {
    axis <- as_vector_rows(axis, "axis")
  }
  n <- max(nrow(u), nrow(v), nrow(axis) %||% 1L)
  u <- recycle_rows(u, n, "u")
  v <- recycle_rows(v, n, "v")

  if (is.null(axis)) {
    norms <- sqrt(rowSums(u^2) * rowSums(v^2))
    cosine <- rowSums(u * v) / norms
    angle <- acos(pmin(1, pmax(-1, cosine)))
    angle[!is.na(norms) & norms == 0] <- NA_real_
    return(angle)
  }

  if (ncol(u) == 2L) {
    u <- cbind(u, 0)
    v <- cbind(v, 0)
  }
  axis <- recycle_rows(axis, n, "axis")
  if (ncol(axis) != 3L) {
    cli::cli_abort("{.arg axis} must have 3 components.")
  }
  axis <- axis / sqrt(rowSums(axis^2))
  u <- u - rowSums(u * axis) * axis
  v <- v - rowSums(v * axis) * axis
  angle <- atan2(rowSums(cross_rows(u, v) * axis), rowSums(u * v))
  degenerate <- rowSums(u^2) < 1e-24 | rowSums(v^2) < 1e-24
  angle[!is.na(degenerate) & degenerate] <- NA_real_
  angle
}


#' @keywords internal
as_vector_rows <- function(x, arg) {
  if (is.data.frame(x)) {
    x <- as.matrix(x)
  }
  if (is.numeric(x) && is.null(dim(x))) {
    x <- matrix(x, nrow = 1L)
  }
  if (!is.matrix(x) || !is.numeric(x) || !ncol(x) %in% c(2L, 3L)) {
    cli::cli_abort(
      "{.arg {arg}} must be a numeric vector or matrix with 2 or 3 components."
    )
  }
  unname(x)
}


#' @keywords internal
recycle_rows <- function(x, n, arg) {
  if (nrow(x) == n) {
    return(x)
  }
  if (nrow(x) != 1L) {
    cli::cli_abort("{.arg {arg}} must have one row or {n}.")
  }
  x[rep(1L, n), , drop = FALSE]
}


#' @keywords internal
cross_rows <- function(a, b) {
  cbind(
    a[, 2] * b[, 3] - a[, 3] * b[, 2],
    a[, 3] * b[, 1] - a[, 1] * b[, 3],
    a[, 1] * b[, 2] - a[, 2] * b[, 1]
  )
}
