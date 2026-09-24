# Attach, read and remove the structures of a frame

A frame can carry any number of named
[`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)s,
each spanning the levels of one identity or temporal variable. Several
may span the same variable and overlap: a football frame can hold
`team`, `defence` and `left_flank` over `individual` alongside a
`skeleton` over `keypoint`. A structure's `points` are its members;
levels it does not list are outside it.

- `set_structure()` attaches a structure under `name`, replacing one of
  the same name.

- `get_structure()` returns all structures as a named list, or one.

- `remove_structure()` drops one.

Points not found in the data are kept with a warning, in case they are
recorded in another file.

## Usage

``` r
set_structure(data, structure, variable = "keypoint", name = variable)

get_structure(data, name = NULL)

remove_structure(data, name)
```

## Arguments

- data:

  An anipoint.

- structure:

  An
  [`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md).

- variable:

  The `what` or `when` key whose levels the points are.

- name:

  Name to store the structure under. Defaults to `variable`.

## Value

`set_structure()` and `remove_structure()`: `data`, with the structures
updated. `get_structure()`: a named list of structures, or one
structure.

## See also

[`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 2)
af <- set_structure(af, example_structure())
get_structure(af, "keypoint")
#> <anistructure> 11 points, 10 segments, 3 joints
#> variable: keypoint; root: abdomen
#> Points: abdomen, neck, hip_right, hip_left, knee_right, knee_left, head, shoulder_right, shoulder_left, foot_right, foot_left
#> Segments: spine (abdomen -> neck), head (neck -> head), shoulder_right (neck -> shoulder_right), shoulder_left (neck -> shoulder_left), hip_right (abdomen -> hip_right), hip_left (abdomen -> hip_left), thigh_right (hip_right -> knee_right), thigh_left (hip_left -> knee_left), shin_right (knee_right -> foot_right), shin_left (knee_left -> foot_left)
#> Joints: neck (spine, head), knee_right (thigh_right, shin_right), knee_left (thigh_left, shin_left)

# Several structures over the same variable
af <- af |>
  set_structure(anistructure(points = c("1", "2")), "individual", "pair") |>
  set_structure(anistructure(points = "1"), "individual", "focal")
names(get_structure(af))
#> [1] "keypoint" "pair"     "focal"   
```
