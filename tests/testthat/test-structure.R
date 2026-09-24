af <- function() {
  example_anipoint(n_obs = 3, n_individuals = 3)
}

test_that("set_structure() attaches under the variable's name by default", {
  x <- set_structure(af(), example_structure())
  s <- get_structure(x, "keypoint")
  expect_s3_class(s, "anistructure")
  expect_equal(s$variable, "keypoint")
})

test_that("several named structures can span the same variable", {
  x <- af() |>
    set_structure(
      anistructure(points = c("1", "2", "3")),
      "individual",
      "team"
    ) |>
    set_structure(
      anistructure(segments = list(c("1", "2"))),
      "individual",
      "pair"
    ) |>
    set_structure(example_structure())

  expect_equal(names(get_structure(x)), c("team", "pair", "keypoint"))
  expect_equal(get_structure(x, "pair")$variable, "individual")
  expect_equal(get_structure(x, "team")$points, c("1", "2", "3"))
})

test_that("a structure of the same name is replaced", {
  x <- af() |>
    set_structure(anistructure(points = "1"), "individual", "focal") |>
    set_structure(anistructure(points = "2"), "individual", "focal")
  expect_equal(get_structure(x, "focal")$points, "2")
})

test_that("remove_structure() drops one and refuses unknown names", {
  x <- set_structure(af(), example_structure())
  x <- remove_structure(x, "keypoint")
  expect_length(get_structure(x), 0)
  expect_error(remove_structure(x, "keypoint"), "no structures")
  x <- set_structure(x, example_structure(), name = "skeleton")
  expect_error(get_structure(x, "nope"), "skeleton")
})

test_that("the variable must be a key, and the name a string", {
  expect_error(set_structure(af(), example_structure(), "x"), "key")
  expect_error(
    set_structure(af(), example_structure(), c("a", "b")),
    "single string"
  )
  expect_error(set_structure(af(), example_structure(), name = ""), "non-empty")
  expect_error(set_structure(af(), list()), "anistructure")
})

test_that("points missing from the data are kept with a warning", {
  expect_warning(
    x <- set_structure(af(), anistructure(points = c("1", "99")), "individual"),
    "99"
  )
  expect_equal(get_structure(x, "individual")$points, c("1", "99"))
})

test_that("structures survive dplyr verbs", {
  x <- set_structure(af(), example_structure())
  expect_equal(
    get_structure(dplyr::filter(x, time > 1)),
    get_structure(x)
  )
})

test_that("legacy connection tables migrate to segments-only structures", {
  x <- legacy_anipoint(
    connections = list(keypoint = data.frame(from = "head", to = "neck"))
  )
  s <- get_structure(x, "keypoint")
  expect_s3_class(s, "anistructure")
  expect_equal(s$segments$segment, "head-neck")
  expect_equal(s$variable, "keypoint")

  md <- unclass(get_metadata(af()))
  md$structure <- list(keypoint = data.frame(from = "a", to = "b"))
  y <- af()
  attr(y, "metadata") <- md
  expect_s3_class(get_structure(y, "keypoint"), "anistructure")
})

test_that("the structure category only holds named anistructures", {
  md <- unclass(get_metadata(af()))
  bad <- md
  bad$structure <- list(example_structure())
  expect_error(ensure_valid_metadata(bad), "Structure names")
  bad$structure <- list(k = list())
  expect_error(ensure_valid_metadata(bad), "anistructure")
  bad$structure <- example_structure()
  expect_error(ensure_valid_metadata(bad), "named list")
})

test_that("set_metadata() points structure writes at set_structure()", {
  expect_error(set_metadata(af(), structure = list()), "set_structure")
  expect_error(get_metadata(af(), "connections"), "get_structure")
})
