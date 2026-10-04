#' Convert NaN to NA in numeric columns
#'
#' Replaces all `NaN` values with `NA` in numeric columns of a data frame.
#'
#' @param data A data frame.
#' @return A data frame with `NaN` values replaced by `NA` in numeric columns.
#' @examples
#' df <- data.frame(x = c(1, NaN, 3))
#' convert_nan_to_na(df)
#' @export
convert_nan_to_na <- function(data) {
  dplyr::mutate(
    data,
    dplyr::across(dplyr::where(is.numeric), function(x) {
      ifelse(is.nan(x), NA, x)
    })
  )
}

#' Convert Inf to NA in numeric columns
#'
#' Replaces all `Inf` and `-Inf` values with `NA` in numeric columns of a
#' data frame. The sibling of [convert_nan_to_na()], for sources that mark a
#' missing observation with an infinity rather than a `NaN` — TRex is one,
#' and its own documentation masks `np.inf` out before plotting.
#'
#' Worth doing at read time rather than later: an `Inf` propagates through
#' arithmetic silently, so a single untracked frame turns a mean, a speed or
#' a bounding box into `Inf` rather than into a missing value.
#'
#' @param data A data frame.
#' @return A data frame with `Inf` and `-Inf` replaced by `NA` in numeric
#'   columns.
#' @examples
#' df <- data.frame(x = c(1, Inf, -Inf, 3))
#' convert_inf_to_na(df)
#' @export
convert_inf_to_na <- function(data) {
  dplyr::mutate(
    data,
    dplyr::across(dplyr::where(is.numeric), function(x) {
      ifelse(is.infinite(x), NA, x)
    })
  )
}

#' Identity variable names recognised across the animovement classes
#'
#' Listed coarsest first. This is detection order, not a hierarchy:
#' identity variables need not nest, so never read a position in
#' `variables_what` as a level.
#'
#' @return Character vector of column names.
#' @keywords internal
list_recognised_variables_what <- function() {
  c("model", "individual", "subject", "track", "keypoint")
}

#' Classes owned by dplyr, tibble and base R
#'
#' Never restored from the input, or e.g. [dplyr::ungroup()] would re-group.
#'
#' @return Character vector of class names.
#' @keywords internal
list_base_frame_classes <- function() {
  c("grouped_df", "rowwise_df", "tbl_df", "tbl", "data.frame")
}

#' Re-clothe a dispatched result with its animovement classes and metadata
#'
#' Restores the incoming class stack, so downstream subclasses survive
#' without registering their own methods.
#'
#' @param x The bare result returned by `NextMethod()`.
#' @param cls Class vector of the original input, captured before dispatch.
#' @param md Metadata captured before dispatch via [get_metadata()].
#'
#' A result that has lost a column the frame is keyed, indexed or bounded by
#' is no longer that frame: it comes back as the plain data frame, without
#' metadata that would describe columns it does not have (#178).
#'
#' @return `x` with the animovement classes and metadata restored, or `x`
#'   without them when it lacks a column from [list_frame_columns()].
#' @keywords internal
preserve_animovement_class <- function(x, cls, md) {
  if (!all(list_frame_columns(md) %in% names(x))) {
    x <- strip_animovement_class(x)
    attr(x, "metadata") <- NULL
    return(x)
  }
  # Keep original order so subclasses stay ahead of `aniframe`.
  animovement_cls <- setdiff(cls, list_base_frame_classes())
  class(x) <- c(animovement_cls, setdiff(class(x), animovement_cls))
  write_metadata(x, md)
}


#' The columns a frame cannot lose
#'
#' Its identity and temporal keys, its index, and an anievent's interval
#' bounds. Dropping a declared value column (a position, an orientation)
#' leaves a frame that can still be re-declared, so those are not listed.
#'
#' @param md A metadata list, or `NULL`.
#'
#' @return Character vector of column names.
#' @keywords internal
list_frame_columns <- function(md) {
  if (is.null(md)) {
    return(character())
  }
  variables <- md_variables(md)
  cols <- c(
    variables$what$keys,
    variables$when$keys,
    variables$when$index,
    variables$when$interval
  )
  unique(as.character(cols[!is.na(cols)]))
}


#' Carry a renaming of columns into the metadata
#'
#' Every column name the metadata records — keys, index, interval, declared
#' variables, and the identity variable each structure spans — follows the
#' rename, so the frame still describes itself (#178).
#'
#' @param md A metadata list.
#' @param from,to Column names before and after, position by position.
#'
#' @return `md`, with the renamed columns.
#' @keywords internal
rename_metadata_columns <- function(md, from, to) {
  changed <- !is.na(from) & !is.na(to) & from != to
  if (is.null(md) || !any(changed) || !is_nested_metadata(md)) {
    return(md)
  }
  lookup <- rlang::set_names(to[changed], from[changed])
  rename <- function(x) {
    if (is.character(x)) {
      hit <- !is.na(x) & x %in% names(lookup)
      x[hit] <- unname(lookup[x[hit]])
    } else if (is.list(x) && !is.data.frame(x)) {
      x[] <- lapply(x, rename)
    }
    x
  }
  md[["variables"]] <- rename(md[["variables"]])
  structures <- md[["structure"]]
  for (i in seq_along(structures)) {
    structures[[i]]$variable <- rename(structures[[i]]$variable)
  }
  if (length(structures) > 0L) {
    md[["structure"]] <- structures
  }
  md
}


#' Wrap a label and comma-separated items to a width
#'
#' Lines break between items, never inside one; continuation lines are
#' indented. An item too long for a line overflows it rather than being split.
#'
#' @param label Text before the first item, such as `"Points:"`.
#' @param items Character vector.
#' @param width Line width in characters.
#' @param indent Indent of the continuation lines.
#'
#' @return Character vector of lines.
#' @noRd
wrap_items <- function(label, items, width, indent = 2) {
  if (length(items) == 0) {
    return(label)
  }
  items <- paste0(items, c(rep(",", length(items) - 1), ""))
  lines <- character()
  line <- label
  has_item <- FALSE
  for (item in items) {
    candidate <- paste(line, item)
    if (!has_item || cli::ansi_nchar(candidate, type = "width") <= width) {
      line <- candidate
    } else {
      lines <- c(lines, line)
      line <- paste0(strrep(" ", indent), item)
    }
    has_item <- TRUE
  }
  c(lines, line)
}
