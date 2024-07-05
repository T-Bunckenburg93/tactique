using LinearAlgebra
using GLMakie
using GLMakie.GeometryBasics
using Random
using Distributions
import Base: show

"""
# This is a simple implementation of a unit in a game.

Name: Name of the Unit
id: uniquely generated Int to identify the unit
type: type of unit. inf/tank/recon
team: team the unit belongs to
positionX/positionY: xy coords of the unit
InfluenceRadius: the radius of influence that the unit holds/contests
soliderCnt: number of soldiers in the unit. this effects the size of the influence radius.
combatStrength: the combat strength modifier of the unit
morale: the morale modifier of the unit
supplies: the supplies that the unit has to engage in combat.

"""
mutable struct Unit

    name::String
    id::Int
    type::String
    team::String
    position::Point2f
    destination::Point2f
    angle::Number # in degrees
    destinationAngle::Number
    visionDistance::Number
    controlDistance::Number
    controlAngle::Number
    spacing::Number
    width::Number
    depth::Number
    staringSoliderCnt::Int # 0-99999
    soliderCnt::Int # 0-99999
    combatStrength::Number # 0,1,2
    morale::Number # 0,1,2
    supplies::Number
    speed::Number  # in m/5mins
    stealth::Number # modifier of unit not being spotted
    reconissance::Number # modifier of unit spotting other unitst
    tactic::String # how the unit behaves in combat.
end

"""
Constructor fucntion for the unit type. 
"""
function unit(
        name::String; 
        id::Int = rand(Int),
        type="debugInfantry", 
        team="teamDev", 
        position = Point2f(0,0),
        destination = missing,
        angle = 0,
        destinationAngle = missing,
        visionDistance = 2000,
        controlDistance = 300,
        controlAngle = 45,
        spacing = 10,
        depth = 200,
        staringSoliderCnt = 300,
        soliderCnt = 300,
        combatStrength = 1,
        morale = 1,
        supplies = 1000,
        speed = 250,
        stealth = 1,
        reconissance = 1,
        tactic = "CONTROL",
        )

        if ismissing(destination)
            destination = position
        end
        if ismissing(destinationAngle)
            destinationAngle = angle
            
        end

        width = soliderCnt/3 * spacing

        # construct the unit here
    u = Unit(
            name,
            id,
            type, 
            team, 
            position, 
            destination,
            angle,
            destinationAngle,
            visionDistance,
            controlDistance,
            controlAngle,
            spacing,
            width,            
            depth,
            staringSoliderCnt,
            soliderCnt,
            combatStrength,
            morale,
            supplies,
            speed,
            stealth,
            reconissance,
            tactic
            )

    return u
end


"""
function that pulls out the values of a unit.
    and throws them into a vector.
"""
function uVals(u::Unit)
    v = []
    for i in fieldnames(Unit)

        push!(v, getfield(u,i))
    end
    return v
end

# First up. Lets plot this bad boi

