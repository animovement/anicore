# ---- Helpers ----
make_af <- function() {
  af <- example_anipoint()
  meta <- get_metadata(af)
  list(obj = af, meta = meta)
}

# Compares metadata, ignoring timezone differences.
expect_metadata_equal <- function(actual, expected) {
  normalize_datetime <- function(x) {
    if (is.list(x)) {
      x <- lapply(x, function(item) {
        if (inherits(item, "POSIXct")) {
          as.numeric(item)
        } else {
          item
        }
      })
    }
    x
  }

  actual_norm <- normalize_datetime(actual)
  expected_norm <- normalize_datetime(expected)

  expect_identical(actual_norm, expected_norm)
}

# ---- dplyr verbs ----
test_that("group_by preserves class & metadata", {
  src <- make_af()
  out <- dplyr::group_by(src$obj, individual)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("ungroup preserves class & metadata", {
  src <- make_af()
  tmp <- dplyr::group_by(src$obj, individual)
  expect_warning(
    out <- dplyr::ungroup(tmp)
  )
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("mutate preserves class & metadata", {
  src <- make_af()
  out <- dplyr::mutate(src$obj, new_col = x * 2)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("select preserves class & metadata", {
  src <- make_af()
  out <- dplyr::select(src$obj, -confidence)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("select without the index or a key gives a plain data frame (#178)", {
  src <- make_af()
  af <- suppressWarnings(dplyr::ungroup(src$obj))
  for (out in list(
    dplyr::select(af, x, y),
    dplyr::select(af, -time),
    dplyr::select(af, -keypoint)
  )) {
    expect_false(inherits(out, "aniframe"))
    expect_null(attr(out, "metadata"))
    expect_s3_class(out, "tbl_df")
  }
  # Grouped, the keys come along but the index does not; still not a frame
  out <- suppressMessages(dplyr::select(src$obj, x, y))
  expect_false(inherits(out, "aniframe"))
  expect_s3_class(out, "grouped_df")
})

test_that("select can rename the index, and the metadata follows (#178)", {
  src <- make_af()
  out <- dplyr::select(src$obj, everything(), t = time)
  expect_s3_class(out, "anipoint")
  expect_equal(get_index(out), "t")
  expect_silent(validate_anipoint(out))
})

test_that("filter preserves class & metadata", {
  src <- make_af()
  out <- dplyr::filter(src$obj, time < 5)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("arrange preserves class & metadata", {
  src <- make_af()
  out <- dplyr::arrange(src$obj, desc(x))
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("rename preserves class & metadata", {
  src <- make_af()
  out <- dplyr::rename(src$obj, x_new = x)
  expect_s3_class(out, "aniframe")
  expect_equal(get_variables(out, "where"), c("x_new", "y"))
  expect_silent(validate_anipoint(out))
})

test_that("rename carries keys, the index and structures along (#178)", {
  src <- make_af()
  af <- set_structure(
    src$obj,
    anistructure(segments = list(c("head", "centroid")))
  )
  out <- dplyr::rename(af, t = time, part = keypoint)
  expect_equal(get_index(out), "t")
  expect_true("part" %in% get_keys(out))
  expect_false("keypoint" %in% get_keys(out))
  expect_equal(get_structure(out)[[1]]$variable, "part")
  expect_silent(validate_anipoint(out))

  out <- dplyr::rename_with(af, toupper, c(x, y))
  expect_equal(get_variables(out, "where"), c("X", "Y"))
})

test_that("relocate can rename, and the metadata follows (#178)", {
  src <- make_af()
  out <- dplyr::relocate(src$obj, t = time)
  expect_equal(names(out)[[1]], "t")
  expect_equal(get_index(out), "t")
  expect_silent(validate_anipoint(out))
})

test_that("relocate preserves class & metadata", {
  src <- make_af()
  out <- dplyr::relocate(src$obj, y, .before = individual)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("slice preserves class & metadata", {
  src <- make_af()
  out <- dplyr::slice(src$obj, 1:3)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

# ---- Base-R extraction ----
test_that("[ ] subsetting preserves class & metadata", {
  src <- make_af()
  out <- src$obj[1:2, ]
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("[ ] without the index or a key gives a plain data frame (#178)", {
  src <- make_af()
  for (out in list(
    src$obj[c("x", "y")],
    src$obj[1:2, c("individual", "x")],
    dplyr::distinct(suppressWarnings(dplyr::ungroup(src$obj)), individual)
  )) {
    expect_false(inherits(out, "aniframe"))
    expect_null(attr(out, "metadata"))
  }
  expect_equal(names(src$obj[c("x", "y")]), c("x", "y"))
})

test_that("removing the index column gives a plain data frame (#178)", {
  src <- make_af()
  out <- src$obj
  out$time <- NULL
  expect_false(inherits(out, "aniframe"))
  out <- src$obj
  out[["keypoint"]] <- NULL
  expect_false(inherits(out, "aniframe"))
})

test_that("[[ ]] extraction preserves metadata when a data.frame is returned", {
  src <- make_af()
  df <- src$obj |> dplyr::mutate(lst = list(list(a = 1)))
  out <- df[["lst"]]
  expect_type(out, "list")
})

test_that("$ extraction returns a plain vector (no class) but does not alter metadata", {
  src <- make_af()
  val <- src$obj$x
  expect_type(val, "double")
  expect_metadata_equal(get_metadata(src$obj), src$meta)
})

# ---- Assignment operators ----
test_that("[<-] assignment preserves class & metadata", {
  src <- make_af()
  out <- src$obj
  out[1, "x"] <- 999
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("[[<-] assignment preserves class & metadata", {
  src <- make_af()
  out <- src$obj
  out[["x"]] <- 123
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("$<- assignment preserves class & metadata", {
  src <- make_af()
  out <- src$obj
  out$x <- 42
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})

test_that("names<- assignment preserves class & metadata", {
  src <- make_af()
  out <- src$obj
  old <- names(out)
  names(out) <- paste0("col_", seq_along(old))
  expect_s3_class(out, "aniframe")
  expect_equal(get_index(out), paste0("col_", match("time", old)))
  expect_equal(
    unname(get_variables(out, "where")),
    paste0("col_", match(c("x", "y"), old))
  )
  expect_silent(validate_anipoint(out))
})

# ---- Conversion ----
test_that("as.data.frame drops the class but leaves metadata untouched", {
  src <- make_af()
  df <- as.data.frame(src$obj)
  expect_false(inherits(df, "aniframe"))
  expect_metadata_equal(get_metadata(src$obj), src$meta)
})

# ---- Round-trip ----
test_that("a full pipeline keeps class & metadata", {
  src <- make_af()
  out <- src$obj |>
    dplyr::group_by(individual) |>
    dplyr::mutate(new = x * 2) |>
    dplyr::filter(new > 10) |>
    dplyr::select(-y) |>
    dplyr::arrange(desc(new))

  expect_s3_class(out, "aniframe")
  # The filter dropped rows, so the interval is measured again (#190).
  expected <- src$meta
  expected$time$sampling_interval <- compute_sampling_interval(
    compute_sampling_gaps(out)
  )
  expect_metadata_equal(get_metadata(out), expected)
})
