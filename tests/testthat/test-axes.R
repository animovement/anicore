# Axis roles (#109) ----

test_that("an unnamed declaration reads the column name as the role", {
  # The historical form. Every existing frame and every reader's output
  # arrives this way, so it has to keep working untouched.
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_equal(get_axes(af), c(x = "x", y = "y"))
  expect_equal(
    as.character(get_metadata(af, "coordinate_system")),
    "cartesian_2d"
  )
})

test_that("get_variables_where() still returns bare column names", {
  # The accessor strips names, so callers that want columns are unaffected
  # by roles being stored.
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_equal(get_variables_where(af), c("x", "y"))
  expect_null(names(get_variables_where(af)))
})

test_that("axes can be carried by columns named anything", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))

  af <- as_anipoint(df, variables_where = c(x = "u", y = "v"))

  expect_equal(get_axes(af), c(x = "u", y = "v"))
  expect_equal(get_variables_where(af), c("u", "v"))
  # Previously this degraded to "unknown" and every spatial function
  # refused the frame.
  expect_equal(
    as.character(get_metadata(af, "coordinate_system")),
    "cartesian_2d"
  )
})

test_that("a renamed polar frame is recognised as polar", {
  df <- data.frame(
    time = 1:3,
    individual = "a",
    r = c(100, 200, 300),
    ang = c(0, 1, 2)
  )

  af <- as_anipoint(df, variables_where = c(rho = "r", phi = "ang"))

  expect_equal(as.character(get_metadata(af, "coordinate_system")), "polar")
  expect_equal(get_axes(af)[["rho"]], "r")
})

test_that("an axis extent is keyed by role, whatever the column is called", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 5, 0))

  af <- as_anipoint(df, variables_where = c(x = "u", y = "v"))
  af <- set_axis_extents(af, c(y = 5))

  expect_equal(get_axis_extents(af), c(y = 5))
})

test_that("an unrecognised role is rejected by name", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))

  # Named by the offending role at the point of declaration, rather than
  # silently degrading to "unknown" and failing later somewhere else.
  expect_error(
    as_anipoint(df, variables_where = c(banana = "u", y = "v")),
    "not recognised"
  )
})

test_that("roles that do not form a coordinate system are rejected", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))

  # x and theta belong to different systems; the set is closed so that
  # transformations between systems stay well defined.
  expect_error(
    as_anipoint(df, variables_where = c(x = "u", theta = "v")),
    "do not form a coordinate system"
  )
})

test_that("a duplicated role is rejected", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))

  expect_error(
    as_anipoint(df, variables_where = c(x = "u", x = "v")),
    "declared more than once"
  )
})

test_that("an unnamed declaration that matches nothing still warns rather than aborting", {
  # The lenient path is preserved for bare column names, because readers
  # and existing frames depend on it.
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))

  expect_warning(
    af <- as_anipoint(df, variables_where = c("u", "v")),
    "Could not infer coordinate system"
  )
  expect_equal(as.character(get_metadata(af, "coordinate_system")), "unknown")
  # Roles are only stored once they mean something.
  expect_equal(get_variables_where(af), c("u", "v"))
  expect_equal(get_axes(af), stats::setNames(character(), character()))
})

test_that("set_variables_where() accepts a role mapping", {
  df <- data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0))
  af <- suppressWarnings(as_anipoint(df, variables_where = c("u", "v")))

  result <- set_variables_where(af, c(x = "u", y = "v"))

  expect_equal(get_axes(result), c(x = "u", y = "v"))
  expect_equal(
    as.character(get_metadata(result, "coordinate_system")),
    "cartesian_2d"
  )
})

test_that("list_axis_role_sets() and infer_coordinate_system() agree", {
  # The inference reads its map from the same place the validator does, so
  # a role set can never be accepted and then fail to infer.
  for (key in names(list_axis_role_sets())) {
    roles <- strsplit(key, ",", fixed = TRUE)[[1]]
    axes <- stats::setNames(roles, roles)
    expect_equal(infer_coordinate_system(axes), list_axis_role_sets()[[key]])
  }
})


# Length-unit conversion resolves roles to columns ----

test_that("set_unit_space() converts the length axes of a renamed frame", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c(x = "u", y = "v")
  )

  result <- expect_no_warning(
    set_unit_space(af, "mm", calibration_factor = 10)
  )

  expect_equal(result$u, c(10, 20, 30))
  expect_equal(result$v, c(0, 10, 0))
  expect_equal(as.character(get_metadata(result, "unit_space")), "mm")
})

test_that("set_unit_space() converts rho but not phi on a renamed polar frame", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", r = c(1, 2, 3), a = c(0, 1, 2)),
    variables_where = c(rho = "r", phi = "a")
  )

  result <- expect_no_warning(
    set_unit_space(af, "mm", calibration_factor = 10)
  )

  expect_equal(result$r, c(10, 20, 30))
  expect_equal(result$a, c(0, 1, 2))
})


# `axes` is a field of its own ----

