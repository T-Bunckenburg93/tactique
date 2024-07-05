using GLMakie




function GLMakie.plot!(
    u::UnitViz{<:AbstractVector{<:Unit}})

# our first argument is an observable of parametric type AbstractVector{<:Real}

units = u[1]



# we predefine a couple of observables for the linesegments
# and barplots we need to draw
# this is necessary because in Makie we want every recipe to be interactively updateable
# and therefore need to connect the observable machinery to do so
unitAngle = Observable(Vector{Number})
unitRectanglePoints = Observable(Vector{Vector{Point{2, Float32}}})
# unitControlPoints = Observable(Vector{Vector{Point{2, Float32}}})
# unitControlAngle = Observable(Vector{Number})
# unitVisionDistance = Observable(Vector{Number})

# this helper function will update our observables
# whenever `times` or `stockvalues` change
function update_plot(units)

    # clear the vectors inside the observables
    empty!(unitAngle[])
    empty!(unitRectanglePoints[])
    # empty!(unitControlPoints[])
    # empty!(unitControlAngle[])
    # empty!(unitVisionDistance[])

    # then refill them with our updated values
    for unit in units

    rectangle_points = get_rectangle_points(unit.position, unit.width, unit.depth, unit.angle)
    controlBox = controlRectangle(unit.position, unit.width, unit.depth, unit.angle, unit.controlDistance)

    push!(unitAngle[], unit.angle)
    push!(unitRectanglePoints[], vcat(rectangle_points,rectangle_points[1]))
    # push!(unitControlPoints[], controlBox)
    # push!(unitControlAngle[], unit.controlAngle)
    # push!(unitVisionDistance[], unit.visionDistance)

    end
end

# connect the `update_plot` function to the observables
Makie.Observables.onany(update_plot, units)

# then call it once manually with the first `times` and `stockvalues`
# contents so we prepopulate all observables with correct values
update_plot(units[])


# in the last step we plot into our `sc` StockChart object, which means
# that our new plot is just made out of two simpler recipes layered on
# top of each other

    lines!(u,unitRectanglePoints, color = :blue)
    lines!(u,[Point2f(rectangle_points[3]), Point2f(rectangle_points[1])], color = :blue)
    lines!(u,[Point2f(rectangle_points[2]), Point2f(rectangle_points[4])], color = :blue)

    # arc!(u,controlBox[4], unit.controlDistance,deg2rad(unit.angle+90), deg2rad(unit.angle + 90 - unit.controlAngle),color = (:blue, 0.2))
    # arc!(u,controlBox[3], unit.controlDistance,deg2rad(unit.angle+90), deg2rad(unit.angle + 90 + unit.controlAngle),color = (:blue, 0.2))
    # lines!(u,[Point2f(controlBox[1]), Point2f(controlBox[2])], color = (:blue, 0.2))
    # lines!(u,[Point2f(controlBox[4]), Point2f(cos(deg2rad(unit.angle + 90 - unit.controlAngle)) * unit.controlDistance + controlBox[4][1], sin(deg2rad(unit.angle + 90 - unit.controlAngle)) * unit.controlDistance + controlBox[4][2]) ], color = (:blue, 0.2))
    # lines!(u,[Point2f(controlBox[3]), Point2f(cos(deg2rad(unit.angle + 90 + unit.controlAngle)) * unit.controlDistance + controlBox[3][1], sin(deg2rad(unit.angle + 90 + unit.controlAngle)) * unit.controlDistance + controlBox[3][2]) ], color = (:blue, 0.2))

u
end


f = Figure()

