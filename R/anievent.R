#' Create an anievent data frame
#'
#' Creates a specialised data frame for behavioural events in long format:
#' one row per bout (state event) or instant (point event). Like
#' [anipoint()], the class inherits the shared `aniframe` substrate —
#' metadata, accessors, dplyr methods — but holds event-bout records
#' rather than per-frame movement data.
#'
#' Mandatory columns: `channel`, `type`, `label`, `start`, `stop`. A
#' "channel" is one mutually-exclusive categorical track of behaviour —
#' at any moment, a subject can only have one `label` active per
#' channel. `type` is `"state"` (durative, `stop > start`) or `"point"`
#' (instant, `start == stop`). Identity columns (e.g. `individual`,
#' `subject`, `track`) are optional and declared via `variables_what`.
#' A `modifiers` list-column may carry per-event modifier values — each
#' cell a character vector (matching the BORIS export format, where one
#' event can have zero or more modifier values selected from the
#' ethogram).
#'
#' @param ... Name-value pairs to create columns in the data frame.
#' @param metadata Optional list of metadata.
#' @param variables_what Character vector of identity columns that together
#'   define a unique entity. When `NULL` (default), auto-detected from a
#'   known list (`model`, `individual`, `subject`, `track`,
#'   `keypoint`).
#' @param variables_when Character vector of temporal columns. When
#'   `NULL` (default), auto-detected from a known grouping list
#'   (`observation`, `session`, `trial`) and concatenated with the
#'   required temporal endpoints `c("start", "stop")`.
#' @param .rows Number of rows (passed to tibble).
#' @param .name_repair How to repair column names (passed to tibble).
#'
#' @return An anievent object.
#' @export
#'
#' @examples
#' anievent(
#'   individual = c(1L, 1L, 1L),
#'   channel = c("behaviour", "behaviour", "call"),
#'   label = c("REM", "wake", "alarm"),
#'   start = c(3, 14, 4.5),
#'   stop = c(9, 19, 4.5)
#' )
anievent <- function(
  ...,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  .rows = NULL,
  .name_repair = c("check_unique", "unique", "universal", "minimal")
) {
  dots <- rlang::list2(...)

  if (length(dots) == 1 && is.data.frame(dots[[1]])) {
    x <- dots[[1]]
  } else {
    x <- dplyr::tibble(..., .rows = .rows, .name_repair = .name_repair)
  }

  as_anievent(
    x,
    metadata = metadata,
    variables_what = variables_what,
    variables_when = variables_when
  )
}
