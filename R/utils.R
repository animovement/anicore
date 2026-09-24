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
#' @return `x` with the animovement classes and metadata restored.
#' @keywords internal
preserve_animovement_class <- function(x, cls, md) {
  # Keep original order so subclasses stay ahead of `aniframe`.
  animovement_cls <- setdiff(cls, list_base_frame_classes())
  class(x) <- c(animovement_cls, setdiff(class(x), animovement_cls))
  write_metadata(x, md)
}
