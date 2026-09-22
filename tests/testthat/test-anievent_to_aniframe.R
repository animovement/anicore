# Tests for to_anievent.aniframe (RLE encoding from aniframe -> anievent)
#
# Construction:
#   - state column run-length-encoded into bouts (start = first frame time,
#     stop = last frame time)
#   - point column emits one row per non-NA frame with start == stop
#   - both state and point columns coexist in one call
#   - NA values break runs (gap is not part of any bout)
#   - per-(individual, observation) grouping isolates bouts
#
# Metadata propagation:
#   - unit_time inherited from the host aniframe
#   - sampling_rate inherited
#   - variables_when picks up grouping cols + start/stop
#
# Errors:
#   - host with no variables_event declared
#   - declared column missing from host data

make_state_aniframe <- function() {
  af <- anipoint(
    individual = rep(1L, 8),
    time = 1:8,
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(
      c("REM", "REM", "REM", "wake", "wake", "REM", "REM", NA),
      levels = c("REM", "wake")
    )
  )
  set_variables_event(af, state = "behaviour", point = character())
}

test_that("state column is run-length-encoded into bouts", {
  af <- make_state_aniframe()
  ae <- to_anievent(af)

  expect_s3_class(ae, "anievent")
  expect_equal(nrow(ae), 3) # REM(1-3), wake(4-5), REM(6-7); the trailing NA closes
  expect_equal(ae$start, c(1, 4, 6))
  expect_equal(ae$stop, c(3, 5, 7))
  expect_equal(as.character(ae$label), c("REM", "wake", "REM"))
  expect_true(all(ae$channel == "behaviour"))
})

test_that("point column emits one row per non-NA frame with start == stop", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = rnorm(5),
    y = rnorm(5),
    call = factor(c(NA, "alarm", NA, "alarm", NA), levels = "alarm")
  )
  af <- set_variables_event(af, state = character(), point = "call")

  ae <- to_anievent(af)
  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(2, 4))
  expect_equal(ae$start, ae$stop)
  expect_true(all(ae$channel == "call"))
})

test_that("state and point columns coexist in one conversion", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = rnorm(5),
    y = rnorm(5),
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake")),
    call = factor(c(NA, "alarm", NA, NA, NA), levels = "alarm")
  )
  af <- set_variables_event(af, state = "behaviour", point = "call")

  ae <- to_anievent(af)
  expect_setequal(unique(ae$channel), c("behaviour", "call"))
  expect_equal(sum(ae$channel == "behaviour"), 2) # REM(1-2), wake(3-5)
  expect_equal(sum(ae$channel == "call"), 1) # one alarm at t=2
})

test_that("per-individual grouping isolates bouts", {
  af <- anipoint(
    individual = rep(c(1L, 2L), each = 4),
    time = c(1:4, 1:4),
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(c(
      "REM",
      "REM",
      "wake",
      "wake",
      "wake",
      "wake",
      "REM",
      "REM"
    ))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_equal(nrow(ae), 4) # 2 bouts per individual
  expect_equal(sum(ae$individual == 1), 2)
  expect_equal(sum(ae$individual == 2), 2)
})

test_that("observation grouping isolates bouts across clips", {
  af <- anipoint(
    individual = rep(1L, 8),
    observation = c(rep("clip_a", 4), rep("clip_b", 4)),
    time = c(1:4, 1:4),
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(c(
      "REM",
      "REM",
      "wake",
      "wake",
      "REM",
      "REM",
      "REM",
      "wake"
    ))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_equal(nrow(ae), 4)
  expect_true("observation" %in% names(ae))
  expect_true("observation" %in% get_metadata(ae, "variables_when"))
})

test_that("metadata is inherited from the host aniframe", {
  af <- make_state_aniframe()
  af <- set_metadata(af, unit_time = "s", sampling_rate = 30)

  ae <- to_anievent(af)
  expect_equal(as.character(get_metadata(ae, "unit_time")), "s")
  expect_equal(get_metadata(ae, "sampling_rate"), 30)
})

test_that("to_anievent.aniframe errors when no event columns are declared", {
  af <- anipoint(individual = 1L, time = 1:3, x = 1:3, y = 1:3)
  expect_error(to_anievent(af), "no event columns declared")
})

test_that("to_anievent.aniframe errors when a declared column is missing", {
  # Declaring a column that isn't there is rejected by the setter, so
  # the drifted state has to be forced to reach to_anievent()'s own check.
  af <- anipoint(individual = 1L, time = 1:3, x = 1:3, y = 1:3)
  af <- drift_metadata(
    af,
    variables_event = list(state = "behaviour", point = character())
  )

  expect_error(to_anievent(af), "not present in the data")
})

test_that("to_anievent.aniframe picks up <channel>_modifiers list-columns", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = rnorm(5),
    y = rnorm(5),
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake")),
    behaviour_modifiers = I(list(
      c("limb", "whisker"),
      c("limb", "whisker"),
      "tail",
      "tail",
      "tail"
    ))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_true("modifiers" %in% names(ae))
  expect_equal(ae$modifiers[[1]], c("limb", "whisker"))
  expect_equal(ae$modifiers[[2]], "tail")
})

test_that("to_anievent.aniframe handles an aniframe with no identity columns", {
  af <- as_anipoint(
    dplyr::tibble(
      time = 1:5,
      x = 1:5,
      y = 1:5,
      behaviour = factor(c("REM", "REM", "wake", "wake", "wake"))
    )
  )
  af <- set_variables_what(af, character())
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(1, 3))
  expect_equal(ae$stop, c(2, 5))
})

