# Constructor for the anipoint class

#' Create a new anipoint object (internal constructor)
#'
#' Lays down the class vector `c("anipoint", "aniframe", ...)`: `anipoint`
#' is the position-grain frame, `aniframe` the abstract parent shared by
#' every animovement frame class.
#'
#' @param x A data frame to convert to anipoint
#' @return An anipoint object
#' @keywords internal
new_anipoint <- function(x) {
  class(x) <- unique(c("anipoint", "aniframe", class(x)))
  x
}
