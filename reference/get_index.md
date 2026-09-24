# The column an anipoint is indexed by

Exactly one column, of any name, holding the position of each row within
its temporal context: the `when$index` slot. It is never a grouping
column. An
[`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
has none, since a bout spans the `start`/`stop` interval.

## Usage

``` r
get_index(data)
```

## Arguments

- data:

  An anipoint object.

## Value

Length-one character vector naming the index column.

## See also

[`set_index()`](https://animovement.dev/anicore/reference/set_index.md)
to change it,
[`get_variables()`](https://animovement.dev/anicore/reference/variables.md)
for the other temporal columns.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
get_index(af)
#> [1] "time"
```