test_that("variables_where stays a plain vector when the roles are known", {
  # A named character vector is a rename instruction to tidyselect, and
  # `variables_where` is read raw and passed to `dplyr::all_of()`
  # downstream, so names on it would silently rename columns.
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c(x = "u", y = "v")
  )

  expect_null(names(get_variables_where(af)))
  expect_equal(get_variables_where(af), c("u", "v"))
  expect_equal(get_variables_where(af), c("u", "v"))
  expect_equal(get_axes(af), c(x = "u", y = "v"))
})

test_that("selecting by variables_where does not rename the columns", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c(x = "u", y = "v")
  )

  where_cols <- get_variables_where(af)
  bare <- dplyr::ungroup(dplyr::as_tibble(af))

  expect_equal(
    names(dplyr::select(bare, dplyr::all_of(where_cols))),
    c("u", "v")
  )

  # `aniprocess` reaches the spatial columns this way.
  picked <- dplyr::mutate(bare, out = dplyr::pick(dplyr::all_of(where_cols)))
  expect_equal(names(picked$out), c("u", "v"))
})

test_that("set_axes() declares the mapping and refreshes coordinate_system", {
  af <- suppressWarnings(as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c("u", "v")
  ))
  expect_equal(as.character(get_metadata(af, "coordinate_system")), "unknown")

  result <- set_axes(af, c(x = "u", y = "v"))

  expect_equal(get_axes(result), c(x = "u", y = "v"))
  expect_equal(
    as.character(get_metadata(result, "coordinate_system")),
    "cartesian_2d"
  )
  expect_equal(get_variables_where(result), c("u", "v"))
})

test_that("set_axes() round-trips its own getter", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c(x = "u", y = "v")
  )

  expect_equal(get_metadata(set_axes(af, get_axes(af))), get_metadata(af))
})

test_that("set_axes() requires a role for every column", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_error(set_axes(af, c("x", "y")), "must name an axis role")
  expect_error(set_axes(af, c(x = "x", banana = "y")), "not recognised")
  expect_error(
    set_axes(af, c(x = "x", theta = "y")),
    "do not form a coordinate system"
  )
})

test_that("set_metadata() refuses axes and names its setter", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_error(set_metadata(af, axes = c(x = "x")), "set_axes")
})

test_that("re-declaring another role keeps the axis mapping", {
  af <- as_anipoint(
    data.frame(
      time = 1:3,
      individual = "a",
      session = "s",
      u = c(1, 2, 3),
      v = c(0, 1, 0)
    ),
    variables_where = c(x = "u", y = "v")
  )

  result <- add_variables_when(af, "session")

  expect_equal(get_axes(result), c(x = "u", y = "v"))
  expect_equal(
    as.character(get_metadata(result, "coordinate_system")),
    "cartesian_2d"
  )
})

test_that("metadata serialised before the field existed still resolves its axes", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
  md <- get_metadata(af)
  md[["axes"]] <- NULL

  expect_true(has_all_metadata_fields(md))
  expect_equal(resolve_axes(md), c(x = "x", y = "y"))
})

test_that("an anievent has no axes", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables_event(state = "b") |>
    to_anievent()

  # No `where` role, and no `space` category at all (#118)
  expect_length(get_variables_where(ae), 0)
  expect_null(get_metadata(ae, "space"))
})


# add_/remove_variables_where() carry the roles ----

test_that("add_variables_where() keeps the roles already declared", {
  # `union()` on bare columns drops the names, which reduced the frame to
  # `unknown` on every addition (#109).
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", x = 1:3, y = 1:3, u = 1:3)
  )

  result <- add_variables_where(af, c(z = "u"))

  expect_equal(get_axes(result), c(x = "x", y = "y", z = "u"))
  expect_equal(get_coordinate_system(result), "cartesian_3d")
})

test_that("add_variables_where() keeps the roles of a renamed frame", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", uu = 1:3, vv = 1:3, ww = 1:3),
    variables_where = c(x = "uu", y = "vv")
  )

  result <- add_variables_where(af, c(z = "ww"))

  expect_equal(get_axes(result), c(x = "uu", y = "vv", z = "ww"))
  expect_equal(get_coordinate_system(result), "cartesian_3d")
})

test_that("add_variables_where() supersedes an existing role", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", uu = 1:3, vv = 1:3, ww = 1:3),
    variables_where = c(x = "uu", y = "vv")
  )

  result <- add_variables_where(af, c(y = "ww"))

  expect_equal(get_axes(result), c(x = "uu", y = "ww"))
  expect_equal(get_coordinate_system(result), "cartesian_2d")
})

test_that("remove_variables_where() keeps the roles of what is left", {
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", uu = 1:3, vv = 1:3),
    variables_where = c(x = "uu", y = "vv")
  )

  result <- remove_variables_where(af, "vv")

  expect_equal(get_axes(result), c(x = "uu"))
  expect_equal(get_coordinate_system(result), "cartesian_1d")
})

