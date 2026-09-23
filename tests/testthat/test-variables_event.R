event_af <- function() {
  anipoint(
    time = 1:5,
    x = as.numeric(1:5),
    y = as.numeric(1:5),
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake")),
    call = factor(c(NA, "alarm", NA, NA, NA), levels = "alarm"),
    variables_what = character(0)
  )
}

mini_ae <- function() {
  anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(1, 4),
    stop = c(3, 5)
  )
}

# ---- The field itself --------------------------------------------------

test_that("list_default_metadata() includes an event role with empty state and point", {
  event <- list_default_metadata()$variables$event

  expect_type(event, "list")
  expect_named(event, c("state", "point"))
  expect_type(event$state, "character")
  expect_type(event$point, "character")
  expect_length(event$state, 0)
  expect_length(event$point, 0)
})

test_that("legacy metadata missing variables_event still reads and writes", {
  af <- legacy_anipoint()
  md <- attr(af, "metadata")
  md$variables_event <- NULL
  attr(af, "metadata") <- md

  expect_equal(
    get_variables(af)$event,
    list(state = character(), point = character())
  )
  expect_no_error(set_metadata(af, source = "x"))
})

test_that("ensure_valid_variables_event() returns invisibly on NULL", {
  expect_no_error(ensure_valid_variables_event(NULL))
})

test_that("a malformed variables_event is caught on any metadata write", {
  # The setters only produce well-formed lists, so force a drift; the next
  # dplyr verb's metadata write should catch it.
  half <- drift_metadata(event_af(), variables_event = list(state = "x"))
  expect_error(dplyr::filter(half, time > 0), "must be a list with entries")

  # A non-list is rejected earlier by the metadata class check.
  expect_error(
    ensure_valid_variables_event("nonsense"),
    "must be a list with entries"
  )
})

test_that("normalise_variables_event passes non-list input through untouched", {
  # Left for the validator above to reject, rather than coerced here.
  expect_identical(normalise_variables_event("nonsense"), "nonsense")
  expect_null(normalise_variables_event(NULL))
})

# ---- set / get ---------------------------------------------------------

test_that("set_variables declares both event slots sides and reads back", {
  af <- set_variables(
    event_af(),
    event = list(state = "behaviour", point = "call")
  )

  expect_equal(
    get_variables(af)$event,
    list(state = "behaviour", point = "call")
  )
})

test_that("set_variables replaces the named event slot, leaving the other", {
  # Otherwise the other side's columns would silently stop being encoded.
  af <- event_af() |>
    dplyr::mutate(did_stuff = factor("yes")) |>
    set_variables(event = list(state = "behaviour", point = "call"))

  swapped <- set_variables(af, event = list(state = "did_stuff"))
  expect_equal(get_variables(swapped)$event$state, "did_stuff")
  expect_equal(get_variables(swapped)$event$point, "call")

  swapped_point <- set_variables(af, event = list(point = character()))
  expect_equal(get_variables(swapped_point)$event$state, "behaviour")
  expect_length(get_variables(swapped_point)$event$point, 0)
})

test_that("clearing a side is explicit, and naming neither is a no-op", {
  af <- set_variables(
    event_af(),
    event = list(state = "behaviour", point = "call")
  )

  expect_equal(get_variables(set_variables(af, event = list()))$event, {
    get_variables(af)$event
  })

  cleared <- set_variables(
    af,
    event = list(state = character(), point = character())
  )
  expect_length(get_variables(cleared)$event$state, 0)
  expect_length(get_variables(cleared)$event$point, 0)
})

test_that("get_variables returns both event slots on an undeclared frame", {
  declared <- get_variables(event_af())$event

  expect_named(declared, c("state", "point"))
  expect_length(declared$state, 0)
  expect_length(declared$point, 0)
})

test_that("multiple state columns are kept in the order given", {
  af <- event_af() |>
    dplyr::mutate(posture = factor("upright")) |>
    set_variables(event = list(state = c("behaviour", "posture")))

  expect_equal(get_variables(af)$event$state, c("behaviour", "posture"))
})

# ---- add / remove ------------------------------------------------------

test_that("add_variables appends to one event slot, leaving the other", {
  af <- event_af() |>
    set_variables(event = list(state = "behaviour")) |>
    add_variables(event = list(point = "call"))

  expect_equal(get_variables(af)$event$state, "behaviour")
  expect_equal(get_variables(af)$event$point, "call")
})

test_that("add_variables appends within an event slot without restating", {
  af <- event_af() |>
    dplyr::mutate(posture = factor("upright")) |>
    set_variables(event = list(state = "behaviour")) |>
    add_variables(event = list(state = "posture"))

  expect_equal(get_variables(af)$event$state, c("behaviour", "posture"))
})

test_that("remove_variables drops an event column from whichever side holds it", {
  af <- set_variables(
    event_af(),
    event = list(state = "behaviour", point = "call")
  )

  no_state <- remove_variables(af, event = "behaviour")
  expect_length(get_variables(no_state)$event$state, 0)
  expect_equal(get_variables(no_state)$event$point, "call")

  no_point <- remove_variables(af, event = "call")
  expect_equal(get_variables(no_point)$event$state, "behaviour")
  expect_length(get_variables(no_point)$event$point, 0)
})

