# Getters for fields that have dedicated setters (#121).

#' The sampling rate, in Hz
#'
#' @param data An aniframe or anievent object.
#'
#' @return Numeric scalar, or `NA` when the rate is not recorded.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_sampling_rate(af)
#'
#' @seealso [set_sampling_rate()]
#' @export
get_sampling_rate <- function(data) {
  ensure_is_aniframe(data)
  get_metadata(data, "sampling_rate")
}


#' The unit the spatial coordinates are in
#'
#' @param data An aniframe or anievent object.
#'
#' @return Length-one character vector.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_unit_space(af)
#'
#' @seealso [set_unit_space()]
#' @export
get_unit_space <- function(data) {
  ensure_is_aniframe(data)
  value <- get_metadata(data, "unit_space")
  if (is.null(value)) {
    # An anievent has no `space` category (#73).
    return(NA_character_)
  }
  as.character(value)
}


#' The unit the index or bout boundaries are in
#'
#' @param data An aniframe or anievent object.
#'
#' @return Length-one character vector.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_unit_time(af)
#'
#' @seealso [set_unit_time()]
#' @export
get_unit_time <- function(data) {
  ensure_is_aniframe(data)
  as.character(get_metadata(data, "unit_time"))
}


#' The unit the angular axes are in
#'
#' @param data An aniframe or anievent object.
#'
#' @return Length-one character vector.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_unit_angle(af)
#'
#' @seealso [set_unit_angle()]
#' @export
get_unit_angle <- function(data) {
  ensure_is_aniframe(data)
  value <- get_metadata(data, "unit_angle")
  if (is.null(value)) {
    return(NA_character_)
  }
  as.character(value)
}
