#' Validate a complete metadata list and attach it
#'
#' No field-level policy; migrates legacy flat metadata on write.
#'
#' @param data An aniframe or anievent object.
#' @param metadata A complete metadata list.
#'
#' @return `data`, with `metadata` attached.
#' @keywords internal
write_metadata <- function(data, metadata) {
  metadata <- migrate_metadata_layout(metadata, anievent = is_anievent(data))
  ensure_valid_metadata(
    metadata,
    class = if (is_anievent(data)) "anievent" else "anipoint"
  )
  ensure_valid_variables_event(md_event(metadata))
  attach_metadata(data, metadata)
}


#' Refuse the metadata fields that have their own setters
#'
#' Complete metadata objects bypass this check, so wholesale restores still
#' work (used internally and downstream, e.g. `animetric`).
#'
#' @param user_md The metadata the caller supplied.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_no_declaration_fields <- function(user_md) {
  offending <- intersect(names(user_md), list_declaration_metadata_fields())

  if (length(offending) > 0) {
    setters <- vapply(
      offending,
      function(field) {
        switch(
          field,
          variables_index = "set_index",
          variables = ,
          variables_what = ,
          variables_when = ,
          variables_where = ,
          variables_event = ,
          axes = "set_variables",
          structure = "set_connections",
          connections = "set_connections"
        )
      },
      character(1)
    )
    cli::cli_abort(c(
      # Keep ASCII: R CMD check warns on non-ASCII sources.
      "{.fn set_metadata} cannot write {.field {offending}} directly.",
      "i" = "{cli::qty(offending)}{?This entry declares/These entries declare} which columns carry identity, time, position and events, or how levels connect. Writing {cli::qty(offending)}{?it/them} here would leave the metadata naming columns the frame may not have, and the frame ordered and grouped as it was before.",
      "i" = "Use {.fn {unique(setters)}} instead, which validate the columns exist and restructure the frame to match.",
      "i" = "A complete metadata object can still be restored wholesale, as in {.code set_metadata(data, metadata = get_metadata(x))}."
    ))
  }

  invisible(TRUE)
}


#' Refuse writes addressed to a category
#'
#' Field names are unique across categories, so flat writes suffice (#118).
#'
#' @param user_md The metadata the caller supplied.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_no_category_fields <- function(user_md) {
  offending <- intersect(
    names(user_md),
    setdiff(list_metadata_categories(), c("variables", "structure"))
  )
  if (length(offending) > 0) {
    cli::cli_abort(c(
      "{.fn set_metadata} writes fields, not categories.",
      "x" = "{.val {offending}} {?is/are} categor{?y/ies}.",
      "i" = "Write the fields themselves; they are found by name wherever they live, e.g. {.code set_metadata(data, sampling_rate = 30)}."
    ))
  }
  invisible(TRUE)
}


#' Coerce a metadata value to the factor its field expects
#'
#' @param value Character or factor value.
#' @param field Name of the metadata field.
#'
#' @return A factor with the field's full set of levels.
#' @keywords internal
as_metadata_factor <- function(value, field) {
  factor(as.character(value), levels = levels(default_metadata_leaf(field)))
}


