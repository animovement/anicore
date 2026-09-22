#' Validate an anievent
#'
#' Re-runs the structural invariants of an `anievent` object on demand:
#' * required columns (`channel`, `type`, `label`, `start`, `stop`)
#'   are present with the expected types — hard errors;
#' * `type` is a factor with levels `c("state", "point")` — hard
#'   error;
#' * `stop >= start` for every row — hard error;
#' * `modifiers`, if present, is a list-column whose cells are
#'   character vectors — hard error;
#' * within each `(identity + temporal-grouping)` group, two bouts of
#'   the same `channel` should not overlap — **warning** only.
#'   Overlapping bouts within a channel are permitted on the
#'   `anievent` side; this is the form the data takes from coding
#'   tools that allow non-mutually-exclusive coding (e.g. BORIS
#'   without strict ethogram).
#'
#' @param data An anievent object.
#'
#' @return The input `data`, invisibly.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' try(validate_anievent(af))
#' @export
validate_anievent <- function(data) {
  ensure_is_anievent(data)
  ensure_has_anievent_cols(data)
  ensure_anievent_col_types(data)
  ensure_anievent_intervals_nonnegative(data)
  ensure_valid_modifiers(data)
  warn_anievent_channels_overlap(data)
  invisible(data)
}


#' @keywords internal
ensure_anievent_col_types <- function(data) {
  if (!is.character(data[["channel"]])) {
    cli::cli_abort("{.field channel} must be character.")
  }
  if (!is.factor(data[["type"]])) {
    cli::cli_abort(
      "{.field type} must be a factor with levels {.val state} and {.val point}."
    )
  }
  if (!identical(levels(data[["type"]]), c("state", "point"))) {
    cli::cli_abort(
      "{.field type} must have levels exactly {.val state} and {.val point}."
    )
  }
  if (!is.factor(data[["label"]])) {
    cli::cli_abort("{.field label} must be a factor.")
  }
  if (!is.numeric(data[["start"]])) {
    cli::cli_abort("{.field start} must be numeric.")
  }
  if (!is.numeric(data[["stop"]])) {
    cli::cli_abort("{.field stop} must be numeric.")
  }
  invisible(TRUE)
}


#' @keywords internal
ensure_anievent_intervals_nonnegative <- function(data) {
  diffs <- data[["stop"]] - data[["start"]]
  bad <- which(!is.na(diffs) & diffs < 0)
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "{.field stop} must be greater than or equal to {.field start} for every row.",
      "x" = "Row{?s} violating the invariant: {.val {bad}}."
    ))
  }
  invisible(TRUE)
}


#' Find the first overlapping bout pair within any (identity +
#' temporal-grouping + channel) group of an anievent.
#'
#' Returns `NULL` when no overlap exists; otherwise a small named list
#' identifying the channel and offending row.
#'
#' @keywords internal
find_anievent_channel_overlap <- function(data) {
  if (nrow(data) < 2) {
    return(NULL)
  }

  md <- get_metadata(data)
  group_cols <- intersect(
    c(md_what_keys(md), md_when_keys(md)),
    names(data)
  )

  # Work on a bare tibble so dplyr verbs don't trigger the
  # `ungroup.anievent` "use with care" warning during validation.
  bare <- dplyr::as_tibble(data)
  groups <- dplyr::group_by(
    bare,
    dplyr::across(dplyr::all_of(c(group_cols, "channel")))
  )
  for (sub in dplyr::group_split(groups)) {
    if (nrow(sub) < 2) {
      next
    }
    sub <- sub[order(sub$start), ]
    overlaps <- sub$start[-1] < sub$stop[-nrow(sub)]
    if (any(overlaps)) {
      bad_row <- which(overlaps)[1] + 1
      return(list(channel = sub$channel[bad_row], row = bad_row))
    }
  }
  NULL
}


#' @keywords internal
warn_anievent_channels_overlap <- function(data) {
  hit <- find_anievent_channel_overlap(data)
  if (!is.null(hit)) {
    cli::cli_warn(c(
      "Two bouts of the same channel overlap for the same subject.",
      "x" = "Channel {.val {hit$channel}} has overlapping bouts at row {.val {hit$row}}.",
      "i" = "Overlap is permitted on the {.cls anievent}; downstream consumers that require mutual exclusion can resolve it at that boundary."
    ))
  }
  invisible(TRUE)
}


#' @keywords internal
ensure_valid_modifiers <- function(data) {
  if (!"modifiers" %in% names(data)) {
    return(invisible(TRUE))
  }
  mods <- data[["modifiers"]]
  if (!is.list(mods)) {
    cli::cli_abort("{.field modifiers} must be a list-column.")
  }
  for (i in seq_along(mods)) {
    cell <- mods[[i]]
    if (!(is.character(cell) || (is.atomic(cell) && length(cell) == 0))) {
      cli::cli_abort(c(
        "Every cell of {.field modifiers} must be a character vector.",
        "x" = "Row {.val {i}} is of type {.cls {class(cell)}}."
      ))
    }
  }
  invisible(TRUE)
}
