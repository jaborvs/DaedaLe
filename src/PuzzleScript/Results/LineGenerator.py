import pandas as pd
import matplotlib.pyplot as plt
import os

# Specify the directory where the CSV files are located
directory = '/Users/dennisvet/Documents/Documents/GitHub/AutomatedPuzzleScript/AutomatedPuzzleScript/src/PuzzleScript/Results/Countables'

# Use a style for the plots
plt.style.use('seaborn-darkgrid')

# Loop through all CSV files in the directory
for filename in os.listdir(directory):
    if filename.endswith('.csv'):
        filepath = os.path.join(directory, filename)
        
        # Read the CSV file into a DataFrame
        df = pd.read_csv(filepath)
        
        plt.figure(figsize=(10,6))

        # Plot 'size', 'moveable_objects', and 'messages' against 'level'
        plt.plot(df['level'], df['size'], 'o-', label='size')
        plt.plot(df['level'], df['moveable_objects'], 's-', label='moveable_objects')
        plt.plot(df['level'], df['messages'], 'd-', label='messages')

        # Add labels, legend, and grid
        plt.xlabel('Level', fontsize=12)
        plt.ylabel('Value', fontsize=12)
        plt.title('Line plots of size, moveable objects, and messages against level for file {}'.format(filename), fontsize=14)
        plt.legend(loc='best', fontsize=10)
        plt.grid(True)

        # Save the plot
        plt.savefig('plot_{}.png'.format(filename.split('.')[0])) # save as PNG
        plt.close() # close the figure
