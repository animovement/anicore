# hip above knee, ankle to the right: the knee is bent by a quarter turn.
knee_frame <- function(ankle = c(1, 0), dims = 2, axis = NA, toe_z = 2) {
  df <- data.frame(
    keypoint = c("hip", "knee", "ankle", "toe"),
    time = 1,
    x = c(0, 0, ankle[1], ankle[1]),
    y = c(1, 0, ankle[2], ankle[2] - 1),
    confidence = c(0.9, 0.4, 0.8, 1)
  )
  if (dims == 3) {
    df$z <- c(0, 0, 2, toe_z)
  }
  as_anipoint(df) |>
    set_structure(anistructure(
      segments = data.frame(
        segment = c("thigh", "shin", "foot"),
        from = c("hip", "knee", "ankle"),
        to = c("knee", "ankle", "toe")
      ),
      joints = data.frame(
        joint = c("knee", "ankle"),
        a = c("thigh", "shin"),
        b = c("shin", "foot"),
        axis = axis
      ),
      root = "hip"
    ))
}

test_that("a 2D joint angle is signed, turning from a to b", {
  j <- as_anijoint(knee_frame())
  expect_s3_class(j, c("anijoint", "aniframe"))
  expect_equal(j$angle[j$joint == "knee"], pi / 2)
  mirrored <- as_anijoint(knee_frame(ankle = c(-1, 0)))
  expect_equal(mirrored$angle[mirrored$joint == "knee"], -pi / 2)
})

test_that("an anipoint is converted to segments on the way", {
  expect_equal(
    as_anijoint(knee_frame()),
    as_anijoint(as_anisegment(knee_frame()))
  )
})

test_that("the joint key replaces the segment key", {
  j <- as_anijoint(knee_frame())
  expect_equal(get_variables(j, "what"), "joint")
  expect_equal(get_variables(j, "where"), "angle")
  expect_equal(levels(j$joint), c("knee", "ankle"))
  expect_equal(get_index(j), "time")
})

test_that("3D joints give the included angle, or a signed one about an axis", {
  j <- as_anijoint(knee_frame(dims = 3))
  shin <- c(1, 0, 2)
  expect_equal(
    j$angle[j$joint == "knee"],
    acos(sum(c(0, -1, 0) * shin) / sqrt(sum(shin^2)))
  )
  signed <- as_anijoint(knee_frame(dims = 3, axis = "z"))
  expect_equal(signed$angle[signed$joint == "knee"], pi / 2)
  about_x <- as_anijoint(knee_frame(dims = 3, axis = c("x", NA)))
  expect_equal(about_x$angle[about_x$joint == "knee"], atan2(-2, 0))
})

test_that("a segment can be the axis", {
  # The foot runs down and out of the plane, so it is not parallel to either.
  j <- as_anijoint(knee_frame(dims = 3, axis = c("foot", NA), toe_z = 3))
  expect_false(is.na(j$angle[j$joint == "knee"]))
  expect_equal(
    j$angle[j$joint == "knee"],
    angle_between(c(0, -1, 0), c(1, 0, 2), axis = c(0, -1, 1))
  )
})

test_that("2D joints only turn about z", {
  expect_error(as_anijoint(knee_frame(axis = "x")), "only turns about")
  expect_equal(
    as_anijoint(knee_frame(axis = "z"))$angle,
    as_anijoint(knee_frame())$angle
  )
})

test_that("confidence is the lower of the two segments", {
  j <- as_anijoint(knee_frame())
  expect_equal(j$confidence[j$joint == "knee"], 0.4)
})

test_that("the angle follows unit_angle", {
  af <- set_metadata(knee_frame(), unit_angle = "deg")
  j <- as_anijoint(af)
  expect_equal(j$angle[j$joint == "knee"], 90)
  back <- convert_unit_angle(j, "rad")
  expect_equal(back$angle[back$joint == "knee"], pi / 2)
  expect_equal(
    unique(convert_unit_time(set_metadata(j, sampling_rate = 2), "s")$time),
    0.5
  )
})

test_that("the conversion refuses what it cannot express", {
  no_joints <- set_structure(
    knee_frame(),
    anistructure(segments = list(c("hip", "knee")))
  )
  expect_error(as_anijoint(no_joints), "no joints")
  expect_error(
    as_anijoint(dplyr::mutate(as_anisegment(knee_frame()), joint = 1)),
    "already has a"
  )
  expect_error(as_anijoint(data.frame()), "not an anisegment")
})

test_that("an anijoint works with the shared verbs and accessors", {
  j <- as_anijoint(knee_frame())
  expect_s3_class(dplyr::filter(j, joint == "knee"), "anijoint")
  expect_true(is_anijoint(j))
  expect_invisible(ensure_is_anijoint(j))
  expect_error(ensure_is_anijoint(knee_frame()), "not an anijoint")
  j2 <- add_variables(dplyr::mutate(j, trial = 1L), when = "trial")
  expect_equal(get_keys(j2), c("joint", "trial"))
  header <- pillar::tbl_sum(j)
  expect_equal(names(header)[1], "anijoint")
  expect_equal(unname(header["Structure"]), "keypoint")
})
