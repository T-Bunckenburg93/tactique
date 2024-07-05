using GLMakie

function controlRectangle(center, width, height, angle,controlR)

    angle = deg2rad(angle)
    # Center of the rectangle
    x_c, y_c = center
    
    # Half dimensions
    half_width = width / 2
    half_height = height / 2
    
    # Define the corners relative to the center (no rotation)
    corners = [
        [ half_width,  half_height + controlR],
        [-half_width,  half_height + controlR],
        [-half_width, half_height],
        [ half_width, half_height]
    ]
    
    # Rotation matrix
    cos_theta = cos(angle)
    sin_theta = sin(angle)
    rotation_matrix = [
        cos_theta -sin_theta;
        sin_theta  cos_theta
    ]
    
    # Rotate and translate corners
    rotated_corners = [rotation_matrix * corner for corner in corners]
    translated_corners = [corner .+ [x_c, y_c] for corner in rotated_corners]
    
    return translated_corners
end



function controlArc(center, width, height, angle,controlR,controlAngle)
    
    # firstup we get the control rectange directly in front, and shunt it fowards.
    angle = deg2rad(angle)
    # Center of the rectangle
    x_c, y_c = center
    
    # Half dimensions
    half_width = width / 2
    half_height = height / 2
    
    # Define the corners relative to the center (no rotation)
    corners = [
        [ half_width,  half_height + controlR],
        [-half_width,  half_height + controlR],
        [-half_width, half_height],
        [ half_width, half_height]
    ]
    
    # Rotation matrix
    cos_theta = cos(angle)
    sin_theta = sin(angle)
    rotation_matrix = [
        cos_theta -sin_theta;
        sin_theta  cos_theta
    ]
    
    # Rotate and translate corners
    rotated_corners = [rotation_matrix * corner for corner in corners]
    translated_corners = [corner .+ [x_c, y_c] for corner in rotated_corners]

    # now we find the arcs either side and convert them into points. 

    leftP = translated_corners[4]
    rightP = translated_corners[3]
    # controlR = controlR
    num_points = 100
    startA = deg2rad(angle + 90 - controlAngle)
    midA = deg2rad(angle + 90)
    endA = deg2rad(angle + 90 + controlAngle)

    lAngle = range(startA, midA, length=num_points)
    rAngle = range(midA, endA, length=num_points)

    lPoints = [leftP .+ controlR * Point2f0(cos(θ), sin(θ)) for θ in lAngle]
    rPoints = [rightP .+ controlR * Point2f0(cos(θ), sin(θ)) for θ in rAngle]

    allPoints = vcat(lPoints,rPoints)
    return allPoints
end


p1 = Observable([1,2])
p1[] = [2,1]
linesegments(p1)

