using GLMakie

u1 = unit("t1u1",team = "team1",position = Point2f(1000,1000),angle = 0)
u2 = unit("t1u2",team = "team1",position = Point2f(2000,2000),angle = 90)
u3 = unit("t1u3",team = "team1",position = Point2f(3000,3000),angle = 180)
u4 = unit("t1u4",team = "team1",position = Point2f(4000,4000),angle = 270)

    activeUnits = [
    u1,
    u2,
    u3,
    u4
    ]
    ActiveO =  Observable(activeUnits) 

    graveyard = [
    # u1,
    # u2,
    # u3,
    # u4,
    ]


ActiveO[] = activeUnits

# println("activeUnits: ",activeUnits)
allU_sz = size(activeUnits,1)+size(graveyard,1)

# Init Plots
s = Figure(size = (10000, 10000))
# Axis(s[1, 1], limits = ((-100, 100), (-100,100)))
ax = Axis(s[1, 2], limits = ((-0, 10000), (-0,10000)), aspect = 1)
# println("interaction: ",interactions(ax))
deregister_interaction!(ax, :rectanglezoom)
# deregister_interaction!(ax, :dragpan)
hidespines!(ax)

# ok, so what do we need to be able to plot?
idx = Observable(1) # this is the index of the selected observable

CurrentUnit = @lift getUnit($ActiveO,$idx)

teamMap = Dict("team1" => "red", "team2" => "blue", "teamDev" => "pink")
speed_vals = [20,50,80,100,200]


ActiveO = Observable(activeUnits)



# teamColours = Observable(fill("red",allU_sz))
# teamUnitNames = Observable(fill("",allU_sz))
# positions = Observable(fill(Point2f(-9999999999,-9999999999),allU_sz))
# linePositions = Observable(fill((Point2f(-9999999999,-9999999999),Point2f(-9999999999,-9999999999)),allU_sz))

teamColours = @lift [teamMap[i.team] for i in $ActiveO]
teamUnitNames = @lift  [i.name for  i in $ActiveO]
positions = @lift [i.position for i in $ActiveO]
linePositions = @lift [(i.position,coalesce(i.destination,i.position)) for i in $ActiveO]
boxO = @lift vec(stack([get_rectangle_points(i.position,i.width,i.depth,i.angle) for i in $ActiveO]))
controlO = @lift vec(stack([controlArc(i.position, i.width, i.depth, i.angle,i.controlDistance,i.controlAngle) for i in $ActiveO ]))
# controlO2 = @lift [controlArc(i.position, i.width, i.depth, i.angle,i.controlDistance,i.controlAngle) for i in $ActiveO ]
boxO[]

controlArc(activeUnits[1].position, activeUnits[1].width, activeUnits[1].depth, activeUnits[1].angle,activeUnits[1].controlDistance,activeUnits[1].controlAngle)
linesegments!(controlO)
# controlO2[]
linesegments!(boxO)
s
# in order to stop length mismatch, we need to have the observables be a static length.
# then we can update the values of the observables as needed.

# on(ActiveO) do s

#     controlO[] = getControlArc(ActiveO[])
#     boxO[] = getSquare(ActiveO[])

# end
# notify(ActiveO) # init the above observables. 

currentObjectSpeed_i = Observable{Any}(0.0)

# Ok so I want to make a whole load of observables that are linked to each unit. 
# this needs to come from all units. 


linesegments!(linePositions,  color = teamColours)
scatter!(positions, strokewidth = 3,  color =teamColours)

text!(positions, text = teamUnitNames, color = teamColours, align = (:center, :top))
s


# When the current unit is updated, we need to update the menus
# println("current unit: ",CurrentUnit[])
on(idx) do s
    println(typeof(s))
    println("selected unit: $idx")

    currentObjectSpeed_i = findfirst( ==(to_value(CurrentUnit).speed), speed_vals)
    speed__M.i_selected = currentObjectSpeed_i

end

