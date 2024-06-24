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
    vision::Number
    InfluenceRadius::Number # limited by density.
    bombardmentRadius::Union{Missing, Number}
    staringSoliderCnt::Int # 0-99999
    soliderCnt::Int # 0-99999
    minDensity::Int # 0,1,2
    combatStrength::Number # 0,1,2
    morale::Number # 0,1,2
    supplies::Number
    pctInflicted::Number
    suppliesConsumed::Number
    speed::Number
    maxSpeed::Number
    isEngaged::Bool

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
        vision = 2,
        InfluenceRadius=10, 
        bombardmentRadius=0,
        staringSoliderCnt=100,
        soliderCnt=100,
        minDensity = 4,
        combatStrength=5, 
        morale=1,
        supplies = 1200,
        pctInflicted = 0,
        suppliesConsumed = 0,
        speed = 6,
        maxSpeed = 5,
        isEngaged = false
        )

        if ismissing(destination)
            destination = position
        end

        # construct the unit here
    u = Unit(
            name,
            id,
            type, 
            team, 
            position, 
            destination,
            vision, 
            InfluenceRadius,
            bombardmentRadius, 
            staringSoliderCnt, 
            soliderCnt,
            minDensity,
            combatStrength, 
            morale, 
            supplies, 
            pctInflicted, 
            suppliesConsumed, 
            speed, 
            maxSpeed, 
            isEngaged
            )
    # ensure that the unit meets required constrants,
    changeInfluence!(u, InfluenceRadius)

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
getPointsFromMap(1,1,0)
getPointsFromMap(1,1,1)
getPointsFromMap(1.5,1,0)
# getPointsFromMap(10,10,1)

"""
    getInfluencePoints(unit::Unit,influence = missing)
    This returns a list of points that are within or on a circle of radius unit.InfluenceRadius centered at unit.position.
    These points must be inside the battlemap, which by default is 1000x1000
    you can check the influence of a unit by changing the influence parameter.

    Points are returned as CartesianIndex{2}[] so that they can be easily applied to the BattleMap.points array.
"""
function getInfluencePoints(unit::Unit,influence = -1.0)
    if influence == -1.0
        influence = unit.InfluenceRadius
    end
    getPointsFromMap(unit.position[1],unit.position[2],influence)
end

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

"""
This changes the influence radius for a unit. Depending on the unit there are min and max densities.
    for debugInfantry these are 1-100 soldiers/Area
"""
function changeInfluence!(unit::Unit, desiredInfluence::Number)

    # get the current unit count and calc min/max influence
    println("Unit: ", unit.name, " has ", unit.soliderCnt, " soldiers.")
    minInfluence = sqrt(unit.soliderCnt/100*π)
    maxInfluence = sqrt(unit.soliderCnt/1*π)


    if desiredInfluence >= minInfluence && desiredInfluence <= maxInfluence 
        unit.InfluenceRadius = desiredInfluence
    else
        if desiredInfluence < minInfluence
            println("Desired influence is too small. Setting to min influence based on density 100.")
            unit.InfluenceRadius = minInfluence

        elseif desiredInfluence > maxInfluence
            println("Desired influence is too large. Setting to max influence based on density 1.")
            unit.InfluenceRadius = maxInfluence
        end
    end

    return unit
end
# Point2f(0,0)

function changeInfluence2!(u::Unit, desiredInfluence::Number)

    # get the current max number of points that the unit can influence.
    maxPoints = max(u.soliderCnt / u.minDensity,1)
    desiredInfluencePoints = getInfluencePoints(u,desiredInfluence)
    
    desiredInfluencePoints = getInfluencePoints(u,desiredInfluence)
    if length(desiredInfluencePoints) < maxPoints
        u.InfluenceRadius = di
    else
        # println("Desired influence is too large.")
    # Else we step down until we find a radius that fits.
    # In the case of a tie at influence 0 and pos(0.5),  rounding sorts it out
        for i in di:-1:0
            desiredInfluencePoints = getInfluencePoints(u,i)

            # println("Checking influence at ",i," with ",length(desiredInfluencePoints)," points.")

            if length(desiredInfluencePoints) < maxPoints
                println("Desired influence is too large, Setting influence to ",i)
                # u.InfluenceRadius = i
                break
            end
        end
    end
    return u
end

# u = unit("hi",InfluenceRadius = 10, soliderCnt=1000, position = Point2f(100,100))
# changeInfluence2!(u,10)


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


Along with points, we also see 