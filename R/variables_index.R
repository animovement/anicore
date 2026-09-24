#' The column an anipoint is indexed by
#'
#' Exactly one column, of any name, holding the position of each row within
#' its temporal context: the `when$index` slot. It is never a grouping column.
#' An [anievent()] has none, since a bout spans the `start`/`stop` interval.
#'
#' @param data An anipoint object.
#'
#' @return Length-one character vector naming the index column.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_index(af)
#'
#' @seealso [set_index()] to change it, [get_variables()] for the other
#'   temporal columns.
#' @export
get_index <- function(data) {
  if (is_anievent(data)) {
    cli::cli_abort(c(
      "An {.cls anievent} has no index column.",
      "i" = "A bout spans an interval, delimited by {.field start} and {.field stop}.",
      "i" = "Read them with {.code get_variables(data, \"when\", \"interval\")}."
    ))
  }
  ensure_is_aniframe(data)
  resolve_index(get_metadata(data))
}


#' Resolve the index from a metadata list
#'
#' Missing (pre-#109 objects) or `NA` (anievent) falls back to `"time"`.
#'
#' @param md A metadata list.
#'
#' @return Length-one character vector.
#' @keywords internal
resolve_index <- function(md) {
  idx <- if (is_nested_metadata(md)) {
    md[["variables"]][["when"]][["index"]]
  } else {
    md[["variables_index"]]
  }
  if (is.null(idx) || length(idx) != 1L || is.na(idx)) {
    return("time")
  }
  as.character(idx)
}


#' Declare which column an anipoint is indexed by
#'
#' Shorthand for `set_variables(data, when = list(index = column))`. The
#' frame is re-sorted. A column that was a `when` key stops being one; the
#' previous index becomes an undeclared column rather than a key.
#'
#' @param data An anipoint object.
#' @param column Length-one character vector naming the index column. It
#'   must exist in `data` and be numeric.
#'
#' @return `data`, re-indexed and restructured.
#'
#' @examples
#' df <- data.frame(frame = 1:3, individual = "a", x = c(1, 2, 3), y = c(0, 1, 0))
#' af <- as_anipoint(df, index = "frame")
#' get_index(af)
#'
#' @seealso [get_index()]
#' @export
set_index <- function(data, column) {
  ensure_is_anipoint(data)
  ensure_valid_index(data, column)

  # The old index is not promoted to a key (one group per row).
  set_variables(data, when = list(index = column))
}


#' Ensure a declared index names exactly one column
#'
#' Otherwise [resolve_index()] would silently answer `"time"`.
#'
#' @param index The proposed index.
#' @param arg Name of the caller's argument, for the message.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_index_name <- function(index, arg = "index") {
  if (!is.character(index) || length(index) != 1L || is.na(index)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be a single column name.",
      "i" = "A frame has exactly one index."
    ))
  }
  invisible(TRUE)
}


#' Ensure a proposed index is usable
#'
#' @param data An anipoint object.
#' @param column The proposed index column.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_index <- function(data, column) {
  ensure_index_name(column, arg = "column")
  if (!column %in% names(data)) {
    cli::cli_abort(
      "Column {.val {column}} is not present in the data."
    )
  }
  if (!is.numeric(data[[column]])) {
    cli::cli_abort(
      "Index column {.val {column}} must be numeric, not {.cls {class(data[[column]])}}."
    )
  }
  invisible(TRUE)
}
