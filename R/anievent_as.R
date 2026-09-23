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

  # Auto-derive `type` from bout duration if the caller didn't
  # supply it. Classification is per `(channel, label)` group,
  # not per row: a (channel, label) pair is "point" only when
  # *all* of its bouts have `start == stop`. If even one bout is
  # durative, the whole group is "state" — keeping the kind of event
  # consistent across its occurrences. Users who know better (e.g. a
  # state channel that happens to have only single-frame bouts) can
  # pass `type` explicitly to override.
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

  # Attach class and metadata first, then let the shared restructure
  # validate, standardise types, relocate and order — the same code the
  # variable setters use, so construction and re-declaration can't drift
  # apart (#82).
  data <- new_anievent(data)
  data <- set_metadata(data, metadata = neutralise_spatial_metadata(metadata))
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
#' Coerces identity and temporal-grouping columns to factor/integer
#' (mirroring the aniframe convention), `channel` to character,
#' `label` to factor, and `start`/`stop` to numeric.
#'
#' @param data Data frame to standardise.
#' @param variables_what Identity variable names.
#' @param variables_when Temporal variable names — grouping columns
#'   (everything except `start`/`stop`) are coerced like identity
#'   columns; `start` and `stop` are forced numeric.
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


#' Fill the spatial metadata fields with their "not applicable" values
#'
#' An anievent shares the metadata substrate with [anipoint()] but has no
#' spatial component: a stream of behavioural events has no axes, no
#' reference frame and no angular unit. Inheriting the movement defaults
#' made it claim otherwise — a BORIS export read into an anievent
#' announced a coordinate system it had no coordinates for (#73).
#'
#' Values the caller supplied are left alone, so a reader that knows
#' better can still say so.
#'
#' @param metadata Metadata supplied by the caller.
#'
#' @return `metadata`, with the untouched spatial fields set to their
#'   neutral values.
#' @keywords internal
neutralise_spatial_metadata <- function(metadata) {
  neutral <- list(
    unit_space = "none",
    unit_angle = "none",
    reference_frame = "none",
    coordinate_system = "unknown",
    axis_directions = stats::setNames(character(), character()),
    axis_extents = stats::setNames(numeric(), character())
  )

  supplied <- names(metadata)
  for (field in setdiff(names(neutral), supplied)) {
    metadata[[field]] <- neutral[[field]]
  }

  metadata
}
