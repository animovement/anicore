#' Set the connections for a variable
#'
#' @description
#' **\[Experimental\]**
#'
#' Replace the connections (e.g. skeleton edges between keypoints, edges of a
#' social network between individuals) for a single variable. Connections are
#' stored as a 2-column `from`/`to` tibble; storage preserves the order
#' supplied so downstream consumers can interpret the table as either
#' directed or undirected.
#'
#' @param data An anipoint object.
#' @param connections One of:
#'   * a 2-column data.frame with columns `from` and `to`,
#'   * a list of length-2 character vectors (each `c(from, to)`),
#'   * `NULL` to clear the connections for `variable`.
#' @param variable Character scalar. Name of the `what` or `when` key the
#'   connections relate to.
#'   Defaults to `"keypoint"`.
#'
#' @return The anipoint with updated `connections` metadata.
#'
#' @details
#' If any `from`/`to` value isn't found in the corresponding column of `data`,
#' a warning is emitted but the connection is kept — the value may legitimately
#' be missing in this particular recording while being valid elsewhere.
#'
#' @seealso [get_connections()], [add_connections()], [remove_connections()]
#'
#' @examples
#' \dontrun{
#' data <- example_anipoint()
#'
#' # Implicit by position (element[1] = from, element[2] = to)
#' data <- set_connections(
#'   data,
#'   list(
#'     c("head", "neck"),
#'     c("neck", "shoulder_right"),
#'     c("neck", "shoulder_left"),
#'     c("shoulder_right", "hip_right"),
#'     c("shoulder_left", "hip_left")
#'   )
#' )
#'
#' # Explicit names within each pair
#' data <- set_connections(
#'   data,
#'   list(
#'     c(from = "head", to = "neck"),
#'     c(from = "neck", to = "shoulder_right")
#'   )
#' )
#'
#' # Or as a 2-column data.frame
#' data <- set_connections(
#'   data,
#'   data.frame(
#'     from = c("head", "neck"),
#'     to   = c("neck", "shoulder_right")
#'   )
#' )
#' }
#'
#' @export
set_connections <- function(data, connections, variable = "keypoint") {
  ensure_is_anipoint(data)
  ensure_known_connection_variable(data, variable)

  current <- get_connections(data)

  if (is.null(connections)) {
    current[[variable]] <- NULL
  } else {
    conn_df <- coerce_to_connection_df(connections)
    warn_unknown_connection_endpoints(data, conn_df, variable)
    current[[variable]] <- conn_df
  }

  write_structure(data, current)
}

#' Get connections from an anipoint
#'
#' @description
#' **\[Experimental\]**
#'
#' Read the connections currently stored on an anipoint. Returns the full
#' named list of `from`/`to` tibbles by default, or a single tibble when
#' `variable` is supplied.
#'
#' @param data An anipoint object.
#' @param variable Optional character scalar. When `NULL` (default), returns
#'   the full named list of connection tables (one per variable). When a
#'   variable name, returns just that variable's `from`/`to` tibble (an empty
#'   tibble if no connections are set for that variable).
#'
#' @return A named list of tibbles (when `variable` is NULL), or a single
#'   2-column tibble.
#'
#' @seealso [set_connections()], [add_connections()], [remove_connections()]
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_connections(af)
#' @export
get_connections <- function(data, variable = NULL) {
  ensure_is_anipoint(data)
  current <- get_metadata(data, "structure") %||% list()

  if (is.null(variable)) {
    return(current)
  }

  conn <- current[[variable]]
  if (is.null(conn)) {
    return(make_empty_connection_df())
  }
  conn
}

#' Add connections to an anipoint
#'
#' @description
#' **\[Experimental\]**
#'
#' Append one or more `from`/`to` pairs to the existing connections for a
#' variable. `from` and `to` may be either single strings or character vectors
#' of equal length (one connection per element).
#'
#' @param data An anipoint object.
#' @param from Character vector of source endpoints.
#' @param to Character vector of target endpoints. Must be the same length
#'   as `from`.
#' @param variable Character scalar. Name of the variable the connections
#'   relate to (must be a `what` or `when` key). Defaults
#'   to `"keypoint"`.
#'
#' @return The anipoint with the new connections appended.
#'
#' @details
#' No deduplication is performed — duplicates of an existing pair will appear
#' twice in the resulting table. Endpoints not found in `data[[variable]]`
#' produce a warning but are still appended.
#'
#' @seealso [set_connections()], [get_connections()], [remove_connections()]
#'
#' @examples
#' \dontrun{
#' data <- example_anipoint()
#' data <- add_connections(data, from = "head", to = "neck")
#' data <- add_connections(
#'   data,
#'   from = c("neck", "neck"),
#'   to = c("shoulder_right", "shoulder_left")
#' )
#' }
#'
#' @export
add_connections <- function(data, from, to, variable = "keypoint") {
  ensure_is_anipoint(data)
  ensure_known_connection_variable(data, variable)

  pairs <- coerce_from_to_to_df(from, to)
  warn_unknown_connection_endpoints(data, pairs, variable)

  current <- get_connections(data)
  existing <- current[[variable]]
  if (is.null(existing)) {
    existing <- make_empty_connection_df()
  }
  current[[variable]] <- dplyr::bind_rows(existing, pairs)

  write_structure(data, current)
}

