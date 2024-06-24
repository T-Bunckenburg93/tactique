# This is a bunch of functions that I find useful, but are not specific to the project.

"""
gets specific fields from an object and prints them out.
If no fields are given, it will print out all fields.
"""
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

"""
Useful and well named function to check if a value is missing.
"""
function falseIfMissing(x)
    if ismissing(x)
        return false
    else
        return true
    end
end
# u1 = unit("Unit1")
# showFields(u1,fields=[:name,])


"""
Used when you need to broadcast over tuples or something
"""
function getNval(x,n=1)
    return Point2f(x[n])
end