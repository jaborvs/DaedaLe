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
width = 10
height = 10
timesteps = 10
playerpos = (1, 1)
winpos = (2, 2)

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

    new_playerpos = (0, 0)

    choice_rule = []

    last_t = []

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

                        # print(f"len lhs = {len(lhs)} and pattern = {len(pattern)}")

                        for j, (xdiff, ydiff, obj) in enumerate(pattern):

                            # Check if pattern fits at player position
                            if m + xdiff < width and n + ydiff < height and len(lhs) != len(pattern):

                                skip.append(tuple((m + xdiff, n + ydiff)))

                                lhs.append(level[m + xdiff][n + ydiff][t - 1] == obj)
                                unchanged.append(
                                    level[m + xdiff][n + ydiff][t]
                                    == level[m + xdiff][n + ydiff][t - 1]
                                )

                                if ((m + xdiff, n + ydiff) == winpos and t == timesteps - 1):
                                    rhs.append(level[m][n][t] == PLAYER[1])
                                else:
                                    rhs.append(
                                        level[m + xdiff][n + ydiff][t]
                                        == replacements[i][j]
                                    )

                        if (x, y) in skip:
                            continue
                        else:
                            unchanged_rhs.append(level[x][y][t] == level[x][y][t - 1])

                # print(f"{lhs}\n\n\n")
                # print(f"{rhs}\n\n\n")
                # print(f"{unchanged}\n\n\n")
                # print(f"{unchanged_rhs}\n\n\n")

                # if (t == timesteps - 1):
                #     print(f"Last timesteps lhs = {lhs}\nrhs = {rhs}\n unchanged rhs = {unchanged_rhs}\n\n")

                lhs = And(lhs)
                rhs = And(rhs)
                unchanged_rhs = And(unchanged_rhs)
                unchanged = And(unchanged)

                # If and else makes unsat for now...
                if (t != timesteps - 1):
                    choice_rule.append(
                        Or(
                            And(lhs, rhs, unchanged_rhs),
                            And(Not(lhs), unchanged, unchanged_rhs),
                        )
                    )

    #             break
    #         break
    #     break
    # break
                else:
                    choice_rule.append(And(lhs, rhs, unchanged_rhs))

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