#' Remove connections from an anipoint
#'
#' @description
#' **\[Experimental\]**
#'
#' Remove `from`/`to` pairs from the connections of a variable. Matching is
#' exact and order-sensitive: `remove_connections(data, "a", "b")` removes
#' the pair `(from = "a", to = "b")` but does *not* remove `(from = "b",
#' to = "a")`. Call twice with swapped arguments if you want both directions
#' gone.
#'
#' @param data An anipoint object.
#' @param from Character vector of source endpoints to remove.
#' @param to Character vector of target endpoints to remove. Must be the same
#'   length as `from`.
#' @param variable Character scalar. Name of the variable. Defaults to
#'   `"keypoint"`.
#'
#' @return The anipoint with matching connections removed.
#'
#' @seealso [set_connections()], [get_connections()], [add_connections()]
#'
#' @examples
#' \dontrun{
#' data <- example_anipoint() |>
#'   add_connections(from = c("head", "neck"), to = c("neck", "shoulder_right"))
#' data <- remove_connections(data, from = "head", to = "neck")
#' }
#'
#' @export
remove_connections <- function(data, from, to, variable = "keypoint") {
  ensure_is_anipoint(data)
  ensure_known_connection_variable(data, variable)

  to_remove <- coerce_from_to_to_df(from, to)

  current <- get_connections(data)
  existing <- current[[variable]]
  if (is.null(existing) || nrow(existing) == 0) {
    return(data)
  }

  remaining <- dplyr::anti_join(existing, to_remove, by = c("from", "to"))
  current[[variable]] <- remaining

  write_structure(data, current)
}

# ---- Internal helpers ----

#' @keywords internal
make_empty_connection_df <- function() {
  dplyr::tibble(from = character(), to = character())
}

#' @keywords internal
ensure_known_connection_variable <- function(data, variable) {
  if (!is.character(variable) || length(variable) != 1) {
    cli::cli_abort("{.arg variable} must be a single character string.")
  }
  md <- get_metadata(data)
  permitted <- unique(c(md_what_keys(md), md_when_keys(md)))
  if (!variable %in% permitted) {
    cli::cli_abort(c(
      "{.arg variable} must be one of {.val {permitted}}, not {.val {variable}}.",
      "i" = "Connections are defined between identity ({.field variables_what}) or temporal ({.field variables_when}) columns."
    ))
  }
}

#' @keywords internal
coerce_to_connection_df <- function(x) {
  if (is.data.frame(x)) {
    if (!all(c("from", "to") %in% names(x))) {
      cli::cli_abort(
        "A connections data.frame must have {.field from} and {.field to} columns."
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
        "When supplied as a list, each element must be a length-2 character vector (one `from`/`to` pair)."
      )
    }
    # A pair may be positional or named c(from = , to = ).
    extract_pair <- function(p) {
      nm <- names(p)
      v <- as.character(p) # strips names
      if (!is.null(nm) && all(c("from", "to") %in% nm)) {
        names(v) <- nm
        c(v[["from"]], v[["to"]])
      } else {
        v
      }
    }
    pairs <- vapply(x, extract_pair, character(2))
    return(dplyr::tibble(from = pairs[1, ], to = pairs[2, ]))
  }
  cli::cli_abort(
    "{.arg connections} must be a 2-column data.frame, a list of length-2 character vectors, or NULL."
  )
}

#' @keywords internal
coerce_from_to_to_df <- function(from, to) {
  from <- as.character(from)
  to <- as.character(to)
  if (length(from) == 0 || length(to) == 0) {
    cli::cli_abort("{.arg from} and {.arg to} must be non-empty.")
  }
  if (length(from) != length(to)) {
    cli::cli_abort(
      "{.arg from} (length {length(from)}) and {.arg to} (length {length(to)}) must be the same length."
    )
  }
  dplyr::tibble(from = from, to = to)
}

#' @keywords internal
warn_unknown_connection_endpoints <- function(data, conn_df, variable) {
  if (!variable %in% names(data)) {
    return(invisible())
  }
  known <- unique(as.character(data[[variable]]))
  unknown <- setdiff(c(conn_df$from, conn_df$to), known)
  unknown <- unknown[!is.na(unknown)]
  if (length(unknown) > 0) {
    cli::cli_warn(c(
      "Some connection endpoints are not present in the {.val {variable}} column: {.val {unknown}}.",
      "i" = "Keeping them in case the value is recorded in another file or video."
    ))
  }
  invisible()
}


#' Write the structure category (connections keyed by variable)
#'
#' @param data An anipoint object.
#' @param structure Named list of connection tables.
#'
#' @return `data`, with the category written.
#' @keywords internal
write_structure <- function(data, structure) {
  md <- get_metadata(data)
  md$structure <- structure
  write_metadata(data, md)
}
