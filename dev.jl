include("main.jl")

# ok so game loop. 

# for each tick, we want to:
    # 1) execute all move orders
    # 1a) kiss anna and make her a sandwhich
    # 2) calculate all combats for overlapping opposing units.
    # 3) apply combat results.
    # 4) check to see if units are dead and move them to the graveyard.
    # 5) update the game and wait for input from the player.

# 1) This can just be teleportation movements for now.

# lets try a 2v2 and add in some more units, sides, as well as some duplicate overlaps and killing units.

# we will also plot the map.

fieldnames(unit)

# init the units. 
inf1 = unit("rifles",team = "team1",combatStrength = 5, soliderCnt = 1000, staringSoliderCnt = 1000, InfluenceRadius = 5,supplies = 1000)
recon1 = unit("recon",team = "team1",combatStrength = 15, soliderCnt = 100, staringSoliderCnt = 100, InfluenceRadius = 10,supplies = 100)

teleportUnit!(inf1, -50, 0)
teleportUnit!(recon1, -50, -30)

inf2 = unit("rifles",team = "team2",combatStrength = 5, soliderCnt = 1000, staringSoliderCnt = 1000, InfluenceRadius = 5,supplies = 1000)
recon2 = unit("recon",team = "team2",combatStrength = 15, soliderCnt = 100, staringSoliderCnt = 100, InfluenceRadius = 15,supplies = 100)


teleportUnit!(inf2, 50, 0)
teleportUnit!(recon2, 50, 30)

activeUnits = [inf1,recon1,inf2,recon2]
graveyard = []

plotMap(activeUnits)


# GLMakie.activate!(inline=false)

# I want a function that takes in a unit and a point, 
# and will move the unit to that point based on the units speed
# currently will not use the map, but will have to eventually. 
"""
This takes a unit and a point and moves it to that point based on the units speed.
"""
function MoveToPoint(unit::Unit, x::Number, y::Number)

    # get the distance between the two points
    distance = sqrt((unit.positionX - x)^2 + (unit.positionY - y)^2)
    if distance <  unit.speed
        teleportUnit!(unit, x, y)
        return
    else
        # move it towards the point. first get the unit vector from the unit to the desired point
        v = [x - unit.positionX, y - unit.positionY]
        vNorm = v / norm(v)
        # move the unit in that direction
        teleportUnit!(unit, unit.positionX + vNorm[1] * unit.speed, unit.positionY + vNorm[2] * unit.speed)

    end
end





inf1 = unit("rifles",team = "team1",combatStrength = 5, soliderCnt = 1000, staringSoliderCnt = 1000, InfluenceRadius = 5,supplies = 1000) 

activeUnits = [inf1]
graveyard = []

plotMap(activeUnits)
MoveToPoint(inf1,0,100)

