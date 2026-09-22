# Restructuring a frame to match its declaration (#82)
#
# Split out of `variables.R`, which had grown to hold both the declaration
# vocabulary and the machinery that rebuilds a frame against it. This is
# the machinery: validate the declared columns exist, standardise their
# types, relocate, arrange, regroup, and refresh the derived fields.
#
# Construction and re-declaration both come through here, so they cannot
# drift apart.

#' Restructure a frame to match a declaration
#'
#' Dispatches to the per-class restructure. The two classes share the
#' metadata substrate but not their layout: an anipoint is grouped and
#' ordered by identity then time, an anievent is ordered by identity then
#' bout start and is never grouped.
#'
#' @param data An aniframe or anievent object.
#' @param variables_what,variables_when,variables_where The full
#'   declaration to apply.
#'
#' @return `data`, restructured, with the declaration recorded.
#' @keywords internal
restructure_frame <- function(
  data,
  variables_what,
  variables_when,
  variables_where,
  strict = TRUE
) {
  if (is_anievent(data)) {
    if (length(variables_where) > 0) {
      cli::cli_abort(c(
        "An {.cls anievent} has no spatial variables.",
        "i" = "{.field variables_where} is always empty on an anievent; spatial position lives on the {.cls anipoint} it was encoded from."
      ))
    }
    return(restructure_anievent(data, variables_what, variables_when))
  }

  restructure_anipoint(
    data,
    variables_what,
    variables_when,
    variables_where,
    strict = strict
  )
}


#' Strip a frame back to its dplyr classes
#'
#' The structural steps operate on a plain frame, so they neither
#' dispatch back into the class-preserving methods nor trigger the
#' `ungroup()` "use with care" warning when a declaration leaves nothing
#' to group by.
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
#' The tail of [as_anipoint()], factored out so that construction and
#' re-declaration cannot drift apart: validate the declared columns
#' exist, standardise their types, relocate, arrange, regroup, and
#' refresh the derived `coordinate_system`.
#'
#' @param data An anipoint object.
#' @param variables_what,variables_when,variables_where The declaration
#'   to apply.
#'
#' @return `data`, restructured, with the declaration recorded.
#' @keywords internal
restructure_anipoint <- function(
  data,
  variables_what,
  variables_when,
  variables_where,
  strict = TRUE
) {
  cls <- class(data)
  md <- get_metadata(data)
  index <- resolve_index(md)
  bare <- strip_animovement_class(data)

  # The index is declared separately and is never one of the context
  # variables. Normalising here rather than at each caller keeps frames
  # built before the field existed coherent too: their `variables_when`
  # still lists the index column, and grouping by it would put every row
  # in its own group.
  variables_when <- setdiff(variables_when, index)

  # Roles decide the coordinate system; columns are what the frame is
  # restructured against. An explicit role mapping is validated strictly —
  # a bad role is named here rather than degrading the frame to "unknown"
  # and failing in whichever spatial function the user reaches first (#109).
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

  # Column order: what, when, index, where, confidence, everything else.
  standard_cols <- unique(
    c(variables_what, variables_when, index, where_cols)
  )
  if ("confidence" %in% names(bare)) {
    standard_cols <- c(standard_cols, "confidence")
  }
  bare <- bare[, c(standard_cols, setdiff(names(bare), standard_cols))]

  # Order by identity, then temporal context, then position within it —
  # the index sorts last, which keeps each trajectory contiguous.
  bare <- dplyr::arrange(
    bare,
    dplyr::across(dplyr::all_of(variables_what)),
    dplyr::across(dplyr::all_of(c(variables_when, index)))
  )

  # Group by identity + temporal context. `variables_when` is exactly the
  # context now, so there is nothing to exclude — the index is not in it.
  grouping_vars <- c(variables_what, variables_when)
  bare <- regroup_frame(bare, grouping_vars)

  coordinate_system <- infer_coordinate_system(axes)

  # `where$position` carries the role mapping when the coordinate system
  # is known, and the bare columns when it is not — the roles cannot
  # drift from the columns because they are one slot.
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
  md$variables <- list(
    what = list(keys = variables_what),
    when = list(index = index, keys = variables_when),
    where = list(position = position),
    event = md_event(md) %||% list(state = character(), point = character())
  )
  md <- md_field_set(
    md,
    "coordinate_system",
    as_metadata_factor(coordinate_system, "coordinate_system")
  )

  out <- preserve_animovement_class(bare, cls, md)

  # Derived from the finished frame, so it measures the data as it now is.
  md <- md_field_set(md, "sampling_interval", compute_sampling_interval(out))
  attach_metadata(out, md)
}


#' Restructure an anievent
#'
#' The anievent counterpart to [restructure_anipoint()]: validate,
#' standardise types, relocate, and order by identity then bout start.
#' An anievent is not grouped.
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

  # An anievent has no `where` role and no index: a bout is delimited by
  # `start` and `stop`, which get the `interval` slot the flat vector
  # could never express (#118). Position lives on the anipoint it was
  # encoded from, so `space` stays absent too.
  md <- migrate_metadata_layout(md)
  md$variables <- list(
    what = list(keys = variables_what),
    when = list(
      interval = intersect(variables_when, c("start", "stop")),
      keys = setdiff(variables_when, c("start", "stop"))
    )
  )
  # No index, so nothing to measure a sampling interval from.
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
  # All declared variables must exist. Declaring a column that isn't
  # there leaves the metadata describing a frame it doesn't have.
  ensure_has_declared_cols(data, variables_what, "what")

  # The frame needs an index. Which column that is comes from the
  # declaration; `time` is only its default (#109).
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
#' Converts character identity and temporal variables to factors.
#' Converts numeric identity and temporal variables (except the index) to
#' integers.
#' Spatial variables are converted to numeric.
#'
#' @param data Data frame to standardise.
#' @param variables_what Identity variable names.
#' @param variables_when Temporal variable names.
#' @param variables_where Spatial variable names.
#' @param index The index column, which stays numeric. The temporal
#'   context variables are made categorical.
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
  # What and when variables (except time) should be categorical or integer
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

  # Convert spatial variables to numeric
  for (col in variables_where) {
    if (col %in% names(data)) {
      data[[col]] <- as.numeric(data[[col]])
    }
  }

  data
}
