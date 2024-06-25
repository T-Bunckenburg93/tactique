include("main.jl")
GLMakie.activate!(inline=false)

BATTLEMAP = battleMap(1000,1000)



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

plotVisions(activeUnits,3)


# m = viz1[1]

# BATTLEMAP.points[m[1],m[2]]
BATTLEMAP = battleMap(1000,1000)
EVENTS = []
EVENTS

sort!(EVENTS,by = x -> x.reliability,rev = true)

setMoveOrder!(recon1,Point2f(28,22))

# First up, execute move orders
for u in activeUnits
    MoveToPoint!(u)
end

# we check if there are any vision events
for i in activeUnits
    for j in activeUnits
        if i != j && i.team != j.team

            viz = getVisionOverlap(i,j)

            # get the real reports
            for cI in viz
                mp = BATTLEMAP.points[cI[1],cI[2]]
                p = reconCheck(mp,i,j)
                println(p)
                if p > 0.5
                    push!(EVENTS,GenerateVisReport(i,j,mp,p,true))
                    # println("Unit 1 sees something at (REAL)", mapPt)
                end
            end
            # get the fake ones
            for cI in setdiff(getVisionPoints(i),viz)
                mp = BATTLEMAP.points[cI[1],cI[2]]

                if rand(Float64) > 0.995 # this is the chance of spotting something that is not real. 
                    push!(EVENTS,GenerateVisReport(i,j,mp,rand(0.5..0.65),false))
                    # println("Unit 1 sees something at (FAKE)",mapPt)
                end
            end 
        end
    end
end




EVENTS

