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

# Define the dimensions of the level and the number of timesteps
width = 10
height = 10
timesteps = 5
playerpos = (1, 1)

# Define the 3D array of Z3 integer variables
level = [[[Int(f"level_{x}_{y}_{t}") for t in range(timesteps)] for y in range(height)] for x in range(width)]

s = Solver()

distinct_objects = len(mapping)

# Initial setup of the level at timestep 0 (0's and 1's)
for x in range(width):
    for y in range(height):
        cell_val = level[x][y][0]
        limit_objects = And(cell_val >= 0, cell_val < distinct_objects)
        s.add(limit_objects)

        if (x == playerpos[0] and y == playerpos[1]):
            s.add(cell_val == PLAYER[1])
        elif x == 0 or x == width - 1 or y == 0 or y == height - 1:
            s.add(cell_val == WALL[1])
        else:
            s.add(cell_val == BACKGROUND[1])

patterns = []
replacements = []
pattern = [(0,0, PLAYER[1]), (1,0, BACKGROUND[1]), (2,0, BACKGROUND[1])]
replacement = [BACKGROUND[1], PLAYER[1], BACKGROUND[1]]

replacements.append(replacement)
patterns.append(pattern)

# Now we add constraints to add the pattern in each timestep
for t in range(1, timesteps):

    pattern_match_constraints = []

    for x in range(0, width):
        for y in range(height):

            cell_val = level[x][y][t]
            limit_objects = And(cell_val >= 0, cell_val < distinct_objects)
            s.add(limit_objects)

            for i in range(len(patterns)):

                pattern = patterns[i]

                if x < len(pattern):

                    lhs = []
                    rhs = []
                    unchanged = []

                    for j in range(len(pattern)):

                        xdiff = pattern[j][0]
                        ydiff = pattern[j][1]
                        obj = pattern[j][2]
                        repl = replacements[i][j]

                        lhs.append(level[x + xdiff][y + ydiff][t - 1] == obj)
                        rhs.append(level[x + xdiff][y + ydiff][t] == repl)
                        unchanged.append(level[x + xdiff][y + ydiff][t] == level[x + xdiff][y + ydiff][t - 1])

                    lhs = And(lhs)
                    rhs = And(rhs)
                    unchanged = And(unchanged)

                    either = [Xor((Implies(lhs, rhs)), (Implies(Not(lhs), unchanged)))]
                    pattern_match_constraints += either
            
    s.add(Or(pattern_match_constraints))

# Now we solve the problem and print the results
if s.check() == sat:
    m = s.model()
    for t in range(timesteps):
        objects = [ [ m[level[x][y][t]].as_long() for x in range(width) ]
            for y in range(height) ]

        print(f"Timestep {t}:")
        print(objects)
        for list_objects in objects:
            row_string = " ".join(mapping[num] for num in list_objects)
            # row_string = " ".join(str(num) for num in list_objects)
            print(row_string)
            print()
        print()

else: 
    print("Unsat core:", s.unsat_core())
