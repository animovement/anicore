# Print a structure

Prints the counts of a structure's points, segments and joints, then
each list wrapped to the console width. A segment prints as `from - to`
when its name is the default `from-to`, and as `name: from - to` when it
has a name of its own; joints likewise, over their two segments.

Like a tibble's rows, a list of more than 20 prints its first 10 and how
many more there are. `n` sets how many to print; `n = Inf` prints all.

## Usage

``` r
# S3 method for class 'anistructure'
print(x, n = NULL, ...)

# S3 method for class 'anistructure'
format(x, n = NULL, width = cli::console_width(), ...)
```

## Arguments

- x:

  An
  [`anistructure()`](https://animovement.dev/anicore/reference/anistructure.md).

- n:

  How many points, segments and joints to print. `NULL` (the default)
  prints a list in full up to 20 entries, and the first 10 of a longer
  one.

- ...:

  Unused.

- width:

  Width to wrap the lists to (default the console width).

## Value

[`print()`](https://rdrr.io/r/base/print.html): `x`, invisibly.
[`format()`](https://rdrr.io/r/base/format.html): a character vector of
lines.

## Examples

``` r
s <- example_structure()
s
#> <anistructure> 11 points, 10 segments, 3 joints
#> root: abdomen
#> Points: abdomen, neck, hip_right, hip_left, knee_right, knee_left, head,
#>   shoulder_right, shoulder_left, foot_right, foot_left
#> Segments: spine: abdomen - neck, head: neck - head,
#>   shoulder_right: neck - shoulder_right, shoulder_left: neck - shoulder_left,
#>   hip_right: abdomen - hip_right, hip_left: abdomen - hip_left,
#>   thigh_right: hip_right - knee_right, thigh_left: hip_left - knee_left,
#>   shin_right: knee_right - foot_right, shin_left: knee_left - foot_left
#> Joints: neck: spine - head, knee_right: thigh_right - shin_right,
#>   knee_left: thigh_left - shin_left
print(s, n = 3)
#> <anistructure> 11 points, 10 segments, 3 joints
#> root: abdomen
#> Points: abdomen, neck, hip_right, ... and 8 more
#> Segments: spine: abdomen - neck, head: neck - head,
#>   shoulder_right: neck - shoulder_right, ... and 7 more
#> Joints: neck: spine - head, knee_right: thigh_right - shin_right,
#>   knee_left: thigh_left - shin_left
```
