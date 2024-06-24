using Random
using GLMakie: Point2f
import LinearAlgebra: norm
import Base: show

# Maps in tactique are made up of points. 
# Each point is a 100m x 100m square, and generally the battlemap is 100km x 100km.
# this gives us 1000 x 1000 points. 

# each point has attributes. The most important one is cover, as this determines
    # The combat strength of a unit.
    # The ability to be seen by other units.
    # The ability to detect other units.
    # the ability to ambush other units.

# as well as traps, previous unit locations, etc.
# each point can have multiple attributes.

mutable struct MapPoint
    cover::String
    attributes::Dict{String,String}
    # changes::Array[] # this is a list of changes that have happened to this point
end

function mappPoint(;c = "Open",d = Dict([("terrain","grass")]))
    return MapPoint(c,d)
end

# the map is a collection of points, as well as containing info about the state of the game. (this the best place?)
mutable struct BattleMap
    runTime::Int # in s
    size::Tuple{Int64, Int64} #Map dimensions in xy. Each point is 100m 
    points::Array{MapPoint,2}
end

function battleMap(x,y)

    p = Array{MapPoint,2}(undef,x,y)
    for i in 1:x
        for j in 1:y
            p[i,j] = mappPoint()
        end
    end
    # points = [mappPoint() for i in 1:size[1], j in 1:size[2]]
    return BattleMap(0,(x,y),p)
end

# f = battleMap(1000,1000)
# f.points[1,1].cover 
# f.runTime
# f.size


# to see what areas a unit can influence, we can just draw a circle around its location.
# Then we get all the points, and these are the points that the unit will influence.
# Unit locations can be anywhere, but they influence points, even if they are not on one (???)

# Q
# if there is a circle w radius 10 at 100,100, how many discrete points where (x,y) is Int, are inside it?

"""
    getPointsFromMap(x::Number,y::Number,r::Number; _battleMap::BattleMap = BATTLEMAP)

    This returns a list of points that are within or on a circle of radius r centered at x,y.
    These points must be inside the battlemap, which by default is 1000x1000
    BattleMap must be defined in global variables.
    ie getPointsFromMap(1,1,1) returns [(1,1),(1,2),(2,1)]

    Points are returned as CartesianIndex{2}[] so that they can be easily applied to the BattleMap.points array.
"""
function getPointsFromMap(x::Number,y::Number,r::Number; _battleMap::BattleMap = BATTLEMAP)

    # try @isdefined _battleMap
    # catch e throw(ArgumentError("No BattleMap defined in global variables. \n Please define a BattleMap named BATTLEMAP."))
    # end

    points = CartesianIndex{2}[]

    # This condition may not be needed, but there to be safe :)
    if x < 0 || y < 0 || x > _battleMap.size[1] || y > _battleMap.size[2]
        throw(ArgumentError("x and y must be within the bounds of the BattleMap."))
        return
    end

    # the radius may not be inside the battlemap though!
    for i in -r:r
        for j in -r:r
            # check the constraints of the points to be within the map.
            if i^2 + j^2 <= r^2 && i+x >= 1 && i+x <= _battleMap.size[1] && j+y >= 1 &&  j+y <= _battleMap.size[2]
                push!(points,CartesianIndex(Int(round(i+x)),Int(round(j+y))))
            end
        end
    end
    return points;
end
# BATTLEMAP = battleMap(1000,1000)
# getPointsFromMap(1,1,1)
# getPointsFromMap(10,10,1)



"""
    getInfluencePoints(unit::Unit)
    This returns a list of points that are within or on a circle of radius unit.InfluenceRadius centered at unit.position.
    These points must be inside the battlemap, which by default is 1000x1000

    Points are returned as CartesianIndex{2}[] so that they can be easily applied to the BattleMap.points array.
"""
getInfluencePoints(unit::Unit) = getPointsFromMap(unit.position[1],unit.position[2],unit.InfluenceRadius)

"""
    getVisionPoints(unit::Unit)
    This returns a list of points that are within or on a circle of radius unit.InfluenceRadius+unit.vision centered at unit.position.
    These points must be inside the battlemap, which by default is 1000x1000

    Points are returned as CartesianIndex{2}[] so that they can be easily applied to the BattleMap.points array.
"""
getVisionPoints(unit::Unit) = getPointsFromMap(unit.position[1],unit.position[2],unit.vision + unit.InfluenceRadius)

# u = unit("hi",position = Point2f(1,1),InfluenceRadius = 10,vision = 5)
# influencePoints = getInfluencePoints(u)
# visionPoints = getVisionPoints(u)

# # to get vision only points, we can just subtract the influence points from the vision points.
# # this will give us the points that are only in vision, but not in influence.
# visionOnlyPoints = setdiff(visionPoints,influencePoints)



