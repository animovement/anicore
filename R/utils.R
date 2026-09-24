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
#' The identity (`what`) columns auto-detection looks for, shared by
#' [as_anipoint()] and [as_anievent()]. Only the names present in the data
#' are used, and any other column can be declared explicitly via
#' `variables_what`.
#'
#' The names are listed coarsest first, which reads naturally for the ones
#' that do nest — a `subject` has `track`s, a track has `keypoint`s. **That
#' is the order detection emits, not a hierarchy a frame asserts.** Identity
#' variables need not nest at all: `sex`, `treatment` and `genotype`
#' partition a population without containing one another, and there is no
#' sense in which one of them is finer than the next.
#'
#' So nothing should read a position in `variables_what` as meaning a level.
#' Where a function needs to know which variable to operate on, it asks —
#' `animetric::add_centroid()` takes `across`, `anispace::translate_coords()`
#' takes `level` — rather than inferring one. The order does still carry
#' through to column order and grouping, which is presentation: grouping by
#' `(a, b)` and `(b, a)` gives the same groups.
#'
#' `subject` and `individual` name the same kind of thing; both are
#' recognised because behavioural coding tools (BORIS and its kin) speak
#' of subjects where tracking tools speak of individuals.
#'
#' @return Character vector of column names.
#' @keywords internal
list_recognised_variables_what <- function() {
  c("model", "individual", "subject", "track", "keypoint")
}

#' Classes owned by dplyr, tibble and base R
#'
#' The tail of the class vector that belongs to dplyr rather than to
#' animovement. `NextMethod()` returns these already set correctly, so
#' they are never restored from the input — doing so would, for instance,
#' re-group the result of an [dplyr::ungroup()].
#'
#' @return Character vector of class names.
#' @keywords internal
list_base_frame_classes <- function() {
  c("grouped_df", "rowwise_df", "tbl_df", "tbl", "data.frame")
}

#' Re-clothe a dispatched result with its animovement classes and metadata
#'
#' After a generic strips a result down to a plain tibble (via
#' `NextMethod()`), restore the animovement classes the input carried and
#' re-attach its metadata.
#'
#' dplyr rebuilds only the classes it knows how to reconstruct, so by the
#' time `NextMethod()` returns, the whole animovement family is gone —
#' `aniframe` / `anievent` and any subclass a downstream package has built
#' on top of them. Restoring the *incoming* stack rather than asserting a
#' fixed one is what lets such a subclass (e.g. `animetric`'s
#' `aniframe_kin`) survive a pipeline without registering methods of its
#' own.
#'
#' Order is preserved, so a subclass stays ahead of its parent and keeps
#' dispatch priority over it.
#'
#' @param x The bare result returned by `NextMethod()`.
#' @param cls Class vector of the original input, captured before dispatch.
#' @param md Metadata captured before dispatch via [get_metadata()].
#'
#' @return `x` with the animovement classes and metadata restored.
#' @keywords internal
#' @details
#' The metadata goes back through [write_metadata()] rather than
#' [set_metadata()]: this is a round-trip of metadata that came off a
#' valid object, structural fields included, and `set_metadata()` refuses
#' those by design.
preserve_animovement_class <- function(x, cls, md) {
  # Lay the incoming animovement classes down in their original order,
  # then whatever dplyr set on the result. Re-adding only the *missing*
  # ones would append them at the front instead, putting `aniframe` ahead
  # of its own subclasses in the methods that strip it before dispatch.
  animovement_cls <- setdiff(cls, list_base_frame_classes())
  class(x) <- c(animovement_cls, setdiff(class(x), animovement_cls))
  write_metadata(x, md)
}
