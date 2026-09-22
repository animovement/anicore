#' Print method for animovement metadata
#'
#' Renders the metadata as a single block, captured via
#' [cli::cli_format_method()] and emitted with [cat()]. Field names
#' and types are padded to fixed widths so the values line up in
#' aligned columns, similar to [str()].
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
    } else {
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
    }
  })

  cat(trimws(paste(out, collapse = "\n")), "\n", sep = "")
  invisible(x)
}
