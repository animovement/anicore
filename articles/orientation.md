# Orientation

``` r

library(anicore)
```

Orientation means two things on an `anipoint`, and this article covers
both. The first is the frame’s own: which way its axes point, how far
they run, and what follows from that for angles and handedness. The
second is the entity’s: which way an animal faces. The second is
measured against the first, so it comes after.

For the metadata fields in general see [Metadata on an
aniframe](https://animovement.dev/anicore/articles/aniframe-metadata.md);
for position and the `where` role see [The anipoint data
structure](https://animovement.dev/anicore/articles/aniframe-structure.md).

## Which way the axes point

Image and video tooling counts `y` **downward** from the top of the
frame; plotting and most maths count it **upward**. The two disagree
about a direction, not about where `(0, 0)` sits — that is a corner
either way — so a direction is what `anipoint` records. A corner also
says nothing about a third axis, and a direction does.

`axis_directions` maps each axis role to one of six words, in three
opposed pairs, read from where the recording was made:

| Pair       | Directions         | Meaning                       |
|------------|--------------------|-------------------------------|
| horizontal | `right` / `left`   | across the view               |
| vertical   | `up` / `down`      | within the view               |
| depth      | `back` / `forward` | toward / away from the viewer |

The words are relative to the viewpoint, not to the world. Whether the
view is fixed in the arena or rides on the animal is `reference_frame`’s
job (`allocentric` or `egocentric`).

[`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md)
declares them, keyed by role. Roles not named keep what they had, and
`NA` clears one. It only declares: the values are left alone.

``` r

img <- anipoint(
  individual = 1L, time = 1:3,
  x = c(100, 200, 300),
  y = c(100, 100, 200)
) |>
  set_axis_directions(c(x = "right", y = "down"))

get_axis_directions(img)
#>       x       y 
#> "right"  "down"
img$y
#> [1] 100 100 200
```

Two axes along the same pair would be parallel, so that is refused:

``` r

set_axis_directions(img, c(y = "left"))
#> Error in `ensure_unopposed_axis_directions()`:
#> ! Axes "x" and "y" point along the same line.
#> ℹ "right" and "left" are all horizontal.
#> ℹ Two axes of one frame cannot be parallel.
```

### Roles, directions and extents

Three fields are keyed the same way and say different things. The
`where` role says which column carries `y`
([`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md));
`axis_directions` says which way `y` points; `axis_extents` says how far
it runs.

``` r

img <- set_metadata(img, axis_extents = c(y = 1080))

get_axes(img)
#>   x   y 
#> "x" "y"
get_axis_directions(img)
#>       x       y 
#> "right"  "down"
get_metadata(img, "axis_extents")
#>    y 
#> 1080
```

An extent is the length of the axis from zero — for image data, the
frame’s height or width in pixels. Its one use is as the thing an axis
is reflected around.
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
warns when the data already runs past it, since that usually means the
extent belongs to another recording.

## Turning an axis over

[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
changes the data. It reflects the column carrying the role and flips its
declared direction, so the frame describes the same scene with that axis
pointing the other way. Around a declared extent the reflection is
`extent - old`:

``` r

up <- reflect_axis(img, "y")

up$y
#> [1] 980 980 880
get_axis_directions(up)
#>       x       y 
#> "right"    "up"
```

Without an extent, the axis is centred on its origin and reflecting it
negates it:

``` r

img |>
  set_metadata(axis_extents = c(y = NA)) |>
  reflect_axis("y") |>
  dplyr::pull(y)
#> [1] -100 -100 -200
```

Turning `y` from down to up is the common case, and aniread’s readers do
it on import for image-derived formats. A known handedness flips too,
and so does any declared entity orientation (see
[below](#which-way-an-entity-faces)).

## What follows from the directions

Two things are read off the directions rather than stored, so they
cannot go on claiming a convention the axes no longer have.

[`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)
is the sense of rotation from `x` toward `y`. `atan2(y, x)` counts
counter-clockwise, so the same physical heading comes out mirrored
between a y-down and a y-up frame:

``` r

c(image = get_angle_direction(img), flipped = get_angle_direction(up))
#>               image             flipped 
#>         "clockwise" "counter_clockwise"
```

[`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md)
needs three axes. Two directions leave it open, so a 2D frame has a
sense of rotation but no handedness:

``` r

get_handedness(up)
#> [1] "unknown"
```

That gap matters more than it looks. A rodent filmed from above and the
same rodent filmed from below through a glass floor give images whose
`x` and `y` are declared identically, but whose rotations run opposite
ways: a left turn is a rising angle in one and a falling angle in the
other. The depth axis is the only thing that tells them apart. With `z`
pointing up out of the floor, it points toward the camera above (`back`)
and away from the camera below (`forward`):

``` r

above <- set_axis_directions(up, c(z = "back"))
below <- set_axis_directions(up, c(z = "forward"))

c(above = get_angle_direction(above), below = get_angle_direction(below))
#>               above               below 
#> "counter_clockwise"         "clockwise"
c(above = get_handedness(above), below = get_handedness(below))
#>   above   below 
#> "right"  "left"
```

The angle direction is seen from the side `z` points to. Since
`det[x y z]` is `(x × y) · z`, a right-handed frame counts
counter-clockwise about its own depth axis — always. The two answers are
one fact seen twice.

Most 3D recordings state the convention rather than spelling out each
axis. Declare it directly; three declared directions take precedence
over it when both are present:

``` r

right <- set_metadata(up, handedness = "right")
get_handedness(right)
#> [1] "right"
get_angle_direction(right)
#> [1] "counter_clockwise"
```

## Which way an entity faces

Position says where an entity is; orientation says which way it faces.
It is declared next to position, in the `where` role’s `orientation`
slot, with the same pattern: a closed set of roles mapped to columns of
any name.

A 2D frame uses `yaw`, measured from `x` toward `y` in `unit_angle`:

``` r

fly <- anipoint(
  individual = 1L, time = 1:3,
  x = c(0, 1, 2), y = c(0, 0, 1),
  heading = c(0, pi / 4, pi / 2)
) |>
  set_variables(where = list(orientation = c(yaw = "heading")))

get_variables(fly, "where", "orientation")
#>       yaw 
#> "heading"
```

A 3D frame uses a unit quaternion, `qw`, `qx`, `qy`, `qz` (Hamilton
convention, scalar first). This one turns a quarter-turn about `z`
between the two rows:

``` r

body <- anipoint(
  individual = 1L, time = 1:2,
  x = 0, y = 0, z = 0,
  qw = c(1, cos(pi / 4)), qx = 0, qy = 0, qz = c(0, sin(pi / 4))
) |>
  set_variables(
    where = list(orientation = c(qw = "qw", qx = "qx", qy = "qy", qz = "qz"))
  )

get_variables(body, "where", "orientation")
#>   qw   qx   qy   qz 
#> "qw" "qx" "qy" "qz"
```

The declaration is checked against the frame. A quaternion needs a 3D
frame and `yaw` a 2D one, and a quaternion must have unit norm:

``` r

body |>
  dplyr::mutate(qx = 0.5) |>
  set_variables(
    where = list(orientation = c(qw = "qw", qx = "qx", qy = "qy", qz = "qz"))
  )
#> Error in `ensure_valid_orientation()`:
#> ! Orientation quaternions must have unit norm; 2 rows do not.
#> ℹ Divide each by its norm before declaring it.
```

Declared orientation follows the frame.
[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
reflects it with the positions — `yaw` like an angle, a quaternion by
negating the two components off the reflected axis — and
[`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)
converts `yaw`:

``` r

reflect_axis(fly, "y")$heading
#> [1] 0.000000 5.497787 4.712389
convert_unit_angle(fly, "deg")$heading
#> [1]  0 45 90
reflect_axis(body, "x")$qz
#> [1]  0.0000000 -0.7071068
```

### Why quaternions, not Euler angles

Euler angles are how most sources report 3D orientation, and they break
under ordinary operations. Each angle wraps at ±π, so a mean or an
interpolation across the wrap gives the opposite direction:

``` r

roll <- c(3.1, -3.1)
mean(roll)
#> [1] 0
circ_mean(roll)
#> [1] 3.141593
```

[`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md)
fixes one column, but three Euler angles are not three independent
circular variables: near gimbal lock two of them describe the same
rotation, and no per-column treatment recovers it. A `summarise()` or an
interpolation over Euler columns gives a wrong rotation without
complaint. A quaternion has neither problem, so that is what the frame
stores.

Showing and entering orientation is a different matter, and there the
source’s convention is what people know. A frame can record it, so tools
don’t need it retyped each time:

``` r

body <- set_metadata(body, euler_sequence = "ZYX", euler_intrinsic = TRUE)
get_metadata(body, "euler_sequence")
#> [1] "ZYX"
```

The two are set together. anispace’s `transform_quaternion_to_euler()`
and `transform_euler_to_quaternion()` read them.

## Heading is not direction of travel

Orientation records measured state: FicTrac’s heading (integrated from
the ball’s rotation), a TRex posture angle, a rigid body from motion
capture. The direction of travel is a different quantity, derived from
successive positions, and the two disagree exactly when it is
interesting — side-slip, backing up, drift. Keep derived travel
direction in an ordinary column, not in `where$orientation`.

Nor is every angle a tracker reports a `yaw`. Blob and mask trackers
such as Bonsai and Octron give the angle of an ellipse’s long axis,
which has no front: θ and θ + π are the same. Declared as `yaw`, a mean,
a difference or a reflection would mix front and back, so these stay as
undeclared columns for now (see
[\#165](https://github.com/animovement/anicore/issues/165)).
