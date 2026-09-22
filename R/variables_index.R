# The index (#109)
#
# `variables_when` used to do two jobs at once: name the column the frame
# is indexed by, and name the surrounding temporal context. The two were
# told apart by the literal string "time", which forced every frame to
# have a column of that name and made the distinction unrecoverable
# downstream without repeating the same literal.
#
# `variables_index` names the column instead, and is kept out of
# `variables_when` entirely, so that field is exactly what the frame
# groups by. Making it a member would leave `set_index()` promoting the
# old index to a grouping variable, and every downstream package
# repeating the same `setdiff` to undo it.

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
      "i" = "Both are in {.field variables_when}; read them with {.fn get_variables_when}."
    ))
  }
  ensure_is_anipoint(data)
  resolve_index(get_metadata(data))
}


#' Resolve the index from a metadata list
#'
#' Objects serialised before the field existed have no `index`. They were
#' built when a literal `time` column was mandatory, so that is what they
#' are indexed by, and defaulting here keeps them working untouched.
#'
#' `NA` — how an [anievent()] spells "not applicable" — falls back the
#' same way. The only path that reaches here with anievent metadata is a
#' cast to [anipoint()], which needs *some* index; [get_index()] refuses
#' the anievent before it gets this far.
#'
#' @param md A metadata list.
#'
#' @return Length-one character vector.
#' @keywords internal
resolve_index <- function(md) {
  idx <- md[["variables_index"]]
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
  md[["variables_index"]] <- column
  data <- attach_metadata(data, md)

  # If the column was serving as temporal context, it stops: a variable
  # cannot be both the position within a context and part of the context.
  # The previous index simply stops being declared — it is not silently
  # promoted to a grouping variable, which for a column of unique values
  # would put every row in its own group.
  declare_variables(
    data,
    "when",
    setdiff(get_variables(data, "when"), column)
  )
}


#' Ensure a declared index names exactly one column
#'
#' Split out from [ensure_valid_index()] because [as_anipoint()] needs it
#' before the column is looked up, and under its own argument name.
#' Unchecked, a two-column `index` falls through to [resolve_index()],
#' which reads anything but a single name as "unset" and answers `"time"`.
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
