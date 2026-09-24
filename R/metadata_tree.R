# Metadata is stored nested by category but accessed flat (#118); this file is
# the only place that knows the layout.

#' The metadata categories
#'
#' @return Character vector of category names.
#' @keywords internal
list_metadata_categories <- function() {
  c("recording", "time", "space", "variables", "structure")
}


#' Which category each flat-addressable field lives in
#'
#' `variables` slots are absent: `keys` is ambiguous between `what` and `when`.
#'
#' @return Named character vector, field name to category.
#' @keywords internal
list_metadata_field_categories <- function() {
  c(
    source = "recording",
    source_version = "recording",
    source_format = "recording",
    filename = "recording",
    unit_time = "time",
    sampling_rate = "time",
    sampling_interval = "time",
    start_datetime = "time",
    coordinate_system = "space",
    reference_frame = "space",
    handedness = "space",
    axis_directions = "space",
    axis_extents = "space",
    unit_space = "space",
    unit_angle = "space"
  )
}


#' Is this metadata list in the nested (category) layout?
#'
#' @param md A metadata list.
#'
#' @return Logical scalar.
#' @keywords internal
is_nested_metadata <- function(md) {
  is.list(md) && any(list_metadata_categories() %in% names(md))
}


#' Read one flat-addressable field from a metadata list
#'
#' Legacy flat metadata is read directly; a missing category gives `NULL`.
#'
#' @param md A metadata list.
#' @param field Length-one character.
#'
#' @return The field's value, or `NULL`.
#' @keywords internal
md_field <- function(md, field) {
  md <- unclass(md)
  if (!is_nested_metadata(md)) {
    return(md[[field]])
  }
  if (identical(field, "spec_version")) {
    return(md[["spec_version"]])
  }
  categories <- list_metadata_field_categories()
  if (!field %in% names(categories)) {
    return(NULL)
  }
  md[[categories[[field]]]][[field]]
}


#' Flat resolution for `$` and `[[` on the classed metadata object
#'
#' Fields resolve through the category tree (#155); a category name returns
#' the whole category.
#'
#' @param x An `aniframe_metadata` object.
#' @param name,i The entry to read.
#'
#' @return The entry's value, or `NULL`.
#' @keywords internal
#' @export
`$.aniframe_metadata` <- function(x, name) {
  get_metadata_entry(unclass(x), name)
}

#' @rdname cash-.aniframe_metadata
#' @keywords internal
#' @export
`[[.aniframe_metadata` <- function(x, i, ...) {
  if (is.character(i) && length(i) == 1L) {
    return(get_metadata_entry(unclass(x), i))
  }
  .subset2(x, i)
}

#' @rdname cash-.aniframe_metadata
#' @param value The value to write.
#' @keywords internal
#' @export
`$<-.aniframe_metadata` <- function(x, name, value) {
  set_metadata_entry(x, name, value)
}

#' @rdname cash-.aniframe_metadata
#' @keywords internal
#' @export
`[[<-.aniframe_metadata` <- function(x, i, ..., value) {
  if (is.character(i) && length(i) == 1L) {
    return(set_metadata_entry(x, i, value))
  }
  cls <- class(x)
  x <- unclass(x)
  x[[i]] <- value
  class(x) <- cls
  x
}

#' Write a category or flat field on the classed metadata object
#'
#' @keywords internal
set_metadata_entry <- function(md, name, value) {
  cls <- class(md)
  md <- unclass(md)
  if (name %in% c("spec_version", list_metadata_categories())) {
    md[[name]] <- value
  } else {
    md <- md_field_set(md, name, value)
  }
  class(md) <- cls
  md
}


