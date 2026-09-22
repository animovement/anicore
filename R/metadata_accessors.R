# Getters for the fields that already have setters (#121)
#
# Every field with a dedicated setter should have a dedicated getter. Six
# did not, and they are the ones downstream reaches for by name -- which
# means downstream has to know the field names, and would have to be
# updated again when the metadata is restructured (#118).
#
# These all read through `get_metadata()`, which is the single place that
# knows the storage layout, so a restructure is invisible to them.

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
    # An anievent carries no `space` category, so the unit is not
    # applicable rather than unset (#73, #118).
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
