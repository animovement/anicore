# Constructor for the anievent class

#' Create a new anievent object (internal constructor)
#'
#' Lays down the class vector `c("anievent", "aniframe", ...)`: an
#' anievent inherits the shared substrate (metadata accessors, dplyr
#' methods, printing) from the abstract `aniframe` parent.
#'
#' @param x A data frame to convert to anievent.
#' @return An anievent object.
#' @keywords internal
new_anievent <- function(x) {
  class(x) <- unique(c("anievent", "aniframe", class(x)))
  x
}
