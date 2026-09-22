#' Check if object is an anipoint
#'
#' An anipoint is the position-grain frame: one row per point per
#' timepoint, with coordinate columns. Use [is_aniframe()] to test for
#' the whole animovement frame family instead.
#'
#' @param x An object to test
#' @return Logical: TRUE if x inherits from anipoint
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_anipoint(af)
#'
#' # A plain data frame is not one
#' is_anipoint(data.frame(x = 1))
#' @export
is_anipoint <- function(x) {
  inherits(x, "anipoint")
}

#' Ensure object is an anipoint
#'
#' @param x An object to test
#' @return Error if not an anipoint
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently, and errors otherwise
#' ensure_is_anipoint(af)
#'
#' try(ensure_is_anipoint(data.frame(x = 1)))
#' @export
ensure_is_anipoint <- function(x) {
  if (!is_anipoint(x)) {
    cli::cli_abort("Data is not an anipoint.")
  }
}
