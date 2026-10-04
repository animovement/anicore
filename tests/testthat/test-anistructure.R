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

test_that("joint limits are plain columns, NA when not given", {
  s <- example_structure()
  knee <- s$joints[s$joints$joint == "knee_right", ]
  expect_equal(c(knee$min, knee$max), c(0, 2.5))
  expect_true(is.na(knee$rest))
  bare <- anistructure(
    segments = list(c("a", "b"), c("b", "c")),
    joints = data.frame(a = "a-b", b = "b-c", axis = "z")
  )
  expect_equal(bare$joints$joint, "a-b-b-c")
  expect_equal(bare$joints$axis, "z")
  expect_true(all(is.na(unlist(bare$joints[c("min", "max", "rest")]))))
})

test_that("several angles on one segment pair are several joints", {
  s <- anistructure(
    segments = list(c("p", "hip"), c("hip", "knee")),
    joints = data.frame(
      joint = c("flexion", "abduction"),
      a = "p-hip",
      b = "hip-knee",
      axis = c("x", "z"),
      min = c(-0.5, -0.9),
      max = c(2.1, 0.5)
    )
  )
  expect_equal(nrow(s$joints), 2L)
  expect_equal(s$joints$axis, c("x", "z"))
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
  out <- format(s)
  expect_match(out[[1]], "11 points, 10 segments, 3 joints")
  expect_match(out[[2]], "variable: keypoint; root: abdomen")
  expect_output(
    print(anistructure(points = "a")),
    "1 point, 0 segments, 0 joints"
  )
  expect_snapshot(print(example_structure()))
})

test_that("a segment prints once, with its name only when it has its own", {
  s <- anistructure(
    segments = data.frame(
      segment = c("a-b", "shin"),
      from = c("a", "b"),
      to = c("b", "c")
    ),
    joints = data.frame(a = "a-b", b = "shin")
  )
  out <- format(s, width = 80)
  expect_equal(out[[3]], "Segments: a - b, shin: b - c")
  expect_equal(out[[4]], "Joints: a-b - shin")
})

test_that("printing wraps the lists to the width", {
  s <- anistructure(
    segments = lapply(1:8, function(i) {
      paste0("point_", c(i, i + 1))
    })
  )
  out <- format(s, width = 40)
  expect_true(all(nchar(out[-1]) <= 40))
  expect_equal(out[[2]], "Points: point_1, point_2, point_3,")
  expect_equal(out[[3]], "  point_4, point_5, point_6, point_7,")

  local_reproducible_output(width = 50)
  expect_snapshot(print(s))
})

test_that("long lists are truncated like tibble rows", {
  chain <- anistructure(
    segments = lapply(1:23, function(i) {
      paste0("s", c(i, i + 1))
    })
  )
  out <- format(chain, width = Inf)
  expect_equal(
    out[[2]],
    "Points: s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, ... and 14 more"
  )
  expect_match(out[[3]], "s10 - s11, ... and 13 more$")

  all_shown <- format(chain, n = Inf, width = Inf)
  expect_match(all_shown[[3]], "s23 - s24$")
  expect_no_match(paste(all_shown, collapse = " "), "more")

  expect_equal(
    format(chain, n = 2, width = Inf)[[2]],
    "Points: s1, s2, ... and 22 more"
  )
  expect_snapshot(print(chain, n = 3))
})

test_that("n must be a non-negative whole number", {
  s <- example_structure()
  expect_error(format(s, n = -1), "non-negative whole number")
  expect_error(format(s, n = 1.5), "non-negative whole number")
  expect_error(format(s, n = "a"), "non-negative whole number")
  expect_equal(
    format(s, n = 0, width = 80)[[3]],
    "Points: ... and 11 more"
  )
})
