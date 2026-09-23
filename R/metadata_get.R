#' Get metadata
#'
#' The metadata is stored as a category tree (see
#' [list_default_metadata()]), but lookup stays flat: a field is found by
#' its own name wherever it lives, and a category name returns the whole
#' category. The `variables` category is the exception — its slots are
#' reached through the `*_variables_*()` accessors, [get_index()] and
#' [get_axes()], not by flat name.
#'
#' @param data An aniframe or anievent object.
#' @param fields Field or category names. A field the object does not
#'   carry gives `NULL` — an [anievent()] has no `space` category, so its
#'   spatial fields read as absent rather than as neutral values. A name
#'   that is not a metadata field at all is an error.
#'
#' @return The metadata associated with the object.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' names(get_metadata(af))
#'
#' # A single field can be pulled out by name, wherever it lives
#' get_metadata(af, 'sampling_rate')
#'
#' # A category name returns the whole category
#' names(get_metadata(af, 'space'))
#' @export
get_metadata <- function(data, fields = NULL) {
  ensure_has_metadata(data)
  ensure_are_metadata_fields(fields)
  x <- migrate_metadata_layout(
    attr(data, "metadata"),
    anievent = is_anievent(data)
  )
  if (!is.null(fields) && length(fields) == 1) {
    x <- get_metadata_entry(x, fields)
  } else if (!is.null(fields) && length(fields) > 1) {
    # Plain list, so `$` doesn't resolve through categories.
    x <- stats::setNames(
      lapply(fields, function(field) get_metadata_entry(x, field)),
      fields
    )
  } else {
    class(x) <- c("aniframe_metadata", "list")
  }
  x
}


#' Resolve one name against the metadata tree
#'
#' @param md A metadata list.
#' @param field Length-one character.
#'
#' @return The entry's value, or `NULL`.
#' @keywords internal
get_metadata_entry <- function(md, field) {
  md <- unclass(md)
  if (field %in% list_metadata_categories()) {
    return(md[[field]])
  }
  md_field(md, field)
}


#' Are these metadata field names?
#'
#' @param fields Character vector of field or category names, or `NULL`.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_are_metadata_fields <- function(fields, call = rlang::caller_env()) {
  if (is.null(fields)) {
    return(invisible(TRUE))
  }
  known <- c(
    "spec_version",
    list_metadata_categories(),
    names(list_metadata_field_categories())
  )
  unknown <- setdiff(fields, known)

  # Old flat names get redirected to their accessors.
  variables_fields <- c(
    "variables_what",
    "variables_when",
    "variables_where",
    "variables_index",
    "variables_event",
    "axes",
    "connections"
  )
  redirected <- intersect(unknown, variables_fields)
  if (length(redirected) > 0L) {
    cli::cli_abort(
      c(
        "{.val {redirected}} {?is/are} not flat metadata field{?s} any more.",
        "i" = "The variable declaration is read with {.fn get_variables_what} and friends, {.fn get_index} and {.fn get_axes}; connections with {.fn get_connections}."
      ),
      call = call
    )
  }
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
