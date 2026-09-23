# The variable-role setters (#82): declaring a role reshapes the frame.

flat_af <- function() {
  anipoint(
    time = 1:6,
    x = as.numeric(1:6),
    y = as.numeric(1:6),
    variables_what = character(0)
  )
}

id_af <- function() {
  anipoint(
    keypoint = rep(c("head", "tail"), each = 3),
    time = rep(1:3, 2),
    x = as.numeric(1:6),
    y = as.numeric(1:6)
  )
}

mini_ae <- function() {
  anievent(
    individual = c(1L, 1L, 2L),
    channel = "behaviour",
    label = c("REM", "wake", "REM"),
    start = c(3, 14, 1),
    stop = c(9, 19, 6)
  )
}

# ---- set_metadata() refuses the structural fields ----------------------

test_that("set_metadata refuses each structural field, pointing at set_variables", {
  af <- flat_af()

  expect_error(
    set_metadata(af, variables_what = "id"),
    "cannot write"
  )
  for (field in c("variables_what", "variables_when", "variables_where")) {
    expect_error(
      rlang::exec(set_metadata, af, !!field := "x"),
      "`set_variables\\(\\)`"
    )
  }
})

test_that("set_metadata refuses them through a partial metadata list too", {
  af <- flat_af()

  expect_error(
    set_metadata(af, metadata = list(variables_what = "id")),
    "cannot write"
  )
})

test_that("a complete metadata object can still be restored wholesale", {
  # A wholesale restore is a round-trip, which downstream rebuilds rely on.
  af <- set_metadata(id_af(), sampling_rate = 30)
  md <- get_metadata(af)

  rebuilt <- as_anipoint(dplyr::as_tibble(af))
  restored <- set_metadata(rebuilt, metadata = md)

  expect_equal(get_metadata(restored), md)
  expect_equal(get_variables(restored, "what"), "keypoint")
  expect_equal(get_metadata(restored, "sampling_rate"), 30)
})

test_that("the refusal points at the wholesale route", {
  expect_error(
    set_metadata(flat_af(), variables_what = "id"),
    "restored wholesale"
  )
})

test_that("set_metadata still writes ordinary fields", {
  af <- set_metadata(flat_af(), sampling_rate = 30, source = "test")

  expect_equal(get_metadata(af, "sampling_rate"), 30)
  expect_equal(get_metadata(af, "source"), "test")
})

test_that("the dplyr methods still round-trip structural metadata", {
  # They restore metadata wholesale, so the refusal must not catch them.
  af <- id_af()
  out <- dplyr::filter(af, x > 0)

  expect_equal(get_variables(out, "what"), "keypoint")
  expect_equal(get_metadata(out), get_metadata(af))
})

# ---- Declaring identity ------------------------------------------------

test_that("declaring an identity column groups, retypes and relocates it", {
  # The reprex from #82: mutate() then declare.
  af <- flat_af() |>
    dplyr::mutate(id = "hi") |>
    add_variables(what = "id")

  expect_equal(get_variables(af, "what"), "id")
  expect_equal(dplyr::group_vars(af), "id")
  expect_s3_class(af$id, "factor")
  expect_equal(names(af)[1], "id")
})

test_that("add_variables appends without restating what is there", {
  af <- id_af() |>
    dplyr::mutate(id = "hi") |>
    add_variables(what = "id")

  expect_equal(get_variables(af, "what"), c("keypoint", "id"))
  expect_setequal(dplyr::group_vars(af), c("keypoint", "id"))
})

test_that("set_variables replaces the declaration wholesale", {
  af <- id_af() |>
    dplyr::mutate(id = "hi") |>
    set_variables(what = "id")

  expect_equal(get_variables(af, "what"), "id")
  expect_equal(dplyr::group_vars(af), "id")
})

test_that("remove_variables drops from the declaration and regroups", {
  af <- remove_variables(id_af(), what = "keypoint")

  expect_length(get_variables(af, "what"), 0)
  expect_false(dplyr::is_grouped_df(af))
  # Dropping the declaration doesn't drop the column.
  expect_true("keypoint" %in% names(af))
})

test_that("adding an identity column keeps the other roles intact", {
  before <- get_metadata(id_af())
  after <- get_metadata(
    dplyr::mutate(id_af(), id = "hi") |> add_variables(what = "id")
  )

  before <- unclass(before)
  after <- unclass(after)
  changed <- names(before)[!mapply(identical, before, after[names(before)])]
  expect_equal(changed, "variables")
  expect_equal(
    setdiff(after$variables$what$keys, before$variables$what$keys),
    "id"
  )
  expect_identical(after$variables$when, before$variables$when)
  expect_identical(after$variables$where, before$variables$where)
  expect_identical(after$variables$event, before$variables$event)
})

# ---- Declaring position ------------------------------------------------

test_that("declaring a third spatial column refreshes coordinate_system", {
  # coordinate_system is derived, so declaring position must refresh it (#82).
  af <- flat_af() |>
    dplyr::mutate(z = 0) |>
    add_variables(where = "z")

  expect_equal(get_variables(af, "where"), c("x", "y", "z"))
  expect_equal(
    as.character(get_metadata(af, "coordinate_system")),
    "cartesian_3d"
  )
  expect_silent(validate_anipoint(af))
})

