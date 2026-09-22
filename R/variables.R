# Declaring the structural variables (#82)
#
# `variables_what`, `variables_when` and `variables_where` are not
# ordinary metadata — they are the frame's structure. They decide how
# columns are typed, which order columns and rows come in, what the frame
# is grouped by, and (from `variables_where`) the `coordinate_system`.
#
# Writing them without redoing that work leaves the frame and its own
# description disagreeing: the print header updates, so it looks like it
# worked, while the grouping still reflects the old declaration. They
# therefore get dedicated setters that do the whole job, and
# `set_metadata()` refuses them.

#' The metadata fields that declare which columns carry which role
#'
#' Writing any of these has consequences beyond the metadata list — at
#' the least the named columns must exist, and for the three structural
#' roles the frame is retyped, reordered and regrouped to match — so they
#' are reachable only through their own setters.
#'
#' @return Character vector of metadata field names.
#' @keywords internal
list_declaration_metadata_fields <- function() {
  c(
    "variables",
    "structure",
    "connections",
    "variables_index",
    "variables_what",
    "variables_when",
    "variables_where",
    "variables_event",
    "axes"
  )
}


#' Read a variable role from the metadata
#'
#' Returns the flat column vector a role names. For `when` on an
#' anievent, the interval columns come after the context keys, matching
#' the order the flat field carried before the slots existed.
#'
#' @param data An aniframe or anievent object.
#' @param role One of `"what"`, `"when"`, `"where"`.
#'
#' @return Character vector of column names.
#' @keywords internal
get_variables <- function(data, role) {
  md <- get_metadata(data)
  switch(
    role,
    what = md_what_keys(md),
    when = c(md_when_keys(md), md_when_interval(md)),
    where = unname(md_where_position(md))
  )
}


#' The spatial declaration, as a role mapping where there is one
#'
#' `get_variables()` strips names, which for `where` throws the axis roles
#' away. Every path that re-declares the spatial columns has to start from
#' the mapping instead, or `union()` and `setdiff()` silently reduce a
#' renamed frame to `unknown` (#109).
#'
#' @param data An aniframe or anievent object.
#'
#' @return Named character vector, or a bare one when no roles are known.
#' @keywords internal
get_declared_where <- function(data) {
  axes <- if (is_anipoint(data)) resolve_axes(get_metadata(data))
  if (length(axes) > 0L) {
    return(axes)
  }
  get_variables(data, "where")
}


#' Declare one variable role and restructure the frame to match
#'
#' The shared kernel behind the `set_` / `add_` / `remove_` functions.
#' Reads the other two roles from the metadata so the frame is always
#' restructured against a complete, consistent declaration.
#'
#' @param data An aniframe or anievent object.
#' @param role One of `"what"`, `"when"`, `"where"`.
#' @param variables Character vector of column names to declare.
#'
#' @return `data`, restructured and re-declared.
#' @keywords internal
declare_variables <- function(data, role, variables, strict = TRUE) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)

  declared <- list(
    what = get_variables(data, "what"),
    when = get_variables(data, "when"),
    where = get_declared_where(data)
  )
  # Only `where` carries names worth keeping; stripping them elsewhere
  # guards `union()`/`setdiff()` against surprises.
  declared[[role]] <- if (identical(role, "where")) {
    variables
  } else {
    unname(variables)
  }

  restructure_frame(
    data,
    declared$what,
    declared$when,
    declared$where,
    strict = strict
  )
}


#' Ensure a declaration is a character vector
#'
#' Guards the `add_` / `remove_` paths in particular, where `union()` and
#' `setdiff()` would otherwise silently coerce.
#'
#' @param variables Value supplied by the caller.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_variables_character <- function(variables) {
  if (!is.character(variables)) {
    cli::cli_abort(
      "{.arg variables} must be a character vector, not {.cls {class(variables)}}."
    )
  }
  invisible(TRUE)
}


#' Ensure declared columns are present
#'
#' Shared by construction ([ensure_has_anipoint_cols()]) and re-declaration,
#' so a column that isn't there is reported the same way whichever route
#' the caller took.
#'
#' @param data A data frame.
#' @param cols Character vector of declared column names.
#' @param role One of `"what"`, `"when"`, `"where"`.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_has_declared_cols <- function(data, cols, role) {
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) == 0) {
    return(invisible(TRUE))
  }

  lead <- switch(
    role,
    what = "Identity variable{?s} not found in data",
    when = "Temporal variable{?s} not found in data",
    where = "Missing spatial variable{?s}",
    event = "Event variable{?s} not found in data"
  )

  cli::cli_abort(c(
    paste0(lead, ": {.val {missing_cols}}."),
    "i" = "Create the column first, then declare it."
  ))
}


