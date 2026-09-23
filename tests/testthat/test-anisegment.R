# Three points on a line: a at the origin, b at (3, 4), c at (3, 0).
line_frame <- function(dims = 2) {
  df <- data.frame(
    individual = "i",
    keypoint = rep(c("a", "b", "c"), each = 2),
    time = rep(1:2, 3),
    x = c(0, 1, 3, 4, 3, 4),
    y = c(0, 0, 4, 4, 0, 0),
    confidence = c(0.9, 0.8, 0.5, 0.7, 1, 1)
  )
  if (dims == 3) {
    df$z <- c(0, 0, 0, 0, 12, 12)
  }
  as_anipoint(df) |>
    set_structure(
      anistructure(
        segments = data.frame(
          segment = c("ab", "bc"),
          from = c("a", "b"),
          to = c("b", "c")
        ),
        root = "a"
      )
    )
}

test_that("each segment gets a length and a unit direction", {
  seg <- as_anisegment(line_frame())
  expect_s3_class(seg, c("anisegment", "aniframe"))
  ab <- seg[seg$segment == "ab" & seg$time == 1, ]
  expect_equal(ab$length, 5)
  expect_equal(c(ab$ux, ab$uy), c(0.6, 0.8))
  bc <- seg[seg$segment == "bc" & seg$time == 1, ]
  expect_equal(c(bc$length, bc$ux, bc$uy), c(4, 0, -1))
})

test_that("the segment key replaces the structure's variable", {
  seg <- as_anisegment(line_frame())
  expect_equal(get_variables(seg, "what"), c("individual", "segment"))
  expect_equal(get_keys(seg), c("individual", "segment"))
  expect_equal(get_index(seg), "time")
  expect_equal(get_variables(seg, "where", "length"), "length")
  expect_equal(get_variables(seg, "where", "direction"), c(x = "ux", y = "uy"))
  expect_equal(levels(seg$segment), c("ab", "bc"))
  expect_equal(dplyr::group_vars(seg), c("individual", "segment"))
})

test_that("3D frames get uz", {
  seg <- as_anisegment(line_frame(dims = 3))
  bc <- seg[seg$segment == "bc" & seg$time == 1, ]
  expect_equal(
    c(bc$length, bc$ux, bc$uy, bc$uz),
    c(4 * sqrt(10), 0, -1, 3) / c(1, 1, sqrt(10), sqrt(10))
  )
})

test_that("confidence is the lower of the two endpoints", {
  seg <- as_anisegment(line_frame())
  expect_equal(seg$confidence[seg$segment == "ab"], c(0.5, 0.7))
})

test_that("a zero-length segment has no direction", {
  af <- line_frame() |> dplyr::mutate(x = 0, y = 0)
  seg <- as_anisegment(af)
  expect_true(all(seg$length == 0))
  expect_true(all(is.na(seg$ux)))
})

test_that("the structure is picked by name, or when it is the only one", {
  af <- line_frame()
  expect_error(
    as_anisegment(remove_structure(af, "keypoint")),
    "no structure with segments"
  )
  af2 <- set_structure(
    af,
    anistructure(segments = list(c("a", "c"))),
    name = "short"
  )
  expect_error(as_anisegment(af2), "Several structures")
  seg <- as_anisegment(af2, structure = "short")
  expect_equal(levels(seg$segment), "a-c")
  expect_error(as_anisegment(af, structure = "nope"), "no structure named")
})

test_that("sibling structures are dropped and others kept", {
  af <- line_frame() |>
    set_structure(anistructure(points = c("a", "b")), name = "pair") |>
    set_structure(anistructure(points = "i"), "individual", "solo")
  seg <- as_anisegment(af, structure = "keypoint")
  expect_equal(sort(names(get_structure(seg))), c("keypoint", "solo"))
})

test_that("the conversion refuses what it cannot express", {
  af <- line_frame()
  expect_error(
    as_anisegment(dplyr::mutate(af, segment = 1)),
    "already has a"
  )
  df <- data.frame(time = 1:2, keypoint = "a", rho = 1, phi = 0)
  expect_error(as_anisegment(as_anipoint(df)), "Cartesian")
})

test_that("as_anipoint() rebuilds the positions from the root", {
  for (dims in c(2, 3)) {
    af <- line_frame(dims)
    back <- as_anipoint(as_anisegment(af), root = af)
    expect_s3_class(back, "anipoint")
    key <- function(x) {
      x <- dplyr::ungroup(strip_animovement_class(x))
      x$keypoint <- as.character(x$keypoint)
      x[order(x$keypoint, x$time), intersect(c("x", "y", "z"), names(x))]
    }
    expect_equal(key(back), key(af), ignore_attr = TRUE)
    expect_equal(get_structure(back), get_structure(af))
  }
})

test_that("segments pointing at the root are walked backwards, and cycles ignored", {
  af <- line_frame() |>
    set_structure(anistructure(
      segments = data.frame(
        segment = c("ba", "bc", "ca"),
        from = c("b", "b", "c"),
        to = c("a", "c", "a")
      ),
      root = "a"
    ))
  back <- as_anipoint(as_anisegment(af), root = af)
  b <- back[as.character(back$keypoint) == "b" & back$time == 1, ]
  expect_equal(c(b$x, b$y), c(3, 4))
})

test_that("the inverse states what it needs", {
  af <- line_frame()
  seg <- as_anisegment(af)
  expect_error(as_anipoint(seg), "root's trajectory")
  expect_error(
    as_anipoint(seg, root = dplyr::filter(af, keypoint != "a")),
    "no rows for the root"
  )
  no_root <- set_structure(af, anistructure(segments = list(c("a", "b"))))
  expect_error(
    as_anipoint(as_anisegment(no_root), root = af),
    "no .*root"
  )
  expect_error(
    as_anipoint(seg, root = line_frame(dims = 3)),
    "but the segments in"
  )
  split <- set_structure(
    af,
    anistructure(
      points = c("a", "b", "c"),
      segments = list(c("a", "b")),
      root = "a"
    )
  )
  expect_error(
    as_anipoint(as_anisegment(split), root = af),
    "not connected to the root"
  )
})

test_that("an anisegment works with the shared verbs and accessors", {
  seg <- as_anisegment(line_frame())
  expect_s3_class(dplyr::filter(seg, time > 1), "anisegment")
  expect_true(is_anisegment(seg))
  expect_invisible(ensure_is_anisegment(seg))
  expect_false(is_anisegment(line_frame()))
  expect_error(ensure_is_anisegment(line_frame()), "not an anisegment")

  seg2 <- add_variables(dplyr::mutate(seg, trial = 1L), when = "trial")
  expect_equal(get_keys(seg2), c("individual", "segment", "trial"))
  expect_error(set_variables(seg, where = "x"), "no slot")

  header <- pillar::tbl_sum(seg)
  expect_equal(names(header)[1], "anisegment")
  expect_equal(unname(header["Structure"]), "keypoint")
})

test_that("unit conversions rescale the index and the length", {
  seg <- set_metadata(as_anisegment(line_frame()), unit_space = "mm")
  cm <- convert_unit_space(seg, "cm")
  expect_equal(cm$length, seg$length / 10)
  expect_equal(cm$ux, seg$ux)

  s <- convert_unit_time(set_metadata(seg, sampling_rate = 2), "s")
  expect_equal(s$time, seg$time / 2)
})
