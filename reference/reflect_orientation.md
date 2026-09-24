# Turn the orientation over with an axis

`yaw` is measured from `x` toward `y`, so it reflects like `phi`. A
reflection conjugates a rotation and reverses its sense: across the
plane normal to `axis`, a quaternion keeps `w` and that axis's component
and negates the other two.

## Usage

``` r
reflect_orientation(data, axis)
```

## Arguments

- data:

  An anipoint object.

- axis:

  `"x"`, `"y"` or `"z"`.

## Value

`data`, with the orientation columns reflected.