test_that("redundant identity columns (e.g. keypoint when behaviour is constant across keypoints) are dropped from bouts", {
  # behaviour is constant across keypoint within (individual, time)
  af <- anipoint(
    individual = rep(1L, 6),
    keypoint = rep(c("head", "tail"), each = 3),
    time = rep(1:3, 2),
    x = rnorm(6),
    y = rnorm(6),
    behaviour = factor(
      c("REM", "REM", "wake", "REM", "REM", "wake"),
      levels = c("REM", "wake")
    )
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)

  # Should be 2 bouts (REM 1-2, wake 3-3), not 4 (duplicated per keypoint)
  expect_equal(nrow(ae), 2)
  expect_false("keypoint" %in% names(ae))
  expect_false("keypoint" %in% get_metadata(ae, "variables_what"))
  expect_equal(ae$start, c(1, 3))
  expect_equal(ae$stop, c(2, 3))
})

test_that("non-redundant identity columns (e.g. behaviour varying by keypoint) are kept", {
  af <- anipoint(
    individual = rep(1L, 6),
    keypoint = rep(c("head", "tail"), each = 3),
    time = rep(1:3, 2),
    x = rnorm(6),
    y = rnorm(6),
    # head: always REM; tail: always wake -> varies by keypoint
    behaviour = factor(
      c("REM", "REM", "REM", "wake", "wake", "wake"),
      levels = c("REM", "wake")
    )
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_true("keypoint" %in% names(ae))
  expect_true("keypoint" %in% get_metadata(ae, "variables_what"))
  expect_equal(nrow(ae), 2) # one bout per keypoint
})

test_that("singleton identity columns are preserved (single individual aniframe carries individual through)", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = rnorm(5),
    y = rnorm(5),
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake"))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_true("individual" %in% names(ae))
  # No auto-added keypoint: `individual` already satisfies the
  # at-least-one-identity rule (#77).
  expect_false("keypoint" %in% names(ae))
  expect_setequal(get_metadata(ae, "variables_what"), "individual")
})

