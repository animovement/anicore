# Aliases from the aniframe -> anipoint rename (#154); remove after one release.

#' Deprecated aniframe constructors
#'
#' The position-grain frame is now called `anipoint`; `aniframe` names the
#' abstract parent class shared with [anievent][is_anievent()]. These
#' aliases forward to their replacements.
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

# deprecate_soft() warns direct callers only, so users are not warned about
# calls inside packages they cannot change.
#' @keywords internal
warn_deprecated_alias <- function(old, new) {
  lifecycle::deprecate_soft(
    "0.9.0",
    paste0(old, "()"),
    paste0(new, "()"),
    env = rlang::caller_env(),
    user_env = rlang::caller_env(2)
  )
}
