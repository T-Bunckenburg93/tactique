using Random
using GLMakie
using Distributions
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
    position::Point2f  # should be the same as the cartesian index of the point.
    cover::String
    attributes::Dict{String,String}
    # changes::Array[] # this is a list of changes that have happened to this point
end

function mappPoint(;position = Point2f(1,1),cover = "Open",d = Dict([("terrain","grass")]))
    return MapPoint(position,cover,d)
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
            p[i,j] = mappPoint(position = Point2f(i,j))
        end
    end
    # points = [mappPoint() for i in 1:size[1], j in 1:size[2]]
    return BattleMap(0,(x,y),p)
end

BATTLEMAP = battleMap(1000,1000)
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
    # bombardmentRadius::Union{Missing, Number}
    staringSoliderCnt::Int # 0-99999
    soliderCnt::Int # 0-99999
    minDensity::Int # 0,1,2
    combatStrength::Number # 0,1,2
    morale::Number # 0,1,2
    supplies::Number
    speed::Number  # in chunks/hour
    stealth::Number # modifier of unit not being spotted
    reconissance::Number # modifier of unit spotting other units
    doctrine::String # how the unit behaves in combat.


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
        InfluenceRadius=4, 
        # bombardmentRadius=0,
        staringSoliderCnt=100,
        soliderCnt=120,
        minDensity = 4,
        combatStrength=5, 
        morale=1,
        supplies = 1200,
        speed = 6,
        stealth=2,
        reconissance=4,
        doctrine = "CONTROL",
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
            # bombardmentRadius, 
            staringSoliderCnt, 
            soliderCnt,
            minDensity,
            combatStrength, 
            morale, 
            supplies, 
            speed,
            stealth,
            reconissance,
            doctrine,
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
    for i in -r + x:r + x
        for j in -r + y:r + y
            # check the constraints of the points to be within the map.
            if (i-x)^2 + (j-y)^2 <= r^2 && i+x >= 1 && i+x <= _battleMap.size[1] && j+y >= 1 &&  j+y <= _battleMap.size[2]
                push!(points,CartesianIndex(Int(round(i)),Int(round(j))))
            end
        end
    end
    return points;
end

floor(-1.5)
# BATTLEMAP = battleMap(1000,1000)
getPointsFromMap(1,1,01)
# getPointsFromMap(1,1,1)
getPointsFromMap(1.5,1,1)
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


function changeInfluence!(u::Unit, desiredInfluence::Number)

    # get the current max number of points that the unit can influence.
    maxPoints = max(u.soliderCnt / u.minDensity,1)
    desiredInfluencePoints = getInfluencePoints(u,desiredInfluence)
    
    desiredInfluencePoints = getInfluencePoints(u,desiredInfluence)
    if length(desiredInfluencePoints) < maxPoints
        u.InfluenceRadius = desiredInfluence
    else
        # println("Desired influence is too large.")
    # Else we step down until we find a radius that fits.
    # In the case of a tie at influence 0 and pos(0.5),  rounding sorts it out
        for i in desiredInfluence:-1:0
            desiredInfluencePoints = getInfluencePoints(u,i)

            # println("Checking influence at ",i," with ",length(desiredInfluencePoints)," points.")

            if length(desiredInfluencePoints) < maxPoints
                println("Desired influence is too large, Setting influence to ",i)
                u.InfluenceRadius = i
                break
            end
        end
    end
    return u
end

# u = unit("hi",InfluenceRadius = 10, soliderCnt=1000, position = Point2f(100,100))
# changeInfluence2!(u,10)



# I want to see if unit1's radius overlaps with unit2
function checkOverlap(unit1::Unit, unit2::Unit;print=false)

    if unit1.team == unit2.team
        return false
    end

    d = sqrt((unit1.position[1] - unit2.position[1])^2 + (unit1.position[2] - unit2.position[2])^2)
    r₁ = unit1.InfluenceRadius
    r₂ = unit2.InfluenceRadius

    if d == 0 && r₁ == r₂ 
        if print
            println("Units ", unit1.name, " and ", unit2.name, " exactly overlap")
        end
        return true
    elseif d <= r₁ - r₂ 
        if print
            println("Units ", unit2.name, " is inside ", unit1.name,)
        end
        return true
    elseif d <= r₂ - r₁ 
        if print
            println("Units ", unit1.name, " is inside ", unit2.name,)
        end
        return true
    elseif d < r₁ + r₂
        if print
            println("Units ", unit1.name, " and ", unit2.name, " overlap")
        end
        return true
    else 
        if print
            println("Units ", unit1.name, " and ", unit2.name, " do not overlap")
        end
        return false
    end
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


