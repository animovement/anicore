# Test outline for connections API:
#
# Storage shape:
#   - default `connections` metadata is an empty list
#   - set_connections stores a 2-col tibble keyed by variable name
#
# set_connections inputs:
#   - accepts data.frame with from/to columns
#   - accepts list of length-2 character vectors
#   - NULL clears the entry for that variable
#   - errors on data.frame missing from/to columns
#   - errors on malformed list elements
#   - errors on unsupported input type
#
# Variable validation:
#   - errors when variable is not in variables_what or variables_when
#   - allows variable in variables_when (e.g. "session")
#
# Endpoint warning (typo-catcher, #6):
#   - warns when from/to value isn't in the variable's column
#   - keeps the connection despite the warning
#   - skips the warning when the variable column is absent from data
#
# get_connections:
#   - returns the full named list when variable is NULL
#   - returns an empty tibble when no connections are set for variable
#
# add_connections:
#   - appends a single pair (length-1 vectors)
#   - appends multiple pairs (length-N vectors)
#   - preserves existing connections from previous calls
#   - errors when from/to lengths differ
#
# remove_connections:
#   - removes exact (directional) matches
#   - leaves non-matching pairs alone
#   - is a no-op when the variable has no connections
#
# Multiple variables:
#   - connections on different variables coexist
#
# Defensive paths and edge cases:
#   - get_connections returns an empty list when the metadata field is NULL
#   - set_connections errors when variable isn't a single character string
#   - add_connections errors when from/to vectors are empty
#   - set_connections doesn't warn when variable is in metadata but the
#     column is absent from data (e.g. staged for a future merge)
#
# Round-trip with set_metadata (regression for tibble-merge bug):
#   - subsequent set_connections call doesn't error (set_metadata replaces
#     list-valued fields rather than deep-merging)

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

mini_aniframe <- function() {
  example_anipoint(n_obs = 3, n_individuals = 2, n_keypoints = 5)
}

# ------------------------------------------------------------------
# Storage shape
# ------------------------------------------------------------------

test_that("default connections metadata is an empty list", {
  data <- mini_aniframe()
  expect_equal(get_metadata(data, "connections"), list())
})

test_that("set_connections stores a from/to tibble keyed by variable", {
  data <- mini_aniframe()
  data <- set_connections(
    data,
    list(c("head", "neck"))
  )
  conns <- get_connections(data)
  expect_named(conns, "keypoint")
  expect_s3_class(conns$keypoint, "tbl_df")
  expect_equal(names(conns$keypoint), c("from", "to"))
})

# ------------------------------------------------------------------
# Inputs
# ------------------------------------------------------------------

test_that("set_connections accepts a data.frame with from/to columns", {
  data <- mini_aniframe()
  df <- data.frame(from = c("head", "neck"), to = c("neck", "abdomen"))
  data <- set_connections(data, df)
  expect_equal(get_connections(data, "keypoint")$from, c("head", "neck"))
  expect_equal(get_connections(data, "keypoint")$to, c("neck", "abdomen"))
})

test_that("set_connections accepts a list of length-2 character vectors", {
  data <- mini_aniframe()
  data <- set_connections(
    data,
    list(c("head", "neck"), c("neck", "abdomen"))
  )
  expect_equal(get_connections(data, "keypoint")$from, c("head", "neck"))
  expect_equal(get_connections(data, "keypoint")$to, c("neck", "abdomen"))
})

test_that("set_connections accepts named pairs (c(from = ..., to = ...))", {
  data <- mini_aniframe()
  data <- set_connections(
    data,
    list(
      c(from = "head", to = "neck"),
      c(from = "neck", to = "abdomen")
    )
  )
  expect_equal(get_connections(data, "keypoint")$from, c("head", "neck"))
  expect_equal(get_connections(data, "keypoint")$to, c("neck", "abdomen"))
})

