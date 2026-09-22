#' Print method for animovement metadata
#'
#' Renders the metadata grouped by category (#118): `spec_version` at the
#' top, then one section per category. Leaf names and types are padded to
#' fixed widths so the values line up, similar to [str()]. The
#' `variables` category prints one line per role, its slots inline.
#'
#' The S3 class is named `aniframe_metadata` for historical reasons,
#' but the metadata substrate is shared by both [anipoint()] and
#' [anievent()] objects.
#'
#' @param x An `aniframe_metadata` list.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @keywords internal
#' @export
print.aniframe_metadata <- function(x, ...) {
  out <- cli::cli_format_method({
    cli::cli_h1("animovement metadata")

    if (length(x) == 0) {
      cli::cli_alert_info("No metadata available")
    } else if (!is_nested_metadata(x)) {
      # A single field or a flat selection pulled out by name.
      print_metadata_leaves(unclass(x))
    } else {
      if (!is.null(x[["spec_version"]])) {
        versions <- x[["spec_version"]]
        cli::cli_verbatim(paste0(
          "spec_version: ",
          paste(names(versions), unlist(versions), sep = " ", collapse = ", ")
        ))
      }
      for (category in intersect(list_metadata_categories(), names(x))) {
        cli::cli_h3(category)
        if (identical(category, "variables")) {
          print_metadata_variables(x[[category]])
        } else if (identical(category, "structure")) {
          print_metadata_structure(x[[category]])
        } else {
          print_metadata_leaves(x[[category]])
        }
      }
    }
  })

  cat(trimws(paste(out, collapse = "\n")), "\n", sep = "")
  invisible(x)
}


#' Render one category's leaves as aligned name/type/value lines
#'
#' @param x A named list of leaf values.
#' @keywords internal
print_metadata_leaves <- function(x) {
  if (length(x) == 0) {
    cli::cli_verbatim("(empty)")
    return(invisible(x))
  }
  nm <- names(x)
  types <- vapply(x, function(v) class(v)[1], character(1))
  name_w <- max(nchar(nm))
  type_w <- max(nchar(types)) + 3 # for the wrapping "(...)"
  indent <- strrep(" ", name_w + 1 + type_w + 2) # value column

  for (i in seq_along(x)) {
    name <- nm[i]
    value <- x[[i]]
    value_class <- types[i]

    padded_name <- format(name, width = name_w)
    padded_type <- format(
      paste0("(", value_class, ")"),
      width = type_w
    )

    if (length(value) == 0) {
      cli::cli_verbatim(paste0(padded_name, " ", padded_type, ": "))
    } else if (length(value) == 1 && is.na(value)) {
      cli::cli_verbatim(paste0(padded_name, " ", padded_type, ": <NA>"))
    } else if (is.factor(value)) {
      cli::cli_verbatim(paste0(
        padded_name,
        " ",
        padded_type,
        ': "',
        as.character(value),
        '"'
      ))
      cli::cli_verbatim(paste0(
        indent,
        "[levels: ",
        paste(levels(value), collapse = ", "),
        "]"
      ))
    } else if (length(value) > 1) {
      cli::cli_verbatim(paste0(
        padded_name,
        " ",
        padded_type,
        ': "',
        paste(value, collapse = ", "),
        '"'
      ))
    } else {
      val_str <- if (is.character(value)) {
        paste0('"', value, '"')
      } else {
        format(value)
      }
      cli::cli_verbatim(paste0(
        padded_name,
        " ",
        padded_type,
        ": ",
        val_str
      ))
    }
  }
  invisible(x)
}


#' Render the variables category: one line per role, slots inline
#'
#' @param variables The variables list.
#' @keywords internal
print_metadata_variables <- function(variables) {
  if (length(variables) == 0) {
    cli::cli_verbatim("(empty)")
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


#' Render the structure category: one line per keyed variable
#'
#' @param structure The structure list.
#' @keywords internal
print_metadata_structure <- function(structure) {
  if (length(structure) == 0) {
    cli::cli_verbatim("(empty)")
    return(invisible(structure))
  }
  for (variable in names(structure)) {
    entry <- structure[[variable]]
    n <- if (is.data.frame(entry)) nrow(entry) else length(entry)
    cli::cli_verbatim(paste0(
      variable,
      ": ",
      n,
      " connection",
      if (n == 1) "" else "s"
    ))
  }
  invisible(structure)
}
