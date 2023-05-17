from z3 import *

# Create a 3x3 grid
grid = [[Int(f"cell_{i}_{j}") for j in range(3)] for i in range(3)]

# Create a solver instance
solver = Solver()

# # Add constraints for walls in the initial grid
# for i in range(3):
#     for j in range(3):
#         solver.add(grid[i][j] >= 0, grid[i][j] < 4)

# solver.add(If(grid[0][0] != 0, grid[0][0] == 0, grid[0][0] == 1))  # Replace top-left cell with a player


# Add the constraints
cell_0_0 = Int('cell_0_0')
cell_0_1 = Int('cell_0_1')
cell_0_2 = Int('cell_0_2')
cell_1_0 = Int('cell_1_0')
cell_1_1 = Int('cell_1_1')
cell_1_2 = Int('cell_1_2')
cell_2_0 = Int('cell_2_0')
cell_2_1 = Int('cell_2_1')
cell_2_2 = Int('cell_2_2')

constraints = [
    cell_0_0 == 0,
    cell_0_1 > 0, cell_0_1 < 4,
    cell_0_2 > 0, cell_0_2 < 4,
    cell_1_0 > 0, cell_1_0 < 4,
    cell_1_1 > 0, cell_1_1 < 4,
    cell_1_2 > 0, cell_1_2 < 4,
    cell_2_0 > 0, cell_2_0 < 4,
    cell_2_1 > 0, cell_2_1 < 4,
    cell_2_2 > 0, cell_2_2 < 4,
]

solver.add(constraints)

print(solver.assertions())

# Solve the initial grid
if solver.check() == sat:
    model = solver.model()
    level = [[model.evaluate(grid[i][j]).as_long() for j in range(3)] for i in range(3)]
    print("Initial grid:")
    for row in level:
        print(row)

    # Modify the grid by substituting a wall with a player
    # solver.add(If(grid[0][0] != 0, grid[0][0] == 0, grid[0][0] == 1))  # Replace top-left cell with a player

    # Solve the modified grid
    if solver.check() == sat:
        model = solver.model()
        level = [[model.evaluate(grid[i][j]).as_long() for j in range(3)] for i in range(3)]
        print("\nGrid with player:")
        for row in level:
            print(row)

        # Move the player two spots to the left
        solver.add(grid[0][0] == 0, grid[0][2] == 1)  # Replace top-left cell with background, top-right cell with a wall

        # Solve the modified grid
        if solver.check() == sat:
            model = solver.model()
            level = [[model.evaluate(grid[i][j]).as_long() for j in range(3)] for i in range(3)]
            print("\nGrid with player moved two spots to the left:")
            for row in level:
                print(row)
        else:
            print("No solution found for the grid with player movement.")
    else:
        print("No solution found for the grid with a player.")
else:
    print("No solution found for the initial grid.")