test_that("set_connections handles named pairs in any order", {
  data <- mini_aniframe()
  # Names supplied "to" first, "from" second — should still route correctly
  data <- set_connections(
    data,
    list(c(to = "neck", from = "head"))
  )
  expect_equal(get_connections(data, "keypoint")$from, "head")
  expect_equal(get_connections(data, "keypoint")$to, "neck")
})

test_that("set_connections with NULL clears the variable entry", {
  data <- mini_aniframe()
  data <- set_connections(data, list(c("head", "neck")))
  expect_true("keypoint" %in% names(get_connections(data)))

  data <- set_connections(data, NULL)
  expect_false("keypoint" %in% names(get_connections(data)))
})

test_that("set_connections errors on data.frame missing required columns", {
  data <- mini_aniframe()
  bad <- data.frame(a = "head", b = "neck")
  expect_error(set_connections(data, bad), "must have")
})

test_that("set_connections errors on malformed list elements", {
  data <- mini_aniframe()
  expect_error(set_connections(data, list(c("head"))), "length-2")
})

test_that("set_connections errors on unsupported input types", {
  data <- mini_aniframe()
  expect_error(set_connections(data, "head -> neck"), "data.frame")
})

# ------------------------------------------------------------------
# Variable validation
# ------------------------------------------------------------------

test_that("set_connections errors on unknown variable", {
  data <- mini_aniframe()
  expect_error(
    set_connections(data, list(c("a", "b")), variable = "foobar"),
    "must be one of"
  )
})

test_that("set_connections accepts variables_when entries (e.g. session)", {
  data <- example_anipoint(n_obs = 3, n_sessions = 2)
  expect_no_error(
    set_connections(data, list(c("1", "2")), variable = "session")
  )
})

# ------------------------------------------------------------------
# Endpoint warning (typo-catcher)
# ------------------------------------------------------------------

test_that("set_connections warns when an endpoint isn't in the column", {
  data <- mini_aniframe()
  expect_warning(
    set_connections(data, list(c("head", "necc"))), # typo
    "not present"
  )
})

test_that("set_connections keeps the typo'd connection despite the warning", {
  data <- mini_aniframe()
  data <- suppressWarnings(set_connections(data, list(c("head", "necc"))))
  expect_equal(get_connections(data, "keypoint")$to, "necc")
})

# ------------------------------------------------------------------
# get_connections
# ------------------------------------------------------------------

test_that("get_connections returns the full list when variable is NULL", {
  data <- mini_aniframe()
  data <- set_connections(data, list(c("head", "neck")))
  expect_type(get_connections(data), "list")
  expect_named(get_connections(data), "keypoint")
})

test_that("get_connections returns an empty tibble for unset variable", {
  data <- mini_aniframe()
  result <- get_connections(data, "keypoint")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_equal(names(result), c("from", "to"))
})

# ------------------------------------------------------------------
# add_connections
# ------------------------------------------------------------------

test_that("add_connections appends a single pair", {
  data <- mini_aniframe()
  data <- add_connections(data, from = "head", to = "neck")
  expect_equal(nrow(get_connections(data, "keypoint")), 1)
})

test_that("add_connections appends multiple pairs (vector form)", {
  data <- mini_aniframe()
  data <- add_connections(
    data,
    from = c("head", "neck", "neck"),
    to = c("neck", "shoulder_right", "shoulder_left")
  )
  expect_equal(nrow(get_connections(data, "keypoint")), 3)
})

test_that("add_connections preserves existing connections", {
  data <- mini_aniframe()
  data <- add_connections(data, from = "head", to = "neck")
  data <- add_connections(data, from = "neck", to = "shoulder_right")
  expect_equal(nrow(get_connections(data, "keypoint")), 2)
})

test_that("add_connections errors on length mismatch", {
  data <- mini_aniframe()
  expect_error(
    add_connections(data, from = c("a", "b"), to = "c"),
    "same length"
  )
})

# ------------------------------------------------------------------
# remove_connections
# ------------------------------------------------------------------

