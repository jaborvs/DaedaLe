from PIL import Image, ImageDraw

import sys
import json

index = json.loads(sys.argv[3])['index']

level_image = Image.open(f"output_image{index}.png")

color_coded_image = level_image.copy()

# Define the initial red color
red_color = (255, 0, 0)

# Create a drawing object
draw = ImageDraw.Draw(color_coded_image)

data = json.loads(sys.argv[1])
size = json.loads(sys.argv[2])

for i in range(len(data)):
    item = data[i]
    x, y = item['x'], item['y']
    
    # Make the red color darker for each step
    alpha = int(255 * (i / len(data)))  # Adjust alpha based on the step
    red_color = (red_color[0], red_color[1], red_color[2], alpha)
    
    # Draw the red circle with the updated color
    draw.ellipse([(x * 5 + 1, y * 5 + 1), (x * 5 + 2, y * 5 + 2)], fill=red_color)

# Save the image
color_coded_image.save(f"dead_image{index}.png", quality=100, subsampling=0)