test_that("removing an axis down to an incoherent set warns rather than aborts", {
  # Declaring an incoherent set asserts something untrue and aborts;
  # arriving at one by removal is a step, and must not be blocked.
  af <- as_anipoint(
    data.frame(
      time = 1:3,
      individual = "a",
      rho = 1:3,
      phi = 1:3,
      theta = 1:3
    )
  )

  expect_warning(
    result <- remove_variables_where(af, "rho"),
    "anispace"
  )
  expect_equal(get_coordinate_system(result), "unknown")

  expect_error(
    as_anipoint(
      data.frame(time = 1:3, individual = "a", u = 1:3, v = 1:3),
      variables_where = c(x = "u", theta = "v")
    ),
    "do not form a coordinate system"
  )
})


# A role shadowed by an undeclared column of the same name (#119) ----

test_that("declaring a role shadowed by a column of that name warns", {
  # `af$x` would return a real column of real numbers that is not the x
  # axis — plausible wrong answers rather than an error.
  df <- data.frame(
    time = 1:3,
    individual = "a",
    u = c(1, 2, 3),
    v = c(0, 1, 0),
    x = 9:11
  )

  expect_warning(
    af <- as_anipoint(df, variables_where = c(x = "u", y = "v")),
    "also has a column"
  )
  expect_equal(get_axes(af)[["x"]], "u")
})

test_that("no warning when the roles are carried by columns of their own name", {
  expect_no_warning(
    as_anipoint(data.frame(time = 1:3, individual = "a", x = 1:3, y = 1:3))
  )
})

test_that("no warning when the shadowing column is not there", {
  expect_no_warning(
    as_anipoint(
      data.frame(time = 1:3, individual = "a", u = 1:3, v = 1:3),
      variables_where = c(x = "u", y = "v")
    )
  )
})

test_that("aniframe.quiet silences the shadowing warning", {
  # The reason it is an option rather than an argument: in a loop you want
  # to set it once, not thread it through every call.
  df <- data.frame(
    time = 1:3,
    individual = "a",
    u = c(1, 2, 3),
    v = c(0, 1, 0),
    x = 9:11
  )

  previous <- options(aniframe.quiet = TRUE)
  on.exit(options(previous), add = TRUE)

  expect_no_warning(as_anipoint(df, variables_where = c(x = "u", y = "v")))
})

test_that("set_axes() warns on shadowing too", {
  df <- data.frame(
    time = 1:3,
    individual = "a",
    u = c(1, 2, 3),
    v = c(0, 1, 0),
    rho = 9:11
  )
  af <- suppressWarnings(as_anipoint(df, variables_where = c("u", "v")))

  expect_warning(set_axes(af, c(rho = "u", phi = "v")), "also has a column")
})


# Turning an axis over resolves it by role ----

test_that("set_axis_directions() reflects the y axis of a renamed frame", {
  # The flip reached for a literal `y` column, so a frame whose vertical
  # axis is called something else got an extent it could not use (#109).
  af <- as_anipoint(
    data.frame(individual = "a", time = 1:3, u = c(1, 2, 3), v = c(0, 5, 10)),
    variables_where = c(x = "u", y = "v")
  )
  af <- set_axis_extents(af, c(y = 10))
  af <- set_axis_directions(af, c(x = "right", y = "up"))

  result <- set_axis_directions(af, c(y = "down"))

  expect_equal(result$v, c(10, 5, 0))
  expect_equal(get_axis_directions(result)[["y"]], "down")
  # The x axis is untouched.
  expect_equal(result$u, c(1, 2, 3))
})

test_that("an angular frame has its angles recomputed rather than left stale", {
  # A polar frame has a sense of rotation, and no column to reflect: the
  # stored phi is what carries the direction, so that is what moves (#134).
  pol <- as_anipoint(
    data.frame(individual = "a", time = 1:3, rho = c(1, 2, 3), phi = c(0, 1, 2))
  )
  pol <- set_axis_directions(pol, c(x = "right", y = "up"))

  result <- set_axis_directions(pol, c(y = "down"))

  expect_equal(result$phi, (-c(0, 1, 2)) %% (2 * pi))
  expect_equal(result$rho, c(1, 2, 3))
})


# The empty and unresolvable paths ----

test_that("normalise_axes() handles an empty declaration", {
  expect_equal(
    normalise_axes(character(0)),
    stats::setNames(character(), character())
  )
  expect_length(normalise_axes(NULL), 0)
})

test_that("resolve_axes() gives nothing when the columns name no system", {
  # Metadata from before the field existed, whose `variables_where` does not
  # read as a coordinate system under the historical name-is-role rule.
  md <- get_metadata(example_anipoint(
    n_obs = 3,
    n_individuals = 1,
    n_keypoints = 1
  ))
  # Roles unknown: `where$position` carries the bare columns, and names
  # that spell no coordinate system resolve to no axes.
  md$variables$where$position <- c("u", "v")

  expect_equal(resolve_axes(md), stats::setNames(character(), character()))
})
