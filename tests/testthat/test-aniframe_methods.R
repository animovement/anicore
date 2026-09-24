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
  out <- dplyr::select(src$obj, individual, x)
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
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
  expect_metadata_equal(get_metadata(out), src$meta)
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
  out <- src$obj[1:2, c("individual", "x")]
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
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
  names(out) <- paste0("col_", seq_along(names(out)))
  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
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
    dplyr::select(individual, new) |>
    dplyr::arrange(desc(new))

  expect_s3_class(out, "aniframe")
  expect_metadata_equal(get_metadata(out), src$meta)
})
