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
    positionX::Number
    positionY::Number
    destinationX::Union{Missing, Number}
    destinationY::Union{Missing, Number}
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


"""
Constructor fucntion for the unit type. 
"""
function unit(
        name::String; 
        id::Int = rand(Int),
        type="debugInfantry", 
        team="teamDev", 
        positionX=0, 
        positionY=0,
        destinationX=missing,
        destinationY=missing,
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
    u = Unit(name,id, type, team, positionX, positionY, destinationX,destinationY, InfluenceRadius,bombardmentRadius, staringSoliderCnt, soliderCnt, combatStrength, morale, supplies, pctInflicted, suppliesConsumed, speed, maxSpeed, isEngaged)
    # ensure that the unit meets required constrants
    changeInfluence!(u, InfluenceRadius)

    return u
end


"""
# basic movement function that sets the position that the unit ends up at. 
"""
function teleportUnit!(unit::Unit, x::Number, y::Number)
    unit.positionX = x
    unit.positionY = y
    return unit
end



# I want to see if unit1's radius overlaps with unit2
function checkOverlap(unit1::Unit, unit2::Unit,print=false)
    d = sqrt((unit1.positionX - unit2.positionX)^2 + (unit1.positionY - unit2.positionY)^2)
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
        x₁ = unit1.positionX
        y₁ = unit1.positionY

        x₂ = unit2.positionX
        y₂ = unit2.positionY

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
    x₁ = unit1.positionX
    y₁ = unit1.positionY
    x₂ = unit2.positionX
    y₂ = unit2.positionY

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

    arc!(Point2f(u1.positionX, u1.positionY), u1.InfluenceRadius, -π, π)
    arc!(Point2f(u2.positionX, u2.positionY), u2.InfluenceRadius, -π, π)

    Label(f[0, 0], "rnd $i")
    f

end

function plotMap(activeUnits)

    f = Figure()
    Axis(f[1, 1], limits = ((-100, 100), (-100,100)))

    teamMap = Dict("team1" => "red", "team2" => "blue")

    # plot the radias of influence for each unit 
    for i in activeUnits
        arc!(Point2f(i.positionX, i.positionY), i.InfluenceRadius, -π, π, color = teamMap[i.team], alpha = 0.5)
    end

    # plot the positions of the units 
    for i in activeUnits
        text!(
            i.positionX, i.positionY,
            text = i.name,
            color = teamMap[i.team],
            align = (:center, :center),
        )
    end
    # string(i.name,"\n",i.type,"\n",i.team)
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
function setMoveOrder!(unit::Unit, x::Number, y::Number, speed=missing)

    unit.destinationX = x
    unit.destinationY = y
    if !ismissing(speed)
        unit.speed = speed
    end

    return unit
end
function MoveToPoint!(unit::Unit)

    speed = unit.speed

    # first, lets check if the unit is engaged.
    if unit.isEngaged
        speed = speed/3
    end

    # get the distance between the two points
    distance = sqrt((unit.positionX - unit.destinationX)^2 + (unit.positionY - unit.destinationY)^2)
    if distance <  unit.speed
        teleportUnit!(unit, unit.destinationX, unit.destinationY)
        return
    else

        # move it towards the point. first get the unit vector from the unit to the desired point
        v = [unit.destinationX - unit.positionX, unit.destinationY - unit.positionY]
        vNorm = v / norm(v)
        # move the unit in that direction
        teleportUnit!(unit, unit.positionX + vNorm[1] * unit.speed, unit.positionY + vNorm[2] * unit.speed)
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
# u1 = unit("Unit1")
# showFields(u1,fields=[:name,])

