#' Validate an anipoint
#'
#' Re-checks, on demand, that an `anipoint`'s metadata still describes the
#' frame it is attached to. The two drift apart silently under ordinary
#' dplyr work: [dplyr::select()] drops a column without touching the
#' metadata that names it, and assignment can change a column's type. The
#' invariants are therefore checked rather than assumed:
#'
#' * the index column is present and numeric — hard error;
#' * every column named in `variables_what`, `variables_when`,
#'   `variables_where` and `variables_event` is present in the data —
#'   hard error;
#' * every column named in `variables_where` is numeric — hard error;
#' * `coordinate_system` agrees with `variables_where` — **warning**
#'   only. The frame is still usable, and the field is derived rather
#'   than declared, so it can be refreshed;
#' * identity, temporal context and the index together name one
#'   observation per row — **warning** only (#49);
#' * a declared `sampling_rate` agrees with the spacing of the index —
#'   **warning** only (#114).
#'
#' @param data An anipoint object.
#'
#' @return The input `data`, invisibly.
#'
#' @seealso [ensure_is_spatial()] for the spatial subset of these checks,
#'   which is the part downstream filters need on every call;
#'   [validate_anievent()] for the `anievent` equivalent.
#'
#' @examples
#' af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
#' validate_anipoint(af)
#'
#' @export
validate_anipoint <- function(data) {
  ensure_is_anipoint(data)
  # Before the generic check, which also names the index but reports it
  # less helpfully.
  ensure_has_index(data)
  ensure_has_declared_variables(data)
  ensure_is_spatial(data)
  warn_coordinate_system_drift(data)
  warn_duplicate_observations(data)
  warn_sampling_rate_mismatch(data)
  invisible(data)
}


#' Warn when the declaration does not identify one observation per row
#'
#' Identity plus temporal context plus the index is meant to be a
#' composite key: one entity, in one context, at one position. When it
#' repeats, some variable that distinguishes the rows is undeclared, and
#' every grouped operation silently folds those rows together — a
#' trajectory with two `x` values at the same instant is not a trajectory.
#'
#' A warning rather than an error. The state is reachable part-way through
#' honest work — a frame read before its identity column is declared, say
#' — and nothing in the class is broken by it (#49).
#'
#' @param data An anipoint object.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_duplicate_observations <- function(data) {
  md <- get_metadata(data)
  key <- intersect(
    c(md_what_keys(md), md_when_keys(md), resolve_index(md)),
    names(data)
  )
  if (length(key) == 0L) {
    return(invisible(TRUE))
  }

  n_duplicated <- sum(duplicated(dplyr::as_tibble(data)[key]))
  if (n_duplicated > 0L) {
    cli::cli_warn(c(
      "{n_duplicated} row{?s} {?is/are} not uniquely identified by {.val {key}}.",
      "i" = "Identity, temporal context and the index together should name one observation.",
      "i" = "A variable that tells these rows apart is probably undeclared; see {.fn add_variables_what} and {.fn add_variables_when}."
    ))
  }

  invisible(TRUE)
}


#' Columns declared by the metadata, keyed by role
#'
#' `variables_event` is a named list of `state` / `point` columns rather
#' than a flat vector, so it is flattened here to give every role the same
#' shape. `NA` entries mean "unset" and are dropped.
#'
#' `variables_index` is read through [resolve_index()] rather than
#' directly, so a frame serialised before the field existed reports the
#' `time` column it was built with rather than nothing at all.
#'
#' @param md An anipoint metadata list.
#'
#' @return Named list of character vectors, one per declaration field.
#' @keywords internal
get_declared_variables <- function(md) {
  drop_na <- function(x) {
    x <- x[!is.na(x)]
    as.character(x)
  }

  list(
    variables_index = drop_na(resolve_index(md)),
    variables_what = drop_na(md_what_keys(md)),
    variables_when = drop_na(md_when_keys(md)),
    variables_where = drop_na(unname(md_where_position(md))),
    variables_event = drop_na(c(
      md_event(md)$state,
      md_event(md)$point
    ))
  )
}


#' Ensure every declared variable names a column that exists
#'
#' @param data An anipoint object.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_has_declared_variables <- function(data) {
  declared <- get_declared_variables(get_metadata(data))

  for (role in names(declared)) {
    cols <- declared[[role]]
    missing_cols <- setdiff(cols, names(data))
    if (length(missing_cols) > 0) {
      cli::cli_abort(c(
        "Metadata field {.field {role}} names {cli::qty(missing_cols)}column{?s} not found in the data: {.val {missing_cols}}.",
        "i" = "Declared: {.val {cols}}.",
        "i" = "Present: {.val {names(data)}}.",
        "i" = "Dropping a declared column leaves the metadata promising a column that isn't there."
      ))
    }
  }

  invisible(TRUE)
}


