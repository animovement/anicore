#' Validate a metadata tree
#'
#' @param metadata A metadata list in the category layout.
#' @param space Whether the `space` category is required (`TRUE`, the
#'   anipoint contract) or must be absent (`FALSE`, the anievent one).
#'
#' @return Invisibly `TRUE`; errors otherwise.
#' @keywords internal
ensure_valid_metadata <- function(metadata, space = TRUE) {
  ensure_is_list(metadata)
  ensure_has_all_metadata_fields(metadata)

  if (isTRUE(space) && !"space" %in% names(metadata)) {
    cli::cli_abort(
      "The metadata carries no {.field space} category, which an {.cls anipoint} requires."
    )
  }
  if (!isTRUE(space) && "space" %in% names(metadata)) {
    cli::cli_abort(c(
      "An {.cls anievent} has no spatial component, so its metadata must not carry a {.field space} category (#73).",
      "i" = "Position lives on the {.cls anipoint} it was encoded from."
    ))
  }

  ensure_valid_metadata_types(metadata)
  ensure_valid_metadata_variables(metadata)
}


# Leaves added after the initial schema. Their absence is tolerated on
# read so previously serialised objects continue to validate; new objects
# always have them via `list_default_metadata()`.
list_optional_metadata_fields <- function() {
  c("source_format", "sampling_interval")
}

# Normalise user-supplied `variables_event` into canonical form. Accepts
# partial input — supplying only `state` or only `point` is fine, and the
# missing side defaults to `character()`. `NULL`, empty, and all-`NA`
# entries collapse to `character()` so callers can write
# `list(point = "call")` or `list(state = "x", point = NA)` without having
# to spell out both sides or wrap values in `as.character()`. Genuinely
# wrong types (e.g. integers) are left untouched for the validator to
# reject. Stored metadata always carries both entries as character vectors.
normalise_variables_event_entry <- function(v) {
  if (is.null(v) || length(v) == 0L || all(is.na(v))) {
    return(character())
  }
  if (is.character(v)) {
    return(v[!is.na(v)])
  }
  v
}

normalise_variables_event <- function(x) {
  if (is.null(x) || !is.list(x)) {
    return(x)
  }
  list(
    state = normalise_variables_event_entry(x$state),
    point = normalise_variables_event_entry(x$point)
  )
}

# Structural check for the event role: must be a list with character
# vectors at `$state` and `$point`, and the two sets must not overlap (a
# column cannot be both state and point).
ensure_valid_variables_event <- function(x) {
  if (is.null(x)) {
    return(invisible())
  }
  if (!is.list(x) || !all(c("state", "point") %in% names(x))) {
    cli::cli_abort(c(
      "{.field variables_event} must be a list with entries {.val state} and {.val point}.",
      "i" = "Got names: {.val {names(x)}}."
    ))
  }
  if (!is.character(x$state) || !is.character(x$point)) {
    cli::cli_abort(
      "Both {.field variables_event$state} and {.field variables_event$point} must be character vectors."
    )
  }
  overlap <- intersect(x$state, x$point)
  if (length(overlap) > 0) {
    cli::cli_abort(c(
      "A column cannot be both a state and a point event variable.",
      "x" = "Overlapping: {.val {overlap}}."
    ))
  }
  invisible()
}

# ------------------------------------------------------------------
# Does the object have a "metadata" attribute?
# ------------------------------------------------------------------
has_metadata <- function(data) {
  "metadata" %in% names(attributes(data)) |> invisible()
}

ensure_has_metadata <- function(data) {
  if (!has_metadata(data)) {
    cli::cli_abort(
      "Metadata hasn't been initiated. Initialise it with {.fn set_metadata}."
    )
  }
}

# ------------------------------------------------------------------
# Is the "metadata" attribute a list?
# ------------------------------------------------------------------
is_list <- function(x) {
  is.list(x) && !is.data.frame(x) |> invisible()
}

ensure_is_list <- function(x) {
  if (!is_list(x)) {
    cli::cli_abort(
      "Metadata should be a list, but it is of class {class(x)}."
    )
  }
}

