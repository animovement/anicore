#' Create a new anipoint object (internal constructor)
#'
#' @param x A data frame to convert to anipoint
#' @return An anipoint object
#' @keywords internal
new_anipoint <- function(x) {
  class(x) <- unique(c("anipoint", "aniframe", class(x)))
  x
}
