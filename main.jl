using Random
using GLMakie
import LinearAlgebra: norm
import Base: show

GLMakie.activate!(inline=true)
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
    destination::Union{Missing, Point2f}
    InfluenceRadius::Number # limited to density.
    bombardmentRadius::Union{Missing, Number}
    staringSoliderCnt::Int # 0-99999
    soliderCnt::Int # 0-99999
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
function that pulls out the values of a unit.
    and throws them into a vector. Can be used to comapre the equality of units.
"""
function uVals(u::Unit)

    v = []
    for i in fieldnames(Unit)

        push!(v, getfield(u,i))
        
    end
    return v
end
    

"""
This changes the influence radius for a unit. Depending on the unit there are min and max densities.
    for debugInfantry these are 1-100 soldiers/Area
"""
function changeInfluence!(unit::Unit, desiredInfluence::Number)

    # get the current unit count and calc min/max influence
    println("Unit: ", unit.name, " has ", unit.soliderCnt, " soldiers.")
    minInfluence = sqrt(unit.soliderCnt/100*π)
    maxInfluence = sqrt(unit.soliderCnt/1*π)

    # println("minInfluence: ", minInfluence)
    # println("maxInfluence: ", maxInfluence)

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
        InfluenceRadius=10, 
        bombardmentRadius=0,
        staringSoliderCnt=1000,
        soliderCnt=1000, 
        combatStrength=5, 
        morale=1,
        supplies = 1200,
        pctInflicted = 0,
        suppliesConsumed = 0,
        speed = 5,
        maxSpeed = 5,
        isEngaged = false

        )
    u = Unit(name,id, type, team, position, destination, InfluenceRadius,bombardmentRadius, staringSoliderCnt, soliderCnt, combatStrength, morale, supplies, pctInflicted, suppliesConsumed, speed, maxSpeed, isEngaged)
    # ensure that the unit meets required constrants
    changeInfluence!(u, InfluenceRadius)

    return u
end


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




# I want to see if unit1's radius overlaps with unit2
function checkOverlap(unit1::Unit, unit2::Unit;print=false)

    d = sqrt((unit1.position[1] - unit2.position[1])^2 + (unit1.position[2] - unit2.position[2])^2)
    r₁ = unit1.InfluenceRadius
    r₂ = unit2.InfluenceRadius

    # println("d:", d)
    # println("r₁:", r₁)
    # println("r₂:", r₂)

    if d == 0 && r₁ == r₂ 
        if print
            println("Units ", unit1.name, " and ", unit2.name, " exactly overlap")
        end
        return "overlap"
    elseif d <= r₁ - r₂ 
        if print
            println("Units ", unit2.name, " is inside ", unit1.name,)
        end
        return "swallow"
    elseif d <= r₂ - r₁ 
        if print
            println("Units ", unit1.name, " is inside ", unit2.name,)
        end
        return "swallowed"
    elseif d < r₁ + r₂
        if print
            println("Units ", unit1.name, " and ", unit2.name, " overlap")
        end
        return "overlap"
    else 
        if print
            println("Units ", unit1.name, " and ", unit2.name, " do not overlap")
        end
        return "no overlap"
    end

end

# u1 = unit("u1")
# u2 = unit("u2")
# checkOverlap(u1,u2,print=true)



"""
finds the two sets of points where two units sphere of influence intersect.
"""
function getIntersectionPoints(unit1::Unit, unit2::Unit)

    if checkOverlap(unit1, unit2) != "overlap"
        # println("Units ", unit1.name, " and ", unit1.name, " do not overlap.")
        return 
    else

        r₁ = unit1.InfluenceRadius
        r₂ = unit2.InfluenceRadius
        x₁ = unit1.position[1]
        y₁ = unit1.position[2]

        x₂ = unit2.position[1]
        y₂ = unit2.position[2]

        R = sqrt((x₂ - x₁)^2 + (y₂ - y₁)^2)

        println("v1 = ",(r₁^2 + r₂^2)/R^2)

        # https://math.stackexchange.com/questions/256100/how-can-i-find-the-points-at-which-two-circles-intersect
        x1 = (1/2)*(x₁+x₂) + ((r₁^2 - r₂^2)/(2*R^2))*(x₁+x₂) + 1/2*sqrt(2((r₁^2 + r₂^2)/R^2) - (r₁^2 - r₂^2)^2/R^4 - 1)*(x₁+x₂)
        x2 = (1/2)*(x₁+x₂) + ((r₁^2 - r₂^2)/(2*R^2))*(x₁+x₂) - 1/2*sqrt(2((r₁^2 + r₂^2)/R^2) - (r₁^2 - r₂^2)^2/R^4 - 1)*(x₁+x₂)
        y1 = (1/2)*(y₁+y₂) + ((r₁^2 - r₂^2)/(2*R^2))*(y₁+y₂) + 1/2*sqrt(2((r₁^2 + r₂^2)/R^2) - (r₁^2 - r₂^2)^2/R^4 - 1)*(y₁+y₂)
        y2 = (1/2)*(y₁+y₂) + ((r₁^2 - r₂^2)/(2*R^2))*(y₁+y₂) - 1/2*sqrt(2((r₁^2 + r₂^2)/R^2) - (r₁^2 - r₂^2)^2/R^4 - 1)*(y₁+y₂)

        return (x1, y1), (x2, y2)
    end
end



# I also want to get the area of overlap if they do overlap
# https://en.wikipedia.org/wiki/Circular_segment
function getOverlapArea(unit1::Unit, unit2::Unit)

    # check that they do overlap else complex lol
    if checkOverlap(unit1, unit2) ∉ ["overlap","swallow","swallowed"]
        # println("Units ", unit1.name, " and ", unit1.name, " do not overlap.")
        return 
    elseif checkOverlap(unit1, unit2) in ["swallow","swallowed"]
        return min(unit1.InfluenceRadius,unit2.InfluenceRadius)^2*π
    else

    r₁ = unit1.InfluenceRadius
    r₂ = unit2.InfluenceRadius
    x₁ = unit1.position[1]
    y₁ = unit1.position[2]
    x₂ = unit2.position[1]
    y₂ = unit2.position[2]

    d = sqrt((x₂ - x₁)^2 + (y₂ - y₁)^2)

    d₁ = (r₁^2 - r₂^2 + d^2)/(2*d)
    d₂ = d - d₁

    A₁ = r₁^2*acos(d₁/r₁) - d₁*sqrt(r₁^2 - d₁^2)
    A₂ = r₂^2*acos(d₂/r₂) - d₂*sqrt(r₂^2 - d₂^2)

    A = A₁ + A₂

    return A
    end

end

# ok, so I have the ways these lads overlap

# ok, so for the combat stage:

# 1) Find the areas that are overlapping 
# 2) the realitive density comparison. 
# 3) from the density, combat strength and morale, Calculate the losses suffered by each unit.
# 4) Once the losses have been calculated for all units, apply the losses to all units.

# 5) If a unit has lost 75% its soldiers, remove it from the game.
# 6) if a unit touches the center of another unit, it is also removed from the game??



# Will start with 3

# combat has several outcomes
    # begins with an overlap which creates a combat zone.
    # the combat zone has a density of soldiers which are compared w combat strength and morale. 
    # This translates into losses. Losses mean that the unit has less soldiers, which translates to less influence radius.      

    # we calculate the losses for each unit. the first unit being the one that is affected
rand(.8:.0001:1.2)


(2/(1+exp(-1*(100 -0))))

function calculateCombat!(unit1::Unit, unit2::Unit)



    # get the area of the compat zone. 
    A = getOverlapArea(unit1, unit2)

    if isnothing(A)
        return unit1
    else

    # get unit densit+ies 
    d₁ = unit1.soliderCnt/A
    d₂ = unit2.soliderCnt/A

    # compare the forces.
    # I pulled this formula out of my ass. I want ongoing combats to be rough, and I want combat strength to really matter
    logistic(x) = 5/(1+exp(-0.2(x  -0))) 

 

    pctInflicted = 
            logistic(( unit2.combatStrength - unit1.combatStrength) ) *
            unit1.morale * min(unit1.supplies/unit1.soliderCnt,1.2) *
            (1/(1+exp(-1*(d₂-d₁ -0)))+0.5) * 
            rand(.8:.0001:1.2)



    # pctSuppliesDestroyed = 0 # I want to add this in to make SpecOps a thing. 
    # suppliesGained = 0
    # If there is a high density diff, the smaller diff can make their supplies go further per casualty.
    suppliesConsumed = 1 + pctInflicted * d₁/ (d₁ + d₂)

    unit1.pctInflicted = pctInflicted
    unit1.suppliesConsumed = suppliesConsumed

    # println("d₁ - d₂ = ",d₂-d₁)
    # println("logistic(d₁ - d₂) = ",(2/(1+exp(-1*(d₂-d₁ -0)))))
    # println("pctInflicted = ",pctInflicted )

    return unit1
    end

end


function applyCombat!(unit::Unit)

    # Apply the combat strengtd changes
    CS = unit.soliderCnt * (1-unit.pctInflicted/100)
    unit.soliderCnt = max(round(CS),0)
    unit.pctInflicted = 0

    # Apply the supplies changes
    supplies = unit.supplies - unit.suppliesConsumed
    unit.supplies = max(supplies,0)
    unit.suppliesConsumed = 0

    # and check to see if the engagement radius has changed.
    changeInfluence!(unit,unit.InfluenceRadius)

    return unit

end


# basic func to plot units engaging
function plotUnits(u1::Unit, u2::Unit, i=0)

    f = Figure()
    Axis(f[1, 1], limits = ((-100, 100), (-100,100)))

    arc!(Point2f(u1.position[1], u1.position[2]), u1.InfluenceRadius, -π, π)
    arc!(Point2f(u2.position[1], u2.position[2]), u2.InfluenceRadius, -π, π)

    Label(f[0, 0], "rnd $i")
    f

end


# I want to be able to kill units if they have lost 75% of their soldiers
# or if morale is too low. TBD
# or if they are out of supplies and are being engaged.
# basically they just disappear if killed

function killCheck(u::Unit)
    if u.soliderCnt < 0.25*u.staringSoliderCnt
        println("Unit ", u.name, " has been killed.")
        return true
    else
        return false
    end
end
# j = unit("u1",combatStrength = 10,staringSoliderCnt= 1000, soliderCnt = 100, InfluenceRadius = 20)

"""
This takes a unit and a point and moves it to that point based on the units speed.
"""
function  setMoveOrder!(unit::Unit,position::Point2f; speed=missing)
    
    unit.destination = position
    if !ismissing(speed)
        unit.speed = speed
    end

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


function MoveToPoint!(unit::Unit)

    if ismissing(unit.destination)
        return
    end

    speed = unit.speed

    # first, lets check if the unit is engaged.
    if unit.isEngaged
        speed = speed/3
    end

    # get the distance between the two points
    distance = sqrt((unit.position[1] - unit.destination[1])^2 + (unit.position[2] - unit.destination[2])^2)
    if distance <  unit.speed
        teleportUnit!(unit, unit.destination)
        return
    else

        # move it towards the point. first get the unit vector from the unit to the desired point
        v = [unit.destination[1] - unit.position[1], unit.destination[2] - unit.position[2]]
        vNorm = v / norm(v)
        # move the unit in that direction
        teleportUnit!(unit, unit.position[1] + vNorm[1] * unit.speed, unit.position[2] + vNorm[2] * unit.speed)
        # and remove supplies equal to 1 + 1/10th of the distance moved.
        unit.supplies = max(unit.supplies - 1 - distance/10,0)
    end
end

function showFields(u;fields = [])
    duds = []
    _type = typeof(u)

    if isempty(fields)
        fields = fieldnames(_type)
    else
        duds = setdiff(fields,fieldnames(_type))
        fields = intersect(fields,fieldnames(_type))
    end

    for i in fields
        println(i, ": ", getfield(u,i))


        if length(duds) > 0
            println("The following fields are not valid fields for the $_type type: ",duds)
            println("Valid fields are: ",fieldnames(_type))
        end
    end
    return
end

function falseIfMissing(x)
    if ismissing(x)
        return false
    else
        return true
    end
end
# u1 = unit("Unit1")
# showFields(u1,fields=[:name,])

    # function to pull out the first tuple, or position data. 
function getNval(x,n=1)
    return Point2f(x[n])
end


# Ok, so here we have some visualisation utilities:
function createArrow(x1,y1,x2,y2;barWidth=nothing,noseLength=nothing,arrowWidth=nothing)

    VectorLen = sqrt((x1-x2)^2 + (y1-y2)^2)
    UnitVector = ((x2-x1)/VectorLen , (y2-y1)/VectorLen)

    if isnothing(barWidth)
        barWidth = 1
    end

    if isnothing(noseLength)
        noseLength = 1
    end

    if isnothing(arrowWidth)
        arrowWidth = 2
    end

    poly = []

    push!(poly,Point2f(x2,y2))

    # Get the nose length, back from the tip, to find this midpoint
    ArrowMiddlePoint = (x2 - noseLength * UnitVector[1] , y2 - noseLength * UnitVector[2] ) 
    
    # println("Arrow from ($x1,$y1), ($x2,$y2)")
    # println("VectorLen = $VectorLen")
    # println("UnitVector = $UnitVector")
    # println("ArrowMiddlePoint = $ArrowMiddlePoint")

    perp = (-UnitVector[2],UnitVector[1])

    # get the arrowhead
    push!(poly, Point2f(ArrowMiddlePoint[1] - arrowWidth/2*perp[1], ArrowMiddlePoint[2] - arrowWidth/2*perp[2]))
    push!(poly, Point2f(ArrowMiddlePoint[1] - barWidth/2*perp[1], ArrowMiddlePoint[2] - barWidth/2*perp[2]))

    # get the tail of the arrowhead bar
    push!(poly, Point2f(x1 - barWidth/2*perp[1], y1 - barWidth/2*perp[2]))
    push!(poly, Point2f(x1 + barWidth/2*perp[1], y1 + barWidth/2*perp[2]))

    # and the other side of the arrowhead
    push!(poly, Point2f(ArrowMiddlePoint[1] + (barWidth/2)*perp[1], ArrowMiddlePoint[2] + (barWidth/2)*perp[2]))
    push!(poly, Point2f(ArrowMiddlePoint[1] + (arrowWidth/2)*perp[1], ArrowMiddlePoint[2] + (arrowWidth/2)*perp[2]))

    # and finish it off at the nose
    push!(poly,Point2f(x2,y2))

    # and make it point
    return Point2f.(poly)

end

function plotMap(activeUnits)

    f = Figure()
    Axis(f[1, 1], limits = ((-100, 100), (-100,100)))

    teamMap = Dict("team1" => "red", "team2" => "blue", "teamDev" => "pink")

    # plot the radias of influence for each unit 
    for o in to_value(activeUnits)
        i = to_value(o)
        arc!(i.position, i.InfluenceRadius, -π, π, color = teamMap[i.team], alpha = 0.5)
    end

    # plot the positions of the units 
    for o in activeUnits
        i = to_value(o)
        text!(
            i.position,
            text = i.name,
            color = teamMap[i.team],
            align = (:center, :center),
        )
    end

    # and plot the movement arrows
    for o in activeUnits
        i = to_value(o)
        # println(i.destination)
        if !ismissing(i.destination) || falseIfMissing(i.destination != i.position)
            # lines!(
            #     [i.position,
            #     i.destination],
            #     color = teamMap[i.team],
            # )
            # Add an arrowhead at the 'to' point
            poly!(createArrow(i.position[1] , i.position[2], i.destination[1],i.destination[2]; barWidth = 0.4,arrowWidth = 2, noseLength = 4  ), color = teamMap[i.team])
            # barWidth=nothing,noseLength=nothing,arrowWidth=nothing
        end
    end
    # string(i.name,"\n",i.type,"\n",i.team)
f
end



# add interactive map

function plotInteractiveMap(activeUnits)
    global idx
    idx = Observable(0)
    teamMap = Dict("team1" => "red", "team2" => "blue", "teamDev" => "pink")
    # pull out the position info
    
    positions = []

    for i in activeUnits
        if ismissing(i.destination)
            push!(positions, (i.position,i.position))
        else 
            push!(positions, (i.position,i.destination))
        end
    end 
    
    # Make these observable
    positions = Observable(positions)

    getNval.(to_value(positions))

    teamColours = [teamMap[i.team] for i in activeUnits]
    teamUnitNames = [i.name for i in activeUnits]
    InfluenceRadius = [i.InfluenceRadius for i in activeUnits]
    pos = [i.position for i in activeUnits]


    # ok, so do the plotting things.
    s = Scene(camera = campixel!, size = (800, 800))

    linesegments!(s,positions,  color = teamColours)
    scatter!(s,getNval.(to_value(positions)), strokewidth = 3,  color = teamColours)

    text!(s,getNval.(to_value(positions)), text = teamUnitNames, color = teamColours, align = (:center, :top))

    # and add area of influence
    # arc!(i.position, i.InfluenceRadius, -π, π, color = teamMap[i.team], alpha = 0.5)
    for i in activeUnits
        arc!(s,i.position, i.InfluenceRadius, -π, π, color = teamMap[i.team], alpha = 0.5)
    end

    # init the observable


    on(events(s).mousebutton, priority = 2) do event

        
        if event.button == Mouse.left && event.action == Mouse.press

            plt, i = GLMakie.pick(s,10)
            println(plt)
            if plt isa Scatter{Tuple{Vector{Point{2, Float32}}}}
                # println("changing idx: ",i)
                idx[] = i
            end

            # println("idx is now: ",idx[])

        end

        # println("positions: ",positions)

        # if event.button == Mouse.right && event.action == Mouse.press && idx[] != 0
        on(events(s).mouseposition, priority = 2) do mp
            mb = events(s).mousebutton[]
            if mb.button == Mouse.right && mb.action == Mouse.press && idx[] != 0
                # println("destination is now: ",mp)
                # println(typeof(mp))
                v = to_value(positions) 

                # v[idx[]][2] = Point2f(mp)
                v[idx[]] = (v[idx[]][1],Point2f(mp))
                positions[] = v
                # println("positions: ",positions)
                notify(positions)
                # println("positions: ",positions)

            end
        end

    end

    display(s)
    return positions
end