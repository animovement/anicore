# Package index

## Creating and converting anipoint objects

Functions that create an anipoint (the position-grain frame), coerce
other objects to anipoint, or provide example data. `aniframe` is the
abstract parent class shared by anipoint and anievent.

- [`as_anipoint()`](https://animovement.dev/anicore/reference/as_anipoint.md)
  : Convert a data frame to anipoint
- [`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md)
  : Create an anipoint data frame
- [`example_anipoint()`](https://animovement.dev/anicore/reference/example_anipoint.md)
  : Create example anipoint data
- [`is_anipoint()`](https://animovement.dev/anicore/reference/is_anipoint.md)
  : Check if object is an anipoint
- [`ensure_is_anipoint()`](https://animovement.dev/anicore/reference/ensure_is_anipoint.md)
  : Ensure object is an anipoint
- [`is_aniframe()`](https://animovement.dev/anicore/reference/is_aniframe.md)
  : Check if object is an aniframe
- [`ensure_is_aniframe()`](https://animovement.dev/anicore/reference/ensure_is_aniframe.md)
  : Ensure object is an aniframe
- [`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
  : Validate an anipoint
- [`aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  [`as_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  [`example_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  [`validate_aniframe()`](https://animovement.dev/anicore/reference/anicore-deprecated.md)
  : Deprecated aniframe constructors

## Creating and converting anievent objects

Functions that create an anievent (long-format behavioural event
records) or coerce other objects to anievent.

- [`to_anievent()`](https://animovement.dev/anicore/reference/to_anievent.md)
  : Encode per-frame data into an anievent
- [`as_anievent()`](https://animovement.dev/anicore/reference/as_anievent.md)
  : Cast a data frame to an anievent
- [`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
  : Create an anievent data frame
- [`is_anievent()`](https://animovement.dev/anicore/reference/is_anievent.md)
  : Check if object is an anievent
- [`ensure_is_anievent()`](https://animovement.dev/anicore/reference/ensure_is_anievent.md)
  : Ensure object is an anievent
- [`validate_anievent()`](https://animovement.dev/anicore/reference/validate_anievent.md)
  : Validate an anievent

## Metadata

Read and declare metadata. `set_*` only declares; it never changes a
value.

- [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md)
  : Get metadata
- [`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
  : Set metadata
- [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)
  : Default metadata structure
- [`get_sampling_interval()`](https://animovement.dev/anicore/reference/get_sampling_interval.md)
  : The interval between consecutive observations
- [`is_sampling_regular()`](https://animovement.dev/anicore/reference/is_sampling_regular.md)
  : Is the frame regularly sampled?
- [`get_axis_directions()`](https://animovement.dev/anicore/reference/get_axis_directions.md)
  : Get the direction each axis points
- [`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md)
  : Say which way an axis points
- [`get_angle_direction()`](https://animovement.dev/anicore/reference/get_angle_direction.md)
  : Which way angles run
- [`get_handedness()`](https://animovement.dev/anicore/reference/get_handedness.md)
  : Whether the frame is right- or left-handed
- [`get_coordinate_system()`](https://animovement.dev/anicore/reference/get_coordinate_system.md)
  : The coordinate system an anipoint is in

## Declaring variables

Declare which columns carry identity, time, position and events. The
setters restructure the frame to match, so
[`set_metadata()`](https://animovement.dev/anicore/reference/set_metadata.md)
refuses these fields.

- [`get_variables()`](https://animovement.dev/anicore/reference/variables.md)
  [`set_variables()`](https://animovement.dev/anicore/reference/variables.md)
  [`add_variables()`](https://animovement.dev/anicore/reference/variables.md)
  [`remove_variables()`](https://animovement.dev/anicore/reference/variables.md)
  : Read and declare which columns carry identity, time, position and
  events
- [`get_keys()`](https://animovement.dev/anicore/reference/get_keys.md)
  : The grouping columns of a frame
- [`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
  : The column an anipoint is indexed by
- [`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
  : Declare which column an anipoint is indexed by
- [`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md)
  : The axis roles of an anipoint, and the columns carrying them

## Transforming values

Functions that change values and update the metadata to match.

- [`convert_unit_space()`](https://animovement.dev/anicore/reference/convert_unit_space.md)
  : Convert the spatial unit of an anipoint
- [`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md)
  : Convert the time unit of an anipoint or anievent
- [`convert_unit_angle()`](https://animovement.dev/anicore/reference/convert_unit_angle.md)
  : Convert the angular unit of an anipoint
- [`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)
  : Turn an axis over

## Structures

Points, the segments between them, and joints, over the levels of an
identity or temporal variable. A frame can hold several named
structures.

- [`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)
  : Create a structure: points, the segments between them, and joints

- [`example_structure()`](https://animovement.dev/anicore/reference/example_structure.md)
  :

  An example structure for the keypoints of
  [`example_anipoint()`](https://animovement.dev/anicore/reference/example_anipoint.md)

- [`validate_anistructure()`](https://animovement.dev/anicore/reference/validate_anistructure.md)
  : Check that a structure is internally consistent

- [`is_anistructure()`](https://animovement.dev/anicore/reference/is_anistructure.md)
  [`ensure_is_anistructure()`](https://animovement.dev/anicore/reference/is_anistructure.md)
  : Test whether an object is an anistructure

- [`set_structure()`](https://animovement.dev/anicore/reference/structures.md)
  [`get_structure()`](https://animovement.dev/anicore/reference/structures.md)
  [`remove_structure()`](https://animovement.dev/anicore/reference/structures.md)
  : Attach, read and remove the structures of a frame

## Segments

The same data re-expressed per segment: a length and a unit direction,
converted from and back to an anipoint.

- [`as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.md)
  : Convert an anipoint to segments: a length and a direction per
  segment
- [`is_anisegment()`](https://animovement.dev/anicore/reference/is_anisegment.md)
  [`ensure_is_anisegment()`](https://animovement.dev/anicore/reference/is_anisegment.md)
  : Test whether an object is an anisegment

## Joints

One angle per joint, computed from its two segments.

- [`as_anijoint()`](https://animovement.dev/anicore/reference/as_anijoint.md)
  : Convert segments to joints: one angle per joint
- [`is_anijoint()`](https://animovement.dev/anicore/reference/is_anijoint.md)
  [`ensure_is_anijoint()`](https://animovement.dev/anicore/reference/is_anijoint.md)
  : Test whether an object is an anijoint

## Spatial checks

These functions provide checks for your coordinate system.
[`is_spatial()`](https://animovement.dev/anicore/reference/is_spatial.md)
and
[`ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.md)
check that the declared position columns are present and numeric; the
`is_cartesian*()` family reports which coordinate system the frame is
in, which follows from the axis roles it declares.

- [`is_spatial()`](https://animovement.dev/anicore/reference/is_spatial.md)
  : Test whether the spatial columns match the metadata
- [`ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.md)
  : Ensure the spatial columns match the metadata
- [`is_cartesian()`](https://animovement.dev/anicore/reference/is_cartesian.md)
  : Test whether an anipoint uses a Cartesian coordinate system
- [`is_cartesian_1d()`](https://animovement.dev/anicore/reference/is_cartesian_1d.md)
  : Test for a 1-D Cartesian coordinate system
- [`is_cartesian_2d()`](https://animovement.dev/anicore/reference/is_cartesian_2d.md)
  : Test for a 2-D Cartesian coordinate system
- [`is_cartesian_3d()`](https://animovement.dev/anicore/reference/is_cartesian_3d.md)
  : Test for a 3-D Cartesian coordinate system
- [`is_polar()`](https://animovement.dev/anicore/reference/is_polar.md)
  : Test whether an anipoint uses a polar coordinate system
- [`is_cylindrical()`](https://animovement.dev/anicore/reference/is_cylindrical.md)
  : Test whether an anipoint uses a cylindrical coordinate system
- [`is_spherical()`](https://animovement.dev/anicore/reference/is_spherical.md)
  : Test whether an anipoint uses a spherical coordinate system
- [`ensure_is_cartesian()`](https://animovement.dev/anicore/reference/ensure_is_cartesian.md)
  : Internal guard for Cartesian checks
- [`ensure_is_cartesian_1d()`](https://animovement.dev/anicore/reference/ensure_is_cartesian_1d.md)
  : Internal guard for 1-D Cartesian checks
- [`ensure_is_cartesian_2d()`](https://animovement.dev/anicore/reference/ensure_is_cartesian_2d.md)
  : Internal guard for 2-D Cartesian checks
- [`ensure_is_cartesian_3d()`](https://animovement.dev/anicore/reference/ensure_is_cartesian_3d.md)
  : Internal guard for 3-D Cartesian checks
- [`ensure_is_polar()`](https://animovement.dev/anicore/reference/ensure_is_polar.md)
  : Internal guard for polar checks
- [`ensure_is_cylindrical()`](https://animovement.dev/anicore/reference/ensure_is_cylindrical.md)
  : Internal guard for cylindrical checks
- [`ensure_is_spherical()`](https://animovement.dev/anicore/reference/ensure_is_spherical.md)
  : Internal guard for spherical checks

## Angles

Two families, and the difference matters. `*_angle()` and the `x_to_y()`
conversions manipulate how an angle is written. The `circ_*()` functions
compute with the wraparound: an ordinary mean or median of angles gives
the wrong answer, since the mean of 350 and 10 degrees is 0, not 180.

### Handling angles

- [`rad_to_deg()`](https://animovement.dev/anicore/reference/rad_to_deg.md)
  : Convert radians to degrees
- [`deg_to_rad()`](https://animovement.dev/anicore/reference/deg_to_rad.md)
  : Convert degrees to radians
- [`wrap_angle()`](https://animovement.dev/anicore/reference/wrap_angle.md)
  : Constrain angles to a standard range
- [`unwrap_angle()`](https://animovement.dev/anicore/reference/unwrap_angle.md)
  : Remove wrapping from a sequence of angles
- [`angle_between()`](https://animovement.dev/anicore/reference/angle_between.md)
  : The angle between two vectors

### Circular statistics

- [`circ_difference()`](https://animovement.dev/anicore/reference/circ_difference.md)
  : Shortest signed distance between two angles
- [`circ_successive_difference()`](https://animovement.dev/anicore/reference/circ_successive_difference.md)
  : Differences between successive angles in a series
- [`circ_mean()`](https://animovement.dev/anicore/reference/circ_mean.md)
  : Circular mean
- [`circ_median()`](https://animovement.dev/anicore/reference/circ_median.md)
  : Circular median
- [`circ_sd()`](https://animovement.dev/anicore/reference/circ_sd.md) :
  Circular standard deviation
- [`circ_mad()`](https://animovement.dev/anicore/reference/circ_mad.md)
  : Circular median absolute deviation

## Helpers

- [`convert_nan_to_na()`](https://animovement.dev/anicore/reference/convert_nan_to_na.md)
  : Convert NaN to NA in numeric columns
- [`convert_inf_to_na()`](https://animovement.dev/anicore/reference/convert_inf_to_na.md)
  : Convert Inf to NA in numeric columns
