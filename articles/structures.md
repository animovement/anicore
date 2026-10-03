# Structures

``` r

library(anicore)
```

## What a structure is

An `anistructure` records how the levels of one variable relate. The
common case is a **skeleton** over `keypoint`, but the same class holds
a team, a colony or a social network over `individual`. It has three
parts:

- **points**: the members.
- **segments**: directed links between two points, with an optional
  expected `length`.
- **joints**: ordered pairs of segments, with angular limits per degree
  of freedom.

Each part beyond the points is optional. A structure with points alone
is a roster; with segments it is a graph; with joints it is a
constrained skeleton.

``` r

leg <- anistructure(
  segments = data.frame(
    segment = c("thigh", "shin"),
    from = c("hip", "knee"),
    to = c("knee", "ankle")
  ),
  joints = data.frame(joint = "knee", a = "thigh", b = "shin", min = 0, max = 2.5),
  root = "hip"
)
leg
#> <anistructure> 3 points, 2 segments, 1 joint
#> root: hip
#> Points: hip, knee, ankle
#> Segments: thigh (hip -> knee), shin (knee -> ankle)
#> Joints: knee (thigh, shin)
```

Segments point one way. Run limbs from the root outward, and paired
segments (left to right) the same way, so joint angles come out with the
clinical convention: 0 when two segments are aligned.

## Attaching structures to a frame

