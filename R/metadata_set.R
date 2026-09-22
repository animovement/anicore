#' Validate a complete metadata list and attach it
#'
#' The write path shared by [set_metadata()] and the internal callers
#' that legitimately write structural fields — the constructors and the
#' variable setters. Unlike [set_metadata()] it applies no field-level
#' policy: the caller has already decided what the metadata should be.
#' Metadata still in the legacy flat layout is migrated to the category
#' tree here, so a write is what upgrades an old serialised object.
#'
#' @param data An aniframe or anievent object.
#' @param metadata A complete metadata list.
#'
#' @return `data`, with `metadata` attached.
#' @keywords internal
write_metadata <- function(data, metadata) {
  metadata <- migrate_metadata_layout(metadata)
  ensure_valid_metadata(metadata, space = !is_anievent(data))
  ensure_valid_variables_event(md_event(metadata))
  attach_metadata(data, metadata)
}


#' Refuse the metadata fields that have their own setters
#'
#' [set_metadata()] writes the metadata list and nothing else, which is
#' what makes it safe to use everywhere. The variable declaration needs
#' more than that: it names columns, so the names have to be checked
#' against the frame, and for the three structural roles the frame has to
#' be retyped, reordered, regrouped and its derived fields refreshed.
#' Writing it — as an old flat field, or as the `variables` or
#' `structure` category — is therefore refused, and the dedicated
#' setters do the job instead.
#'
#' Restoring a **complete** metadata object is a different operation, and
#' is allowed — [set_metadata()] hands it to [write_metadata()] before
#' this check runs. Rebuilding a frame and putting its metadata back is
#' the round-trip the class-preserving methods perform internally, and
#' downstream packages do it too — `animetric::summarise_keypoints()`
#' recomputes a frame and restores the metadata it captured beforehand.
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
          variables = "set_variables_what",
          axes = "set_axes",
          structure = "set_connections",
          connections = "set_connections",
          paste0("set_", field)
        )
      },
      character(1)
    )
    cli::cli_abort(c(
      # Message strings are code, not comments, so they must stay ASCII:
      # R CMD check warns on non-ASCII in R sources, and CI errors on
      # warnings.
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
#' Nested writes were considered and rejected on #118: field names are
#' unique across the categories, so a flat write is unambiguous, and a
#' category write would hand `set_metadata()` a merge policy it should
#' not have. (`variables` and `structure` are refused with their own
#' message by [ensure_no_declaration_fields()].)
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
  # ------------------------------------------------------------------
  # Process the inputs
  # ------------------------------------------------------------------
  dot_args <- list(...)

  # Ensure that the user provides input with *either* ... or a metadata list
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

  # ------------------------------------------------------------------
  # A complete metadata object is a wholesale replacement
  # ------------------------------------------------------------------
  if (has_all_metadata_fields(user_md)) {
    return(write_metadata(data, user_md))
  }

  # ------------------------------------------------------------------
  # Refuse the entries that have their own setters, and categories
  # ------------------------------------------------------------------
  ensure_no_declaration_fields(user_md)
  ensure_no_category_fields(user_md)
  ensure_are_metadata_fields(names(user_md))

  # ------------------------------------------------------------------
  # Convert character values to factors where appropriate
  # ------------------------------------------------------------------
  for (n in names(user_md)) {
    default_val <- default_metadata_leaf(n)
    if (is.factor(default_val)) {
      if (is.character(user_md[[n]]) || is.factor(user_md[[n]])) {
        value <- as.character(user_md[[n]])
        if (!value %in% levels(default_val)) {
          cli::cli_abort(
            "Metadata field {.field {n}} can only be {.val {levels(default_val)}} not {.val {value}}."
          )
        }
        user_md[[n]] <- factor(value, levels = levels(default_val))
      }
    } else if (is_class(default_val, "POSIXct")) {
      if (length(user_md[[n]]) == 1 && is.na(user_md[[n]])) {
        # Convert NA to POSIXct NA to maintain correct class
        user_md[[n]] <- as.POSIXct(NA_character_)
      } else {
        user_md[[n]] <- anytime::anytime(user_md[[n]])
      }
    }
  }

  # ------------------------------------------------------------------
  # Does the data have metadata or not?
  # ------------------------------------------------------------------
  if (!has_metadata(data)) {
    new_md <- if (is_anievent(data)) {
      list_default_metadata("anievent")
    } else {
      list_default_metadata()
    }
  } else {
    new_md <- migrate_metadata_layout(attr(data, "metadata"))
  }

  # ------------------------------------------------------------------
  # Write each field into its category and attach
  # ------------------------------------------------------------------
  for (n in names(user_md)) {
    new_md <- md_field_set(new_md, n, user_md[[n]])
  }

  write_metadata(data, new_md)
}