"""
This takes a unit and a point and sets the unit to move to that point.
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


# movement works as so.
# each unit has a speed/hour and destination.

# each tick, the unit moves towards the destination at speed/hour.
# it then looks for over lap of veiw and influence to see if units notice each other. - if so, this generates an event.
# then it looks for overlap of influence to see if units are occupying the same points. This compares recon.
# if one notices the other, depending on the doctrine, they may engage or they may not.
    # if they engage, a combat resolution occurs, as well as an event.
# if they don't engage, nothing happens, but they may get detected next round. - Chance for hidden units to change doctrine to ambush.


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

# ok, I want  a way to visualise 2 units on the map.
# I need to see their influence and vision radii.
# and the points that they influence.

function plotSingleUnit(u::Unit,col = :red)

    influencePoints = getInfluencePoints(u)
    visionPoints = getVisionPoints(u)


    p = scatter([i[1] for i in influencePoints],[i[2] for i in influencePoints],markersize = 2,color = col)
    scatter!([i[1] for i in visionPoints],[i[2] for i in visionPoints],markersize = 1,color = col)
    scatter!([u.position[1]],[u.position[2]],markersize = 5,color = col)

    arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius,0,2π,color = col)
    arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius + u.vision,-π,π,color = col,linestyle = :dash, linewidth = 0.5)
    return p
end

function plotVisions(u1::Unit,u2::Unit,display::Int=3)

    influencePoints1 = getInfluencePoints(u1)
    visionPoints1 = getVisionPoints(u1)
    visionOnlyPoints1 = setdiff(visionPoints1,influencePoints1)

    influencePoints2 = getInfluencePoints(u2)
    visionPoints2 = getVisionPoints(u2)
    visionOnlyPoints2 = setdiff(visionPoints2,influencePoints2)

    contestedPoints = intersect(influencePoints1,influencePoints2)


    p = scatter([i[1] for i in contestedPoints],[i[2] for i in contestedPoints],color = :black,  markersize = 25, marker  ='⚔')

    if display == 1 || display == 3

        # lets get the arcs
        col = :blue
        scatter!([u1.position[1]],[u1.position[2]],markersize = 30,color = col,marker = '⌂')
        arc!(Point2f(u1.position[1],u1.position[2]),u1.InfluenceRadius,0,2π,color = col)
        arc!(Point2f(u1.position[1],u1.position[2]),u1.InfluenceRadius + u1.vision,-π,π,color = col,linestyle = :dash, linewidth = 0.5)

        visionOverlap1 = intersect(visionOnlyPoints1,influencePoints2)
        scatter!([i[1] for i in visionOverlap1],[i[2] for i in visionOverlap1],color = col,  markersize = 10, marker  ='⚆', marker_offset = -5)

        controlInfluencePoints1 = setdiff(influencePoints1,influencePoints2)
        scatter!([i[1] for i in controlInfluencePoints1],[i[2] for i in controlInfluencePoints1],markersize = 10,color = col, marker = '⚐', marker_offset = -5)
    end

    if display == 2 || display == 3

        col = :red
        scatter!([u2.position[1]],[u2.position[2]],markersize = 30,color = col,marker = '⌂')
        arc!(Point2f(u2.position[1],u2.position[2]),u2.InfluenceRadius,0,2π,color = col)
        arc!(Point2f(u2.position[1],u2.position[2]),u2.InfluenceRadius + u2.vision,-π,π,color = col,linestyle = :dash, linewidth = 0.5)

        visionOverlap2 = intersect(visionOnlyPoints2,influencePoints1)
        scatter!([i[1] for i in visionOverlap2],[i[2] for i in visionOverlap2],color = col,  markersize = 10, marker  ='⚆', marker_offset = 2)

        controlInfluencePoints2 = setdiff(influencePoints2,influencePoints1)
        scatter!([i[1] for i in controlInfluencePoints2],[i[2] for i in controlInfluencePoints2],markersize = 10,color = col, marker = '⚐', marker_offset = 2)

    end
    # display(p)
    p
end

u1 = unit("u1",position = Point2f(10,10),InfluenceRadius = 10,vision =3)
u2 = unit("u2",position = Point2f(20,25),InfluenceRadius = 12,vision = 2)
plotVisions(u1,u2,3)







# ok, now lets check if a unit spots another unit.
# first, we need to see if there is any overlap in the vision of unitA with the influence of unitB.
"""
Gets the points that are in the vision of unitA and the influence of unitB.
"""
function getVisionOverlap(unitA::Unit,unitB::Unit)


    # if checkOverlap(unitA,unitB) == false
    #     return []
    # else

        overlap = Vector{CartesianIndex{2}}
        visionOnlyPointsA = setdiff(getVisionPoints(unitA),getInfluencePoints(unitA))
        influencePointsB = getInfluencePoints(unitB)
        overlap = intersect(visionOnlyPointsA,influencePointsB)
        return overlap

    # end

end

u1 = unit("u1",position = Point2f(56,50),InfluenceRadius = 3,vision =2)
u2 = unit("u2",position = Point2f(50,50),InfluenceRadius = 3,vision = 2)

cI= getVisionOverlap(u1,u2)
plotVisions(u1,u2,3)


# mp = BATTLEMAP.points[1]
# mp.cover

"""
Logistic function
"""
logistic(x) = 1/(1+exp(-(x  -0))) 

"""
Probability of a unit spotting another unit.
"""
function reconProb(u1_sz,u2_sz,u1_recon,u2_stealth,cover=1)
    # we need:
      # - the recon of the unit looking,
      # - the stealth of the unit being looked at,
      # - the cover of the point being looked at.
      # - the density of the 2 units. More units = more recon, less units = more stealth.
  
      # so these are my parameters. 
          # One stealthy boi should be able to reasonably evade detection from 10 dudes
          # 5 v 5 non stealthy be a good chance of detection
          # 5 v 5 stealthy, should be be v low. 
          # 1 v 5 non stealthy should have a reasonable chance of evasion.
          # cover should increase the liklihood of evasion.
      p = (rand(Normal(u1_recon/10, 0.5),1)[1]+0.25) * sqrt(u1_sz) * sqrt(u2_sz) * (rand(Normal((10-u2_stealth)/10, 0.5),1)[1]+0.25)
  
      p = min(sqrt(abs(p)),6)/5
  
      return p
  
  end

#   prob = []
#   u1 = []
#   u2  = []

  reconProb(5,5,10,5)

#   for i in 1:10
#       for j in 1:10
#           p =  reconProb(i,j,5,5)
#           push!(u1,i)
#           push!(u2,j)
#           push!(prob,p)
#       end
#   end
# scatter(u1,u2,prob,)
# scatter(u2,prob,)
# scatter(u1,prob,)
# hist(prob)
# maximum(prob)
# minimum(prob)



"""
This is to see if unit1 spots unit2
    we assume that all points are vision points
