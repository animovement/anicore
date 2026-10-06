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
#' @description
#' Makes `column` the index, the `when$index` slot, and re-sorts the frame.
#' A column that was a `when` key stops being one. `unit` declares the unit
#' of the new index in the same call; without it, the frame goes on
#' declaring the unit of the old index.
#'
#' The new index must be numeric, with no missing values, and must increase
#' within each group of keys (identity plus temporal context) in the order
#' of the old index, so the rows keep their order: values that go backwards
#' have been matched to the wrong rows. Date-times are refused: the index
#' holds the time since the start, as numbers, and the start goes in
#' `start_datetime`, so absolute time is `start_datetime` plus the index.
#'
#' @section The old index:
#' The previous index becomes an ordinary, undeclared column rather than a
#' key, as grouping by it would put each row in a group of its own.
#'
#' When it counted frames (`unit_time` is `"frame"`), it is renamed
#' `frame`. Frame numbers recorded with the data are data, not something to
#' compute again from a rate, and [convert_unit_time()] makes the `frame`
#' column the index again when converting to `"frame"`. An old index
#' already named `frame` keeps its name, and so does one replaced by a new
#' index named `frame`. If the frame has another column named `frame`,
#' `set_index()` refuses rather than overwrite either; rename one first.
#'
#' @section Indexing by recorded timestamps:
#' Timestamps recorded alongside the data, such as a camera's log of when
#' each frame was taken, are added as a column and made the index with
#' their unit:
#'
#' ```r
#' data |>
#'   dplyr::mutate(timestamp = stamps[time + 1]) |>
#'   set_index("timestamp", unit = "s")
#' ```
#'
#' Here the log has one entry per frame and frames count from 0, so the
#' timestamp of a row is matched by its frame number. Matching by position,
#' assigning the log in row order, lines up only when every group is
#' complete and sorted: an anipoint has one row per time per key, and a
#' keypoint can be missing from some frames. Bringing a log, or any other
#' data, into a frame is a join question, tracked in
#' [anicore#1](https://github.com/animovement/anicore/issues/1).
#'
#' The frame numbers move to a column named `frame`, and a declared
#' `sampling_rate` is kept as the nominal rate. `sampling_interval` is
#' measured from the timestamps, and [validate_anipoint()] allows the two to
#' differ by 1%. Overwriting `time` with [dplyr::mutate()] instead would
#' lose the frame numbers and leave the frame saying the index counts frames
#' when it holds seconds.
#'
#' @param data An anipoint object.
#' @param column Length-one character vector naming the index column. It
#'   must exist in `data` and be numeric.
#' @param unit The unit of the new index, one of the levels of `unit_time`
#'   in [list_default_metadata()]. `NULL`, the default, leaves `unit_time`
#'   as it is.
#'
#' @return `data`, re-indexed and restructured.
#'
#' @examples
#' df <- data.frame(frame = 1:3, individual = "a", x = c(1, 2, 3), y = c(0, 1, 0))
#' af <- as_anipoint(df, index = "frame")
#' get_index(af)
#'
#' # A camera log, one timestamp per frame, frames counted from 0
#' af <- as_anipoint(data.frame(
#'   individual = "a",
#'   keypoint = rep(c("head", "tail"), each = 4),
#'   time = rep(0:3, 2),
#'   x = 1:8,
#'   y = 1:8
#' ))
#' stamps <- c(0, 0.0332, 0.0668, 0.1001)
#' logged <- af |>
#'   dplyr::mutate(timestamp = stamps[time + 1]) |>
#'   set_index("timestamp", unit = "s")
#' logged
#'
#' # The frame numbers are kept, and become the index again
#' get_index(convert_unit_time(logged, "frame"))
#'
#' @seealso [get_index()], [convert_unit_time()] to rescale the index into
#'   another unit.
#' @export
set_index <- function(data, column, unit = NULL) {
  ensure_is_anipoint(data)
  ensure_valid_index(data, column)
  ensure_valid_index_unit(unit)

  old <- get_index(data)
  keep_frames <- FALSE
  if (!identical(column, old)) {
    ensure_index_increases(data, column, old)
    keep_frames <- keeps_recorded_frames(data, column, old)
  }

  # The old index is not promoted to a key (one group per row).
  data <- set_variables(data, when = list(index = column))
  if (keep_frames) {
    data <- dplyr::rename(data, frame = dplyr::all_of(old))
  }
  if (!is.null(unit)) {
    data <- set_metadata(data, unit_time = unit)
  }
  data
}