# ------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------

#' Declare which columns carry identity, time and position
#'
#' @description
#' `variables_what`, `variables_when` and `variables_where` name the
#' columns that carry, respectively, entity identity, temporal position
#' and spatial position. They are the frame's structure rather than a
#' description of it: [as_anipoint()] uses them to coerce column types,
#' order columns and rows, group the frame, and derive
#' `coordinate_system`.
#'
#' These functions declare them *and* restructure the frame to match, so
#' the two cannot drift apart. [set_metadata()] refuses these three
#' fields for that reason.
#'
#' * `set_variables_*()` replaces the declaration.
#' * `add_variables_*()` appends to it — the common case, and one that
#'   avoids the footgun of having to restate the existing variables.
#' * `remove_variables_*()` drops from it.
#' * `get_variables_*()` reads it.
#'
#' The column must exist before it can be declared, so the order is
#' always create-then-declare:
#'
#' ```r
#' data |>
#'   dplyr::mutate(id = "hi") |>
#'   add_variables_what("id")
#' ```
#'
#' @param data An aniframe or anievent object.
#' @param variables Character vector of column names.
#'
#' @return For the setters, `data` restructured and re-declared. For the
#'   getters, a character vector of column names.
#'
#' @seealso [validate_anipoint()], which reports a frame whose metadata
#'   has drifted out of sync by some other route.
#'
#' @examples
#' af <- anipoint(time = 1:5, x = 1:5, y = 1:5)
#'
#' # Declaring an identity column groups the frame by it
#' af |>
#'   dplyr::mutate(id = "a") |>
#'   add_variables_what("id") |>
#'   dplyr::group_vars()
#'
#' # Declaring a third spatial column refreshes coordinate_system
#' af |>
#'   dplyr::mutate(z = 0) |>
#'   add_variables_where("z") |>
#'   get_metadata("coordinate_system")
#'
#' @name variables
NULL


#' @rdname variables
#' @export
get_variables_what <- function(data) {
  ensure_is_aniframe(data)
  get_variables(data, "what")
}

#' @rdname variables
#' @export
get_variables_when <- function(data) {
  ensure_is_aniframe(data)
  get_variables(data, "when")
}

#' @rdname variables
#' @export
get_variables_where <- function(data) {
  ensure_is_aniframe(data)
  get_variables(data, "where")
}

#' @rdname variables
#' @export
set_variables_what <- function(data, variables) {
  declare_variables(data, "what", variables)
}

#' @rdname variables
#' @export
set_variables_when <- function(data, variables) {
  declare_variables(data, "when", variables)
}

#' @rdname variables
#' @export
set_variables_where <- function(data, variables) {
  declare_variables(data, "where", variables)
}

#' @rdname variables
#' @export
add_variables_what <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)
  declare_variables(data, "what", union(get_variables(data, "what"), variables))
}

#' @rdname variables
#' @export
add_variables_when <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)

  # `variables_when` holds only the temporal context, so a new column
  # simply joins it — the index sorts after all of them regardless, and is
  # declared separately.
  declare_variables(data, "when", union(get_variables(data, "when"), variables))
}

#' @rdname variables
#' @export
add_variables_where <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)

  # `union()` drops names, so combining has to happen on the mapping: the
  # roles already declared, plus the new ones, with anything the addition
  # supersedes -- by role or by column -- taken out first.
  current <- normalise_axes(get_declared_where(data))
  added <- normalise_axes(variables)
  superseded <- names(current) %in% names(added) | current %in% added

  declare_variables(data, "where", c(current[!superseded], added))
}

#' @rdname variables
#' @export
remove_variables_what <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)
  declare_variables(
    data,
    "what",
    setdiff(get_variables(data, "what"), variables)
  )
}

#' @rdname variables
#' @export
remove_variables_when <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)
  declare_variables(
    data,
    "when",
    setdiff(get_variables(data, "when"), variables)
  )
}

#' @rdname variables
#' @export
remove_variables_where <- function(data, variables) {
  ensure_is_aniframe(data)
  ensure_variables_character(variables)

  # By column, like the other `remove_` verbs; the roles of whatever is
  # left travel with it, which `setdiff()` on bare columns would lose.
  current <- normalise_axes(get_declared_where(data))

  # Leniently: the caller removed a column, they did not assert that what
  # is left is a coordinate system. Declaring an incoherent set outright
  # still aborts; arriving at one by removal degrades to `unknown` with a
  # warning, so a remove-then-add is not blocked halfway through.
  declare_variables(
    data,
    "where",
    current[!current %in% variables],
    strict = FALSE
  )
}
