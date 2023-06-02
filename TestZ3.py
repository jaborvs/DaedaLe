from z3 import *

# Create a Z3 solver
s = Optimize()  # use an optimizing solver to minimize the number of timesteps

# Define the size of the array and the number of timesteps
array_size = 3
max_timesteps = 10  # maximum number of timesteps (to be minimized)

# Create variables for the position of the "1" (player) and the "2" (crate) in the array at each timestep
player_positions = [(Int(f'player_row_{t}'), Int(f'player_col_{t}')) for t in range(max_timesteps)]
crate_positions = [(Int(f'crate_row_{t}'), Int(f'crate_col_{t}')) for t in range(max_timesteps)]
player_row, player_col = zip(*player_positions)
crate_row, crate_col = zip(*crate_positions)

# Define the initial position and the final position for the player and the crate
initial_player_position = (0, 0)
initial_crate_position = (0, 1)
final_player_position = (2, 2)
final_crate_position = (2, 1)

# Add constraints for the initial position and the final position for the player and the crate
s.add(player_row[0] == initial_player_position[0], player_col[0] == initial_player_position[1])
s.add(crate_row[0] == initial_crate_position[0], crate_col[0] == initial_crate_position[1])
s.add(player_row[max_timesteps - 1] == final_player_position[0], player_col[max_timesteps - 1] == final_player_position[1])
s.add(crate_row[max_timesteps - 1] == final_crate_position[0], crate_col[max_timesteps - 1] == final_crate_position[1])

# Define the movement rules for the player (in all directions) and the crate-pushing rule
movement_rules = [(0, 1), (1, 0), (0, -1), (-1, 0)]  # each rule is a pair (delta_row, delta_col)

# Add constraints for the movement rules and the crate-pushing rule
for t in range(max_timesteps - 1):
    s.add(Or([
        # Movement rules for the player (in all directions)
        And(player_row[t + 1] == player_row[t] + rule[0], 
            player_col[t + 1] == player_col[t] + rule[1], 
            crate_row[t + 1] == crate_row[t], 
            crate_col[t + 1] == crate_col[t])
        for rule in movement_rules
    ] + [
        # Crate-pushing rule
        And(
            player_row[t + 1] == crate_row[t], 
            player_col[t + 1] == crate_col[t],  # player moves to the crate's position
            crate_row[t + 1] == crate_row[t] + rule[0], 
            crate_col[t + 1] == crate_col[t] + rule[1],  # crate is pushed in the direction of the movement
            player_row[t] + rule[0] == crate_row[t], 
            player_col[t] + rule[1] == crate_col[t]  # player is adjacent to the crate
        ) for rule in movement_rules
    ]))

# Minimize the number of timesteps by introducing an additional variabletimesteps = Int('timesteps')
timesteps = Int('timesteps')
s.add(timesteps >= 0, timesteps <= max_timesteps)
s.add(Or([And(player_row[t] == final_player_position[0], player_col[t] == final_player_position[1], timesteps == t) for t in range(max_timesteps)]))
s.minimize(timesteps)

# Check if there is a solution
if s.check() == sat:
    print('Solution found:')
    m = s.model()
    print(f'Timesteps: {m.evaluate(timesteps)}')
    for t in range(m.evaluate(timesteps)):
        print(f'Timestep {t}: Player ({m.evaluate(player_row[t])}, {m.evaluate(player_col[t])}), Crate ({m.evaluate(crate_row[t])}, {m.evaluate(crate_col[t])})')
else:
    print('No solution found.')
