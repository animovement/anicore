# Each method must keep the anievent class and its metadata.

make_anievent <- function() {
  ae <- anievent(
    individual = c(1L, 1L, 2L, 2L),
    channel = c("behaviour", "behaviour", "behaviour", "call"),
    label = c("REM", "wake", "REM", "alarm"),
    start = c(3, 14, 1, 7.5),
    stop = c(9, 19, 6, 7.5)
  )
  set_metadata(ae, sampling_rate = 30)
}

expect_anievent_with_md <- function(x, sr_expected = 30) {
  expect_s3_class(x, "anievent")
  expect_equal(get_metadata(x, "sampling_rate"), sr_expected)
}

# ---- dplyr verbs -------------------------------------------------------

test_that("arrange preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::arrange(ae, .data$start))
})

test_that("filter preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::filter(ae, .data$start > 5))
})

test_that("group_by preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::group_by(ae, individual))
})

test_that("ungroup preserves anievent class and metadata (with warning)", {
  ae <- dplyr::group_by(make_anievent(), individual)
  expect_warning(
    result <- dplyr::ungroup(ae),
    "Ungrouping"
  )
  expect_anievent_with_md(result)
})

test_that("mutate preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::mutate(ae, duration = stop - start))
})

test_that("relocate preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::relocate(ae, "stop", .before = "start"))
})

test_that("rename preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::rename(ae, chan = "channel"))
})

test_that("select preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::select(ae, "channel", "start", "stop"))
})

test_that("slice preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(dplyr::slice(ae, 1:2))
})

# ---- Base R extraction --------------------------------------------------

test_that("[ preserves anievent class and metadata", {
  ae <- make_anievent()
  expect_anievent_with_md(ae[1:2, ])
})

test_that("[[ returns a vector and does not preserve class", {
  ae <- make_anievent()
  v <- ae[["start"]]
  expect_type(v, "double")
  expect_false(inherits(v, "anievent"))
})

test_that("$ returns a vector", {
  ae <- make_anievent()
  v <- ae$start
  expect_type(v, "double")
})

# ---- Assignment ---------------------------------------------------------

test_that("[<- preserves anievent class and metadata", {
  ae <- make_anievent()
  ae[1, "label"] <- factor("REM", levels = levels(ae$label))
  expect_anievent_with_md(ae)
})

test_that("[[<- preserves anievent class and metadata", {
  ae <- make_anievent()
  ae[["start"]] <- ae[["start"]] + 1
  expect_anievent_with_md(ae)
})

test_that("$<- preserves anievent class and metadata", {
  ae <- make_anievent()
  ae$start <- ae$start + 1
  expect_anievent_with_md(ae)
})

test_that("names<- preserves anievent class and metadata", {
  ae <- make_anievent()
  nm <- names(ae)
  nm[nm == "channel"] <- "chan"
  names(ae) <- nm
  expect_anievent_with_md(ae)
  expect_true("chan" %in% names(ae))
})

# ---- Modifier list-column round-trip ------------------------------------

test_that("dplyr verbs round-trip a modifiers list-column", {
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "wake", "alarm"),
    start = c(3, 14, 4.5),
    stop = c(9, 19, 4.5),
    modifiers = list(
      c("limb", "whisker"),
      "tail",
      character()
    )
  )

  result <- dplyr::filter(ae, .data$channel == "behaviour")
  expect_s3_class(result, "anievent")
  expect_type(result$modifiers, "list")
  expect_equal(result$modifiers[[1]], c("limb", "whisker"))
})

# ---- Conversion ---------------------------------------------------------

test_that("as.data.frame drops the anievent class", {
  ae <- make_anievent()
  df <- as.data.frame(ae)
  expect_false(inherits(df, "anievent"))
  expect_s3_class(df, "data.frame")
})
