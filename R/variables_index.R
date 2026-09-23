# The index is kept out of `variables_when`, which is exactly what the frame
# groups by (#109).

#' The column an anipoint is indexed by
#'
#' Exactly one column, of any name, holding the position of each row
#' within its temporal context. It is declared separately from
#' `variables_when`, which holds the context itself — session, trial,
#' observation — and which, with `variables_what`, is what the frame is
#' grouped by. The index is never a grouping variable.
#'
#' An [anievent()] has none: a bout spans an interval rather than sitting
#' at a point, so it is delimited by `start` and `stop`, which are
#' declared temporal columns. Its `variables_index` is `NA`, and asking
#' for it here is an error rather than a guess.
#'
#' @param data An anipoint object.
#'
#' @return Length-one character vector naming the index column.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_index(af)
#'
#' @seealso [set_index()] to change it, [get_variables_when()] for the
#'   full set of temporal columns.
#' @export
get_index <- function(data) {
  if (is_anievent(data)) {
    cli::cli_abort(c(
      "An {.cls anievent} has no index column.",
      "i" = "A bout spans an interval, delimited by {.field start} and {.field stop}.",
      "i" = "Read them with {.fn get_variables_when}."
    ))
  }
  ensure_is_anipoint(data)
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
#' Changing the index changes the order the rows come in, so — like the
#' `variables_*` declarations — it is not reachable through
#' [set_metadata()] and has its own setter, which does the restructuring
#' too.
#'
#' If the column was declared as temporal context it stops being so: a
#' variable cannot be both the position within a context and part of it.
#' The column the frame was previously indexed by becomes an ordinary
#' undeclared column rather than being promoted to a grouping variable —
#' which, holding one value per row, would put every row in its own
#' group.
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

  md <- get_metadata(data)
  md$variables$when$index <- column
  data <- attach_metadata(data, md)

  # The old index is not promoted to a grouping variable (one group per row).
  declare_variables(
    data,
    "when",
    setdiff(get_variables(data, "when"), column)
  )
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
