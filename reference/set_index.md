# Declare which column an anipoint is indexed by

Makes `column` the index, the `when$index` slot, and re-sorts the frame.
A column that was a `when` key stops being one. `unit` declares the unit
of the new index in the same call; without it, the frame goes on
declaring the unit of the old index.

The new index must be numeric, with no missing values, and must increase
within each group of keys (identity plus temporal context) in the order
of the old index, so the rows keep their order: values that go backwards
have been matched to the wrong rows. Date-times are refused: the index
holds the time since the start, as numbers, and the start goes in
`start_datetime`, so absolute time is `start_datetime` plus the index.

## Usage

``` r
set_index(data, column, unit = NULL)
```

## Arguments

- data:

  An anipoint object.

- column:

  Length-one character vector naming the index column. It must exist in
  `data` and be numeric.

- unit:

  The unit of the new index, one of the levels of `unit_time` in
  [`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md).
  `NULL`, the default, leaves `unit_time` as it is.

## Value

`data`, re-indexed and restructured.

## The old index

The previous index becomes an ordinary, undeclared column rather than a
key, as grouping by it would put each row in a group of its own.

When it counted frames (`unit_time` is `"frame"`), it is renamed
`frame`. Frame numbers recorded with the data are data, not something to
compute again from a rate, and
[`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md)
makes the `frame` column the index again when converting to `"frame"`.
An old index already named `frame` keeps its name, and so does one
replaced by a new index named `frame`. If the frame has another column
named `frame`, `set_index()` refuses rather than overwrite either;
rename one first.

## Indexing by recorded timestamps

Timestamps recorded alongside the data, such as a camera's log of when
each frame was taken, are added as a column and made the index with
their unit:

    data |>
      dplyr::mutate(timestamp = stamps[time + 1]) |>
      set_index("timestamp", unit = "s")

Here the log has one entry per frame and frames count from 0, so the
timestamp of a row is matched by its frame number. Matching by position,
assigning the log in row order, lines up only when every group is
complete and sorted: an anipoint has one row per time per key, and a
keypoint can be missing from some frames. Bringing a log, or any other
data, into a frame is a join question, tracked in
[anicore#1](https://github.com/animovement/anicore/issues/1).

The frame numbers move to a column named `frame`, and a declared
`sampling_rate` is kept as the nominal rate. `sampling_interval` is
measured from the timestamps, and
[`validate_anipoint()`](https://animovement.dev/anicore/reference/validate_anipoint.md)
allows the two to differ by 1%. Overwriting `time` with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
instead would lose the frame numbers and leave the frame saying the
index counts frames when it holds seconds.

## See also

[`get_index()`](https://animovement.dev/anicore/reference/get_index.md),
[`convert_unit_time()`](https://animovement.dev/anicore/reference/convert_unit_time.md)
to rescale the index into another unit.

## Examples

``` r
df <- data.frame(frame = 1:3, individual = "a", x = c(1, 2, 3), y = c(0, 1, 0))
af <- as_anipoint(df, index = "frame")
get_index(af)
#> [1] "frame"

# A camera log, one timestamp per frame, frames counted from 0
af <- as_anipoint(data.frame(
  individual = "a",
  keypoint = rep(c("head", "tail"), each = 4),
  time = rep(0:3, 2),
  x = 1:8,
  y = 1:8
))
stamps <- c(0, 0.0332, 0.0668, 0.1001)
logged <- af |>
  dplyr::mutate(timestamp = stamps[time + 1]) |>
  set_index("timestamp", unit = "s")
logged
#> # Individuals: a
#> # Keypoints:   head, tail
#> # Time:        00:00:00.000 to 00:00:00.100
#>   individual keypoint timestamp     x     y frame
#>   <fct>      <fct>        <dbl> <dbl> <dbl> <int>
#> 1 a          head        0          1     1     0
#> 2 a          head        0.0332     2     2     1
#> 3 a          head        0.0668     3     3     2
#> 4 a          head        0.100      4     4     3
#> 5 a          tail        0          5     5     0
#> 6 a          tail        0.0332     6     6     1
#> 7 a          tail        0.0668     7     7     2
#> 8 a          tail        0.100      8     8     3

# The frame numbers are kept, and become the index again
get_index(convert_unit_time(logged, "frame"))
#> [1] "frame"
```
