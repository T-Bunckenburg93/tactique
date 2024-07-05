using Test
include("main.jl")


# checking equality of units
@test uVals(unit("u")) != uVals(unit("u")) # id is the only thing that is different.
@test uVals(unit("u",id = 1)) == uVals(unit("u",id = 1)) # as we see here.

# tests unit creation
u1 = unit("Unit1")
u2 = unit("Unit1", type="tank")

# tests unit creation
u1 = unit("Unit1")
changeInfluence!(u1,100)

# tests
u1 = unit("Unit1")
teleportUnit!(u1, 10.0, 10.0)
dump(u1)

# tests
u1 = unit("Unit1", InfluenceRadius=11)
u2 = unit("Unit2")
checkOverlap(u1, u2)
teleportUnit!(u2, 1, 0)
teleportUnit!(u2, 10, 0)

# tests
# u1 = unit("Unit1")
# teleportUnit!(u1, 5.0, 0.0)
# u2 = unit("Unit2")
# getIntersectionPoints(u1, u2)
# teleportUnit!(u1, 100.0, 100.0)
# getIntersectionPoints(u1, u2)

# unit1 = unit("Unit1")
# teleportUnit!(unit1, 18.0, 0)
# unit2 = unit("Unit2")
# checkOverlap(unit1, unit2)
# getIntersectionPoints(unit1, unit2)
# getOverlapArea(unit1, unit2)

# u1 = unit("u1",combatStrength = 20, soliderCnt = 100)
# u2 = unit("u2",combatStrength = 5)
# teleportUnit!(u1,15,1)

# calculateCombat!(u1,u2)
# calculateCombat!(u2,u1)

# applyCombat!(u1)
# applyCombat!(u2)

