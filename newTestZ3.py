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
width = 7
height = 7
timesteps = 10
playerpos = (2, 2)
winpos = (5, 4)

# Define the 3D array of Z3 integer variables
level = [[[Int(f"level_{x}_{y}_{t}") for t in range(timesteps)] for y in range(height)] for x in range(width)]

s = Solver()


### DIT IS BELANGRIJK VOOR GENEREREN ###
# Add constraints to ensure uniqueness of arrays
# distinct_arrays = [Distinct([level[x][y][t] for y in range(height) for x in range(width)]) for t in range(timesteps)]
# s.add(distinct_arrays)

distinct_objects = len(mapping)

# Initial setup of the level at timestep 0
for x in range(width):
    for y in range(height):
        cell_val = level[x][y][0]

        if (x == playerpos[0] and y == playerpos[1]):
            s.add(cell_val == PLAYER[1])

        elif (x == playerpos[0] + 1 and y == playerpos[1]):
            s.add(cell_val == CRATE[1])
        
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

push_r = [(0, 0, PLAYER[1]), (1, 0, CRATE[1]), (2, 0, BACKGROUND[1])]
patterns.append(push_r)
repl_push_r = [BACKGROUND[1], PLAYER[1], CRATE[1]]
replacements.append(repl_push_r)

push_l = [(0, 0, PLAYER[1]), (-1, 0, CRATE[1]), (-2, 0, BACKGROUND[1])]
patterns.append(push_l)
repl_push_l = [BACKGROUND[1], PLAYER[1], CRATE[1]]
replacements.append(repl_push_l)

push_u = [(0, 0, PLAYER[1]), (0, -1, CRATE[1]), (0, -2, BACKGROUND[1])]
patterns.append(push_u)
repl_push_u = [BACKGROUND[1], PLAYER[1], CRATE[1]]
replacements.append(repl_push_u)

push_d = [(0, 0, PLAYER[1]), (0, 1, CRATE[1]), (0, 2, BACKGROUND[1])]
patterns.append(push_d)
repl_push_d = [BACKGROUND[1], PLAYER[1], CRATE[1]]
replacements.append(repl_push_d)

for t in range(1, timesteps):
    all_patterns = []
    new_playerpos = (0, 0)
    choice_rule = []
    last_t = []

    for i in range(len(patterns)):
        pattern = patterns[i]

        unchanged = []

        # For every cell: Add pattern + changed pattern in next timestep or remain unchanged
        for m in range(0, width):
            for n in range(0, height):

                lhs = []
                rhs = []
                unchanged_rhs = []
                skip = []

                # For the last timestep we only care about an applied lhs pattern that results in a winning rhs
                if (t == timesteps - 1 and (m, n) != winpos): continue

                # For every pattern: Go over the whole board.
                for x in range(0, width):
                    for y in range(0, height):

                        if (len(unchanged) != width * height): unchanged.append(level[x][y][t] == level[x][y][t-1])

                        # Extract cell value at pos x, y
                        cell_val = level[x][y][t]

                        for j, (xdiff, ydiff, obj) in enumerate(pattern):

                            # Check if pattern fits at player position
                            if m + xdiff < width and n + ydiff < height and len(lhs) != len(pattern):

                                curr_cel_value = level[m + xdiff][n + ydiff][t]
                                prev_cel_value = level[m + xdiff][n + ydiff][t - 1]

                                lhs.append(prev_cel_value == obj)

                                # if ((m + xdiff, n + ydiff) == winpos and t == timesteps - 1):
                                    # rhs.append(curr_cel_value == CRATE[1])

                                if (t == timesteps - 1 and ):
                                    rhs.append(level[m + xdiff][n + ydiff][t] == replacements[i][j])
                                    skip.append(tuple((m + xdiff, n + ydiff)))
                                
                                elif (t != timesteps - 1):
                                    rhs.append(curr_cel_value == replacements[i][j])
                                    skip.append(tuple((m + xdiff, n + ydiff)))
                                    # unchanged.append(curr_cel_value == prev_cel_value)

                        if (x, y) in skip:
                            continue
                        else:
                            unchanged_rhs.append(cell_val == level[x][y][t - 1])

                lhs = And(lhs)
                rhs = And(rhs)
                unchanged_rhs = And(unchanged_rhs)
                # unchanged = And(unchanged)

                # If - else geeft nu unsat.
                if (t != timesteps - 1):
                    choice_rule.append(And(lhs, rhs, unchanged_rhs))
                else:
                    last_t.append(And(lhs, rhs, unchanged_rhs))

    if (t == timesteps - 1):
        if (last_t): s.add(AtLeast(*last_t, 1))
        s.add(Sum([If(level[i][j][t] == 2, 1, 0) for j in range(width) for i in range(height)]) == 1)


    if (choice_rule and t != timesteps - 1):
        constraint = (AtLeast(*choice_rule, 1))
    
    s.add(Xor(constraint, And(unchanged)))

newtime = time.time() - timebefore
print(f"Took: {newtime}")

# Now we solve the problem and print the results
if s.check() == sat:
    print("sat")
    m = s.model()
    for t in range(timesteps):
        objects = [[m[level[x][y][t]] for x in range(width)] for y in range(height)]

        print(f"Timestep {t}:")
        for list_objects in objects:
            row_string = " ".join(mapping[num.as_long()] if num is not None and num.as_long() < 4 else "?" for num in list_objects)
            # row_string = " ".join(str(num) if num is not None else "?" for num in list_objects)
            print(row_string)
        print()

    print(f"Took: {time.time() - timebefore - newtime}")
else:
    print("Unsat core:", s.unsat_core())
