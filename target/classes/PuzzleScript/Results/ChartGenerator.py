import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

# Configure color palette
sns.set_palette("Paired") 

# Specify your directory here
directory = '/Users/dennisvet/Documents/Documents/GitHub/AutomatedPuzzleScript/AutomatedPuzzleScript/src/PuzzleScript/Results/Rules'

for filename in os.listdir(directory):
    if filename.endswith(".csv"): 
        df = pd.read_csv(os.path.join(directory, filename))

        # Print column names for debugging
        print(f"Columns in {filename}: {df.columns}")
        
        if 'rules' not in df.columns or 'level' not in df.columns:
            print(f"Required columns are not found in {filename}. Skipping...")
            continue

        # Get unique levels and rules
        levels = df['level'].unique()
        rules = sorted(df['rules'].unique())  # Sort rules in ascending order

        if len(rules) == 0:
            print(f"No rules found in file {filename}. Skipping...")
            continue

        # Prepare zero-filled dataframe for storing counts
        data = pd.DataFrame(0, index=np.arange(len(levels)), columns=rules)
        data.index = levels

        # Count rule occurrences for each level
        for index, row in df.iterrows():
            data.loc[row['level'], row['rules']] += 1

        # Plotting
        fig, ax = plt.subplots()

        x = np.arange(len(levels)) # label locations

        for i, rule in enumerate(rules):
            if i == 0:
                ax.bar(x, data[rule], label=rule)
            else:
                # Stack bars on top of the previous ones
                ax.bar(x, data[rule], bottom=data[rules[:i]].sum(axis=1), label=rule)

        # Add some text for labels, title
        ax.set_xlabel('Level')
        ax.set_ylabel('Count of Rules')
        ax.set_title('Rules usage by level in file ' + filename)
        ax.set_xticks(x)
        ax.set_xticklabels(levels)
        ax.legend()

        fig.tight_layout()

        # Save the plot
        plt.savefig(f'{filename}.png')

    else:
        print(f"Skipping non-CSV file: {filename}")
