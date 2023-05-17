from z3 import *

BACKGROUND = (".", 0)
WALL = ("#", 1)
CRATE = ("*", 2)
PLAYER = ("P", 3)

mapping = {
    BACKGROUND[1]: BACKGROUND[0],
    WALL[1]: WALL[0],
    CRATE[1]: CRATE[0],
    PLAYER[1]: PLAYER[0]
}

class PSObject:

    def __init__(self, name):
        # self.pos_x = pos_x
        # self.pos_y = pos_y
        self.name = name

class LevelData:

    def __init__(self, width, height, moving_objects):
        self.width = width
        self.height = height
        self.moving_objects = moving_objects

ld = LevelData(4,4,2)
psobjects = [PSObject("Crate"), PSObject("Crate")]

objects = {"Crate": 4, "Player": 1}

# Define the number of objects
num_objects = 0
for k in objects:
    num_objects += objects[k]

distinct_objects = len(mapping)


# Define the play area width and height
playw = 10
playh = 10

# Create Z3 solver
solver = Solver()

# Create variables for the object positions
X = [ [ Int("x_%s_%s" % (i, j)) for j in range(playw) ]
      for i in range(playh) ]

# Create objects
# objects = [
#     PSObject("Crate")
#     for i in range(num_objects)
# ]

# Add constraints to ensure objects have distinct positions
one_object = [ Distinct([ X[i][j] for i in range(playw) ])
             for j in range(playh) ]


for i in range(playw):
    for j in range(playh):
        
        X_val = X[i][j]
        # Add constraint to enforce the range [0, 5]
        limit_objects = And(X_val >= 0, X_val < distinct_objects)
        solver.add(limit_objects)
        
        if i == 0 or i == playw - 1 or j == 0 or j == playh - 1:
            solver.add(X[i][j] == WALL[1])
        

# crate_objects = Sum([If(X[i][j] == CRATE[1], 1, 0) for i in range(playh) for j in range(playw)])
# solver.add(crate_objects == objects["Crate"])

# Add constraints for placing a specific number of crates randomly
positions = []
for key, value in objects.items():
    pos_x = Int(f"{key}_x")
    pos_y = Int(f"{key}_y")
    positions.append((pos_x, pos_y))

    solver.add(pos_x >= 1, pos_x < playw - 1)
    solver.add(pos_y >= 1, pos_y < playh - 1)
    solver.add(Int("x_%s_%s" % (pos_x, pos_y)) == CRATE[1])

# player_objects = Sum([If(X[i][j] == PLAYER[1], 1, 0) for i in range(playh) for j in range(playw)])
# solver.add(player_objects == objects["Player"])

# background_objects = Sum([If(X[i][j] == BACKGROUND[1], 1, 0) for i in range(playh) for j in range(playw)])
# solver.add(background_objects == (playw * playh) - (4 * playw - 4) - num_objects)



# Check if the constraints are satisfiable
if solver.check() == sat:
    model = solver.model()
    # Get the values of the variables
    objects = [ [ model[X[i][j]].as_long() for i in range(playw) ]
      for j in range(playh) ]

    print(objects)
    # object_positions = [(model[X[i][0]].as_long(), model[X[i][0]].as_long()) for i in range(num_objects)]
    print("Object positions:")
    for list_objects in objects:
        row_string = " ".join(mapping[num] for num in list_objects)
        print(row_string)
        # print(f"{objects[i].name}: (x={object_positions[i][0]}, y={object_positions[i][1]})")

        # print("\n")
else:
    print("No satisfying assignment.")


print ("statistics for the last check method...")
print (solver.statistics())
# Traversing statistics
for k, v in solver.statistics():
    print ("%s : %s" % (k, v))

# x = Real('x')
# y = Real('y')
# s = Solver()
# s.add(x > 1, y > 1, Or(x + y > 3, x - y < 2))
# print ("asserted constraints...")
# for c in s.assertions():
#     print (c)

# print (s.check())
# print ("statistics for the last check method...")
# print (s.statistics())
# # Traversing statistics
# for k, v in s.statistics():
#     print ("%s : %s" % (k, v))