from z3 import *
import time

timebefore = time.time()


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
width = 5
height = 5
timesteps = 10
playerpos = (1, 1)
winpos = (3, 3)

# Define the 3D array of Z3 integer variables
level = [[[Int(f"level_{x}_{y}_{t}") for t in range(timesteps)] for y in range(height)] for x in range(width)]

s = Solver()

distinct_objects = len(mapping)

# Initial setup of the level at timestep 0
for x in range(width):
    for y in range(height):
        cell_val = level[x][y][0]

        if (x == playerpos[0] and y == playerpos[1]):
            s.add(cell_val == PLAYER[1])
        
        elif x == 0 or x == width - 1 or y == 0 or y == height - 1:
            s.add(cell_val == WALL[1])

        else:
            s.add(cell_val == BACKGROUND[1])


patterns = []
replacements = []

move_r = [(0, 0, PLAYER[1]), (1, 0, BACKGROUND[1])]
patterns.append(move_r)
repl_move_r = [BACKGROUND[1], PLAYER[1]]
replacements.append(repl_move_r)

move_l = [(0, 0, PLAYER[1]), (-1, 0, BACKGROUND[1])]
patterns.append(move_l)
repl_move_l = [BACKGROUND[1], PLAYER[1]]
replacements.append(repl_move_l)

move_u = [(0, 0, PLAYER[1]), (0, -1, BACKGROUND[1])]
patterns.append(move_u)
repl_move_u = [BACKGROUND[1], PLAYER[1]]
replacements.append(repl_move_u)

move_d = [(0, 0, PLAYER[1]), (0, 1, BACKGROUND[1])]
patterns.append(move_d)
repl_move_d = [BACKGROUND[1], PLAYER[1]]
replacements.append(repl_move_d)

for t in range(1, timesteps):

    all_patterns = []

    new_playerpos = (0,0)

    choice_rule = []

    for i in range(len(patterns)):
        pattern = patterns[i]

        # For every cell: Add pattern + changed pattern in next timestep or remain unchanged
        for m in range(0, width):
            for n in range(0, height):

                lhs = []
                rhs = []
                unchanged_rhs = []
                unchanged = []
                skip = []

                # For every pattern: Go over the whole board.
                for x in range(0, width):
                    for y in range(0, height):

                        # Extract cell value at pos x, y
                        cell_val = level[x][y][t]

                        for j, (xdiff, ydiff, obj) in enumerate(pattern):

                            # Check if pattern fits at player position
                            if x + xdiff < width and y + ydiff < height:

                                skip.append(tuple((x + xdiff, y + ydiff)))

                                lhs.append(level[x + xdiff][y + ydiff][t - 1] == obj)
                                unchanged.append(level[x+xdiff][y + ydiff][t] == level[x+xdiff][y + ydiff][t - 1])

                                if ((x + xdiff, y + ydiff) == winpos and t == timesteps - 1):
                                    rhs.append(level[x][y][t] == PLAYER[1])
                                else:
                                    rhs.append(level[x + xdiff][y + ydiff][t] == replacements[i][j])


                        if (x,y) in skip:
                            continue
                        else:
                            unchanged_rhs.append(level[x][y][t] == level[x][y][t - 1])
                                    
                        # s.add(Xor(Implies(lhs, And(rhs, unchanged_rhs)), Implies(Not(lhs), And(unchanged_rhs, unchanged))))

                lhs = And(lhs)
                rhs = And(rhs)
                unchanged_rhs = And(unchanged_rhs)
                unchanged = And(unchanged)

                # If and else makes unsat for now...
                if (t != timesteps - 1):
                    choice_rule.append(Or(And(lhs, rhs, unchanged_rhs), And(Not(lhs), unchanged, unchanged_rhs)))
                else:
                    choice_rule.append(And(lhs, rhs, unchanged_rhs))

    # playerpos = new_playerpos

    s.add(AtLeast(*choice_rule, 1))


# Now we solve the problem and print the results
if s.check() == sat:
    print("sat")
    m = s.model()
    for t in range(timesteps):
        objects = [[m[level[x][y][t]] for x in range(width)] for y in range(height)]

        print(f"Timestep {t}:")
        for list_objects in objects:
            row_string = " ".join(mapping[num.as_long()] if num is not None else "?" for num in list_objects)
            # row_string = " ".join(str(num) if num is not None else "?" for num in list_objects)
            print(row_string)
        print()
else:
    print("Unsat core:", s.unsat_core())