#' Write one flat-addressable field into a metadata list
#'
#' Refuses a category the object lacks (e.g. `space` on an anievent, #73).
#'
#' @param md A metadata list in the nested layout.
#' @param field Length-one character.
#' @param value The value to store.
#'
#' @return `md`, with the field written.
#' @keywords internal
md_field_set <- function(md, field, value, call = rlang::caller_env()) {
  if (identical(field, "spec_version")) {
    md[["spec_version"]] <- value
    return(md)
  }
  categories <- list_metadata_field_categories()
  if (!field %in% names(categories)) {
    cli::cli_abort("{.val {field}} is not a metadata field.", call = call)
  }
  category <- categories[[field]]
  if (!category %in% names(md)) {
    cli::cli_abort(
      c(
        "This object carries no {.field {category}} category, so {.field {field}} cannot be set on it.",
        "i" = "An {.cls anievent} has no spatial component; {.field space} is absent by design (#73)."
      ),
      call = call
    )
  }
  md[[category]][[field]] <- value
  md
}


#' The variables category, in canonical list shape (legacy metadata translated)
#'
#' @param md A metadata list.
#'
#' @return A named list of roles (`what`, `when`, `where`, `event`), each
#'   a named list of slots.
#' @keywords internal
md_variables <- function(md) {
  md <- unclass(md)
  if (is_nested_metadata(md)) {
    return(md[["variables"]])
  }

  when_cols <- as.character(md[["variables_when"]] %||% character())
  when_cols <- when_cols[!is.na(when_cols)]
  interval <- intersect(c("start", "stop"), when_cols)
  variables <- list(
    what = list(
      keys = as.character(md[["variables_what"]] %||% character())
    ),
    when = if (length(interval) == 2L) {
      list(interval = interval, keys = setdiff(when_cols, interval))
    } else {
      # Before #109 the index sat in variables_when.
      index <- resolve_index(md)
      list(index = index, keys = setdiff(when_cols, index))
    },
    where = list(position = legacy_where_position(md)),
    event = md[["variables_event"]] %||%
      list(state = character(), point = character())
  )
  variables
}


#' The spatial declaration of a legacy flat metadata list
#'
#' `axes` wins over `variables_where` where it exists.
#'
#' @param md A metadata list in the legacy flat layout.
#'
#' @return Character vector, named by role when roles are known.
#' @keywords internal
legacy_where_position <- function(md) {
  axes <- md[["axes"]]
  if (!is.null(axes) && length(axes) > 0L && !is.null(names(axes))) {
    return(stats::setNames(as.character(axes), names(axes)))
  }
  declared <- as.character(md[["variables_where"]] %||% character())
  declared[!is.na(declared)]
}


#' @keywords internal
md_what_keys <- function(md) {
  as.character(md_variables(md)$what$keys %||% character())
}

#' @keywords internal
md_when_keys <- function(md) {
  as.character(md_variables(md)$when$keys %||% character())
}
#' @keywords internal
md_event <- function(md) {
  md_variables(md)$event
}

#' @keywords internal
md_where_position <- function(md) {
  position <- md_variables(md)$where$position %||% character()
  position <- position[!is.na(position)]
  as.character(position) |> stats::setNames(names(position))
}


#' Migrate a legacy flat metadata list to the category layout
#'
#' @param md A metadata list, flat or nested.
#' @param anievent Whether the metadata belongs to an anievent. `NULL`
#'   infers it from a `start`/`stop` interval in `variables_when`.
#'
#' @return The metadata in the nested layout.
#' @keywords internal
migrate_metadata_layout <- function(md, anievent = NULL) {
  if (is_nested_metadata(md)) {
    return(md)
  }
  md <- unclass(md)

  variables <- md_variables(md)
  anievent <- anievent %||% (length(variables$when$interval) == 2L)
  class <- if (anievent) "anievent" else "anipoint"

  out <- list(
    spec_version = unclass(list_default_metadata(class))[["spec_version"]]
  )
  categories <- list_metadata_field_categories()
  for (category in c("recording", "time", "space")) {
    fields <- names(categories)[categories == category]
    out[[category]] <- md[intersect(fields, names(md))]
  }
  out$variables <- variables
  out$structure <- md[["connections"]] %||% list()

  if (anievent) {
    out$space <- NULL
    out$variables <- variables[c("what", "when")]
  }

  class(out) <- "aniframe_metadata"
  out
}
