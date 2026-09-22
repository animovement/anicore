# Tests for the variables_event field and its setters (#66, #76, #82)
#
# The fourth variable role. Unlike the other three it doesn't change the
# shape of the frame — nothing is retyped, relocated or regrouped — but
# it names columns, so a name matching nothing is a promise the frame
# can't keep. Since #82 the field is written through its own setters and
# refused by set_metadata(), so the validation that used to be exercised
# through set_metadata() now runs behind declare_variables_event().

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

test_that("ensure_valid_metadata() tolerates metadata missing variables_event", {
  md <- list_default_metadata()
  md$variables_event <- NULL

  expect_no_error(ensure_valid_metadata(md))
})

test_that("ensure_valid_variables_event() returns invisibly on NULL", {
  expect_no_error(ensure_valid_variables_event(NULL))
})

test_that("a malformed variables_event is caught on any metadata write", {
  # The setters can only produce a well-formed list, so these guards now
  # only fire on metadata forced onto an object by hand or read back from
  # an object serialised elsewhere. `write_metadata()` runs them on every
  # write, so a drifted frame trips them on the next dplyr verb.
  half <- drift_metadata(event_af(), variables_event = list(state = "x"))
  expect_error(dplyr::filter(half, time > 0), "must be a list with entries")

  # A non-list never gets that far through a write — the metadata class
  # check rejects it first — so the guard is exercised directly.
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

test_that("set_variables_event declares both sides and reads back", {
  af <- set_variables_event(event_af(), state = "behaviour", point = "call")

  expect_equal(
    get_variables_event(af),
    list(state = "behaviour", point = "call")
  )
})

test_that("set_variables_event replaces the named side, leaving the other", {
  # Naming one side must not silently undeclare the other: the columns
  # would stay in the frame while to_anievent() quietly stopped encoding
  # them.
  af <- event_af() |>
    dplyr::mutate(did_stuff = factor("yes")) |>
    set_variables_event(state = "behaviour", point = "call")

  swapped <- set_variables_event(af, state = "did_stuff")
  expect_equal(get_variables_event(swapped)$state, "did_stuff")
  expect_equal(get_variables_event(swapped)$point, "call")

  swapped_point <- set_variables_event(af, point = character())
  expect_equal(get_variables_event(swapped_point)$state, "behaviour")
  expect_length(get_variables_event(swapped_point)$point, 0)
})

test_that("clearing a side is explicit, and naming neither is a no-op", {
  af <- set_variables_event(event_af(), state = "behaviour", point = "call")

  expect_equal(get_variables_event(set_variables_event(af)), {
    get_variables_event(af)
  })

  cleared <- set_variables_event(af, state = character(), point = character())
  expect_length(get_variables_event(cleared)$state, 0)
  expect_length(get_variables_event(cleared)$point, 0)
})

test_that("get_variables_event returns both sides on an undeclared frame", {
  declared <- get_variables_event(event_af())

  expect_named(declared, c("state", "point"))
  expect_length(declared$state, 0)
  expect_length(declared$point, 0)
})

test_that("multiple state columns are kept in the order given", {
  af <- event_af() |>
    dplyr::mutate(posture = factor("upright")) |>
    set_variables_event(state = c("behaviour", "posture"))

  expect_equal(get_variables_event(af)$state, c("behaviour", "posture"))
})

# ---- add / remove ------------------------------------------------------

test_that("add_variables_event appends to one side, leaving the other", {
  af <- event_af() |>
    set_variables_event(state = "behaviour") |>
    add_variables_event(point = "call")

  expect_equal(get_variables_event(af)$state, "behaviour")
  expect_equal(get_variables_event(af)$point, "call")
})

test_that("add_variables_event appends within a side without restating", {
  af <- event_af() |>
    dplyr::mutate(posture = factor("upright")) |>
    set_variables_event(state = "behaviour") |>
    add_variables_event(state = "posture")

  expect_equal(get_variables_event(af)$state, c("behaviour", "posture"))
})

test_that("remove_variables_event drops from whichever side holds it", {
  af <- set_variables_event(event_af(), state = "behaviour", point = "call")

  no_state <- remove_variables_event(af, "behaviour")
  expect_length(get_variables_event(no_state)$state, 0)
  expect_equal(get_variables_event(no_state)$point, "call")

  no_point <- remove_variables_event(af, "call")
  expect_equal(get_variables_event(no_point)$state, "behaviour")
  expect_length(get_variables_event(no_point)$point, 0)
})

test_that("removing a declaration leaves the column in place", {
  af <- set_variables_event(event_af(), state = "behaviour")
  dropped <- remove_variables_event(af, "behaviour")

  expect_true("behaviour" %in% names(dropped))
})

# ---- Validation --------------------------------------------------------

test_that("declaring a column that does not exist errors", {
  expect_error(
    set_variables_event(event_af(), state = "grooming"),
    "Event variable"
  )
  expect_error(
    set_variables_event(event_af(), state = "grooming"),
    "grooming"
  )
  expect_error(
    add_variables_event(event_af(), point = "whistle"),
    "not found in data"
  )
})

test_that("a column cannot be both state and point", {
  expect_error(
    set_variables_event(event_af(), state = "behaviour", point = "behaviour"),
    "both a state and a point"
  )
})

test_that("a non-character declaration errors", {
  af <- event_af()

  expect_error(add_variables_event(af, state = 1), "must be a character")
  expect_error(add_variables_event(af, point = 1), "must be a character")
  expect_error(remove_variables_event(af, 1), "must be a character")
  expect_error(
    set_variables_event(af, state = 1:3),
    "must be character vectors"
  )
})

test_that("either side can be declared on its own (#76)", {
  # On a frame with nothing declared, naming one side leaves the other
  # empty -- not because it is cleared, but because it already was.
  state_only <- set_variables_event(event_af(), state = "behaviour")
  expect_equal(get_variables_event(state_only)$state, "behaviour")
  expect_equal(get_variables_event(state_only)$point, character())

  point_only <- set_variables_event(event_af(), point = "call")
  expect_equal(get_variables_event(point_only)$state, character())
  expect_equal(get_variables_event(point_only)$point, "call")
})

test_that("NA entries are read as none rather than erroring (#76)", {
  af <- set_variables_event(event_af(), state = "behaviour", point = NA)

  expect_equal(get_variables_event(af)$state, "behaviour")
  expect_equal(get_variables_event(af)$point, character())
})

# ---- Class boundaries --------------------------------------------------

test_that("an anievent cannot carry an event declaration", {
  ae <- mini_ae()

  expect_error(set_variables_event(ae, state = "label"), "does not have")
  expect_error(get_variables_event(ae), "channel")
})

test_that("the setters reject objects that are neither class", {
  df <- data.frame(time = 1:3, x = 1:3, y = 1:3, behaviour = "REM")

  expect_error(set_variables_event(df, state = "behaviour"), "not an anipoint")
  expect_error(get_variables_event(df), "not an anipoint")
  expect_error(add_variables_event(df, state = "behaviour"), "not an anipoint")
  expect_error(remove_variables_event(df, "behaviour"), "not an anipoint")
})

# ---- set_metadata refuses it -------------------------------------------

test_that("set_metadata refuses variables_event, naming its setter", {
  af <- event_af()

  expect_error(
    set_metadata(af, variables_event = list(state = "behaviour")),
    "cannot write"
  )
  expect_error(
    set_metadata(af, variables_event = list(state = "behaviour")),
    "set_variables_event"
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

test_that("tbl_sum.aniframe surfaces state and point variables in the header", {
  af <- anipoint(
    individual = rep(1L, 4),
    time = 1:4,
    x = rnorm(4),
    y = rnorm(4),
    behaviour = factor(c("REM", "REM", "wake", "wake")),
    call = factor(c(NA, "alarm", NA, NA))
  )
  af <- set_variables_event(af, state = "behaviour", point = "call")

  header <- pillar::tbl_sum(af)
  expect_true("State event variables" %in% names(header))
  expect_equal(unname(header["State event variables"]), "behaviour")
  expect_true("Point event variables" %in% names(header))
  expect_equal(unname(header["Point event variables"]), "call")
})

test_that("tbl_sum.aniframe omits state/point rows when variables_event is empty", {
  af <- example_anipoint()
  header <- pillar::tbl_sum(af)

  expect_false("State event variables" %in% names(header))
  expect_false("Point event variables" %in% names(header))
})

# ---- Downstream --------------------------------------------------------

test_that("to_anievent reads a declaration made through the setter", {
  ae <- event_af() |>
    set_variables_event(state = "behaviour") |>
    to_anievent()

  expect_s3_class(ae, "anievent")
  expect_equal(nrow(ae), 2) # REM(1-2), wake(3-5)
  expect_equal(as.character(ae$label), c("REM", "wake"))
})

test_that("a declared event column passes validate_anipoint", {
  af <- set_variables_event(event_af(), state = "behaviour")
  expect_silent(validate_anipoint(af))
})