"""
function reconVizCheck(mp::MapPoint,u1::Unit,u2::Unit)

    recon = u1.reconissance
    stealth = u2.stealth
    cover = mp.cover
    u1_sz = u1.soliderCnt / size(getInfluencePoints(u1),1)
    u2_sz = u2.soliderCnt / size(getInfluencePoints(u2),1)

    p = reconProb(u1_sz,u2_sz,recon,stealth,cover)

    # println("prob detect: ",p)
    
    # I then want the vision distance of each point
    d = sqrt((u1.position[1] - mp.position[1])^2 + (u1.position[2] - mp.position[2])^2) - u1.InfluenceRadius

    # println("Distance: ",d) 
    
    # we can add more terrain effects here.

    return p/ceil(d)

end

# I want to get all the MP's that t1 can see.
# as a list of cartesian indexes.

function getVisionEvents(activeUnits,EVENTS=EVENTS)
    visArray = []
    visProb = []
    # we check if there are any vision events
    for i in activeUnits
        for j in activeUnits
            if i != j && i.team != j.team

                viz = getVisionOverlap(i,j)

                # get the real reports
                for cI in viz
                    mp = BATTLEMAP.points[cI[1],cI[2]]
                    p = reconVizCheck(mp,i,j)
                    println(p)
                    if p > 0.5
                        push!(EVENTS,GenerateVisReport(i,j,mp,p,true))
                        push!(visArray,cI)
                        push!(visProb,p)
                        # println("Unit 1 sees something at (REAL)", mapPt)
                    end
                end
                # get the fake ones
                for cI in setdiff(getVisionPoints(i),viz)
                    mp = BATTLEMAP.points[cI[1],cI[2]]

                    if rand(Float64) > 0.995 # this is the chance of spotting something that is not real. 
                        fakeP = rand(0.5..0.65)
                        push!(EVENTS,GenerateVisReport(i,j,mp,fakeP,false))
                        push!(visArray,cI)
                        push!(visProb,fakeP)
                        # println("Unit 1 sees something at (FAKE)",mapPt)
                    end
                end 
            end
        end
    end
    return visArray,visProb
end


"""
This is to see if unit1 spots unit2
    we assume that all points are influence points
