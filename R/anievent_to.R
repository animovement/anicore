#' Encode per-frame data into an anievent
#'
#' Run-length-encodes per-frame state and point variables into the
#' long-format [anievent()]. Works on a data frame (with bare-name
#' selection of the event columns and explicit `time` / identity)
#' or on an [anipoint()] (where everything is read from metadata).
#'
#' Distinct from [as_anievent()]: that one is a strict cast — the
#' input must already be in canonical anievent shape (one row per
#' bout, with `channel` / `type` / `label` / `start` / `stop`).
#' `to_anievent()` is the encoding verb that *produces* that shape
#' from per-frame data.
#'
#' @param data A data frame or an [anipoint()].
#' @param time For data-frame input, the column holding per-frame
#'   times. Bare name (tidyselect). Required.
#' @param state For data-frame input, columns to run-length-encode
#'   as state bouts. Bare names (tidyselect). Logical columns produce
#'   bouts on TRUE-runs, labelled by the column name; factor or
#'   character columns produce one bout per contiguous non-`NA` run
#'   of the same value.
#' @param point For data-frame input, columns to encode as point
#'   bouts. Bare names (tidyselect). Logical columns produce one
#'   point bout per TRUE frame, labelled by the column name; factor
#'   or character columns produce one bout per non-`NA` frame.
#' @param variables_what For data-frame input, identity columns
#'   (e.g. `individual`). Bare names (tidyselect). Bouts are
#'   isolated per identity group.
#' @param variables_when For data-frame input, additional temporal-
#'   grouping columns (e.g. `observation`, `session`, `trial`). Bare
#'   names (tidyselect). Like identity, these isolate bouts.
#' @param metadata Optional list of metadata attached to the result.
#'   For an anipoint input, fields like `unit_time` and
#'   `sampling_rate` are propagated automatically; `metadata`
#'   overrides those.
#' @param ... Passed to methods.
#'
#' @return An [anievent()].
#'
#' @examples
#' \dontrun{
#' library(tibble)
#' df <- tibble(
#'   individual = 1L,
#'   time = 1:8,
#'   behaviour = factor(c("REM", "REM", "REM", "wake", "wake", "REM", "REM", NA)),
#'   woke_up = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
#'   call = c(NA, "alarm", NA, NA, NA, NA, NA, NA)
#' )
#' to_anievent(
#'   df,
#'   time = time,
#'   state = c(behaviour, woke_up),
#'   point = call,
#'   variables_what = individual
#' )
#' }
#'
#' @export
to_anievent <- function(data, ...) {
  UseMethod("to_anievent")
}

#' @rdname to_anievent
#' @export
to_anievent.anievent <- function(data, ...) {
  data
}

#' @rdname to_anievent
#' @export
to_anievent.data.frame <- function(
  data,
  time,
  state = NULL,
  point = NULL,
  variables_what = NULL,
  variables_when = NULL,
  metadata = list(),
  ...
) {
  time_col <- colnames(dplyr::select(data, {{ time }}))
  if (length(time_col) != 1L) {
    cli::cli_abort(c(
      "{.arg time} must select exactly one column.",
      "x" = "Selected {length(time_col)} column{?s}: {.val {time_col}}."
    ))
  }

  state_cols <- colnames(dplyr::select(data, {{ state }}))
  point_cols <- colnames(dplyr::select(data, {{ point }}))
  if (length(state_cols) == 0L && length(point_cols) == 0L) {
    cli::cli_abort(c(
      "At least one of {.arg state} or {.arg point} must select a column.",
      "i" = "Use bare names: e.g. {.code state = c(behaviour, posture)}."
    ))
  }

  what_cols <- colnames(dplyr::select(data, {{ variables_what }}))
  when_cols <- colnames(dplyr::select(data, {{ variables_when }}))

  to_anievent_from_columns(
    data,
    time_col = time_col,
    state_cols = state_cols,
    point_cols = point_cols,
    what_cols = what_cols,
    when_cols = when_cols,
    metadata = metadata
  )
}

