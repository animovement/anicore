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
#>    individual keypoint session trial  time       x       y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>   <dbl>      <dbl>
#>  1          1 head           1     1     1  1.01    0.0129      0.749
#>  2          1 head           1     1     2  2.17    0.291       0.450
#>  3          1 head           1     1     3  2.32   -2.02        0.731
#>  4          1 head           1     1     4 -1.02   -1.60        0.450
#>  5          1 head           1     1     5  0.0488  0.791       0.715
#>  6          1 head           1     1     6 -0.772  -0.0560      0.858
#>  7          1 head           1     1     7 -0.785   2.78        0.539
#>  8          1 head           1     1     8 -0.727   0.395       0.627
#>  9          1 head           1     1     9  0.682   2.70        0.568
#> 10          1 head           1     1    10 -0.230   1.06        0.955
#> # ℹ 1,640 more rows

# Create a 1D example
example_anipoint(n_dims = 1)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.319      0.555
#>  2          1 head           1     1     2  0.408      0.707
#>  3          1 head           1     1     3 -0.734      0.532
#>  4          1 head           1     1     4 -0.281      0.527
#>  5          1 head           1     1     5 -0.147      0.455
#>  6          1 head           1     1     6  0.190      0.728
#>  7          1 head           1     1     7  0.652      0.828
#>  8          1 head           1     1     8 -0.101      0.653
#>  9          1 head           1     1     9  0.860      0.795
#> 10          1 head           1     1    10 -1.63       0.861
#> # ℹ 1,640 more rows

# Create a 3D example
example_anipoint(n_dims = 3)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x       y      z confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>   <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -1.30   0.655   2.37       0.504
#>  2          1 head           1     1     2  1.02   1.35    0.312      0.802
#>  3          1 head           1     1     3  0.534  0.0500 -1.04       0.684
#>  4          1 head           1     1     4  0.456 -0.724   0.388      0.474
#>  5          1 head           1     1     5 -0.885 -0.745  -0.754      0.730
#>  6          1 head           1     1     6 -1.49   0.514   0.377      0.764
#>  7          1 head           1     1     7  0.703  1.04    0.533      0.453
#>  8          1 head           1     1     8 -0.975 -0.0868  0.955      0.541
#>  9          1 head           1     1     9 -0.446  1.17   -0.854      0.644
#> 10          1 head           1     1    10 -1.14  -0.398  -0.207      0.544
#> # ℹ 1,640 more rows

# Create a smaller example with 2 individuals and 5 keypoints
example_anipoint(n_individuals = 2, n_keypoints = 5)
#> # Individuals: 1, 2
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x       y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>   <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.384   0.393       0.720
#>  2          1 head           1     1     2  1.28    0.468       0.649
#>  3          1 head           1     1     3  0.481   1.83        0.620
#>  4          1 head           1     1     4 -0.209  -1.53        0.550
#>  5          1 head           1     1     5 -0.522   0.484       0.654
#>  6          1 head           1     1     6 -0.737   0.167       0.732
#>  7          1 head           1     1     7  0.269   0.362       0.679
#>  8          1 head           1     1     8  1.10    0.0849      0.692
#>  9          1 head           1     1     9 -0.0613  0.771       0.785
#> 10          1 head           1     1    10 -1.40   -0.267       0.801
#> # ℹ 490 more rows

# Create example with multiple trials and sessions
example_anipoint(n_obs = 100, n_trials = 3, n_sessions = 2)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1, 2
#> # Trials:      1, 2, 3
#>    individual keypoint session trial  time       x        y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>    <dbl>      <dbl>
#>  1          1 head           1     1     1  0.960   0.107        0.773
#>  2          1 head           1     1     2 -0.283  -0.00991      0.434
#>  3          1 head           1     1     3  0.291  -0.778        0.610
#>  4          1 head           1     1     4  0.537   1.17         0.729
#>  5          1 head           1     1     5  0.632   0.440        0.799
#>  6          1 head           1     1     6  0.292  -0.790        0.627
#>  7          1 head           1     1     7 -0.0304 -1.23         0.919
#>  8          1 head           1     1     8  0.774   0.434        0.775
#>  9          1 head           1     1     9 -0.552   0.282        0.689
#> 10          1 head           1     1    10 -0.711  -1.74         0.866
#> # ℹ 19,790 more rows

# Create minimal example with just centroid in 3D
example_anipoint(n_keypoints = 1, n_dims = 3)
#> # Individuals: 1, 2, 3
#> # Keypoints:   centroid
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time       x      y       z confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>  <dbl>   <dbl>      <dbl>
#>  1          1 centroid       1     1     1 -0.0298 -1.36  -0.298       0.441
#>  2          1 centroid       1     1     2  0.0586  1.62  -0.283       0.695
#>  3          1 centroid       1     1     3  0.592   1.68   0.877       0.693
#>  4          1 centroid       1     1     4 -0.948  -0.475 -2.48        0.889
#>  5          1 centroid       1     1     5  0.649   1.08   0.391       0.680
#>  6          1 centroid       1     1     6  1.05    1.38   0.528       0.769
#>  7          1 centroid       1     1     7  1.42    1.24  -1.01        0.833
#>  8          1 centroid       1     1     8  0.314   0.284 -1.02        0.713
#>  9          1 centroid       1     1     9  1.15    0.620 -0.0716      0.515
#> 10          1 centroid       1     1    10  0.624  -0.931 -0.0884      0.840
#> # ℹ 140 more rows
```
