from PIL import Image, ImageDraw

import sys
import json

index = json.loads(sys.argv[3])['index']

level_image = Image.open(f"../bin/output_image{index}.png")

color_coded_image = level_image.copy()

# Define the initial red color
color = (0,128,0)
if sys.argv[2] == "0": 
    color = (255, 0, 0)

# Create a drawing object
draw = ImageDraw.Draw(color_coded_image)

data = json.loads(sys.argv[1])

for i in range(len(data)):
    item = data[i]
    x, y = item['x'], item['y']
    
    # Draw the red circle with the updated color
    draw.ellipse([(x * 5 + 1, y * 5 + 1), (x * 5 + 2, y * 5 + 2)], fill=color)


# Save the image
# if index > 1 and sys.argv[4]: os.remove(f"dead_image{index - 1}.png")
color_coded_image.save(f"../bin/path{index}.png", quality=100, subsampling=0)
