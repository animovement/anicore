# Unlike other variable roles, declaring events doesn't restructure (#82).

#' Declare the event columns and validate them against the frame
#'
#' @param data An anipoint object.
#' @param state,point Character vectors of column names, or `NULL`.
#'
#' @return `data`, with the declaration recorded.
#' @keywords internal
declare_variables_event <- function(data, state, point) {
  ensure_can_declare_events(data)

  # `NULL` leaves a side alone; clearing it requires an explicit `character()`.
  current <- normalise_variables_event(md_event(get_metadata(data)))
  if (is.null(state)) {
    state <- current$state
  }
  if (is.null(point)) {
    point <- current$point
  }

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


#' Ensure the object can carry an event declaration (only an anipoint can)
#'
#' @param data Object to test.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_can_declare_events <- function(data) {
  if (is_anievent(data)) {
    cli::cli_abort(c(
      "{.field variables_event} declares per-frame event columns, which an {.cls anievent} does not have.",
      "i" = "An anievent is already the encoded form: its events live in {.field channel} and {.field label}."
    ))
  }

  ensure_is_anipoint(data)
  invisible(TRUE)
}