#' Ensure a unit for the index is a level of unit_time
#'
#' @param unit The proposed unit, or `NULL`.
#' @param call The caller's environment, for the error.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_valid_index_unit <- function(unit, call = rlang::caller_env()) {
  if (is.null(unit)) {
    return(invisible(TRUE))
  }
  permitted <- levels(list_default_metadata()[["unit_time"]])
  if (
    !is.character(unit) ||
      length(unit) != 1L ||
      is.na(unit) ||
      !unit %in% permitted
  ) {
    cli::cli_abort(
      "{.arg unit} must be one of {.val {permitted}}, not {.val {unit}}.",
      call = call
    )
  }
  invisible(TRUE)
}


#' Ensure a new index keeps the rows in order
#'
#' Within each group of keys, wherever the old index increases, the new one
#' must increase too. Rows that share a value of the old index are already
#' duplicates, which [validate_anipoint()] reports, so their order is not
#' checked.
#'
#' @param data An anipoint object.
#' @param column The proposed index column.
#' @param old The current index column.
#' @param call The caller's environment, for the error.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_index_increases <- function(
  data,
  column,
  old,
  call = rlang::caller_env()
) {
  values <- .subset2(data, column)
  if (anyNA(values)) {
    cli::cli_abort(
      c(
        "Index column {.val {column}} has missing values.",
        "i" = "Every row needs a place in time; drop the rows without one first."
      ),
      call = call
    )
  }
  before <- if (old %in% names(data)) {
    .subset2(data, old)
  } else {
    seq_along(values)
  }
  group <- key_group_ids(data)
  ordered <- order(group, before, method = "radix")
  group <- group[ordered]
  values <- values[ordered]
  before <- before[ordered]
  within <- group[-1L] == group[-length(group)]
  step <- diff(values)[within]
  step_before <- diff(before)[within]
  backwards <- !is.na(step_before) & step_before > 0 & step <= 0
  if (any(backwards)) {
    at <- which(within)[backwards][[1]]
    keys <- intersect(get_keys(data), names(data))
    cli::cli_abort(
      c(
        "Index column {.val {column}} must increase with {.val {old}} within each group of keys{if (length(keys)) paste0(' (', paste(keys, collapse = ', '), ')') else ''}.",
        "x" = "Where {.field {old}} goes from {before[[at]]} to {before[[at + 1L]]}, {.field {column}} goes from {values[[at]]} to {values[[at + 1L]]}.",
        "i" = "Values that go backwards have been matched to the wrong rows. Match them by {.field {old}}, not by position."
      ),
      call = call
    )
  }
  invisible(TRUE)
}


#' Should the old index be kept as the recorded frame numbers?
#'
#' When it counts frames and the new index is another column, it is renamed
#' `frame`, unless it already is, or the new index takes that name. Another
#' column named `frame` is in the way, so that is refused.
#'
#' @param data An anipoint object.
#' @param column The proposed index column.
#' @param old The current index column.
#' @param call The caller's environment, for the error.
#'
#' @return Logical scalar: whether to rename `old` to `frame`.
#' @keywords internal
keeps_recorded_frames <- function(
  data,
  column,
  old,
  call = rlang::caller_env()
) {
  in_frames <- identical(as.character(get_metadata(data, "unit_time")), "frame")
  if (!in_frames || "frame" %in% c(old, column) || !old %in% names(data)) {
    return(FALSE)
  }
  if ("frame" %in% names(data)) {
    cli::cli_abort(
      c(
        "Cannot keep the frame numbers in {.field {old}}: the frame already has a column named {.field frame}.",
        "i" = "{.fn set_index} moves an index that counts frames to {.field frame}, so the recorded frame numbers are kept.",
        "i" = "Rename or drop the other {.field frame} column first."
      ),
      call = call
    )
  }
  TRUE
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
    cli::cli_abort(c(
      "Index column {.val {column}} must be numeric, not {.cls {class(data[[column]])}}.",
      "i" = if (inherits(data[[column]], c("POSIXt", "Date"))) {
        "Store the time since the start as numbers, and the start as {.field start_datetime} with {.fn set_metadata}."
      }
    ))
  }
  invisible(TRUE)
}
