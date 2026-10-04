# printing summarises the parts

    Code
      print(example_structure())
    Output
      <anistructure> 11 points, 10 segments, 3 joints
      root: abdomen
      Points: abdomen, neck, hip_right, hip_left, knee_right, knee_left, head,
        shoulder_right, shoulder_left, foot_right, foot_left
      Segments: spine: abdomen - neck, head: neck - head,
        shoulder_right: neck - shoulder_right, shoulder_left: neck - shoulder_left,
        hip_right: abdomen - hip_right, hip_left: abdomen - hip_left,
        thigh_right: hip_right - knee_right, thigh_left: hip_left - knee_left,
        shin_right: knee_right - foot_right, shin_left: knee_left - foot_left
      Joints: neck: spine - head, knee_right: thigh_right - shin_right,
        knee_left: thigh_left - shin_left

# printing wraps the lists to the width

    Code
      print(s)
    Output
      <anistructure> 9 points, 8 segments, 0 joints
      Points: point_1, point_2, point_3, point_4,
        point_5, point_6, point_7, point_8, point_9
      Segments: point_1 - point_2, point_2 - point_3,
        point_3 - point_4, point_4 - point_5,
        point_5 - point_6, point_6 - point_7,
        point_7 - point_8, point_8 - point_9

# long lists are truncated like tibble rows

    Code
      print(chain, n = 3)
    Output
      <anistructure> 24 points, 23 segments, 0 joints
      Points: s1, s2, s3, ... and 21 more
      Segments: s1 - s2, s2 - s3, s3 - s4, ... and 20 more