#' Set metadata
#'
#' @description
#' Sets or updates metadata for an aniframe or anievent object. Metadata
#' can be provided either as named arguments or as a list. If the object
#' already has metadata, the new values will be merged with existing
#' values, with new values taking precedence.
#'
#' Fields are written by their own name wherever they live in the
#' category tree (see [list_default_metadata()]): `set_metadata(data,
#' sampling_rate = 30)` lands in `time`, `set_metadata(data, handedness =
#' "left")` in `space`. Categories themselves are not writable, and the
#' variable declaration goes through its dedicated setters.
#'
#' Character values for factor fields will be automatically converted to
#' factors if they match allowed levels.
#'
#' @param data An aniframe or anievent object.
#' @param ... Named metadata values (e.g., `sampling_rate = 30, source = "sleap"`)
#' @param metadata Alternatively, a named list of metadata. Cannot be used
#'   simultaneously with `...`
#'
#' @return The object with updated metadata.
#'
#' @seealso [get_metadata()], [list_default_metadata()]
#'
#' @examples
#' \dontrun{
#' # Set metadata using named arguments
#' data <- set_metadata(data, sampling_rate = 30, source = "sleap")
#'
#' # Set metadata using a list
#' md <- list(sampling_rate = 30, source = "sleap")
#' data <- set_metadata(data, metadata = md)
#' }
#'
#' @export
set_metadata <- function(data, ..., metadata = NULL) {
  dot_args <- list(...)

  if (!is.null(metadata) && !rlang::is_empty(dot_args)) {
    cli::cli_abort(
      "Metadata input can only be provided as either name-value pairs *or* a list through the {.arg metadata} parameter, not both."
    )
  } else if (!is.null(metadata)) {
    user_md <- metadata
  } else if (!rlang::is_empty(dot_args)) {
    ensure_is_list(dot_args)
    user_md <- dot_args
  } else {
    user_md <- list()
  }

  # A complete metadata object is a wholesale replacement.
  if (has_all_metadata_fields(user_md)) {
    return(write_metadata(data, user_md))
  }

  ensure_no_declaration_fields(user_md)
  ensure_no_category_fields(user_md)
  ensure_are_metadata_fields(names(user_md))
  is_null <- vapply(user_md, is.null, logical(1))
  if (any(is_null)) {
    cli::cli_abort(c(
      "Metadata fields cannot be set to {.code NULL}: {.field {names(user_md)[is_null]}}.",
      "i" = "Use {.code NA} to mark a field as unknown."
    ))
  }

  for (n in names(user_md)) {
    default_val <- default_metadata_leaf(n)
    if (is.factor(default_val)) {
      if (is.character(user_md[[n]]) || is.factor(user_md[[n]])) {
        value <- as.character(user_md[[n]])
        if (length(value) != 1L || !value %in% levels(default_val)) {
          cli::cli_abort(
            "Metadata field {.field {n}} can only be {.val {levels(default_val)}} not {.val {value}}."
          )
        }
        user_md[[n]] <- factor(value, levels = levels(default_val))
      }
    } else if (is_class(default_val, "POSIXct")) {
      if (length(user_md[[n]]) == 1 && is.na(user_md[[n]])) {
        user_md[[n]] <- as.POSIXct(NA_character_)
      } else {
        user_md[[n]] <- anytime::anytime(user_md[[n]])
      }
    }
  }

  if (!has_metadata(data)) {
    new_md <- if (is_anievent(data)) {
      list_default_metadata("anievent")
    } else {
      list_default_metadata()
    }
  } else {
    new_md <- migrate_metadata_layout(
      attr(data, "metadata"),
      anievent = is_anievent(data)
    )
  }

  for (n in names(user_md)) {
    new_md <- md_field_set(new_md, n, user_md[[n]])
  }
  new_md <- check_orientation_fields(data, new_md, user_md)

  write_metadata(data, new_md)
}


#' Validate the orientation fields being written, and keep handedness in step
#'
#' @param data The frame being written to.
#' @param md The metadata about to be written.
#' @param user_md The fields the caller supplied.
#'
#' @return `md`.
#' @keywords internal
check_orientation_fields <- function(data, md, user_md) {
  if ("axis_extents" %in% names(user_md)) {
    ensure_valid_axis_extents(user_md$axis_extents)
    extents <- user_md$axis_extents
    extents <- stats::setNames(as.numeric(extents), names(extents))
    md <- md_field_set(md, "axis_extents", extents[!is.na(extents)])
    if (has_metadata(data)) {
      warn_short_axis_extents(data, md_field(md, "axis_extents"))
    }
  }
  if ("axis_directions" %in% names(user_md)) {
    directions <- user_md$axis_directions
    ensure_valid_axis_directions(directions)
    directions <- stats::setNames(as.character(directions), names(directions))
    directions <- directions[!is.na(directions)]
    md <- md_field_set(md, "axis_directions", directions)
    settled <- derive_handedness(directions)
    if (!identical(settled, "unknown") && !"handedness" %in% names(user_md)) {
      md <- md_field_set(
        md,
        "handedness",
        as_metadata_factor(settled, "handedness")
      )
    }
  }
  md
}