A structure is a template: it names no variable until it is attached.
[`set_structure()`](https://animovement.dev/anicore/reference/structures.md)
binds it to a variable and stores it under a name, which defaults to the
variable:

``` r

af <- example_anipoint(n_individuals = 4) |>
  set_structure(example_structure())

get_structure(af, "keypoint")
#> <anistructure> 11 points, 10 segments, 3 joints
#> variable: keypoint; root: abdomen
#> Points: abdomen, neck, hip_right, hip_left, knee_right, knee_left, head, shoulder_right, shoulder_left, foot_right, foot_left
#> Segments: spine (abdomen -> neck), head (neck -> head), shoulder_right (neck -> shoulder_right), shoulder_left (neck -> shoulder_left), hip_right (abdomen -> hip_right), hip_left (abdomen -> hip_left), thigh_right (hip_right -> knee_right), thigh_left (hip_left -> knee_left), shin_right (knee_right -> foot_right), shin_left (knee_left -> foot_left)
#> Joints: neck (spine, head), knee_right (thigh_right, shin_right), knee_left (thigh_left, shin_left)
```

## Several structures over one variable

A frame can hold any number of named structures, and several may span
the same variable. A structure’s points are its members, so a subset of
the levels makes a sub-group, and groups may overlap:

``` r

af <- af |>
  set_structure(
    anistructure(points = c("1", "2", "3", "4")),
    variable = "individual",
    name = "team"
  ) |>
  set_structure(
    anistructure(segments = list(c("1", "2"), c("2", "3"))),
    variable = "individual",
    name = "defence"
  )

names(get_structure(af))
#> [1] "keypoint" "team"     "defence"
get_structure(af, "defence")
#> <anistructure> 3 points, 2 segments, 0 joints
#> variable: individual
#> Points: 1, 2, 3
#> Segments: 1-2 (1 -> 2), 2-3 (2 -> 3)
```

[`remove_structure()`](https://animovement.dev/anicore/reference/structures.md)
drops one by name.

Membership is fixed for the frame: a player who changes role partway
through needs a separate frame, or a column recording the role.

## From points to segments

[`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md)
re-expresses an anipoint as the segments of one of its structures. Each
row is one segment at one time: its `length`, and the unit vector from
its `from` point to its `to` point (`ux`, `uy`, and `uz` in 3D). The
structure’s variable is replaced by a `segment` key.

``` r

skeleton <- example_anipoint(n_obs = 3, n_individuals = 1) |>
  set_structure(example_structure())

seg <- as_anisegment(skeleton)
seg
#> # anisegment: 30 × 9
#> # Groups:     individual, segment, session, trial [10]
#> # Structure:  keypoint
#>    individual segment     session trial  time length       ux      uy confidence
#>         <int> <fct>         <int> <int> <int>  <dbl>    <dbl>   <dbl>      <dbl>
#>  1          1 spine             1     1     1  3.34   0.626   -0.780       0.508
#>  2          1 spine             1     1     2  1.45   0.721    0.692       0.703
#>  3          1 spine             1     1     3  2.57  -0.00555  1.000       0.586
#>  4          1 head              1     1     1  3.86  -0.337    0.941       0.431
#>  5          1 head              1     1     2  1.53  -1.000   -0.0283      0.440
#>  6          1 head              1     1     3  1.74   0.0818   0.997       0.586
#>  7          1 shoulder_r…       1     1     1  0.549 -0.599    0.801       0.508
#>  8          1 shoulder_r…       1     1     2  2.09  -0.994   -0.110       0.662
#>  9          1 shoulder_r…       1     1     3  1.87  -0.249   -0.969       0.586
#> 10          1 shoulder_l…       1     1     1  0.873  0.804    0.595       0.508
#> # ℹ 20 more rows
get_variables(seg, "where")
#> [1] "length" "ux"     "uy"
```

Segment lengths should stay constant for a rigid body, so their spread
is a first check on tracking quality:

``` r

seg |>
  dplyr::summarise(length_sd = sd(length), .groups = "drop") |>
  head()
#> # A tibble: 6 × 5
#>   individual segment        session trial length_sd
#>        <int> <fct>            <int> <int>     <dbl>
#> 1          1 spine                1     1     0.951
#> 2          1 head                 1     1     1.29 
#> 3          1 shoulder_right       1     1     0.834
#> 4          1 shoulder_left        1     1     0.556
#> 5          1 hip_right            1     1     2.20 
#> 6          1 hip_left             1     1     1.05
```

Editing the segments and rebuilding the positions carries the edit into
every point but the root. Holding each segment at its median length
makes the body rigid:

``` r

rigid <- seg |>
  dplyr::mutate(length = stats::median(length)) |>
  as_anipoint(root = skeleton)
rigid
#> # Individuals: 1
#> # Keypoints:   abdomen, neck, hip_right, hip_left, knee_right, knee_left, head,
#> #   shoulder_right, shoulder_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint  session trial  time      x      y
#>         <int> <fct>       <int> <int> <int>  <dbl>  <dbl>
#>  1          1 abdomen         1     1     1 -1.88   2.40 
#>  2          1 abdomen         1     1     2  0.529 -0.459
#>  3          1 abdomen         1     1     3  0.611 -2.87 
#>  4          1 neck            1     1     1 -0.268  0.395
#>  5          1 neck            1     1     2  2.38   1.32 
#>  6          1 neck            1     1     3  0.596 -0.301
#>  7          1 hip_right       1     1     1 -1.54  -2.27 
#>  8          1 hip_right       1     1     2  2.68  -4.61 
#>  9          1 hip_right       1     1     3 -0.965  1.53 
#> 10          1 hip_left        1     1     1 -1.32   0.278
#> # ℹ 23 more rows
```

The rebuild walks the segments outward from the structure’s `root`, so
it needs the root point’s trajectory; `root` can be the frame the
segments came from.

## From segments to joints

[`as_anijoint()`](https://animovement.dev/anicore/reference/as_anijoint.md)
computes one angle per joint of the structure, from the directions of
its two segments. The angle is 0 when they point the same way. In 2D it
is signed, turning from segment `a` to segment `b`. In 3D it is the
included angle, or signed about the joint’s `axis` when one is declared:
`"x"`, `"y"`, `"z"`, or another segment, such as the spine for trunk
twist.

``` r

joints <- as_anijoint(skeleton)
joints
#> # anijoint:  9 × 7
#> # Groups:    individual, joint, session, trial [3]
#> # Structure: keypoint
#>   individual joint      session trial  time   angle confidence
#>        <int> <fct>        <int> <int> <int>   <dbl>      <dbl>
#> 1          1 neck             1     1     1  2.81        0.431
#> 2          1 neck             1     1     2  2.40        0.440
#> 3          1 neck             1     1     3 -0.0874      0.586
#> 4          1 knee_right       1     1     1  2.61        0.539
#> 5          1 knee_right       1     1     2 -1.77        0.347
#> 6          1 knee_right       1     1     3 -3.08        0.626
#> 7          1 knee_left        1     1     1 -3.00        0.618
#> 8          1 knee_left        1     1     2 -1.96        0.654
#> 9          1 knee_left        1     1     3  3.14        0.719
```

The same computation is available for any pair of vectors as
[`angle_between()`](https://animovement.dev/anicore/reference/angle_between.md):

``` r

angle_between(c(1, 0, 0), c(0, 1, 0))
#> [1] 1.570796
angle_between(c(1, 0, 0), c(0, 1, 0), axis = c(0, 0, -1))
#> [1] -1.570796
```

A joint frame is a view for measuring and checking against limits; it
cannot be converted back, since it keeps no lengths and, in 3D, no
rotation about the segments themselves.

## Catching typos

Points that don’t appear in the data are kept with a warning, since they
may be recorded in another file:

``` r

example_anipoint(n_keypoints = 5) |>
  set_structure(anistructure(segments = list(c("head", "necc"))))
#> Warning: Point "necc" is not in the "keypoint" column.
#> ℹ Keeping it in case it is recorded in another file.
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time        x       y confidence
#>         <int> <fct>      <int> <int> <int>    <dbl>   <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.259   -0.624       0.665
#>  2          1 head           1     1     2  1.16     2.42        0.931
#>  3          1 head           1     1     3  0.121   -0.554       0.497
#>  4          1 head           1     1     4  0.00589  0.632       0.916
#>  5          1 head           1     1     5  1.30     0.198       0.681
#>  6          1 head           1     1     6  0.731   -0.0753      0.783
#>  7          1 head           1     1     7  1.31     0.242       0.411
#>  8          1 head           1     1     8  0.194   -0.0845      0.661
#>  9          1 head           1     1     9  0.207   -0.672       0.885
#> 10          1 head           1     1    10  0.240    0.237       0.927
#> # ℹ 740 more rows
```
