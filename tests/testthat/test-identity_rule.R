# Tests for the identity (`what`) rule (#77)
#
# The rule an aniframe actually enforces is "at least one identity
# variable", not "a keypoint column". Auto-detection guarantees it by
# adding one when the data has none; an explicit `character(0)` is a
# deliberate opt-out and is left alone.

flat_df <- function() {
  data.frame(time = 1:5, x = as.numeric(1:5), y = as.numeric(1:5))
}

# ---- The rule ----------------------------------------------------------

test_that("auto-detection guarantees at least one identity variable", {
  af <- as_anipoint(flat_df())

  expect_gte(length(get_metadata(af, "variables_what")), 1)
  expect_true(all(get_metadata(af, "variables_what") %in% names(af)))
})

test_that("an identity column present in the data is used as-is", {
  af <- as_anipoint(dplyr::mutate(flat_df(), track = 1L))

  expect_equal(get_metadata(af, "variables_what"), "track")
  expect_false("keypoint" %in% names(af))
})

test_that("every recognised identity column is picked up, in order", {
  df <- dplyr::mutate(
    flat_df(),
    keypoint = "snout",
    model = "m",
    individual = "a",
    track = 1L
  )
  af <- as_anipoint(df)

  expect_equal(
    get_metadata(af, "variables_what"),
    c("model", "individual", "track", "keypoint")
  )
  # Identity columns lead the frame, in the same order.
  expect_equal(
    names(af)[1:4],
    c("model", "individual", "track", "keypoint")
  )
})

test_that("the injected identity is keypoint = centroid", {
  af <- as_anipoint(flat_df())

  expect_equal(get_metadata(af, "variables_what"), "keypoint")
  expect_equal(as.character(unique(af$keypoint)), "centroid")
})

test_that("add_default_identity leaves data that already has an identity alone", {
  with_id <- dplyr::mutate(flat_df(), individual = "a")

  expect_identical(add_default_identity(with_id), with_id)
  expect_false("keypoint" %in% names(add_default_identity(with_id)))
})

test_that("add_default_identity adds one when there is none", {
  out <- add_default_identity(flat_df())

  expect_true("keypoint" %in% names(out))
  expect_equal(unique(out$keypoint), "centroid")
})

# ---- The opt-out -------------------------------------------------------

test_that("an explicit character(0) declares no identity variables", {
  af <- as_anipoint(flat_df(), variables_what = character(0))

  expect_length(get_metadata(af, "variables_what"), 0)
  expect_false("keypoint" %in% names(af))
  expect_false(dplyr::is_grouped_df(af))
})

test_that("the opt-out survives the anipoint() constructor too", {
  af <- anipoint(
    time = 1:5,
    x = as.numeric(1:5),
    y = as.numeric(1:5),
    variables_what = character(0)
  )

  expect_length(get_metadata(af, "variables_what"), 0)
  expect_false("keypoint" %in% names(af))
})

# ---- Validation --------------------------------------------------------

test_that("declaring an identity column that isn't there errors", {
  expect_error(
    as_anipoint(flat_df(), variables_what = "individual"),
    "Identity variable"
  )
  expect_error(
    as_anipoint(flat_df(), variables_what = "individual"),
    "individual"
  )
})

test_that("a partly-present declaration errors and names only the missing", {
  df <- dplyr::mutate(flat_df(), keypoint = "snout")

  expect_error(
    as_anipoint(df, variables_what = c("nope", "keypoint")),
    "nope"
  )
})

test_that("declared identity variables are all present in the metadata", {
  df <- dplyr::mutate(flat_df(), individual = "a", keypoint = "snout")
  af <- as_anipoint(df, variables_what = c("individual", "keypoint"))

  expect_equal(get_metadata(af, "variables_what"), c("individual", "keypoint"))
  expect_true(all(get_metadata(af, "variables_what") %in% names(af)))
})

test_that("the recognised identity names are a single source of truth", {
  # Guards against the list drifting between the docs and the code.
  expect_equal(
    list_recognised_variables_what(),
    c("model", "individual", "subject", "track", "keypoint")
  )
})

test_that("aniframe and anievent recognise the same identity names", {
  # `subject` is the behavioural-coding name for what tracking tools
  # call an `individual`; both classes accept both.
  af <- as_anipoint(dplyr::mutate(flat_df(), subject = "a"))
  expect_equal(get_metadata(af, "variables_what"), "subject")
  expect_false("keypoint" %in% names(af))

  ae <- as_anievent(data.frame(
    keypoint = "snout",
    channel = "behaviour",
    label = "REM",
    start = 1,
    stop = 2
  ))
  expect_equal(get_metadata(ae, "variables_what"), "keypoint")
})
