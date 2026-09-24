# Encode one state event column into bouts

One row per maximal run of identical non-`NA` values; `NA` breaks runs.

## Usage

``` r
encode_state_bouts(data, col, time_col, group_cols)
```