# ------------------------------------------------------------------
# Are all the necessary categories and leaves present?
# ------------------------------------------------------------------
# A complete metadata object has the category tree — `space` optional,
# since only some classes carry it — plus `spec_version`. A complete
# *legacy flat* list (all of the old mandatory fields) also counts, so
# the wholesale-restore path accepts objects serialised before the
# categories existed; the write path migrates them.
has_all_metadata_fields <- function(metadata) {
  if (is_nested_metadata(metadata)) {
    mandatory_categories <- setdiff(list_metadata_categories(), "space")
    return(
      all(mandatory_categories %in% names(metadata)) |> invisible()
    )
  }
  legacy_mandatory <- c(
    "source",
    "source_version",
    "filename",
    "sampling_rate",
    "start_datetime",
    "variables_what",
    "variables_when",
    "variables_where",
    "unit_space",
    "unit_angle",
    "unit_time",
    "reference_frame",
    "coordinate_system",
    "axis_directions",
    "axis_extents",
    "handedness",
    "connections"
  )
  all(legacy_mandatory %in% names(metadata)) |> invisible()
}

ensure_has_all_metadata_fields <- function(metadata) {
  if (!has_all_metadata_fields(metadata)) {
    cli::cli_abort(
      "The object does not have the mandatory metadata fields."
    )
  }
}

# ------------------------------------------------------------------
# Are all the leaves of the correct class?
# ------------------------------------------------------------------
has_valid_metadata_types <- function(metadata) {
  field_categories <- list_metadata_field_categories()
  for (nm in names(field_categories)) {
    category <- field_categories[[nm]]
    if (!category %in% names(metadata)) {
      next
    }
    if (!nm %in% names(metadata[[category]])) {
      if (nm %in% list_optional_metadata_fields()) {
        next
      }
      return(invisible(FALSE))
    }
    user_val <- metadata[[category]][[nm]]
    default_val <- default_metadata_leaf(nm)

    # Allow NA for any field (NA values can have any class)
    if (length(user_val) == 1 && is.na(user_val)) {
      next
    }
    if (!identical(class(user_val), class(default_val))) {
      return(invisible(FALSE))
    }
  }
  invisible(TRUE)
}

ensure_valid_metadata_types <- function(metadata) {
  if (!has_valid_metadata_types(metadata)) {
    cli::cli_abort(
      "Metadata fields are not of the correct types."
    )
  }
}

# ------------------------------------------------------------------
# Is the variables category well-shaped?
# ------------------------------------------------------------------
# Roles are lists of named slots; every slot is a character vector. The
# closed sets: roles from (what, when, where, event); slots per role as
# below. `where$position` may carry names (axis roles) or not (columns
# whose roles are unknown).
ensure_valid_metadata_variables <- function(metadata) {
  variables <- metadata[["variables"]]
  if (!is.list(variables)) {
    cli::cli_abort(
      "The {.field variables} category must be a list of roles."
    )
  }
  known_slots <- list(
    what = "keys",
    when = c("index", "interval", "keys"),
    where = c("position", "orientation"),
    event = c("state", "point")
  )
  unknown_roles <- setdiff(names(variables), names(known_slots))
  if (length(unknown_roles) > 0L) {
    cli::cli_abort(
      "Unknown variable role{?s}: {.val {unknown_roles}}."
    )
  }
  for (role in names(variables)) {
    slots <- variables[[role]]
    if (!is.list(slots)) {
      cli::cli_abort(
        "The {.field {role}} role must be a list of slots."
      )
    }
    unknown <- setdiff(names(slots), known_slots[[role]])
    if (length(unknown) > 0L) {
      cli::cli_abort(
        "{cli::qty(unknown)}Unknown slot{?s} for the {.field {role}} role: {.val {unknown}}."
      )
    }
    is_character <- vapply(slots, is.character, logical(1))
    if (!all(is_character)) {
      cli::cli_abort(
        "Every slot of the {.field {role}} role must be a character vector."
      )
    }
  }
  invisible(TRUE)
}
