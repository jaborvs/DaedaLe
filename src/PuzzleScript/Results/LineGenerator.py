import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

# Specify the directory where the CSV files are located
directory = '/Users/dennisvet/Documents/Documents/GitHub/automatedpuzzlescript/Tutomate/automatedpuzzlescript/Tutomate/src/PuzzleScript/Results/Countables'

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
        # plt.plot(df['level'], df['messages'], 'd-', label='messages')

        # Add labels, legend, and grid
        plt.xlabel('Level', fontsize=18)
        plt.ylabel('Amount', fontsize=18)
        plt.title('{}'.format(filename), fontsize=22)
        plt.legend(loc='best', fontsize=15)
        plt.grid(True)

        # Set the x-axis tick increment to 1
        plt.xticks(np.arange(min(df['level']), max(df['level'])+1, 1.0))

        # Save the plot
        plt.savefig('Countables/plot_{}.png'.format(filename.split('.')[0]), bbox_inches='tight')
        plt.close() # close the figure
