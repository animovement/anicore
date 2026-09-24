#' Get metadata
#'
#' @param data An aniframe or anievent object.
#' @param fields If only specific metadata fields should be returned. A field
#'   the object does not carry gives `NULL`; a name that is not a metadata
#'   field at all is an error.
#'
#' @return The metadata associated with the object.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' names(get_metadata(af))
#'
#' # A single field can be pulled out by name
#' get_metadata(af, 'sampling_rate')
#' @export
get_metadata <- function(data, fields = NULL) {
  ensure_has_metadata(data)
  ensure_are_metadata_fields(fields)
  x <- attr(data, "metadata")
  if (!is.null(fields) && length(fields) == 1) {
    x <- x[[fields]]
  } else if (!is.null(fields) && length(fields) > 1) {
    x <- x[names(x) %in% fields]
    class(x) <- c("aniframe_metadata", "data.frame")
  } else {
    class(x) <- c("aniframe_metadata", "list")
  }
  x
}


#' Are these metadata field names?
#'
#' @param fields Character vector of field names, or `NULL`.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_are_metadata_fields <- function(fields, call = rlang::caller_env()) {
  if (is.null(fields)) {
    return(invisible(TRUE))
  }
  known <- names(list_default_metadata())
  unknown <- setdiff(fields, known)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.val {unknown}} {?is/are} not {?a/} metadata field{?s}.",
        "i" = "See {.fn list_default_metadata} for the fields an object can carry."
      ),
      call = call
    )
  }
  invisible(TRUE)
}