test_that("removing a spatial column refreshes coordinate_system downwards", {
  af <- remove_variables(flat_af(), where = "y")

  expect_equal(get_variables(af, "where"), "x")
  expect_equal(
    as.character(get_metadata(af, "coordinate_system")),
    "cartesian_1d"
  )
})

test_that("declared spatial columns are coerced to numeric", {
  af <- flat_af() |>
    dplyr::mutate(z = "0") |>
    add_variables(where = "z")

  expect_true(is.numeric(af$z))
})

# ---- Declaring time ----------------------------------------------------

test_that("declaring a temporal grouping column groups and orders by it", {
  af <- flat_af() |>
    dplyr::mutate(session = rep(c("b", "a"), each = 3)) |>
    add_variables(when = "session")

  # `time` stays last: rows sort by session, then by time within it.
  expect_equal(get_variables(af, "when", "keys"), "session")
  expect_equal(dplyr::group_vars(af), "session")
  expect_s3_class(af$session, "factor")
  expect_equal(as.character(af$session), c("a", "a", "a", "b", "b", "b"))
})

test_that("remove_variables on when drops the temporal context and ungroups", {
  af <- flat_af() |>
    dplyr::mutate(session = rep(c("b", "a"), each = 3)) |>
    add_variables(when = "session")

  dropped <- remove_variables(af, when = "session")

  # Nothing left but the index, which lives in its own field.
  expect_equal(get_variables(dropped, "when", "keys"), character(0))
  expect_false(dplyr::is_grouped_df(dropped))
  expect_true("session" %in% names(dropped))
})

# ---- Validation --------------------------------------------------------

test_that("declaring a column that does not exist errors", {
  expect_error(add_variables(flat_af(), what = "nope"), "not found in data")
  expect_error(set_variables(flat_af(), where = c("x", "z")), "z")
})

test_that("the error points at create-then-declare", {
  expect_error(
    add_variables(flat_af(), what = "id"),
    "Create the column first"
  )
})

test_that("a non-character declaration errors", {
  af <- flat_af()

  expect_error(
    set_variables(af, what = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    add_variables(af, what = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    remove_variables(af, what = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    add_variables(af, when = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    remove_variables(af, when = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    add_variables(af, where = 1),
    "must be a named list of slots or a character vector"
  )
  expect_error(
    remove_variables(af, where = 1),
    "must be a named list of slots or a character vector"
  )
})

test_that("the setters reject objects that are neither class", {
  df <- data.frame(time = 1:3, x = 1:3, y = 1:3)

  expect_error(set_variables(df, what = "x"), "not an aniframe")
  expect_error(get_variables(df, "what"), "not an aniframe")
  expect_error(get_variables(df, "when", "keys"), "not an aniframe")
  expect_error(get_variables(df, "where"), "not an aniframe")
  expect_error(add_variables(df, what = "x"), "not an aniframe")
  expect_error(remove_variables(df, what = "x"), "not an aniframe")
  expect_error(add_variables(df, when = "x"), "not an aniframe")
  expect_error(remove_variables(df, when = "x"), "not an aniframe")
  expect_error(add_variables(df, where = "x"), "not an aniframe")
  expect_error(remove_variables(df, where = "x"), "not an aniframe")
  expect_error(set_variables(df, when = "x"), "not an aniframe")
  expect_error(set_variables(df, where = "x"), "not an aniframe")
})

# ---- anievent ----------------------------------------------------------

test_that("the setters work on an anievent", {
  ae <- mini_ae() |>
    dplyr::mutate(observation = c("b", "b", "a")) |>
    add_variables(when = "observation")

  expect_true("observation" %in% get_variables(ae, "when", "keys"))
  expect_s3_class(ae, "anievent")
  # Ordered by identity, then temporal context, then start.
  expect_equal(as.character(ae$observation), c("b", "b", "a"))
})

test_that("declaring identity on an anievent relocates and retypes", {
  ae <- set_variables(mini_ae(), what = "individual")

  expect_equal(get_variables(ae, "what"), "individual")
  expect_equal(names(ae)[1], "individual")
})

test_that("an anievent refuses spatial variables", {
  ae <- dplyr::mutate(mini_ae(), x = 1)

  expect_error(set_variables(ae, where = "x"), "has no where variables")
})

test_that("an anievent is never grouped by a declaration", {
  ae <- set_variables(mini_ae(), what = "individual")
  expect_false(dplyr::is_grouped_df(ae))
})

# ---- Construction and re-declaration agree -----------------------------

test_that("declaring reaches the same state as constructing with it", {
  # The two routes used to differ in column order, type and grouping (#82).
  declared <- flat_af() |>
    dplyr::mutate(id = "hi") |>
    add_variables(what = "id")

  constructed <- as_anipoint(
    dplyr::mutate(dplyr::as_tibble(flat_af()), id = "hi"),
    variables_what = "id"
  )

  expect_equal(names(declared), names(constructed))
  expect_equal(dplyr::group_vars(declared), dplyr::group_vars(constructed))
  expect_equal(class(declared$id), class(constructed$id))
  expect_equal(get_metadata(declared), get_metadata(constructed))
})