test_that("remove_connections removes exact matches", {
  data <- mini_aniframe() |>
    add_connections(
      from = c("head", "neck"),
      to = c("neck", "shoulder_right")
    )
  data <- remove_connections(data, from = "head", to = "neck")
  expect_equal(nrow(get_connections(data, "keypoint")), 1)
  expect_equal(get_connections(data, "keypoint")$from, "neck")
})

test_that("remove_connections is directional (does not match swap)", {
  data <- mini_aniframe() |>
    add_connections(from = "head", to = "neck")
  # Removing the swapped pair should be a no-op.
  data <- remove_connections(data, from = "neck", to = "head")
  expect_equal(nrow(get_connections(data, "keypoint")), 1)
})

test_that("remove_connections is a no-op when no connections exist for variable", {
  data <- mini_aniframe()
  expect_no_error(
    remove_connections(data, from = "head", to = "neck")
  )
})

# ------------------------------------------------------------------
# Multiple variables
# ------------------------------------------------------------------

test_that("connections on different variables coexist", {
  data <- mini_aniframe()
  data <- set_connections(data, list(c("head", "neck")))
  data <- set_connections(data, list(c("1", "2")), variable = "individual")

  conns <- get_connections(data)
  expect_named(conns, c("keypoint", "individual"))
  expect_equal(nrow(conns$keypoint), 1)
  expect_equal(nrow(conns$individual), 1)
})

# ------------------------------------------------------------------
# Defensive paths and input-validation edge cases
# ------------------------------------------------------------------

test_that("get_connections defensively returns an empty list when the field is NULL", {
  # Older / externally-constructed metadata may have a NULL connections
  # field rather than an empty list. Force that state and confirm the
  # defensive `is.null(current)` branch returns list().
  data <- mini_aniframe()
  md <- attr(data, "metadata")
  md["connections"] <- list(NULL)
  attr(data, "metadata") <- md

  expect_equal(get_connections(data), list())
})

test_that("set_connections errors when variable isn't a single character string", {
  data <- mini_aniframe()
  expect_error(
    set_connections(data, list(c("a", "b")), variable = 1L),
    "single character string"
  )
  expect_error(
    set_connections(
      data,
      list(c("a", "b")),
      variable = c("keypoint", "individual")
    ),
    "single character string"
  )
})

test_that("add_connections errors when from or to is empty", {
  data <- mini_aniframe()
  expect_error(
    add_connections(data, from = character(0), to = character(0)),
    "non-empty"
  )
})

test_that("set_connections doesn't warn when variable is in metadata but absent from data", {
  # Declaring a column that isn't in the data is rejected at
  # construction (#77), but metadata can still drift out of sync with
  # the frame afterwards — the divergence `validate_anipoint()` reports.
  # Given such an object, the endpoint check has nothing to check
  # against, so it should early-return rather than warn about every
  # value.
  data <- as_anipoint(
    data.frame(individual = 1L, time = 1:3, x = 1:3, y = 1:3)
  )
  drifted <- get_metadata(data)
  drifted$variables_what <- c("individual", "future_keypoint")
  data <- attach_metadata(data, drifted)

  expect_no_warning(
    data <- set_connections(
      data,
      list(c("a", "b")),
      variable = "future_keypoint"
    )
  )
  expect_equal(nrow(get_connections(data, "future_keypoint")), 1)
})

# ------------------------------------------------------------------
# Round-trip with set_metadata (regression: list-of-tibbles merge bug)
# ------------------------------------------------------------------

test_that("repeated set_connections doesn't error (regression for list merge)", {
  data <- mini_aniframe()
  data <- set_connections(data, list(c("head", "neck")))
  expect_no_error(
    data <- set_connections(
      data,
      list(c("neck", "shoulder_right"), c("neck", "shoulder_left"))
    )
  )
  expect_equal(nrow(get_connections(data, "keypoint")), 2)
})
