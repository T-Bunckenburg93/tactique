# include("main.jl")

GLMakie.activate!(inline=false)

BATTLEMAP = battleMap(1000,1000)





# init the units. 
inf1 = unit("rifles1",team = "team1",speed = 20 ,supplies = 1000, position = Point2f(10,10))
recon1 = unit("recon1",team = "team1",combatStrength = 15, soliderCnt = 200, InfluenceRadius = 6, position = Point2f(20,10),minDensity = 1)
inf2 = unit("rifles2",team = "team2",combatStrength = 5, soliderCnt = 1000, InfluenceRadius = 5,supplies = 1000, position = Point2f(30,30))
recon2 = unit("recon2",team = "team2",combatStrength = 15, soliderCnt = 100, InfluenceRadius = 15,supplies = 100, position = Point2f(30,10))

inf1.InfluenceRadius
recon1.InfluenceRadius
inf2.InfluenceRadius

activeUnits = [
    inf1,
    recon1,
    inf2,
    recon2
    ]
graveyard = []

plotVisions(activeUnits,1)


# m = viz1[1]

# BATTLEMAP.points[m[1],m[2]]
BATTLEMAP = battleMap(1000,1000)
EVENTS = []
EVENTS

sort!(EVENTS,by = x -> x.reliability,rev = true)

setMoveOrder!(recon1,Point2f(27,22))
setMoveOrder!(recon2,Point2f(26,16))

# First up, execute move orders
for u in activeUnits
    MoveToPoint!(u)
end

# This gets the vision events, and the points where vision is attained.
visArray, visProb = getVisionEvents(activeUnits)

visArray
visProb

# now we we want look for vision events, inside areas of influence.
# Doctrine will have some effect on this. 
# For now, we will just look for vision events in the influence area of recon units.

influenceVisArray = []
influenceVisProb = []

for i in activeUnits
    for j in activeUnits
        if i != j && i.team != j.team
            influenceOverlap = union(getInfluencePoints(i),getInfluencePoints(j))

            # get the real reports
            for xy in influenceOverlap
                mp = BATTLEMAP.points[xy[1],xy[2]]
                p = reconInfluenceCheck(mp,i,j)

                if p > 0.5
                    push!(EVENTS,GenerateVisReport(i,j,mp,p,true))
                    push!(visArray,cI)
                    push!(visProb,p)
                    # println("Unit 1 sees something at (REAL)", mapPt)
                end
            end

        end
    end
end













EVENTS

