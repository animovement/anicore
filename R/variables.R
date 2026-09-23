#' The metadata fields that declare which columns carry which role
#'
#' Reachable only through their own setters, which restructure the frame.
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


#' The slot a bare character vector declares, per role
#'
#' @return Named character vector, role to slot; `NA` when a role has no
#'   main slot.
#' @keywords internal
list_main_variable_slots <- function() {
  c(what = "keys", when = "keys", where = "position", event = NA)
}


#' The frame class whose metadata schema applies to `data`
#'
#' @keywords internal
frame_class <- function(data) {
  if (is_anievent(data)) "anievent" else "anipoint"
}


#' Read and declare which columns carry identity, time, position and events
#'
#' @description
#' The `variables` metadata category says which columns play which role.
#' Each role is a list of named slots:
#'
#' * `what`: `keys`, the identity columns.
#' * `when`: `keys`, the temporal context (session, trial), plus `index` on
#'   an anipoint or `interval` (`start`, `stop`) on an anievent.
#' * `where`: `position`, axis role to column (anipoint only).
#' * `event`: `state` and `point`, the per-frame event columns (anipoint
#'   only).
#'
#' The frame is grouped by the `keys` of `what` and `when`; see [get_keys()].
#'
#' Declaring restructures the frame to match — columns are retyped,
#' reordered and regrouped, and `coordinate_system` is re-derived — so the
#' metadata and the frame cannot drift apart. A column must exist before it
#' is declared.
#'
#' * `set_variables()` replaces the slots it is given and leaves the rest.
#' * `add_variables()` appends to them.
#' * `remove_variables()` drops columns from them.
#'
#' Each role argument takes a named list of slots, or a character vector for
#' the role's main slot: `keys` for `what` and `when`, `position` for
#' `where`. In `remove_variables()` a character vector drops the columns
#' from every slot of the role.
#'
#' @param data An aniframe.
#' @param role Role to read, or `NULL` for the whole category.
#' @param slot Slot within `role`, or `NULL` for the union of its slots.
#' @param what,when,where,event A named list of slots, or a character vector
#'   for the role's main slot.
#'
#' @return `get_variables()`: the whole category; the columns of a role,
#'   unnamed; or one slot as stored. The setters: `data`, restructured.
#'
#' @seealso [get_keys()], [get_index()], [set_index()], [get_axes()]
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_variables(af, "what")
#' get_variables(af, "where", "position")
#'
#' # Declaring an identity column groups the frame by it
#' af |>
#'   dplyr::mutate(id = "a") |>
#'   add_variables(what = "id") |>
#'   dplyr::group_vars()
#'
#' # Axis roles map to columns of any name
#' df <- data.frame(time = 1:3, u = c(1, 2, 3), v = c(0, 1, 0))
#' as_anipoint(df, variables_where = c("u", "v")) |>
#'   set_variables(where = c(x = "u", y = "v")) |>
#'   get_metadata("coordinate_system")
#'
#' @name variables
NULL


#' @rdname variables
#' @export
get_variables <- function(data, role = NULL, slot = NULL) {
  ensure_is_aniframe(data)
  variables <- md_variables(get_metadata(data))
  if (is.null(role)) {
    return(variables)
  }
  role <- rlang::arg_match(role, names(list_main_variable_slots()))
  slots <- variables[[role]] %||% list()
  if (!is.null(slot)) {
    ensure_known_variable_slots(data, role, slot)
    return(slots[[slot]] %||% character())
  }
  unique(unlist(slots, use.names = FALSE)) %||% character()
}


#' @rdname variables
#' @export
set_variables <- function(
  data,
  what = NULL,
  when = NULL,
  where = NULL,
  event = NULL
) {
  ensure_is_aniframe(data)
  update <- collect_variable_update(data, what, when, where, event)
  variables <- get_variables(data)
  for (role in names(update)) {
    for (slot in names(update[[role]])) {
      variables[[role]][[slot]] <- update[[role]][[slot]]
    }
  }
  apply_variables(data, variables)
}


#' @rdname variables
#' @export
add_variables <- function(
  data,
  what = NULL,
  when = NULL,
  where = NULL,
  event = NULL
) {
  ensure_is_aniframe(data)
  update <- collect_variable_update(data, what, when, where, event)
  variables <- get_variables(data)
  for (role in names(update)) {
    for (slot in names(update[[role]])) {
      if (slot %in% c("index", "interval")) {
        cli::cli_abort(c(
          "{.field when${slot}} cannot be added to.",
          "i" = "Use {.fn set_index} to change the index."
        ))
      }
      current <- variables[[role]][[slot]] %||% character()
      added <- update[[role]][[slot]]
      variables[[role]][[slot]] <- if (identical(slot, "position")) {
        current <- normalise_axes(current)
        added <- normalise_axes(added)
        superseded <- names(current) %in% names(added) | current %in% added
        c(current[!superseded], added)
      } else {
        union(current, added)
      }
    }
  }
  apply_variables(data, variables)
}


