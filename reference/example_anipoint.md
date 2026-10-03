# Create example anipoint data

Generates a synthetic anipoint object with random coordinates for
testing and demonstration purposes. The function creates a complete
design with all combinations of time points, individuals, keypoints,
trials, and sessions.

## Usage

``` r
example_anipoint(
  n_obs = 50,
  n_individuals = 3,
  n_keypoints = 11,
  n_trials = 1,
  n_sessions = 1,
  n_dims = 2
)
```

## Arguments

- n_obs:

  Integer. Number of time observations per combination. Default is 50.

- n_individuals:

  Integer. Number of individuals to simulate. Default is 3.

- n_keypoints:

  Integer. Number of keypoints per individual (max 11). Default is 11.
  When set to 1, only "centroid" is used. Otherwise, anatomical
  keypoints are used (head, neck, shoulders, etc.).

- n_trials:

  Integer. Number of trials per session. Default is 1.

- n_sessions:

  Integer. Number of sessions. Default is 1.

- n_dims:

  Integer. Number of spatial dimensions (1, 2, or 3). Default is 2. If
  1, only x coordinates are generated. If 2, x and y coordinates are
  generated. If 3, x, y, and z coordinates are generated.

## Value

An anipoint object containing randomly generated tracking data with
columns for individual, keypoint, time, trial, session, and spatial
coordinates (x, y, and/or z depending on `n_dims`). The coordinates are
drawn from a standard normal distribution.

## Examples

``` r
# Create a basic example with default parameters (2D)
example_anipoint()
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x      y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.230   1.78       0.568
#>  2          1 head           1     1     2 -1.51    1.32       0.955
#>  3          1 head           1     1     3 -0.584  -0.724      0.818
#>  4          1 head           1     1     4 -2.02   -0.263      0.444
#>  5          1 head           1     1     5  0.404  -0.349      0.810
#>  6          1 head           1     1     6  0.550  -0.213      0.556
#>  7          1 head           1     1     7  0.0284  0.749      0.833
#>  8          1 head           1     1     8  0.893  -3.00       0.825
#>  9          1 head           1     1     9 -0.377  -0.206      0.914
#> 10          1 head           1     1    10  0.606  -0.144      0.630
#> # ℹ 1,640 more rows

# Create a 1D example
example_anipoint(n_dims = 1)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>      <dbl>
#>  1          1 head           1     1     1  0.539       0.861
#>  2          1 head           1     1     2  1.80        0.784
#>  3          1 head           1     1     3 -0.232       0.704
#>  4          1 head           1     1     4  0.758       0.674
#>  5          1 head           1     1     5  0.552       0.846
#>  6          1 head           1     1     6 -0.864       0.516
#>  7          1 head           1     1     7 -0.348       0.849
#>  8          1 head           1     1     8 -1.18        0.840
#>  9          1 head           1     1     9 -2.38        0.529
#> 10          1 head           1     1    10 -0.0452      0.712
#> # ℹ 1,640 more rows

# Create a 3D example
example_anipoint(n_dims = 3)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x       y      z confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>   <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -1.14    1.17   -0.854      0.644
#>  2          1 head           1     1     2 -1.58   -0.398  -0.207      0.544
#>  3          1 head           1     1     3 -1.78   -0.761   0.646      0.855
#>  4          1 head           1     1     4 -1.33    0.0570 -0.830      0.490
#>  5          1 head           1     1     5  0.125  -0.608   0.414      0.952
#>  6          1 head           1     1     6  1.42   -1.15   -1.76       0.826
#>  7          1 head           1     1     7 -3.17   -1.23    1.40       0.944
#>  8          1 head           1     1     8  0.959   0.287  -1.95       0.366
#>  9          1 head           1     1     9  0.231  -0.887  -0.243      0.578
#> 10          1 head           1     1    10  0.0745 -0.696   1.08       0.893
#> # ℹ 1,640 more rows

# Create a smaller example with 2 individuals and 5 keypoints
example_anipoint(n_individuals = 2, n_keypoints = 5)
#> # Individuals: 1, 2
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x      y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.0613  0.771      0.692
#>  2          1 head           1     1     2 -1.40   -0.267      0.785
#>  3          1 head           1     1     3  1.00   -0.397      0.801
#>  4          1 head           1     1     4  1.26    1.67       0.667
#>  5          1 head           1     1     5 -0.763  -0.357      0.884
#>  6          1 head           1     1     6  0.791  -0.489      0.928
#>  7          1 head           1     1     7  0.181  -0.885      0.663
#>  8          1 head           1     1     8 -0.562  -0.974      0.941
#>  9          1 head           1     1     9 -1.20   -1.13       0.334
#> 10          1 head           1     1    10 -0.338  -1.74       0.897
#> # ℹ 490 more rows

# Create example with multiple trials and sessions
example_anipoint(n_obs = 100, n_trials = 3, n_sessions = 2)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1, 2
#> # Trials:      1, 2, 3
#>    individual keypoint session trial  time       x      y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.552  -0.851      0.689
#>  2          1 head           1     1     2 -0.711   1.86       0.866
#>  3          1 head           1     1     3 -1.52    1.24       0.686
#>  4          1 head           1     1     4  0.576  -0.596      0.887
#>  5          1 head           1     1     5  0.775   0.911      0.523
#>  6          1 head           1     1     6  0.0397 -0.266      0.971
#>  7          1 head           1     1     7  1.21    0.318      0.198
#>  8          1 head           1     1     8  0.520   0.378      0.724
#>  9          1 head           1     1     9  0.0752 -0.902      0.661
#> 10          1 head           1     1    10  0.553   1.21       0.608
#> # ℹ 19,790 more rows

# Create minimal example with just centroid in 3D
example_anipoint(n_keypoints = 1, n_dims = 3)
#> # Individuals: 1, 2, 3
#> # Keypoints:   centroid
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x      y        z confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>  <dbl>    <dbl>      <dbl>
#>  1          1 centroid       1     1     1  0.713   0.757 -0.735        0.703
#>  2          1 centroid       1     1     2  1.32   -0.995  1.67         0.468
#>  3          1 centroid       1     1     3 -1.18   -0.549 -0.332        0.658
#>  4          1 centroid       1     1     4 -2.41   -1.51  -0.00790      0.806
#>  5          1 centroid       1     1     5 -0.582  -1.41   0.487        0.858
#>  6          1 centroid       1     1     6  1.74   -1.51   1.62         0.829
#>  7          1 centroid       1     1     7 -0.191  -0.861  0.651        0.889
#>  8          1 centroid       1     1     8 -0.199   2.17  -1.52         0.708
#>  9          1 centroid       1     1     9  0.0163 -0.787 -0.578        0.746
#> 10          1 centroid       1     1    10 -1.65    1.51  -1.48         0.895
#> # ℹ 140 more rows
```
