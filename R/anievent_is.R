#' Check if object is an anievent
#'
#' @param x An object to test.
#' @return Logical: `TRUE` if `x` inherits from `anievent`.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_anievent(af)
#' @export
is_anievent <- function(x) {
  inherits(x, "anievent")
}

#' Ensure object is an anievent
#'
#' @param x An object to test.
#' @return Errors if `x` is not an anievent; otherwise returns invisibly.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' try(ensure_is_anievent(af))
#' @export
ensure_is_anievent <- function(x) {
  if (!is_anievent(x)) {
    cli::cli_abort("Data is not an anievent.")
  }
}