#' @rdname variables
#' @export
remove_variables <- function(
  data,
  what = NULL,
  when = NULL,
  where = NULL,
  event = NULL
) {
  ensure_is_aniframe(data)
  args <- list(what = what, when = when, where = where, event = event)
  args <- args[!vapply(args, is.null, logical(1))]
  variables <- get_variables(data)

  for (role in names(args)) {
    removal <- args[[role]]
    if (is.character(removal)) {
      slots <- names(variables[[role]])
      removal <- stats::setNames(rep(list(removal), length(slots)), slots)
    }
    removal <- as_variable_slots(removal, role)
    ensure_known_variable_slots(data, role, names(removal))
    for (slot in names(removal)) {
      current <- variables[[role]][[slot]] %||% character()
      kept <- current[!current %in% removal[[slot]]]
      if (slot %in% c("index", "interval") && length(kept) < length(current)) {
        cli::cli_abort(c(
          "{.field when${slot}} cannot be removed.",
          "i" = "Use {.fn set_index} to index the frame by another column."
        ))
      }
      variables[[role]][[slot]] <- kept
    }
  }

  # Non-strict so a remove-then-add is not blocked halfway; the leftover set
  # degrades to `unknown` with a warning.
  apply_variables(data, variables, strict = !"where" %in% names(args))
}


#' The grouping columns of a frame
#'
#' The frame is grouped by its identity keys and temporal context keys:
#' `c(what$keys, when$keys)`. The index and an anievent's interval are never
#' grouping columns.
#'
#' @param data An aniframe.
#'
#' @return Character vector of column names.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
#' get_keys(af)
#'
#' @seealso [get_variables()]
#' @export
get_keys <- function(data) {
  ensure_is_aniframe(data)
  md <- get_metadata(data)
  c(md_what_keys(md), md_when_keys(md))
}


#' Normalise the role arguments of the variables setters
#'
#' @return Named list, role to a named list of slots.
#' @keywords internal
collect_variable_update <- function(
  data,
  what,
  when,
  where,
  event,
  call = rlang::caller_env()
) {
  args <- list(what = what, when = when, where = where, event = event)
  args <- args[!vapply(args, is.null, logical(1))]
  update <- list()
  for (role in names(args)) {
    slots <- as_variable_slots(args[[role]], role, call = call)
    ensure_known_variable_slots(data, role, names(slots), call = call)
    update[[role]] <- slots
  }
  update
}


#' Turn one role argument into a named list of slots
#'
#' @keywords internal
as_variable_slots <- function(value, role, call = rlang::caller_env()) {
  if (is.character(value)) {
    slot <- list_main_variable_slots()[[role]]
    if (is.na(slot)) {
      cli::cli_abort(
        c(
          "{.arg {role}} must be a named list of slots.",
          "i" = "For example {.code list(state = \"behaviour\")}."
        ),
        call = call
      )
    }
    return(stats::setNames(list(value), slot))
  }
  if (is.list(value) && length(value) == 0L) {
    return(list())
  }
  if (!is.list(value) || is.null(names(value)) || any(names(value) == "")) {
    cli::cli_abort(
      "{.arg {role}} must be a named list of slots or a character vector.",
      call = call
    )
  }
  # `NULL` and all-`NA` slots read as empty (#76).
  value <- lapply(value, function(v) {
    if (length(v) == 0L || all(is.na(v))) character() else v
  })
  if (!all(vapply(value, is.character, logical(1)))) {
    cli::cli_abort(
      "Every slot of {.arg {role}} must be a character vector.",
      call = call
    )
  }
  lapply(value, function(v) v[!is.na(v)])
}


#' Refuse roles and slots the frame's class does not carry
#'
#' @keywords internal
ensure_known_variable_slots <- function(
  data,
  role,
  slots,
  call = rlang::caller_env()
) {
  class <- frame_class(data)
  known <- list_metadata_schema(class)$slots
  if (!role %in% names(known)) {
    cli::cli_abort(
      "An {.cls {class}} has no {.field {role}} variables.",
      call = call
    )
  }
  unknown <- setdiff(slots, known[[role]])
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.field {role}} on an {.cls {class}} has no slot{?s} {.val {unknown}}.",
        "i" = "Its slots are {.val {known[[role]]}}."
      ),
      call = call
    )
  }
  invisible(TRUE)
}


#' Declare a complete variables category and restructure the frame to match
#'
#' @param data An aniframe.
#' @param variables The complete variables category.
#' @param strict Whether an invalid axis role errors rather than degrading
#'   the coordinate system to `unknown`.
#'
#' @return `data`, restructured and re-declared.
#' @keywords internal
apply_variables <- function(data, variables, strict = TRUE) {
  if (is_anievent(data)) {
    return(restructure_anievent(
      data,
      as.character(variables$what$keys),
      c(variables$when$keys, variables$when$interval)
    ))
  }

  index <- variables$when$index
  if (!identical(index, get_index(data))) {
    ensure_valid_index(data, index)
    md <- get_metadata(data)
    md$variables$when$index <- index
    data <- attach_metadata(data, md)
  }

  data <- restructure_anipoint(
    data,
    as.character(variables$what$keys),
    as.character(variables$when$keys),
    variables$where$position %||% character(),
    orientation = variables$where$orientation,
    strict = strict
  )
  declare_variables_event(
    data,
    state = variables$event$state,
    point = variables$event$point
  )
}


#' Ensure a declaration is a character vector
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
#' @param data A data frame.
#' @param cols Character vector of declared column names.
#' @param role One of `"what"`, `"when"`, `"where"`, `"event"`.
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


#' The spatial declaration, as a role mapping where there is one
#'
#' Re-declaring from the bare columns would lose the axis roles and reduce
#' the frame to `unknown` (#109).
#'
#' @param data An aniframe.
#'
#' @return Named character vector, or a bare one when no roles are known.
#' @keywords internal
get_declared_where <- function(data) {
  axes <- if (is_anipoint(data)) resolve_axes(get_metadata(data))
  if (length(axes) > 0L) {
    return(axes)
  }
  unname(md_where_position(get_metadata(data)))
}
