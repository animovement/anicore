#' Attach, read and remove the structures of a frame
#'
#' @description
#' A frame can carry any number of named [anistructure()]s, each spanning the
#' levels of one identity or temporal variable. Several may span the same
#' variable and overlap: a football frame can hold `team`, `defence` and
#' `left_flank` over `individual` alongside a `skeleton` over `keypoint`. A
#' structure's `points` are its members; levels it does not list are
#' outside it.
#'
#' * `set_structure()` attaches a structure under `name`, replacing one of
#'   the same name.
#' * `get_structure()` returns all structures as a named list, or one.
#' * `remove_structure()` drops one.
#'
#' Points not found in the data are kept with a warning, in case they are
#' recorded in another file.
#'
#' @param data An anipoint.
#' @param structure An [anistructure()].
#' @param variable The `what` or `when` key whose levels the points are.
#' @param name Name to store the structure under. Defaults to `variable`.
#'
#' @return `set_structure()` and `remove_structure()`: `data`, with the
#'   structures updated. `get_structure()`: a named list of structures, or
#'   one structure.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 2)
#' af <- set_structure(af, example_structure())
#' get_structure(af, "keypoint")
#'
#' # Several structures over the same variable
#' af <- af |>
#'   set_structure(anistructure(points = c("1", "2")), "individual", "pair") |>
#'   set_structure(anistructure(points = "1"), "individual", "focal")
#' names(get_structure(af))
#'
#' @seealso [anistructure()]
#' @name structures
NULL


#' @rdname structures
#' @export
set_structure <- function(
  data,
  structure,
  variable = "keypoint",
  name = variable
) {
  ensure_is_anipoint(data)
  validate_anistructure(structure)
  ensure_structure_variable(data, variable)
  ensure_structure_name(name)

  structure$variable <- variable
  warn_missing_structure_points(data, structure)

  structures <- get_structure(data)
  structures[[name]] <- structure
  write_structure(data, structures)
}


#' @rdname structures
#' @export
get_structure <- function(data, name = NULL) {
  ensure_is_aniframe(data)
  structures <- get_metadata(data, "structure") %||% list()
  if (is.null(name)) {
    return(structures)
  }
  ensure_known_structure(structures, name)
  structures[[name]]
}


#' @rdname structures
#' @export
remove_structure <- function(data, name) {
  ensure_is_anipoint(data)
  structures <- get_structure(data)
  ensure_known_structure(structures, name)
  structures[[name]] <- NULL
  write_structure(data, structures)
}


#' @keywords internal
write_structure <- function(data, structures) {
  md <- get_metadata(data)
  md$structure <- structures
  write_metadata(data, md)
}


#' @keywords internal
ensure_structure_name <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name) || name == "") {
    cli::cli_abort("{.arg name} must be a single non-empty string.")
  }
  invisible(TRUE)
}


#' @keywords internal
ensure_known_structure <- function(structures, name) {
  ensure_structure_name(name)
  if (!name %in% names(structures)) {
    cli::cli_abort(c(
      "There is no structure named {.val {name}}.",
      "i" = if (length(structures) > 0L) {
        "Structures: {.val {names(structures)}}."
      } else {
        "This frame has no structures."
      }
    ))
  }
  invisible(TRUE)
}


#' @keywords internal
ensure_structure_variable <- function(data, variable) {
  if (!is.character(variable) || length(variable) != 1L) {
    cli::cli_abort("{.arg variable} must be a single string.")
  }
  permitted <- get_keys(data)
  if (!variable %in% permitted) {
    cli::cli_abort(c(
      "{.arg variable} must be a {.field what} or {.field when} key, not {.val {variable}}.",
      "i" = "Keys: {.val {permitted}}."
    ))
  }
  invisible(TRUE)
}


#' @keywords internal
warn_missing_structure_points <- function(data, structure) {
  known <- unique(as.character(data[[structure$variable]]))
  missing <- setdiff(structure$points, known)
  if (length(missing) > 0L) {
    cli::cli_warn(c(
      "{cli::qty(missing)}Point{?s} {.val {missing}} {?is/are} not in the {.val {structure$variable}} column.",
      "i" = "Keeping {cli::qty(missing)}{?it/them} in case {?it is/they are} recorded in another file."
    ))
  }
  invisible(TRUE)
}


#' Upgrade a structure category holding connection tables
#'
#' Before #154 the category held one `from`/`to` table per variable; each
#' becomes a segments-only structure named after its variable. Built
#' without validation so malformed old tables still read.
#'
#' @param structures The `structure` category.
#' @return A named list of `anistructure`s.
#' @keywords internal
migrate_structure_category <- function(structures) {
  structures <- structures %||% list()
  for (name in names(structures)) {
    entry <- structures[[name]]
    if (is.data.frame(entry)) {
      pairs <- coerce_to_pair_df(entry)
      structures[[name]] <- new_anistructure(
        points = unique(c(pairs$from, pairs$to)),
        segments = dplyr::tibble(
          segment = make.unique(paste(pairs$from, pairs$to, sep = "-")),
          from = pairs$from,
          to = pairs$to,
          length = rep(NA_real_, nrow(pairs))
        ),
        variable = name
      )
    }
  }
  structures
}


#' Coerce links to a `from`/`to` table
#'
#' @param x A data frame with `from` and `to`, or a list of `c(from, to)`
#'   pairs.
#' @return A tibble with character `from` and `to`.
#' @keywords internal
coerce_to_pair_df <- function(x) {
  if (is.data.frame(x)) {
    if (!all(c("from", "to") %in% names(x))) {
      cli::cli_abort(
        "{.arg segments} must have {.field from} and {.field to} columns."
      )
    }
    return(dplyr::tibble(
      from = as.character(x$from),
      to = as.character(x$to)
    ))
  }
  if (is.list(x)) {
    is_pair <- vapply(
      x,
      function(p) length(p) == 2 && (is.character(p) || is.factor(p)),
      logical(1)
    )
    if (!all(is_pair)) {
      cli::cli_abort(
        "Each element of {.arg segments} must be a length-2 character vector."
      )
    }
    pairs <- vapply(
      x,
      function(p) {
        v <- as.character(p)
        if (all(c("from", "to") %in% names(p))) {
          v <- c(v[names(p) == "from"], v[names(p) == "to"])
        }
        v
      },
      character(2)
    )
    return(dplyr::tibble(from = pairs[1, ], to = pairs[2, ]))
  }
  cli::cli_abort(
    "{.arg segments} must be a data frame or a list of {.code c(from, to)} pairs."
  )
}