"""
function reconInfluenceCheck(mp::MapPoint,u1::Unit,u2::Unit)

    recon = u1.reconissance
    stealth = u2.stealth
    cover = mp.cover
    u1_sz = u1.soliderCnt / size(getInfluencePoints(u1),1)
    u2_sz = u2.soliderCnt / size(getInfluencePoints(u2),1)
    u1_doctrine = u1.doctrine
    u2_doctrine = u2.doctrine

    p = (rand(Normal(recon/10, 0.5),1)[1]+0.25) * sqrt(u1_sz) * sqrt(u2_sz) * (rand(Normal((10-stealth)/10, 0.5),1)[1]+0.25) 
  
    p = min(sqrt(abs(p)),6)/3
    
    # apply Doctrine effects here.

 
    if u1_doctrine in ["DASH","ROUT"] # low chance of detection of other unit.
        p = p / 10
    elseif u1_doctrine in ["WITHDRAW"] # you're probably not proactivly scouting, but you are keeping tabs
        p = p / 2
    else if u1_doctrine in ["CONTROL","PERIMETER"]
        p = p / 2
    elseif u1_doctrine in ["RECONNAISSANCE","HUNT","AMBUSH"]
        p = p * 1.5
    end



    # println("prob detect: ",p)
    
    # I then want the vision distance of each point
    d = sqrt((u1.position[1] - mp.position[1])^2 + (u1.position[2] - mp.position[2])^2) - u1.InfluenceRadius
    if d <= 0
        d = 1
    end
    # println("Distance: ",d) 
    
    # we can add more terrain effects here.
    return p/ceil(d)
end

function miniTick()
end



# This will create an event! hell yea!!
struct Event
    team::String
    time::Int
    type::String
    reliability::Float64
    reportedBy::Int #Unit ID
    position::Point2f
    data::Dict{String,Any}
end


# ok, so here we have a function that creates a events.


# ok, so how can we generate an event from this?
"""
generates an event from a vision report that may be sent to the player. 
"""
function GenerateVisReport(u1,u2,mp,confidence,real=true)

# possible information to include in the event:
    EPos  = u2.position
    EDest = u2.destination
    ESpeed = u2.speed
    ESupplies = u2.supplies
    ECombatStrength = u2.combatStrength
    Emorale = u2.morale
    ESoliderCnt = u2.soliderCnt/100
    EstaringSoliderCnt = u2.staringSoliderCnt
    Elosses =  ESoliderCnt/EstaringSoliderCnt
    EInfluenceRadius = u2.InfluenceRadius
    Estealth = u2.stealth
    Erecon = u2.reconissance
    # Edoctrine = u2.doctrine
    EType = u2.type
    if !real
    ESpeed = round(rand(Float64)*10)
    # ESoliderCnt = round(rand(Float64)*1000)
    EDest = Point2f(mp.position[1] + rand(1:10),mp.position[2] + rand(1:10))
    end

    d = Dict()
    # want to be able to mix up fake and real reports
    if rand(Float64) > 0.8
        d["Enemy_Speed"] = ESpeed
    end
    if rand(Float64) > 0.8
        d["Enemy_Dest"] = EDest
    end

    if confidence > 0.75
        if rand(Float64) > 0.5
            d["Enemy_Type"] = EType
        end
        if rand(Float64) > 0.8
            d["Enemy_morale"] = Emorale
        end
        if rand(Float64) > 0.8
            d["losses"] = Elosses
        end

        if rand(Float64) > 0.8
            d["Enemy_Supplies"] = ESupplies
        end
        if rand(Float64) > 0.8
            d["Enemy_CombatStrength"] = ECombatStrength
        end
    elseif confidence > 0.8
        
        if rand(Float64) > 0.9
            d["Enemy_Pos"] = EPos
        end
        if rand(Float64) > 0.9
            d["Enemy_Dest"] = EDest
        end
        if rand(Float64) > 0.9
            d["EInfluenceRadius"] = EInfluenceRadius
        end
        if rand(Float64) > 0.9
            d["Estealth"] = Estealth
        end
        if rand(Float64) > 0.9
            d["Erecon"] = Erecon
        end
    end

    event = Event("team1",1,"recon",confidence,u1.id,mp.position,d)
    return event
end



# u1 = unit("u1",position = Point2f(10,10),InfluenceRadius = 3,vision =2)
# plotSingleUnit(u1)
"""
Plots the units on the map.
 
