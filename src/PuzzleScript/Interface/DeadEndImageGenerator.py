from PIL import Image
from PIL import ImageColor
from PIL import ImageDraw

import os
import sys
import json

index = json.loads(sys.argv[3])['index']

level_image = Image.open(f"output_image{index}.png")

color_coded_image = level_image.copy()

# Define colors for dead-ends and winning paths
dead_end_color = (255, 0, 0)
# winning_path_color = (0, 255, 0)  # Green

# Create a drawing object
draw = ImageDraw.Draw(color_coded_image)


data = json.loads(sys.argv[1])
size = json.loads(sys.argv[2])

for item in data:
    x, y = item['x'], item['y']
    draw.ellipse([(x * 5 + 1, y * 5 + 1), (x * 5 + 2, y * 5 + 2)], fill=dead_end_color)

# Save the image
# if index > 1: os.remove(f"output_image{index - 1}.png")
color_coded_image.save(f"dead_image{index}.png", quality=100, subsampling=0)

# # Optionally, display the image
# resulting_image.show()
