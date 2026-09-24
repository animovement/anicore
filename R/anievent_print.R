#' Custom tibble summary for anievent
#'
#' Print header rows: identity columns, event channels and sampling rate.
#'
#' @param x An anievent object.
#' @param ... Additional arguments (unused).
#' @return Named character vector with summary information.
#' @importFrom pillar tbl_sum
#' @keywords internal
#' @export
tbl_sum.anievent <- function(x, ...) {
  default_header <- NextMethod()
  names(default_header)[1] <- "anievent"

  md <- get_metadata(x)
  new_header <- default_header

  identity_vars <- intersect(md_what_keys(md), names(x))
  for (col in identity_vars) {
    new_header <- c(
      new_header,
      stats::setNames(
        paste(unique(x[[col]]), collapse = ", "),
        format_plural_title(col)
      )
    )
  }

  if ("channel" %in% names(x) && nrow(x) > 0) {
    channels <- unique(x[["channel"]])
    new_header <- c(
      new_header,
      "Event channels" = paste(channels, collapse = ", ")
    )
  }

  if ("type" %in% names(x) && nrow(x) > 0) {
    counts <- table(as.character(x[["type"]]))
    parts <- character()
    if ("state" %in% names(counts)) {
      parts <- c(parts, paste0(counts[["state"]], " state"))
    }
    if ("point" %in% names(counts)) {
      parts <- c(parts, paste0(counts[["point"]], " point"))
    }
    if (length(parts) > 0) {
      new_header <- c(
        new_header,
        "Event types" = paste(parts, collapse = ", ")
      )
    }
  }

  sampling_rate <- md_field(md, "sampling_rate")
  if (!is.null(sampling_rate) && !is.na(sampling_rate)) {
    new_header <- c(new_header, "Sampling rate" = paste(sampling_rate, "Hz"))
  }

  new_header
}
