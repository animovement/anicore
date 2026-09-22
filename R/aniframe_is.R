#' Check if object is an aniframe
#'
#' `aniframe` is the abstract parent of every animovement frame class, so
#' this tests for the whole family: an [anipoint][is_anipoint()], an
#' [anievent][is_anievent()], and any subclass built on them all pass.
#' Use [is_anipoint()] to test for the position grain specifically.
#'
#' @param x An object to test
#' @return Logical: TRUE if x inherits from aniframe
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' is_aniframe(af)
#'
#' # A plain data frame is not one
#' is_aniframe(data.frame(x = 1))
#' @export
is_aniframe <- function(x) {
  inherits(x, "aniframe")
}

#' Ensure object is an aniframe
#'
#' Guard form of [is_aniframe()], passed by any animovement frame class.
#' Functions that need coordinates should guard with
#' [ensure_is_anipoint()] instead.
#'
#' @param x An object to test
#' @return Error if not an aniframe
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' # Passes silently, and errors otherwise
#' ensure_is_aniframe(af)
#'
#' try(ensure_is_aniframe(data.frame(x = 1)))
#' @export
ensure_is_aniframe <- function(x) {
  if (!is_aniframe(x)) {
    cli::cli_abort("Data is not an aniframe.")
  }
}