"""
function plotVisions(activeUnits,display::Int=3)

    # get team1 vision points
        team1 = [u for u in activeUnits if u.team == "team1"]
        # get the points for each unit
        t1_influencePoints = []
        t1_visionPoints = []
    
        for i in team1
    
            influencePoints = getInfluencePoints(i)
            visionPoints = getVisionPoints(i)
            union!(t1_influencePoints,influencePoints)
            union!(t1_visionPoints,visionPoints)
    
        end
        t1_visionOnlyPoints = setdiff(t1_visionPoints,t1_influencePoints)
    
        team2 = [u for u in activeUnits if u.team == "team2"]
        # get the points for each unit
        t2_influencePoints = []
        t2_visionPoints = []
    
        for i in team2
            influencePoints = getInfluencePoints(i)
            visionPoints = getVisionPoints(i)
            union!(t2_influencePoints,influencePoints)
            union!(t2_visionPoints,visionPoints)
        end
        t2_visionOnlyPoints = setdiff(t2_visionPoints,t2_influencePoints)
    
        contestedPoints = intersect(t1_influencePoints,t2_influencePoints)
    
    # Now we start plotting
        f = Figure()
        ax = f[1, 1] = Axis(f)
    
        if size(contestedPoints,1) > 0
            scatter!([i[1] for i in contestedPoints],[i[2] for i in contestedPoints],color = :black,  markersize = 25, marker  ='⚔')
        end
    
        if display == 1 || display == 3 # team1
    
            # lets get the arcs
            col = :blue
            for u in team1
                scatter!([u.position[1]],[u.position[2]],markersize = 30,color = col,marker = '⌂')
                arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius,0,2π,color = col)
                arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius + u.vision,-π,π,color = col,linestyle = :dash, linewidth = 0.5)
            end
    
            t1_visionOverlap = intersect(t1_visionOnlyPoints,t2_influencePoints)
            if size(t1_visionOverlap,1) > 0
                scatter!([i[1] for i in t1_visionOverlap],[i[2] for i in t1_visionOverlap],color = col,  markersize = 10, marker  ='⚆', marker_offset = -5)
            end
    
            t1_controlPoints = setdiff(t1_influencePoints,t2_influencePoints)
            if size(t1_controlPoints,1) > 0
                scatter!([i[1] for i in t1_controlPoints],[i[2] for i in t1_controlPoints],markersize = 10,color = col, marker = '⚐', marker_offset = -5)
            end
        end
        if display == 2 || display == 3
    
            col = :red
            for u in team2
                scatter!([u.position[1]],[u.position[2]],markersize = 30,color = col,marker = '⌂')
                arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius,0,2π,color = col)
                arc!(Point2f(u.position[1],u.position[2]),u.InfluenceRadius + u.vision,-π,π,color = col,linestyle = :dash, linewidth = 0.5)
            end
    
            t2_visionOverlap = intersect(t2_visionOnlyPoints,t1_influencePoints)
            if size(t2_visionOverlap,1) > 0
                scatter!([i[1] for i in t2_visionOverlap],[i[2] for i in t2_visionOverlap],color = col,  markersize = 10, marker  ='⚆', marker_offset = -5)
            end
    
            t2_controlPoints = setdiff(t2_influencePoints,t1_influencePoints)
            if size(t2_controlPoints,1) > 0
                scatter!([i[1] for i in t2_controlPoints],[i[2] for i in t2_controlPoints],markersize = 10,color = col, marker = '⚐', marker_offset = -5)
            end
    
        end
        # display(f)
        f
    end


# ok, so combat.
# happens on each point where there is an intersection of influence.
# && the doctrines of the units are to engage.

mp = BATTLEMAP.points[1,1]
u1 = unit("u1",position = Point2f(56,50),InfluenceRadius = 3,vision =2)
u2 = unit("u2",position = Point2f(50,50),InfluenceRadius = 3,vision = 2)