test_that("temporal-grouping columns (observation / session / trial) are always carried over regardless of variation", {
  # Two observations with the SAME behaviour pattern. The old aggressive
  # rule would drop observation; the new rule keeps temporal grouping
  # unconditionally because clips are distinct contexts.
  af <- anipoint(
    individual = rep(1L, 8),
    observation = c(rep("clip_a", 4), rep("clip_b", 4)),
    time = c(1:4, 1:4),
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(rep(c("REM", "REM", "wake", "wake"), 2))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  ae <- to_anievent(af)
  expect_true("observation" %in% names(ae))
  expect_true("observation" %in% get_metadata(ae, "variables_when"))
  # 4 bouts: REM clip_a, wake clip_a, REM clip_b, wake clip_b
  expect_equal(nrow(ae), 4)
})

test_that("multi-value identity columns are dropped when the event is constant across them", {
  # individual: 2 values, epoch constant per time -> dropped, leaving the
  # anievent with no identity columns at all, which is permitted there.
  af <- anipoint(
    individual = c(1L, 1L, 2L, 2L),
    time = c(1:2, 1:2),
    x = rnorm(4),
    y = rnorm(4),
    epoch = factor(c("A", "B", "A", "B")) # same value for both individuals at each time
  )
  af <- set_variables_event(af, state = "epoch", point = character())

  ae <- to_anievent(af)
  expect_false("individual" %in% names(ae))
  expect_false("keypoint" %in% names(ae))
  expect_length(get_metadata(ae, "variables_what"), 0)
  expect_equal(nrow(ae), 2) # one A bout, one B bout
})

test_that("channels with disagreeing scopes error with a helpful message", {
  af <- anipoint(
    individual = rep(1L, 6),
    keypoint = rep(c("head", "tail"), each = 3),
    time = rep(1:3, 2),
    x = rnorm(6),
    y = rnorm(6),
    # behaviour: individual-scope (constant across keypoint)
    behaviour = factor(rep(c("REM", "REM", "wake"), 2)),
    # limb_extended: keypoint-scope (varies by keypoint)
    limb_extended = factor(rep(c("yes", "no"), each = 3))
  )
  af <- set_variables_event(
    af,
    state = c("behaviour", "limb_extended"),
    point = character()
  )

  expect_error(to_anievent(af), "disagree on their identity scope")
})

test_that("point channel keeps identity columns when the scope detection requires it", {
  af <- anipoint(
    individual = rep(c(1L, 2L), each = 4),
    time = rep(1:4, 2),
    x = rnorm(8),
    y = rnorm(8),
    # individual 1 has alarm only at t=2; individual 2 has alarm only at t=3
    call = factor(
      c(NA, "alarm", NA, NA, NA, NA, "alarm", NA),
      levels = "alarm"
    )
  )
  af <- set_variables_event(af, state = character(), point = "call")

  ae <- to_anievent(af)
  expect_true("individual" %in% names(ae))
  expect_equal(nrow(ae), 2)
  expect_equal(sort(ae$individual), c(1L, 2L))
})

test_that("empty-rows path keeps identity columns when forced via variables_what", {
  # All-NA event with an explicit variables_what override -> empty bout df
  # is produced with the (forced) identity column present.
  af <- anipoint(
    individual = c(1L, 2L),
    time = c(1, 2),
    x = c(1, 2),
    y = c(1, 2),
    call = factor(c(NA, NA), levels = "alarm")
  )
  af <- set_variables_event(af, state = character(), point = "call")

  ae <- to_anievent(af, variables_what = "individual")
  expect_equal(nrow(ae), 0)
  expect_true("individual" %in% names(ae))
})

test_that("explicit variables_what overrides scope detection", {
  af <- anipoint(
    individual = rep(1L, 6),
    keypoint = rep(c("head", "tail"), each = 3),
    time = rep(1:3, 2),
    x = rnorm(6),
    y = rnorm(6),
    behaviour = factor(rep(c("REM", "REM", "wake"), 2))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  # Force keypoint to be kept even though it's redundant
  ae <- to_anievent(af, variables_what = c("individual", "keypoint"))
  expect_true("keypoint" %in% names(ae))
  expect_equal(nrow(ae), 4) # duplicate per keypoint
})

test_that("to_anievent.aniframe returns an empty anievent when all event rows are NA", {
  af <- anipoint(
    individual = rep(1L, 3),
    time = 1:3,
    x = rnorm(3),
    y = rnorm(3),
    behaviour = factor(c(NA, NA, NA), levels = "REM"),
    call = factor(c(NA, NA, NA), levels = "alarm")
  )
  af <- set_variables_event(af, state = "behaviour", point = "call")

  ae <- to_anievent(af)
  expect_s3_class(ae, "anievent")
  expect_equal(nrow(ae), 0)
})

test_that("as_anievent on an aniframe errors with a redirect to to_anievent", {
  af <- make_state_aniframe()
  expect_error(as_anievent(af), "to_anievent")
})

test_that("scope-disagreement error formats empty scopes as '<none>'", {
  # 2 individuals x 2 keypoints x 2 times = 8 rows.
  # behaviour: constant across both identities -> scope = character()
  # limb_extended: varies by keypoint only -> scope = c("keypoint")
  # Different scopes -> disagreement error, empty scope rendered as <none>.
  af <- anipoint(
    individual = rep(c(1L, 2L), each = 4),
    keypoint = rep(c("head", "tail"), 4),
    time = rep(c(1, 1, 2, 2), 2),
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(rep("REM", 8)), # constant across everything
    limb_extended = factor(rep(c("yes", "no"), 4)) # varies by keypoint
  )
  af <- set_variables_event(
    af,
    state = c("behaviour", "limb_extended"),
    point = character()
  )

  expect_error(to_anievent(af), "<none>")
})

test_that("explicit variables_when overrides metadata-driven grouping", {
  af <- anipoint(
    individual = 1L,
    observation = c(rep("clip_a", 4), rep("clip_b", 4)),
    time = c(1:4, 1:4),
    x = rnorm(8),
    y = rnorm(8),
    behaviour = factor(rep(c("REM", "REM", "wake", "wake"), 2))
  )
  af <- set_variables_event(af, state = "behaviour", point = character())

  # Override drops `observation` from the grouping; bouts cross clips.
  ae <- to_anievent(af, variables_when = character())
  expect_false("observation" %in% get_metadata(ae, "variables_when"))
})

test_that("to_anievent.aniframe gathers <col>_modifiers on point channels", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = rnorm(5),
    y = rnorm(5),
    call = factor(c(NA, "alarm", NA, "contact", NA)),
    call_modifiers = I(list(
      character(),
      c("loud", "long"),
      character(),
      "soft",
      character()
    ))
  )
  af <- set_variables_event(af, state = character(), point = "call")

  ae <- to_anievent(af)
  expect_true("modifiers" %in% names(ae))
  expect_equal(ae$modifiers[[1]], c("loud", "long"))
  expect_equal(ae$modifiers[[2]], "soft")
})
