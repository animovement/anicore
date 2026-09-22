# Deprecated aliases from the aniframe -> anipoint rename (#154).
# `aniframe` survives as the abstract parent class; the position-grain
# constructors now carry the grain's name. Remove after one release cycle.

#' Deprecated aniframe constructors
#'
#' The position-grain frame is now called `anipoint`; `aniframe` names the
#' abstract parent class shared with [anievent][is_anievent()]. These
#' aliases forward to their replacements and warn once per session.
#'
#' @param ... Passed to the replacement function.
#' @param data Passed to the replacement function.
#' @return The replacement function's value.
#' @seealso [anipoint()], [as_anipoint()], [example_anipoint()],
#'   [validate_anipoint()]
#' @name anicore-deprecated
#' @keywords internal
NULL

#' @rdname anicore-deprecated
#' @export
aniframe <- function(...) {
  warn_deprecated_alias("aniframe", "anipoint")
  anipoint(...)
}

#' @rdname anicore-deprecated
#' @export
as_aniframe <- function(data, ...) {
  warn_deprecated_alias("as_aniframe", "as_anipoint")
  as_anipoint(data, ...)
}

#' @rdname anicore-deprecated
#' @export
example_aniframe <- function(...) {
  warn_deprecated_alias("example_aniframe", "example_anipoint")
  example_anipoint(...)
}

#' @rdname anicore-deprecated
#' @export
validate_aniframe <- function(data) {
  warn_deprecated_alias("validate_aniframe", "validate_anipoint")
  validate_anipoint(data)
}

#' @keywords internal
warn_deprecated_alias <- function(old, new) {
  cli::cli_warn(
    "{.fn {old}} is deprecated as of anicore 0.9.0; use {.fn {new}} instead.",
    .frequency = "once",
    .frequency_id = paste0(old, "-deprecated")
  )
}