#' @rdname to_anievent
#' @export
to_anievent.anipoint <- function(
  data,
  variables_what = NULL,
  variables_when = NULL,
  metadata = list(),
  ...
) {
  md <- get_metadata(data)
  ve <- md_event(md)
  if (is.null(ve) || (length(ve$state) == 0 && length(ve$point) == 0)) {
    cli::cli_abort(c(
      "The {.cls anipoint} has no event columns declared.",
      "i" = "Declare them with {.code set_variables(data, event = list(state = ))} before conversion."
    ))
  }

  declared <- c(ve$state, ve$point)
  missing_cols <- setdiff(declared, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Some declared event columns are not present in the data: {.val {missing_cols}}.",
      "i" = "Either remove them from {.field variables_event} or add the columns."
    ))
  }

  index <- resolve_index(md)
  host_what <- intersect(md_what_keys(md), names(data))
  grouping_when <- intersect(
    setdiff(md_when_keys(md), index),
    names(data)
  )

  bare <- dplyr::ungroup(dplyr::as_tibble(data))

  if (is.null(variables_what)) {
    # Identity columns only: temporal contexts must never be merged.
    channel_scopes <- list()
    for (col in declared) {
      channel_scopes[[col]] <- detect_event_scope(
        bare,
        col,
        host_what,
        time_col = index
      )
    }
    unique_scopes <- unique(channel_scopes)
    if (length(unique_scopes) > 1) {
      scope_lines <- vapply(
        names(channel_scopes),
        function(nm) {
          sc <- channel_scopes[[nm]]
          sc_str <- if (length(sc) == 0) {
            "<none>"
          } else {
            paste(sc, collapse = ", ")
          }
          paste0(nm, " -> ", sc_str)
        },
        character(1)
      )
      cli::cli_abort(c(
        "Declared event columns disagree on their identity scope.",
        "i" = "Detected scopes per channel:",
        stats::setNames(scope_lines, rep("*", length(scope_lines))),
        "i" = "Pass {.arg variables_what} explicitly or split the channels into separate {.cls anievent}s."
      ))
    }
    detected_scope <- unique_scopes[[1]]
  } else {
    detected_scope <- variables_what
  }

  if (!is.null(variables_when)) {
    grouping_when <- setdiff(variables_when, c("start", "stop"))
  }

  # Only `recording` and `time` carry over; `space` belongs to the host (#73)
  # and `structure` may name variables the anievent lacks.
  inherited_metadata <- c(
    unclass(md[["recording"]]),
    unclass(md[["time"]])
  )
  metadata <- utils::modifyList(inherited_metadata, metadata)

  to_anievent_from_columns(
    bare,
    time_col = index,
    state_cols = ve$state,
    point_cols = ve$point,
    what_cols = detected_scope,
    when_cols = grouping_when,
    metadata = metadata
  )
}


#' String-keyed kernel shared by `to_anievent` methods
#'
#' @keywords internal
to_anievent_from_columns <- function(
  data,
  time_col,
  state_cols,
  point_cols,
  what_cols,
  when_cols,
  metadata
) {
  group_cols <- c(what_cols, when_cols)

  bouts <- list()
  for (col in state_cols) {
    sub <- encode_state_bouts(data, col, time_col, group_cols)
    if (nrow(sub) > 0) {
      sub$type <- "state"
    }
    bouts[[paste0("state__", col)]] <- sub
  }
  for (col in point_cols) {
    sub <- encode_point_bouts(data, col, time_col, group_cols)
    if (nrow(sub) > 0) {
      sub$type <- "point"
    }
    bouts[[paste0("point__", col)]] <- sub
  }

  out <- dplyr::bind_rows(bouts)
  if (!is.factor(out$label)) {
    out$label <- factor(out$label)
  }

  variables_when <- c(when_cols, "start", "stop")

  as_anievent(
    out,
    metadata = metadata,
    variables_what = what_cols,
    variables_when = variables_when
  )
}
