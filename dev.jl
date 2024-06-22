include("main.jl")
GLMakie.activate!(inline=false)

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

# fieldnames(unit)

# init the units. 
inf1 = unit("rifles1",team = "team1",speed = 20 ,supplies = 1000, position = Point2f(10,0))
recon1 = unit("recon1",team = "team1",combatStrength = 15, soliderCnt = 100, staringSoliderCnt = 100, InfluenceRadius = 10,supplies = 100, position = Point2f(40,0))
inf2 = unit("rifles2",team = "team2",combatStrength = 5, soliderCnt = 1000, staringSoliderCnt = 1000, InfluenceRadius = 5,supplies = 1000, position = Point2f(80,0))
recon2 = unit("recon2",team = "team2",combatStrength = 15, soliderCnt = 100, staringSoliderCnt = 100, InfluenceRadius = 15,supplies = 100, position = Point2f(120,0))


activeUnits = [
    inf1,
    recon1,
    inf2,recon2
    ]
graveyard = []

# plotMap(activeUnits)


# GLMakie.activate!(inline=false)

# ok, so I want some code to deal with engagements and combat.
# when engaging, units move much more slowly to not take a massive combat penalty.
# perhaps 1/3 speed? towards, and 1/2 speed away? or can retreat at full speed for high losses.

# Lets do this later....


function tick()
    global activeUnits, graveyard
    # moof all units to their move orders.

    for u in activeUnits
        # showFields(u,fields = [:position,:destination])
        MoveToPoint!(u)
    end
    
    # check to see if any units are overlapping, and apply engaged status.
    for i in activeUnits
        for j in activeUnits
            if i != j && i.team != j.team
                if checkOverlap(i,j) in ["overlap","swallow","swallowed"]
                    i.isEngaged = true
                else 
                    i.isEngaged = false
                end
                calculateCombat!(i,j)
            end
        end
    end
    
    # and apply them. 
    for i in activeUnits
        applyCombat!(i)
        # and see if any have died
        if killCheck(i)
            push!(graveyard,i)
            filter!(x -> x != i, activeUnits)
        end
    end
    
    activeUnits = plotInteractiveMap(activeUnits)
end


tick()