#' Ensure the index column is present and numeric
#'
#' Which column that is comes from the frame's own declaration; `time` is
#' its default, not a requirement (#109).
#'
#' @param data An anipoint object.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_has_index <- function(data) {
  index <- resolve_index(get_metadata(data))
  if (!index %in% names(data)) {
    cli::cli_abort(c(
      "Index column {.val {index}} is required but not found in data.",
      "i" = "An anipoint is indexed by exactly one column."
    ))
  }
  if (!is.numeric(data[[index]])) {
    cli::cli_abort(
      "Index column {.val {index}} must be numeric, not {.cls {class(data[[index]])}}."
    )
  }
  invisible(TRUE)
}


#' Spatial columns that are missing or not numeric
#'
#' The shared kernel behind [is_spatial()] and [ensure_is_spatial()].
#'
#' @param data An anipoint object.
#'
#' @return Named list with the `declared` spatial variables and the
#'   `missing` and `non_numeric` subsets of them.
#' @keywords internal
find_spatial_problems <- function(data) {
  declared <- get_variables(data, "where")
  declared <- as.character(declared[!is.na(declared)])

  present <- intersect(declared, names(data))
  is_num <- vapply(present, function(col) is.numeric(data[[col]]), logical(1))

  list(
    declared = declared,
    missing = setdiff(declared, names(data)),
    non_numeric = present[!is_num]
  )
}


#' Test whether the spatial columns match the metadata
#'
#' Returns `TRUE` when `variables_where` declares at least one column and
#' every column it names is present and numeric.
#'
#' This is a different question from the one [is_cartesian()] and its
#' siblings answer: those test for the presence of particular column
#' *names* (`x`, `y`, `z`, …) and never consult the metadata or the column
#' types. A frame that has lost its `x` column still satisfies
#' `is_cartesian_1d()` on the strength of `y` alone, while its
#' `variables_where` still promises both.
#'
#' @param data An anipoint object.
#'
#' @return Logical scalar.
#'
#' @seealso [ensure_is_spatial()], [validate_anipoint()].
#'
#' @examples
#' af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
#' is_spatial(af)
#'
#' # Dropping a declared column breaks the correspondence
#' is_spatial(dplyr::select(af, -x))
#'
#' @export
is_spatial <- function(data) {
  problems <- find_spatial_problems(data)
  length(problems$declared) > 0 &&
    length(problems$missing) == 0 &&
    length(problems$non_numeric) == 0
}


#' Ensure the spatial columns match the metadata
#'
#' Guard form of [is_spatial()], for functions that reach coordinates by
#' iterating `variables_where`. Aborts naming the offending columns, so
#' the error points at the metadata mismatch rather than surfacing later
#' and further away.
#'
#' @param data An anipoint object.
#'
#' @return The input `data`, invisibly.
#'
#' @seealso [is_spatial()], [validate_anipoint()].
#'
#' @examples
#' af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
#' ensure_is_spatial(af)
#'
#' @export
ensure_is_spatial <- function(data) {
  ensure_is_anipoint(data)
  problems <- find_spatial_problems(data)

  if (length(problems$declared) == 0) {
    cli::cli_abort(c(
      "No spatial variables are declared in {.field variables_where}.",
      "i" = "Spatial operations need at least one coordinate column."
    ))
  }

  if (length(problems$missing) > 0) {
    cli::cli_abort(c(
      "Missing spatial {cli::qty(problems$missing)}column{?s}: {.val {problems$missing}}.",
      "i" = "Spatial variables from metadata: {.val {problems$declared}}."
    ))
  }

  if (length(problems$non_numeric) > 0) {
    classes <- vapply(
      problems$non_numeric,
      function(col) class(data[[col]])[[1]],
      character(1)
    )
    cli::cli_abort(c(
      "Spatial {cli::qty(problems$non_numeric)}column{?s} must be numeric: {.val {problems$non_numeric}}.",
      "x" = "Found {.cls {classes}}."
    ))
  }

  invisible(data)
}


#' Warn when coordinate_system no longer matches variables_where
#'
#' `coordinate_system` is derived from `variables_where` by
#' [infer_coordinate_system()], but only at construction. Writing the
#' source field on its own leaves the derived one stale.
#'
#' Called only from [validate_anipoint()], after [ensure_is_spatial()] has
#' established that `variables_where` declares at least one column.
#'
#' @param data An anipoint object.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
warn_coordinate_system_drift <- function(data) {
  md <- get_metadata(data)
  declared <- as.character(unname(md_where_position(md))[
    !is.na(unname(md_where_position(md)))
  ])
  recorded <- as.character(md_field(md, "coordinate_system"))
  # `infer_coordinate_system()` warns on combinations it doesn't
  # recognise; we report the mismatch ourselves below.
  implied <- suppressWarnings(infer_coordinate_system(declared))

  if (!identical(recorded, implied)) {
    cli::cli_warn(c(
      "{.field coordinate_system} does not match {.field variables_where}.",
      "x" = "Recorded {.val {recorded}}, but {.val {declared}} implies {.val {implied}}.",
      "i" = "{.field coordinate_system} is derived at construction, so setting {.field variables_where} on its own leaves it stale."
    ))
  }

  invisible(TRUE)
}
