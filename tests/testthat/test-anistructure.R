test_that("points default to the segment endpoints", {
  s <- anistructure(segments = list(c("a", "b"), c("b", "c")))
  expect_equal(s$points, c("a", "b", "c"))
  expect_equal(s$segments$segment, c("a-b", "b-c"))
  expect_true(all(is.na(s$segments$length)))
  expect_true(is.na(s$variable))
})

test_that("a structure can be points alone", {
  s <- anistructure(points = c("gk", "cb"))
  expect_equal(nrow(s$segments), 0L)
  expect_equal(nrow(s$joints), 0L)
})

test_that("named from/to pairs are read by name", {
  s <- anistructure(segments = list(c(to = "b", from = "a")))
  expect_equal(c(s$segments$from, s$segments$to), c("a", "b"))
})

test_that("single-DoF limits fold into the dof list", {
  s <- example_structure()
  knee <- s$joints$dof[[which(s$joints$joint == "knee_right")]]
  expect_equal(knee$dof, "angle")
  expect_equal(c(knee$min, knee$max), c(0, 2.5))
})

test_that("a dof list-column is kept per degree of freedom", {
  s <- anistructure(
    segments = list(c("a", "b"), c("b", "c")),
    joints = dplyr::tibble(
      a = "a-b",
      b = "b-c",
      dof = list(data.frame(
        dof = c("flexion", "abduction"),
        axis = c("x", "z"),
        min = c(0, -0.5),
        max = c(2, 0.5)
      ))
    )
  )
  expect_equal(s$joints$joint, "a-b-b-c")
  expect_equal(s$joints$dof[[1]]$dof, c("flexion", "abduction"))
  expect_true(all(is.na(s$joints$dof[[1]]$rest)))
})

test_that("joints without limits carry an empty dof table", {
  s <- anistructure(
    segments = list(c("a", "b"), c("b", "c")),
    joints = data.frame(a = "a-b", b = "b-c", axis = "z")
  )
  expect_equal(nrow(s$joints$dof[[1]]), 0L)
  expect_equal(s$joints$axis, "z")
})

test_that("the validator names each inconsistency", {
  seg <- list(c("a", "b"), c("b", "c"))
  expect_error(anistructure(points = c("a", "a")), "unique")
  expect_error(
    anistructure(points = "a", segments = seg),
    "not among the points"
  )
  expect_error(anistructure(segments = list(c("a", "a"))), "itself")
  expect_error(
    anistructure(segments = data.frame(from = "a", to = "b", length = -1)),
    "positive"
  )
  expect_error(
    anistructure(
      segments = data.frame(
        segment = c("s", "s"),
        from = c("a", "b"),
        to = c("b", "c")
      )
    ),
    "Segment names"
  )
  expect_error(
    anistructure(segments = seg, joints = data.frame(a = "a-b", b = "nope")),
    "not defined"
  )
  expect_error(
    anistructure(segments = seg, joints = data.frame(a = "a-b", b = "a-b")),
    "with itself"
  )
  expect_error(
    anistructure(
      segments = seg,
      joints = data.frame(a = "a-b", b = "b-c", axis = "w")
    ),
    "axis"
  )
  expect_error(
    anistructure(
      segments = seg,
      joints = data.frame(a = "a-b", b = "b-c", min = 1, max = 0)
    ),
    "above"
  )
  expect_error(
    anistructure(
      segments = seg,
      joints = data.frame(a = "a-b", b = "b-c", min = 0, max = 1, rest = 2)
    ),
    "outside"
  )
  expect_error(anistructure(segments = seg, root = "z"), "root")
  expect_error(anistructure(joints = data.frame(x = 1)), "a.*b")
  expect_error(anistructure(segments = 1), "data frame or a list")
  expect_error(anistructure(segments = list("a")), "length-2")
  expect_error(anistructure(segments = data.frame(a = 1)), "from")
})

test_that("a joint axis may be a segment name", {
  seg <- list(c("a", "b"), c("b", "c"), c("a", "c"))
  s <- anistructure(
    segments = seg,
    joints = data.frame(a = "a-b", b = "b-c", axis = "a-c")
  )
  expect_equal(s$joints$axis, "a-c")
})

test_that("is_anistructure() and its guard", {
  expect_true(is_anistructure(example_structure()))
  expect_false(is_anistructure(list()))
  expect_error(ensure_is_anistructure(list()), "anistructure")
  expect_invisible(validate_anistructure(example_structure()))
})

test_that("printing summarises the parts", {
  s <- example_structure()
  s$variable <- "keypoint"
  s$twist <- "zero"
  out <- format(s)
  expect_match(out[[1]], "11 points, 10 segments, 3 joints")
  expect_match(out[[2]], "variable: keypoint; root: abdomen; twist: zero")
  expect_output(
    print(anistructure(points = "a")),
    "1 point, 0 segments, 0 joints"
  )
})