test_that("removing a declaration leaves the column in place", {
  af <- set_variables(event_af(), event = list(state = "behaviour"))
  dropped <- remove_variables(af, event = "behaviour")

  expect_true("behaviour" %in% names(dropped))
})

# ---- Validation --------------------------------------------------------

test_that("declaring a column that does not exist errors", {
  expect_error(
    set_variables(event_af(), event = list(state = "grooming")),
    "Event variable"
  )
  expect_error(
    set_variables(event_af(), event = list(state = "grooming")),
    "grooming"
  )
  expect_error(
    add_variables(event_af(), event = list(point = "whistle")),
    "not found in data"
  )
})

test_that("a column cannot be both state and point", {
  expect_error(
    set_variables(
      event_af(),
      event = list(state = "behaviour", point = "behaviour")
    ),
    "both a state and a point"
  )
})

test_that("a non-character declaration errors", {
  af <- event_af()

  expect_error(
    add_variables(af, event = list(state = 1)),
    "must be a character"
  )
  expect_error(
    add_variables(af, event = list(point = 1)),
    "must be a character"
  )
  expect_error(
    remove_variables(af, event = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    set_variables(af, event = list(state = 1:3)),
    "must be a character vector"
  )
})

test_that("either side can be declared on its own (#76)", {
  # The other side is empty because it already was, not because it's cleared.
  state_only <- set_variables(event_af(), event = list(state = "behaviour"))
  expect_equal(get_variables(state_only)$event$state, "behaviour")
  expect_equal(get_variables(state_only)$event$point, character())

  point_only <- set_variables(event_af(), event = list(point = "call"))
  expect_equal(get_variables(point_only)$event$state, character())
  expect_equal(get_variables(point_only)$event$point, "call")
})

test_that("NA entries are read as none rather than erroring (#76)", {
  af <- set_variables(event_af(), event = list(state = "behaviour", point = NA))

  expect_equal(get_variables(af)$event$state, "behaviour")
  expect_equal(get_variables(af)$event$point, character())
})

# ---- Class boundaries --------------------------------------------------

test_that("an anievent cannot carry an event declaration", {
  ae <- mini_ae()

  expect_error(
    set_variables(ae, event = list(state = "label")),
    "has no event variables"
  )
  expect_null(get_variables(ae)$event)
})

test_that("the setters reject objects that are neither class", {
  df <- data.frame(time = 1:3, x = 1:3, y = 1:3, behaviour = "REM")

  expect_error(
    set_variables(df, event = list(state = "behaviour")),
    "not an aniframe"
  )
  expect_error(get_variables(df)$event, "not an aniframe")
  expect_error(
    add_variables(df, event = list(state = "behaviour")),
    "not an aniframe"
  )
  expect_error(remove_variables(df, event = "behaviour"), "not an aniframe")
})

# ---- set_metadata refuses it -------------------------------------------

test_that("set_metadata refuses variables_event, pointing at set_variables", {
  af <- event_af()

  expect_error(
    set_metadata(af, variables_event = list(state = "behaviour")),
    "cannot write"
  )
  expect_error(
    set_metadata(af, variables_event = list(state = "behaviour")),
    "`set_variables\\(\\)`"
  )
})

test_that("the refusal names every offending field at once", {
  af <- event_af()

  expect_error(
    set_metadata(af, variables_what = "x", variables_event = list()),
    "variables_what"
  )
  expect_error(
    set_metadata(af, variables_what = "x", variables_event = list()),
    "variables_event"
  )
})

# ---- Print header ------------------------------------------------------

test_that("tbl_sum.anipoint surfaces state and point variables in the header", {
  af <- anipoint(
    individual = rep(1L, 4),
    time = 1:4,
    x = rnorm(4),
    y = rnorm(4),
    behaviour = factor(c("REM", "REM", "wake", "wake")),
    call = factor(c(NA, "alarm", NA, NA))
  )
  af <- set_variables(af, event = list(state = "behaviour", point = "call"))

  header <- pillar::tbl_sum(af)
  expect_true("State event variables" %in% names(header))
  expect_equal(unname(header["State event variables"]), "behaviour")
  expect_true("Point event variables" %in% names(header))
  expect_equal(unname(header["Point event variables"]), "call")
})

test_that("tbl_sum.anipoint omits state/point rows when variables_event is empty", {
  af <- example_anipoint()
  header <- pillar::tbl_sum(af)

  expect_false("State event variables" %in% names(header))
  expect_false("Point event variables" %in% names(header))
})

# ---- Downstream --------------------------------------------------------

test_that("to_anievent reads a declaration made through the setter", {
  ae <- event_af() |>
    set_variables(event = list(state = "behaviour")) |>
    to_anievent()

  expect_s3_class(ae, "anievent")
  expect_equal(nrow(ae), 2) # REM(1-2), wake(3-5)
  expect_equal(as.character(ae$label), c("REM", "wake"))
})

test_that("a declared event column passes validate_anipoint", {
  af <- set_variables(event_af(), event = list(state = "behaviour"))
  expect_silent(validate_anipoint(af))
})
