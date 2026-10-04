# metadata prints one compact line per field set

    Code
      print(md)
    Output
      -- animovement metadata --------------------------------------------------------
      
      -- recording 
      source: deeplabcut
      
      -- time 
      unit_time: frame
      sampling_rate: 30 Hz
      sampling_interval: 1 frame
      
      -- space 
      coordinate_system: cartesian_2d
      reference_frame: allocentric
      handedness: unknown
      unit_space: px
      unit_angle: rad
      
      -- variables 
      what   keys: individual, keypoint
      when   index: time | keys: session, trial
      where  position: x = x, y = y
      event  state: - | point: -
      
      -- structure 
      keypoint: 11 points, 10 segments, 3 joints
      pair (over individual): 2 points, 1 segment, 0 joints
      
      Not set: source_version, source_format, filename, start_datetime,
        axis_directions, axis_extents, euler_sequence, euler_intrinsic

# all = TRUE prints every field, the allowed values and spec_version

    Code
      print(md, all = TRUE)
    Output
      -- animovement metadata --------------------------------------------------------
      
      -- recording 
      source: deeplabcut
      source_version: -
      source_format: -
      filename: -
      
      -- time 
      unit_time: frame
        levels: unknown, frame, ns, us, ms, s, m, h
      sampling_rate: 30 Hz
      sampling_interval: 1 frame
      start_datetime: -
      
      -- space 
      coordinate_system: cartesian_2d
        levels: unknown, cartesian_1d, cartesian_2d, cartesian_3d, polar, cylindrical,
          spherical
      reference_frame: allocentric
        levels: allocentric, egocentric, none
      handedness: unknown
        levels: right, left, unknown
      axis_directions: -
      axis_extents: -
      unit_space: px
        levels: px, none, nm, um, mm, cm, m, km
      unit_angle: rad
        levels: rad, deg, none
      euler_sequence: -
      euler_intrinsic: -
      
      -- variables 
      what   keys: individual, keypoint
      when   index: time | keys: session, trial
      where  position: x = x, y = y
      event  state: - | point: -
      
      -- structure 
      keypoint: 11 points, 10 segments, 3 joints
      pair (over individual): 2 points, 1 segment, 0 joints
      
      spec_version: aniframe 3.0.0, anievent 1.0.0

# anievent metadata prints without a space category

    Code
      print(get_metadata(ev))
    Output
      -- animovement metadata --------------------------------------------------------
      
      -- time 
      unit_time: frame
      
      -- variables 
      what  keys: individual
      when  interval: start, stop | keys: -
      
      Not set: source, source_version, source_format, filename, sampling_rate,
        sampling_interval, start_datetime, structure

# metadata print wraps to the console width

    Code
      print(get_metadata(example_anipoint()))
    Output
      -- animovement metadata --------------------------
      
      -- time 
      unit_time: frame
      sampling_interval: 1 frame
      
      -- space 
      coordinate_system: cartesian_2d
      reference_frame: allocentric
      handedness: unknown
      unit_space: px
      unit_angle: rad
      
      -- variables 
      what   keys: individual, keypoint
      when   index: time | keys: session, trial
      where  position: x = x, y = y
      event  state: - | point: -
      
      Not set: source, source_version, source_format,
        filename, sampling_rate, start_datetime,
        axis_directions, axis_extents, euler_sequence,
        euler_intrinsic, structure

