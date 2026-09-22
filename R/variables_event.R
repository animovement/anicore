# Declaring the event variables (#82)
#
# `variables_event` is the fourth variable role, and the odd one out: it
# declares which columns carry per-frame event labels, but unlike the
# other three it does not change the shape of the frame — nothing is
# retyped, relocated, reordered or regrouped by declaring it. What it
# shares with them is that it names columns, and a name that doesn't
# match a column is a promise the frame can't keep. So it gets the same
# four verbs, and `set_metadata()` refuses it for the same reason.

#' Declare the event columns and validate them against the frame
#'
#' @param data An anipoint object.
#' @param state,point Character vectors of column names, or `NULL`.
#'
#' @return `data`, with the declaration recorded.
#' @keywords internal
declare_variables_event <- function(data, state, point) {
  ensure_can_declare_events(data)

  # `NULL` means "leave this side alone". With named arguments it reads as
  # not-supplied, and silently clearing the side the caller never mentioned
  # is the same footgun `add_*()` exists to avoid elsewhere. A side is
  # cleared by naming it explicitly as `character()`.
  current <- normalise_variables_event(md_event(get_metadata(data)))
  if (is.null(state)) {
    state <- current$state
  }
  if (is.null(point)) {
    point <- current$point
  }

  declared <- normalise_variables_event(list(state = state, point = point))
  ensure_valid_variables_event(declared)
  ensure_has_declared_cols(
    data,
    c(declared$state, declared$point),
    "event"
  )

  md <- get_metadata(data)
  md$variables$event <- declared

  write_metadata(data, md)
}


#' Ensure the object can carry an event declaration
#'
#' `variables_event` names per-frame columns, which only an anipoint
#' has. An anievent already *is* the encoded form — its events live in
#' `channel` and `label` — so `to_anievent()` drops the field rather than
#' inheriting it.
#'
#' @param data Object to test.
#'
#' @return `TRUE`, invisibly.
#' @keywords internal
ensure_can_declare_events <- function(data) {
  if (is_anievent(data)) {
    cli::cli_abort(c(
      "{.field variables_event} declares per-frame event columns, which an {.cls anievent} does not have.",
      "i" = "An anievent is already the encoded form: its events live in {.field channel} and {.field label}."
    ))
  }

  ensure_is_anipoint(data)
  invisible(TRUE)
}


#' Declare which columns carry per-frame event labels
#'
#' @description
#' `variables_event` names the `anipoint` columns holding per-frame
#' categorical event labels, split into two kinds:
#'
#' * **state** columns are interval-valued — a run of identical values is
#'   one durative bout. List them coarse to fine when they nest.
#' * **point** columns are instantaneous — every non-`NA` frame is its
#'   own zero-length event.
#'
#' [to_anievent()] reads the declaration to know what to encode, and the
#' print header surfaces it as "State event variables" / "Point event
#' variables".
#'
#' These functions declare the columns and check they exist, so the
#' metadata cannot promise a column the frame doesn't have.
#' [set_metadata()] refuses the field for that reason.
#'
#' * `set_variables_event()` replaces the side(s) you name and leaves the
#'   other alone, so `set_variables_event(data, state = "x")` swaps the
#'   state declaration without touching any point columns. Clear a side by
#'   naming it explicitly: `set_variables_event(data, point = character())`.
#' * `add_variables_event()` appends to the side(s) you name, leaving the
#'   other untouched.
#' * `remove_variables_event()` drops the named columns from whichever
#'   side they are on — a column can only be one kind, so it needs no
#'   `state` / `point` argument.
#' * `get_variables_event()` reads the declaration back as a named list.
#'
#' Only an `anipoint` can carry this declaration: an `anievent` is
#' already the encoded form, with its events in `channel` and `label`.
#'
#' @param data An anipoint object.
#' @param state,point Character vectors of column names. `NULL` (the
#'   default) leaves that side of the declaration as it was.
#' @param variables Character vector of column names to undeclare.
#'
#' @return For the setters, `data` with the declaration recorded. For
#'   `get_variables_event()`, a named list with `state` and `point`
#'   entries.
#'
#' @seealso [to_anievent()], which consumes the declaration;
#'   [set_variables_what()] and friends for the other variable roles.
#'
#' @examples
#' af <- anipoint(
#'   time = 1:5,
#'   x = 1:5,
#'   y = 1:5,
#'   behaviour = factor(c("REM", "REM", "wake", "wake", "wake")),
#'   call = factor(c(NA, "alarm", NA, NA, NA), levels = "alarm")
#' )
#'
#' af <- set_variables_event(af, state = "behaviour", point = "call")
#' get_variables_event(af)
#'
#' # Naming one side leaves the other alone
#' get_variables_event(set_variables_event(af, state = "behaviour"))
#'
#' # Clearing a side is explicit
#' get_variables_event(set_variables_event(af, point = character()))
#'
#' # Declaring a column that isn't there is caught
#' try(add_variables_event(af, state = "grooming"))
#'
#' @name variables_event
NULL


#' @rdname variables_event
#' @export
get_variables_event <- function(data) {
  ensure_can_declare_events(data)
  normalise_variables_event(md_event(get_metadata(data)))
}


#' @rdname variables_event
#' @export
set_variables_event <- function(data, state = NULL, point = NULL) {
  declare_variables_event(data, state = state, point = point)
}


#' @rdname variables_event
#' @export
add_variables_event <- function(data, state = NULL, point = NULL) {
  if (!is.null(state)) {
    ensure_variables_character(state)
  }
  if (!is.null(point)) {
    ensure_variables_character(point)
  }
  current <- get_variables_event(data)

  declare_variables_event(
    data,
    state = union(current$state, state),
    point = union(current$point, point)
  )
}


#' @rdname variables_event
#' @export
remove_variables_event <- function(data, variables) {
  ensure_variables_character(variables)
  current <- get_variables_event(data)

  declare_variables_event(
    data,
    state = setdiff(current$state, variables),
    point = setdiff(current$point, variables)
  )
}
