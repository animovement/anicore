# Create a structure: points, the segments between them, and joints

An `anistructure` describes how the levels of one identity or temporal
variable relate: the keypoints of a skeleton, or the players of a team.
It has three parts, each optional beyond the first:

- **points** — the members, levels of the variable it is attached to.

- **segments** — directed links between two points, with an optional
  expected `length`. Direction matters for joint angles: run limbs
  proximal to distal, and paired segments (left to right) the same way.

- **joints** — one measured angle each, between an ordered pair of
  segments `(a, b)`, with optional limits `min`, `max` and `rest` in
  radians. The angle is 0 when the two segments point the same way. In
  2D it is signed, turning from `a` to `b`. In 3D it is the included
  angle, or, when `axis` is given (`"x"`, `"y"`, `"z"` or a segment
  name), the signed angle about it. Several angles on the same pair of
  segments — flexion and abduction, say — are several joints with
  different axes.

Lengths and limits are recorded, not enforced: checks compare the data
against them.

A structure is a template: it records no data and no variable until it
is attached to a frame with
[`set_structure()`](https://animovement.dev/anicore/reference/structures.md),
so one structure can be reused across frames.

## Usage

``` r
anistructure(
  points = NULL,
  segments = NULL,
  joints = NULL,
  root = NA_character_,
  source = NA_character_,
  citation = NA_character_,
  license = NA_character_
)
```

## Arguments

- points:

  Character vector of point names. Defaults to the segment endpoints.

- segments:

  A data frame with `from` and `to`, and optionally `segment` (defaults
  to `"from-to"`) and `length`; or a list of `c(from, to)` pairs.

- joints:

  A data frame with `a` and `b` (segment names), and optionally `joint`
  (defaults to `"a-b"`), `axis`, `min`, `max` and `rest`.

- root:

  The point the structure hangs from when positions are rebuilt from
  segments. `NA` if unset.

- source, citation, license:

  Provenance of the structure.

## Value

An `anistructure`.

## See also

[`set_structure()`](https://animovement.dev/anicore/reference/structures.md),
[`example_structure()`](https://animovement.dev/anicore/reference/example_structure.md)

## Examples

``` r
anistructure(
  segments = data.frame(
    segment = c("thigh", "shin"),
    from = c("hip", "knee"),
    to = c("knee", "ankle")
  ),
  joints = data.frame(joint = "knee", a = "thigh", b = "shin", min = 0, max = 2.5),
  root = "hip"
)

# A team: points only, or points with links between them
anistructure(points = c("gk", "lb", "cb", "rb"))
anistructure(segments = list(c("lb", "cb"), c("cb", "rb")))
```
