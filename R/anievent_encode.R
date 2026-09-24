# Encoding per-frame labels into bouts (#66)
#
# Split out of `anievent_to.R`, which held both the `to_anievent()` API
# and this: the engine that turns a column of per-frame labels into the
# bouts an anievent is made of. The dispatch is one subject, the encoding
# another, and this is the intricate half.

#' Normalise an event-column vector to character labels
#'
#' Logical → column name on TRUE, `NA` on FALSE. Factor / character →
#' character. Lets a single kernel handle both binary (logical) and
#' multi-level (factor / character) inputs.
#'
#' @keywords internal
normalise_event_values <- function(x, col_name) {
  if (is.logical(x)) {
    return(ifelse(x, col_name, NA_character_))
  }
  as.character(x)
}


#' Detect the identity / grouping scope of one event column
#'
#' Returns the minimal subset of `candidate_cols` that the value of
#' `event_col` varies across (given `time_col`). Used by
#' `to_anievent.anipoint()` to drop redundant identity columns —
#' e.g. a `behaviour` column that is constant across `keypoint`
#' for each `(individual, time)` drops `keypoint` from the resulting
#' anievent's grouping.
#'
#' @keywords internal
detect_event_scope <- function(
  data,
  event_col,
  candidate_cols,
  time_col = "time"
) {
  if (all(is.na(data[[event_col]]))) {
    return(character())
  }

  scope <- candidate_cols
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (col in scope) {
      if (dplyr::n_distinct(data[[col]]) <= 1) {
        next
      }
      smaller <- setdiff(scope, col)
      grouped <- data |>
        dplyr::group_by(
          dplyr::across(dplyr::all_of(c(smaller, time_col)))
        ) |>
        dplyr::summarise(
          n = dplyr::n_distinct(.data[[event_col]]),
          .groups = "drop"
        )
      if (all(grouped$n <= 1)) {
        scope <- smaller
        changed <- TRUE
        break
      }
    }
  }
  scope
}


#' Encode one state event column into bouts
#'
#' Within each `group_cols` partition, emit one row per maximal run
#' of identical non-`NA` (normalised) values in `col`. `NA` rows
#' break runs (so a value sequence like `c("REM", NA, "REM")` becomes
#' two bouts, not one). `start` is the `time_col` value at the first
#' frame in the run; `stop` is the value at the last frame.
#'
#' @keywords internal
encode_state_bouts <- function(data, col, time_col, group_cols) {
  vals <- normalise_event_values(data[[col]], col)
  if (length(vals) == 0 || all(is.na(vals))) {
    return(make_empty_bouts(group_cols, col))
  }

  if (length(group_cols) > 0) {
    ord <- do.call(order, c(data[group_cols], list(data[[time_col]])))
    data <- data[ord, , drop = FALSE]
    vals <- vals[ord]
    key <- do.call(paste, c(data[group_cols], list(sep = "\r")))
  } else {
    ord <- order(data[[time_col]])
    data <- data[ord, , drop = FALSE]
    vals <- vals[ord]
    key <- rep("", nrow(data))
  }

  # Run-start detection on the full sequence (NAs included). A run
  # starts when the group key changes, OR the NA-ness flips, OR the
  # value changes (both sides non-NA). NA rows form their own runs
  # and get dropped from the emit list below.
  prev_key <- c(NA_character_, key[-length(key)])
  prev_val <- c(NA_character_, vals[-length(vals)])
  key_changed <- is.na(prev_key) | key != prev_key
  na_flip <- xor(is.na(vals), is.na(prev_val))
  val_changed <- !is.na(vals) & !is.na(prev_val) & vals != prev_val
  run_start <- key_changed | na_flip | val_changed
  run_id <- cumsum(run_start)

  first_idx <- which(!duplicated(run_id))
  last_idx <- which(!duplicated(run_id, fromLast = TRUE))

  keep_runs <- !is.na(vals[first_idx])
  first_idx <- first_idx[keep_runs]
  last_idx <- last_idx[keep_runs]

  out <- dplyr::tibble(
    channel = col,
    label = vals[first_idx],
    start = data[[time_col]][first_idx],
    stop = data[[time_col]][last_idx]
  )

  mod_col <- paste0(col, "_modifiers")
  if (mod_col %in% names(data)) {
    out$modifiers <- data[[mod_col]][first_idx]
  }

  if (length(group_cols) > 0) {
    grp_first <- data[first_idx, group_cols, drop = FALSE]
    out <- dplyr::bind_cols(grp_first, out)
  }
  out
}


#' Emit one row per non-`NA` frame of a point event column
#'
#' @keywords internal
encode_point_bouts <- function(data, col, time_col, group_cols) {
  vals <- normalise_event_values(data[[col]], col)
  mod_col <- paste0(col, "_modifiers")
  has_modifiers <- mod_col %in% names(data)

  keep <- !is.na(vals)
  data <- data[keep, , drop = FALSE]
  vals <- vals[keep]
  if (length(vals) == 0) {
    return(make_empty_bouts(group_cols, col))
  }

  out <- dplyr::tibble(
    channel = col,
    label = vals,
    start = data[[time_col]],
    stop = data[[time_col]]
  )

  if (has_modifiers) {
    out$modifiers <- data[[mod_col]]
  }

  if (length(group_cols) > 0) {
    out <- dplyr::bind_cols(data[, group_cols, drop = FALSE], out)
  }
  out
}


#' @keywords internal
make_empty_bouts <- function(group_cols, col) {
  out <- dplyr::tibble(
    channel = character(),
    label = character(),
    start = numeric(),
    stop = numeric()
  )
  if (length(group_cols) > 0) {
    for (g in group_cols) {
      out[[g]] <- character()
    }
    out <- out[, c(group_cols, "channel", "label", "start", "stop")]
  }
  out
}
