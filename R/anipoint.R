#' Create an anipoint data frame
#'
#' Creates a specialized data frame for movement data with columns defining
#' entity identity, timepoints, and spatial position.
#'
#' @param ... Name-value pairs to create columns in the data frame.
#' @param metadata Optional list of metadata.
#' @inheritParams as_anipoint
#' @param .rows Number of rows (passed to tibble).
#' @param .name_repair How to repair column names (passed to tibble).
#'
#' @return An anipoint object (tibble with anipoint class).
#' @export
#'
#' @examples
#' anipoint(
#'   individual = rep(1:2, each = 25),
#'   time = rep(1:10, 5),
#'   x = rnorm(50),
#'   y = rnorm(50)
#' )
#'
#' # Custom variables
#' anipoint(
#'   track = rep(1:3, each = 10),
#'   trial = 1,
#'   time = rep(1:10, 3),
#'   x = rnorm(30),
#'   y = rnorm(30),
#'   variables_what = "track",
#'   variables_when = "trial"
#' )
#'
#' # Indexed by a column that isn't called `time`
#' anipoint(
#'   individual = 1L,
#'   frame = 1:10,
#'   x = rnorm(10),
#'   y = rnorm(10),
#'   index = "frame"
#' )
anipoint <- function(
  ...,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  variables_where = NULL,
  index = NULL,
  .rows = NULL,
  .name_repair = c("check_unique", "unique", "universal", "minimal")
) {
  dots <- rlang::list2(...)

  # Check if a single data frame was passed
  if (length(dots) == 1 && is.data.frame(dots[[1]])) {
    x <- dots[[1]]
  } else {
    x <- dplyr::tibble(..., .rows = .rows, .name_repair = .name_repair)
  }

  as_anipoint(
    x,
    metadata = metadata,
    variables_what = variables_what,
    variables_when = variables_when,
    variables_where = variables_where,
    index = index
  )
}
