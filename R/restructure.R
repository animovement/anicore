#' Strip a frame back to its dplyr classes
#'
#' Avoids dispatching into class-preserving methods and the `ungroup()`
#' "use with care" warning.
#'
#' @param data An aniframe or anievent object.
#'
#' @return `data` with the animovement classes removed.
#' @keywords internal
strip_animovement_class <- function(data) {
  class(data) <- intersect(class(data), list_base_frame_classes())
  data
}


#' Restructure an anipoint
#'
#' Shared by construction and re-declaration so they cannot drift apart.
#'
#' @param data An anipoint object.
#' @param variables_what,variables_when,variables_where The declaration
#'   to apply.
#' @param orientation `where$orientation`; `NULL` keeps the current one.
#'
#' @return `data`, restructured, with the declaration recorded.
#' @keywords internal
restructure_anipoint <- function(
  data,
  variables_what,
  variables_when,
  variables_where,
  orientation = NULL,
  strict = TRUE
) {
  cls <- class(data)
  md <- get_metadata(data)
  index <- resolve_index(md)
  bare <- strip_animovement_class(data)

  # Older frames list the index in `variables_when`; grouping by it would
  # put every row in its own group.
  variables_when <- setdiff(variables_when, index)

  # Fail on a bad role here rather than degrading to "unknown" (#109).
  axes <- normalise_axes(variables_where)
  if (strict && has_axis_roles(variables_where)) {
    ensure_valid_axis_roles(axes)
  }
  where_cols <- unname(axes)

  ensure_has_anipoint_cols(
    bare,
    variables_what,
    variables_when,
    where_cols,
    index
  )
  bare <- standardise_anipoint_cols(
    bare,
    variables_what,
    variables_when,
    where_cols,
    index
  )

  standard_cols <- unique(
    c(variables_what, variables_when, index, where_cols)
  )
  if ("confidence" %in% names(bare)) {
    standard_cols <- c(standard_cols, "confidence")
  }
  bare <- bare[, c(standard_cols, setdiff(names(bare), standard_cols))]

  # Index sorts last so each trajectory stays contiguous.
  bare <- dplyr::arrange(
    bare,
    dplyr::across(dplyr::all_of(variables_what)),
    dplyr::across(dplyr::all_of(c(variables_when, index)))
  )

  grouping_vars <- c(variables_what, variables_when)
  bare <- regroup_frame(bare, grouping_vars)

  coordinate_system <- infer_coordinate_system(axes)

  position <- if (identical(coordinate_system, "unknown")) {
    where_cols
  } else {
    axes
  }
  warn_shadowed_axis_roles(
    if (identical(coordinate_system, "unknown")) {
      stats::setNames(character(), character())
    } else {
      axes
    },
    names(bare)
  )

  md <- migrate_metadata_layout(md)
  where <- list(position = position)
  orientation <- orientation %||% md$variables$where$orientation
  if (length(orientation) > 0L) {
    ensure_has_declared_cols(bare, unname(orientation), "where")
    where$orientation <- orientation
  }
  md$variables <- list(
    what = list(keys = variables_what),
    when = list(index = index, keys = variables_when),
    where = where,
    event = md_event(md) %||% list(state = character(), point = character())
  )
  md <- md_field_set(
    md,
    "coordinate_system",
    as_metadata_factor(coordinate_system, "coordinate_system")
  )

  out <- preserve_animovement_class(bare, cls, md)

  # Computed from the finished frame, after arranging.
  md <- md_field_set(md, "sampling_interval", compute_sampling_interval(out))
  attach_metadata(out, md)
}


#' Restructure an anievent
#'
#' Like [restructure_anipoint()], but never grouped.
#'
#' @param data An anievent object.
#' @param variables_what,variables_when The declaration to apply.
#'
#' @return `data`, restructured, with the declaration recorded.
#' @keywords internal
restructure_anievent <- function(data, variables_what, variables_when) {
  cls <- class(data)
  md <- get_metadata(data)
  bare <- strip_animovement_class(data)

  ensure_has_anievent_cols(bare)
  ensure_has_declared_cols(bare, variables_what, "what")
  ensure_has_declared_cols(
    bare,
    setdiff(variables_when, c("start", "stop")),
    "when"
  )
  bare <- standardise_anievent_cols(bare, variables_what, variables_when)

  event_cols <- c("channel", "type", "label")
  if ("modifiers" %in% names(bare)) {
    event_cols <- c(event_cols, "modifiers")
  }
  standard_cols <- c(variables_what, variables_when, event_cols)
  bare <- bare[, c(standard_cols, setdiff(names(bare), standard_cols))]

  when_grouping <- setdiff(variables_when, c("start", "stop"))
  bare <- dplyr::arrange(
    bare,
    dplyr::across(dplyr::all_of(c(variables_what, when_grouping))),
    .data$start
  )

  # No `where` and no index: bouts are delimited by `start`/`stop` (#118).
  md <- migrate_metadata_layout(md)
  md$variables <- list(
    what = list(keys = variables_what),
    when = list(
      interval = intersect(variables_when, c("start", "stop")),
      keys = setdiff(variables_when, c("start", "stop"))
    )
  )
  md <- md_field_set(md, "sampling_interval", as.numeric(NA))

  preserve_animovement_class(bare, cls, md)
}


#' Group a frame by the given columns, or ungroup it when there are none
#'
#' @param data A plain (non-animovement) data frame.
#' @param grouping_vars Character vector of columns to group by.
#'
#' @return `data`, grouped or ungrouped.
#' @keywords internal
regroup_frame <- function(data, grouping_vars) {
  if (length(grouping_vars) == 0) {
    return(dplyr::ungroup(data))
  }

  suppressWarnings(
    dplyr::group_by(data, dplyr::across(dplyr::all_of(grouping_vars)))
  )
}


#' Validate required columns for anipoint
#'
#' @param data Data frame to validate.
#' @param variables_what Identity variables.
#' @param variables_when Temporal variables.
#' @param variables_where Spatial variables.
#'
#' @keywords internal
ensure_has_anipoint_cols <- function(
  data,
  variables_what,
  variables_when,
  variables_where,
  index = "time"
) {
  ensure_has_declared_cols(data, variables_what, "what")

  if (!index %in% names(data)) {
    cli::cli_abort(
      c(
        "Index column {.val {index}} is required but not found in data.",
        "i" = "An anipoint is indexed by exactly one column.",
        "i" = "Declare a different one with {.arg index}, or {.fn set_index}."
      )
    )
  }

  ensure_has_declared_cols(data, variables_when, "when")
  ensure_has_declared_cols(data, variables_where, "where")

  invisible(TRUE)
}


#' Standardize column types for anipoint
#'
#' Identity/context columns become factor or integer; spatial become numeric.
#'
#' @param data Data frame to standardise.
#' @param variables_what Identity variable names.
#' @param variables_when Temporal variable names.
#' @param variables_where Spatial variable names.
#' @param index The index column, which stays numeric.
#'
#' @return Data frame with standardised column types.
#' @keywords internal
standardise_anipoint_cols <- function(
  data,
  variables_what,
  variables_when,
  variables_where,
  index = "time"
) {
  categorical_vars <- c(variables_what, variables_when)
  for (col in categorical_vars) {
    if (col %in% names(data)) {
      if (is.character(data[[col]])) {
        data[[col]] <- factor(data[[col]])
      } else if (is.numeric(data[[col]])) {
        data[[col]] <- as.integer(data[[col]])
      }
    }
  }

  for (col in variables_where) {
    if (col %in% names(data)) {
      data[[col]] <- as.numeric(data[[col]])
    }
  }

  data
}