# Lets add menus
TUN = filter(x -> x != "", to_value(teamUnitNames))
# when I select a unit, I want to be able to change the attributes of that unit.
selectUnit__M = Menu(s,
    options = zip((TUN),collect(1:length(TUN))),
    # selection = idx[]
    )

on(selectUnit__M.selection) do s
    # println("selected unit: ",s)
    idx[] = s
end

# now I want to add attributes of the selected unit that we can change.
# when IDX changes, this needs to update.

speed__M = Menu(s,
    options = zip(string.("Speed ", speed_vals),collect(1:length(to_value(speed_vals)))),
    )   

on(speed__M.selection) do s
println("speed change: Changing Unit ",CurrentUnit[].name," speed to : ",CurrentUnit[].speed)
    cu = to_value(CurrentUnit)
    cu.speed = speed_vals[s]*100
    ActiveO[] = putUnit(activeUnits,idx[],cu)
end


s[1, 1] = vgrid!(
    Label(s, "Unit:", width = nothing), 
    selectUnit__M,
    Label(s, "Attributes:", width = nothing),
    speed__M
    ;
    tellheight = false, width = 200
    )

# button to run the simulation again. 

RunButton = Button(s, label = "Run Simulation")
on(RunButton.clicks, priority = 10) do s
    tick()
end


# and add the units. 

# Here are the keyboard interactions:


# This selects a unit. 
on(events(ax).mousebutton, priority = 2) do event

    if event.button == Mouse.right && event.action == Mouse.press

        plt, i = GLMakie.pick(s,10)
        println(plt)
        if plt isa Scatter{Tuple{Vector{Point{2, Float32}}}}

            selectUnit__M.i_selected = i 
        end
    end

    # println("positions: ",positions)

    hotkey = Keyboard.a
    # if event.button == Mouse.right && event.action == Mouse.press && idx[] != 0
    on(events(ax).mouseposition, priority = 3) do mp
        mb = events(ax).mousebutton[]

        if to_value(events(ax).entered_window) == true && mb.button == Mouse.left && mb.action == Mouse.press && ispressed(ax, hotkey)
            # get current unit and update destination
            cu = to_value(CurrentUnit)
            # println("current dest: ",cu.destination)
            cu.destination = Point2f(mouseposition(ax))
            CurrentUnit[] = cu

            # push it back unto the active Unit, and update Observable
            ActiveO[] = putUnit(activeUnits,idx[],cu)
            notify(ActiveO)

        end
    end

end

display(s)
# return to_value(ActiveO)




function tick()
    global ActiveO, activeUnits, graveyard

    println(size(controlO[]))

    # moof all units to their move orders.
    for i = 1:4
        println(i)

        for u in activeUnits
            # showFields(u,fields = [:position,:destination])
            MoveToPoint!(u)
            rotateUnit!(u)
        end

        
        # check to see if any units are overlapping, and apply engaged status.
        # for i in activeUnits
        #     for j in activeUnits
        #         if i != j && i.team != j.team
        #             if checkOverlap(i,j) in ["overlap","swallow","swallowed"]
        #                 i.isEngaged = true
        #             else 
        #                 i.isEngaged = false
        #             end
        #             calculateCombat!(i,j)
        #         end
        #     end
        # end
        
        # and apply them. 
        # for i in activeUnits
        #     applyCombat!(i)
        #     # and see if any have died
        #     if killCheck(i)
        #         push!(graveyard,i)
        #         filter!(x -> x != i, activeUnits)
        #     end
        # end

        ActiveO[] = activeUnits
        notify(ActiveO)

        display(s)
    end
    # activeUnits = plotInteractiveMap(activeUnits)
end

# t1u1 = unit("t1u1",team = "team1",position = Point2f(1000,1000))
# tu2 = unit("t1u2",team = "team2",position = Point2f(5000,5000))

# activeUnits = [t1u1,tu2]
# graveyard = []

# tick()
s   