function get_rectangle_points(center, width, height, angle)

    angle = deg2rad(angle)
    # Center of the rectangle
    x_c, y_c = center
    
    # Half dimensions
    half_width = width / 2
    half_height = height / 2
    
    # Define the corners relative to the center (no rotation)
    corners = [
        [ half_width,  half_height],
        [-half_width,  half_height],
        [-half_width, -half_height],
        [ half_width, -half_height]
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
    # fullBox = Point2f.(vcat(translated_corners,translated_corners[1]))
    fullBox = Point2f.(translated_corners)

    lineSegs = collect(zip(fullBox[1:end-1], fullBox[2:end]))

    push!(lineSegs,(Point2f(translated_corners[1]),Point2f(translated_corners[3])))
    push!(lineSegs,(Point2f(translated_corners[2]),Point2f(translated_corners[4])))
    push!(lineSegs,(Point2f(translated_corners[1]),Point2f(translated_corners[4])))

    
    # return Point2f.(
    #         vcat(translated_corners, 
    #             [translated_corners[1]],
    #             [NaN, NaN],
    #             [translated_corners[3]],
    #             [translated_corners[1]],
    #             [NaN, NaN],
    #             [translated_corners[2]],
    #             [translated_corners[4]],
    #             [NaN, NaN]
    #             ))
    return lineSegs
end

function controlArc(center, width, height, angleD,controlR,controlAngle)
    
    # firstup we get the control rectange directly in front, and shunt it fowards.
    angle = deg2rad(angleD)
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

    leftP = translated_corners[1]
    rightP = translated_corners[2]
    # controlR = controlR
    num_points = 100
    startA = angle + deg2rad(90 - controlAngle)
    midA = angle + deg2rad(90)
    endA = angle + deg2rad(90 + controlAngle)

    lAngle = range(startA, midA, length=num_points)
    rAngle = range(midA, endA, length=num_points)

    lPoints = [leftP .+ controlR * Point2f0(cos(θ), sin(θ)) for θ in lAngle]
    rPoints = [rightP .+ controlR * Point2f0(cos(θ), sin(θ)) for θ in rAngle]

    arc_points = Point2f.(vcat(lPoints,rPoints))
    arcSegments = collect(zip(arc_points[1:end-1], arc_points[2:end]))

    # return Point2f.(arcSegments)
    return arcSegments

end

# points = [1, 2, 3, 4]
# segments = collect(zip(points[1:end-1], points[2:end]))

function plotUnit!(axis,unit::Unit, unitColor = :red)
    # get the boxes of the units.
    rectangle_points = get_rectangle_points(unit.position, unit.width, unit.depth, unit.angle)
    control_Arc = controlArc(unit.position, unit.width, unit.depth, unit.angle, unit.controlDistance, unit.controlAngle)

    linesegments!(axis,rectangle_points, color = unitColor)
    linesegments!(axis,control_Arc, color = (:blue,0.5))

end

# lets add some movement stuff to the unit. 

"""
# basic movement function that sets the position that the unit ends up at. 
works with either a point or x,y coords.
"""
function teleportUnit!(unit::Unit, p::Point2f)
    unit.position = p
    return unit
end
function teleportUnit!(unit::Unit, x::Number, y::Number)
    p = Point2f(x,y)
    teleportUnit!(unit,p)
    return unit
end


"""
This takes a unit and a point and sets the unit to move to that point.
if the unit is facing a different way, it will also update the destination angle.
"""
function setMoveOrder!(unit::Unit,position::Point2f; speed=missing)
    unit.destination = position
    if !ismissing(speed)
        unit.speed = speed
    end
    # get the angle between the two points
    v = [unit.destination[1] - unit.position[1], unit.destination[2] - unit.position[2]]
    unit.destinationAngle = atan(v[2],v[1]) * 180 / pi

    return unit
end
function setMoveOrder!(unit::Unit, x::Number, y::Number; speed=missing)
    p = Point2f(x,y)
    setMoveOrder!(unit,p,speed=speed)
    return 
end
function setMoveOrder!(unit::Observable, x::Number, y::Number; speed=missing)
    u = to_value(unit)
    p = Point2f(x,y)
    setMoveOrder!(u,p,speed=speed)
    unit[] = u
    return 
end

# and here is a function to execute these move orders

"""
This moves the unit towards the destination by the amount set in unit.speed. 
"""
function MoveToPoint!(unit::Unit)

    if ismissing(unit.destination) 
        return
    end

    speed = unit.speed

    # get the distance between the two points
    distance = sqrt((unit.position[1] - unit.destination[1])^2 + (unit.position[2] - unit.destination[2])^2)
    if distance <  speed
        teleportUnit!(unit, unit.destination)
        return
    else

        # move it towards the point. first get the unit vector from the unit to the desired point
        v = [unit.destination[1] - unit.position[1], unit.destination[2] - unit.position[2]]
        vNorm = v / norm(v)
        # move the unit in that direction
        teleportUnit!(unit, unit.position[1] + vNorm[1] * speed, unit.position[2] + vNorm[2] * speed)
        ### Will need to add in supply consuption
        # and remove supplies equal to 1 + 1/10th of the distance moved.
        # unit.supplies = max(unit.supplies - 1 - distance/10,0)
    end
end
function MoveToPoint!(unit::Observable)
    u = to_value(unit)
    MoveToPoint!(u)
    unit[] = u
end

function rotateUnit!(unit::Unit)

    if ismissing(unit.destinationAngle)
        return unit
    end
    
    angle = unit.angle
    destinationAngle = unit.destinationAngle
    
    # I want to get the max rotational speed. Max speed at end depends.
    # V = r * ω  => ω = V/r
    r = unit.width / 2
    ω = unit.speed / r

    if abs(destinationAngle - angle) < ω
        unit.angle = destinationAngle
    else
        if destinationAngle > angle
            unit.angle = angle + ω
        else
            unit.angle = angle - ω
        end
    end

    return unit
end


"""
Utility function for pulling out the ith unit from a list of units.
"""
function getUnit(activeUnits,i)
    return activeUnits[i]
end
"""
Utility function for putting a unit back into a list of units at point n
    """
function putUnit(activeUnits,i,u)
    activeUnits[i] = u
    return activeUnits
end


u1 = unit("unit1", position = Point2f(5000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)
f = Figure()
ax = Axis(f[1, 1], aspect  =DataAspect(), limits = ((0,10000),(0,10000)))
plotUnit!(ax,u1)
f