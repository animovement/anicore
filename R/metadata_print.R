#' Print the metadata of a frame
#'
#' @description
#' Prints the metadata of an [anipoint()] or [anievent()] one category at a
#' time, one `name: value` line per field, wrapped to the console width.
#' Values carry their units where the metadata declares them, such as
#' `sampling_rate: 30 Hz`. Fields that are not set are left out and named
#' together on a closing line.
#'
#' `all = TRUE` prints every field, including those not set, the values each
#' factor field allows, and `spec_version`.
#'
#' @param x An `aniframe_metadata` object, as returned by [get_metadata()].
#' @param all Whether to print every field (default `FALSE`): those not set,
#'   the allowed values of factor fields, and `spec_version`.
#' @param ... Unused.
#' @return `x`, invisibly.
#'
#' @examples
#' md <- get_metadata(set_metadata(example_anipoint(), sampling_rate = 30))
#' md
#' print(md, all = TRUE)
#' @export
print.aniframe_metadata <- function(x, all = FALSE, ...) {
  width <- cli::console_width()
  out <- cli::cli_format_method({
    cli::cli_h1("animovement metadata")

    if (length(x) == 0) {
      cli::cli_alert_info("No metadata available")
    } else if (!is_nested_metadata(x)) {
      # A single field or a flat selection pulled out by name.
      unset <- print_metadata_fields(unclass(x), x, all, width)
      print_metadata_unset(unset, all, width)
    } else {
      unset <- character()
      for (category in intersect(list_metadata_categories(), names(x))) {
        unset <- c(
          unset,
          print_metadata_category(x[[category]], category, x, all, width)
        )
      }
      print_metadata_unset(unset, all, width)
      if (all && !is.null(x[["spec_version"]])) {
        versions <- x[["spec_version"]]
        cli::cli_verbatim("")
        cli::cli_verbatim(wrap_items(
          "spec_version:",
          paste(names(versions), unlist(versions)),
          width
        ))
      }
    }
  })

  cat(trimws(paste(out, collapse = "\n")), "\n", sep = "")
  invisible(x)
}


#' Print one category under its heading
#'
#' A category with nothing set gets no heading unless `all` is `TRUE`.
#'
#' @return The names of the fields not set: a field name, or `"structure"`
#'   for an empty structure category.
#' @noRd
print_metadata_category <- function(values, category, md, all, width) {
  if (identical(category, "variables")) {
    cli::cli_h3(category)
    print_metadata_variables(values)
    return(character())
  }
  if (identical(category, "structure")) {
    if (length(values) == 0) {
      if (all) {
        cli::cli_h3(category)
        cli::cli_verbatim("-")
      }
      return(category)
    }
    cli::cli_h3(category)
    print_metadata_structure(values)
    return(character())
  }
  set <- !vapply(values, is_metadata_unset, logical(1))
  if (all || any(set)) {
    cli::cli_h3(category)
  }
  print_metadata_fields(values, md, all, width)
}


#' Print fields as `name: value` lines
#'
#' @param values A named list of leaf values.
#' @param md The whole metadata, for the units a value is read in.
#'
#' @return The names of the fields not set, invisibly.
#' @noRd
print_metadata_fields <- function(values, md, all, width) {
  unset <- character()
  for (field in names(values)) {
    value <- values[[field]]
    if (is_metadata_unset(value)) {
      unset <- c(unset, field)
      if (all) {
        cli::cli_verbatim(paste0(field, ": -"))
      }
      next
    }
    items <- format_metadata_value(field, value, md)
    cli::cli_verbatim(wrap_items(paste0(field, ":"), items, width))
    if (all && is.factor(value)) {
      cli::cli_verbatim(wrap_items(
        "  levels:",
        levels(value),
        width,
        indent = 4
      ))
    }
  }
  invisible(unset)
}


#' Print the closing line naming the fields not set
#'
#' @noRd
print_metadata_unset <- function(unset, all, width) {
  if (all || length(unset) == 0) {
    return(invisible())
  }
  cli::cli_verbatim("")
  cli::cli_verbatim(wrap_items("Not set:", unset, width))
  invisible()
}


#' Is a metadata value unset: absent, empty, or all `NA`?
#'
#' @noRd
is_metadata_unset <- function(value) {
  length(value) == 0 || all(is.na(value))
}


#' Format a metadata value as the items of a comma-separated list
#'
#' Named vectors give `name = value` items. `sampling_rate` is in Hz,
#' `sampling_interval` in `unit_time` and `axis_extents` in `unit_space`.
#'
#' @param field The field's name.
#' @param value The field's value, not unset.
#' @param md The whole metadata, for the units.
#'
#' @return Character vector.
#' @noRd
format_metadata_value <- function(field, value, md) {
  value <- value[!is.na(value)]
  shown <- if (inherits(value, "POSIXt")) {
    format(value, usetz = TRUE)
  } else if (is.numeric(value)) {
    vapply(value, format, character(1))
  } else {
    as.character(value)
  }

  unit <- switch(
    field,
    sampling_rate = "Hz",
    sampling_interval = as.character(md_field(md, "unit_time") %||% NA),
    axis_extents = as.character(md_field(md, "unit_space") %||% NA),
    NA_character_
  )
  if (length(unit) == 1 && !is.na(unit) && !unit %in% c("unknown", "none")) {
    if (identical(unit, "frame")) {
      unit <- ifelse(value == 1, "frame", "frames")
    }
    shown <- paste(shown, unit)
  }

  if (!is.null(names(value)) && any(nzchar(names(value)))) {
    shown <- paste(names(value), shown, sep = " = ")
  }
  shown
}


#' Render the variables category: one line per role, slots inline
#'
#' @param variables The variables list.
#' @noRd
print_metadata_variables <- function(variables) {
  if (length(variables) == 0) {
    cli::cli_verbatim("-")
    return(invisible(variables))
  }
  name_w <- max(nchar(names(variables)))
  for (role in names(variables)) {
    slots <- variables[[role]]
    rendered <- vapply(
      names(slots),
      function(slot) {
        values <- slots[[slot]]
        shown <- if (length(values) == 0) {
          "-"
        } else if (!is.null(names(values)) && any(nzchar(names(values)))) {
          paste(names(values), values, sep = " = ", collapse = ", ")
        } else {
          paste(values, collapse = ", ")
        }
        paste0(slot, ": ", shown)
      },
      character(1)
    )
    cli::cli_verbatim(paste0(
      format(role, width = name_w),
      "  ",
      paste(rendered, collapse = " | ")
    ))
  }
  invisible(variables)
}


#' Render the structure category: one line per structure
#'
#' `name: 11 points, 10 segments, 3 joints`, naming the variable only when
#' it differs from the name.
#'
#' @param structure The structure list.
#' @noRd
print_metadata_structure <- function(structure) {
  for (name in names(structure)) {
    s <- structure[[name]]
    label <- if (identical(s$variable, name) || is.na(s$variable)) {
      name
    } else {
      paste0(name, " (over ", s$variable, ")")
    }
    cli::cli_verbatim(paste0(label, ": ", format_structure_counts(s)))
  }
  invisible(structure)
}
