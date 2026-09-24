#' Create a new anievent object (internal constructor)
#'
#' @param x A data frame to convert to anievent.
#' @return An anievent object.
#' @keywords internal
new_anievent <- function(x) {
  class(x) <- unique(c("anievent", "aniframe", class(x)))
  x
}
