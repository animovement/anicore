# Unlike other variable roles, declaring events doesn't restructure (#82).

#' Declare the event columns and validate them against the frame
#'
#' @param data An anipoint object.
#' @param state,point Character vectors of column names.
#'
#' @return `data`, with the declaration recorded.
#' @keywords internal
declare_variables_event <- function(data, state, point) {
  declared <- normalise_variables_event(list(state = state, point = point))
  ensure_valid_variables_event(declared)
  ensure_has_declared_cols(
    data,
    c(declared$state, declared$point),
    "event"
  )

  md <- get_metadata(data)
  md$variables$event <- declared

  write_metadata(data, md)
}