u1 = unit("unit1", position = Point2f(5000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)
u2 = unit("unit2", position = Point2f(4000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)

active_units = [u1,u2]

UnitViz(u1.u, active_units)





function get_rectangle_points(center, width, height, angle)

    angle = deg2rad(angle)
    # Center of the rectangle
    x_c, y_c = center
    
    # Half dimensions
    half_width = width / 2
    half_height = height / 2
    
    # Define the corners relative to the center (no rotation)
    corners = [
        [ half_width,  half_height],
        [-half_width,  half_height],
        [-half_width, -half_height],
        [ half_width, -half_height]
    ]
    
    # Rotation matrix
    cos_theta = cos(angle)
    sin_theta = sin(angle)
    rotation_matrix = [
        cos_theta -sin_theta;
        sin_theta  cos_theta
    ]
    
    # Rotate and translate corners
    rotated_corners = [rotation_matrix * corner for corner in corners]
    translated_corners = [corner .+ [x_c, y_c] for corner in rotated_corners]
    
    return translated_corners
end

function controlRectangle(center, width, height, angle,controlR)

    angle = deg2rad(angle)
    # Center of the rectangle
    x_c, y_c = center
    
    # Half dimensions
    half_width = width / 2
    half_height = height / 2
    
    # Define the corners relative to the center (no rotation)
    corners = [
        [ half_width,  half_height + controlR],
        [-half_width,  half_height + controlR],
        [-half_width, half_height],
        [ half_width, half_height]
    ]
    
    # Rotation matrix
    cos_theta = cos(angle)
    sin_theta = sin(angle)
    rotation_matrix = [
        cos_theta -sin_theta;
        sin_theta  cos_theta
    ]
    
    # Rotate and translate corners
    rotated_corners = [rotation_matrix * corner for corner in corners]
    translated_corners = [corner .+ [x_c, y_c] for corner in rotated_corners]
    
    return translated_corners
end



@recipe(UnitViz, positionx, positiony, angle, width, depth, controlDistance, controlAngle, visionDistance) do scene
    Attributes(;
        unitColor = :blue,
        controlArea = :red,
        # visonArea = :green,
        )
end


function Makie.plot!(unit::UnitViz)

    # get the boxes of the units.
    # rectangle_points = get_rectangle_points(unit.position, unit.width, unit.depth, unit.angle)
    # controlBox = controlRectangle(unit.position, unit.width, unit.depth, unit.angle, unit.controlDistance)

    unitAngle = Observable(Vector{Number})
    unitRectanglePoints = Observable(Vector{Vector{Point{2, Float32}}})

    function update_plot(units)

        # clear the vectors inside the observables
        empty!(unitAngle[])
        empty!(unitRectanglePoints[])
        # empty!(unitControlPoints[])
        # empty!(unitControlAngle[])
        # empty!(unitVisionDistance[])
    
        # then refill them with our updated values
        for unit in units
    
            rectangle_points = get_rectangle_points(Point2f(unit.positionx,unit.positiony), unit.width, unit.depth, unit.angle)
            controlBox = controlRectangle(Point2f(unit.positionx,unit.positiony), unit.width, unit.depth, unit.angle, unit.controlDistance)
        
            push!(unitAngle[], unit.angle)
            push!(unitRectanglePoints[], vcat(rectangle_points,rectangle_points[1]))
            # push!(unitControlPoints[], controlBox)
            # push!(unitControlAngle[], unit.controlAngle)
            # push!(unitVisionDistance[], unit.visionDistance)
    
        end
    end
    
    # connect the `update_plot` function to the observables
    Makie.Observables.onany(update_plot, units)
    
    # then call it once manually with the first `times` and `stockvalues`
    # contents so we prepopulate all observables with correct values
    update_plot(units[])
    
    lines!(unit,unitRectanglePoints, color = :blue)


    # normal plotting code, building on any previously defined recipes
    # or atomic plotting operations, and adding to the combined `myplot`:
    # lines!(myplot, rand(10), color = myplot.plot_color)
    # plot!(myplot, myplot.x, myplot.y)
    # myplot
    unit
end


f = Figure()

u1 = unit("unit1", position = Point2f(5000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)
u2 = unit("unit2", position = Point2f(4000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)

active_units = [u1,u2]



UnitViz(u1.position[1],u1.position[2], u1.angle, u1.width, u1.depth, u1.controlDistance, u1.controlAngle, u1.visionDistance)





function plotUnit!(axis,unit::Unit, unitColor = :red)
    # get the boxes of the units.
    rectangle_points = get_rectangle_points(unit.position, unit.width, unit.depth, unit.angle)
    controlBox = controlRectangle(unit.position, unit.width, unit.depth, unit.angle, unit.controlDistance)

    # poly!(axis,Polygon(Point2f.(rectangle_points),),  color =  (unitColor,0.2),   strokecolor = unitColor, strokewidth = 1)
    lines!(axis,[Point2f(rectangle_points[1]), Point2f(rectangle_points[2]),Point2f(rectangle_points[3]), Point2f(rectangle_points[4]),Point2f(rectangle_points[1])], color = unitColor)
    lines!(axis,[Point2f(rectangle_points[3]), Point2f(rectangle_points[1])], color = unitColor)
    lines!(axis,[Point2f(rectangle_points[2]), Point2f(rectangle_points[4])], color = unitColor)

    arc!(axis,controlBox[4], unit.controlDistance,deg2rad(unit.angle+90), deg2rad(unit.angle + 90 - unit.controlAngle),color = (:blue, 0.2))
    arc!(axis,controlBox[3], unit.controlDistance,deg2rad(unit.angle+90), deg2rad(unit.angle + 90 + unit.controlAngle),color = (:blue, 0.2))
    lines!(axis,[Point2f(controlBox[1]), Point2f(controlBox[2])], color = (:blue, 0.2))
    lines!(axis,[Point2f(controlBox[4]), Point2f(cos(deg2rad(unit.angle + 90 - unit.controlAngle)) * unit.controlDistance + controlBox[4][1], sin(deg2rad(unit.angle + 90 - unit.controlAngle)) * unit.controlDistance + controlBox[4][2]) ], color = (:blue, 0.2))
    lines!(axis,[Point2f(controlBox[3]), Point2f(cos(deg2rad(unit.angle + 90 + unit.controlAngle)) * unit.controlDistance + controlBox[3][1], sin(deg2rad(unit.angle + 90 + unit.controlAngle)) * unit.controlDistance + controlBox[3][2]) ], color = (:blue, 0.2))
end



u1 = unit("unit1", position = Point2f(5000,5000),spacing = 5, depth = 100, angle = 45, controlDistance = 350)
f = Figure()
ax = Axis(f[1, 1], aspect  =DataAspect(), limits = ((0,10000),(0,10000)))
rectangle_points = get_rectangle_points(u1.position, u1.width, u1.depth, u1.angle)
Point2f.(rectangle_points)
plotUnit!(ax,u1)
f