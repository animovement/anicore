#' Cast a data frame to an anievent
#'
#' Strict cast — the input must already be in canonical anievent
#' shape: one row per bout or instant, with the columns `channel`,
#' `type`, `label`, `start`, and `stop`. Identity columns travel via
#' `variables_what`. An optional `modifiers` list-column may carry
#' per-event modifier values (each cell a character vector, matching
#' the BORIS export format).
#'
#' To *encode* per-frame data (factor / logical / character columns)
#' into the bout shape, use [to_anievent()] instead.
#'
#' @param data A data frame with the required columns.
#' @param metadata Optional list of metadata.
#' @param variables_what Character vector of identity columns. When
#'   `NULL` (default), auto-detected from a known list (`model`,
#'   `individual`, `subject`, `track`, `keypoint`) — only those present
#'   in `data` are used. Pass an explicit value to use any other
#'   column name(s) as
#'   identity. An anievent with no identity column is permitted (e.g. a
#'   single-subject experiment).
#' @param variables_when Character vector of temporal columns. When
#'   `NULL` (default), auto-detected from a known grouping list
#'   (`observation`, `session`, `trial`) and concatenated with the
#'   required temporal endpoints `c("start", "stop")`. Pass explicitly
#'   to use other names for the grouping context.
#'
#' @return An anievent object.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' try(as_anievent(af))
#' @export
as_anievent <- function(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL
) {
  UseMethod("as_anievent")
}

#' @rdname as_anievent
#' @export
as_anievent.anievent <- function(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL
) {
  # Repair objects serialised before the aniframe superclass existed.
  if (!inherits(data, "aniframe")) {
    class(data) <- append(
      class(data),
      "aniframe",
      after = match("anievent", class(data))
    )
  }
  data
}

#' @rdname as_anievent
#' @export
as_anievent.aniframe <- function(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL
) {
  cli::cli_abort(c(
    "Cannot cast an {.cls {class(data)[[1]]}} directly to an {.cls anievent}.",
    "i" = "Use {.fn to_anievent} to encode per-frame event columns into bouts."
  ))
}

#' @rdname as_anievent
#' @export
as_anievent.data.frame <- function(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL
) {
  if (is.null(variables_what)) {
    variables_what <- list_recognised_variables_what()[
      list_recognised_variables_what() %in% names(data)
    ]
  }
  if (is.null(variables_when)) {
    recognised_when_grouping <- c("observation", "session", "trial")
    detected_when <- recognised_when_grouping[
      recognised_when_grouping %in% names(data)
    ]
    variables_when <- c(detected_when, "start", "stop")
  }

  # `type` is per (channel, label): "point" only if every bout has start == stop.
  if (
    !"type" %in% names(data) &&
      all(c("start", "stop", "channel", "label") %in% names(data))
  ) {
    key <- paste(
      as.character(data[["channel"]]),
      as.character(data[["label"]]),
      sep = "\r"
    )
    is_point_per_key <- tapply(
      data[["start"]] == data[["stop"]],
      key,
      all
    )
    data[["type"]] <- ifelse(
      is_point_per_key[key],
      "point",
      "state"
    )
  }

  # Same restructure as the variable setters, so the two can't drift (#82).
  data <- new_anievent(data)
  data <- set_metadata(data, metadata = drop_spatial_metadata(metadata))
  data <- restructure_anievent(data, variables_what, variables_when)

  data
}


#' Validate the structural columns of an anievent
#'
#' @param data Data frame to validate.
#' @keywords internal
ensure_has_anievent_cols <- function(data) {
  required <- c("channel", "type", "label", "start", "stop")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "Missing required column{?s} for an anievent: {.val {missing}}.",
      "i" = "An anievent requires {.val {required}}.",
      "i" = "{.field type} must be {.val state} or {.val point} per row.",
      "i" = "Identity columns (e.g. {.val individual}) are recognised via {.arg variables_what} but are not required.",
      "i" = "To encode per-frame event columns into bouts, use {.fn to_anievent} instead."
    ))
  }
  invisible(TRUE)
}


#' Standardise column types for an anievent
#'
#' @param data Data frame to standardise.
#' @param variables_what Identity variable names.
#' @param variables_when Temporal variable names, including `start`/`stop`.
#'
#' @return Data frame with standardised column types.
#' @keywords internal
standardise_anievent_cols <- function(data, variables_what, variables_when) {
  categorical_vars <- c(
    variables_what,
    setdiff(variables_when, c("start", "stop"))
  )
  for (col in categorical_vars) {
    if (col %in% names(data)) {
      if (is.character(data[[col]])) {
        data[[col]] <- factor(data[[col]])
      } else if (is.numeric(data[[col]])) {
        data[[col]] <- as.integer(data[[col]])
      }
    }
  }

  if (!is.character(data[["channel"]])) {
    data[["channel"]] <- as.character(data[["channel"]])
  }

  permitted_types <- c("state", "point")
  raw_type <- as.character(data[["type"]])
  bad_type <- setdiff(unique(raw_type), c(permitted_types, NA_character_))
  if (length(bad_type) > 0) {
    cli::cli_abort(c(
      "{.field type} must be {.val state} or {.val point}.",
      "x" = "Got: {.val {bad_type}}."
    ))
  }
  data[["type"]] <- factor(raw_type, levels = permitted_types)

  if (!is.factor(data[["label"]])) {
    data[["label"]] <- factor(data[["label"]])
  }
  data[["start"]] <- as.numeric(data[["start"]])
  data[["stop"]] <- as.numeric(data[["stop"]])

  data
}


#' Drop spatial metadata an anievent cannot carry
#'
#' Dropped rather than refused, since readers still pass them (#73).
#'
#' @param metadata Metadata supplied by the caller.
#'
#' @return `metadata` without spatial fields.
#' @keywords internal
drop_spatial_metadata <- function(metadata) {
  metadata <- unclass(metadata)
  categories <- list_metadata_field_categories()
  spatial <- c("space", names(categories)[categories == "space"])
  metadata[setdiff(names(metadata), spatial)]
}
