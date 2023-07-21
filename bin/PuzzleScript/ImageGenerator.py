from PIL import Image
from PIL import ImageColor

import sys
import json

def convert_data_to_image(data, width, height):
    # Create an empty image canvas

    jsonfile = open('json.txt', 'r')
    line = jsonfile.readlines()[0]

    data = json.loads(line)

    for item in data:
        print(item)

    img = Image.new('RGB', (width, height), color='white')
    pixels = img.load()

    # Map data points to image pixels
    for item in data:
        x, y, color = item['x'], item['y'], ImageColor.getcolor(item['c'], "RGB")
        pixels[x, y] = color  # Set the pixel color based on the data

    return img

# Example data with coordinates and colors
data = [
    {'x': 10, 'y': 20, 'color': (255, 0, 0)},  # Red pixel at (10, 20)
    {'x': 50, 'y': 80, 'color': (0, 255, 0)},  # Green pixel at (50, 80)
    {'x': 50, 'y': 50, 'color': (0, 0, 255)}  # Blue pixel at (100, 150)
]

width = 100
height = 100

# Convert data to image
resulting_image = convert_data_to_image(data, width, height)

# Save the image
resulting_image.save("output_image.png")

# # Optionally, display the image
# resulting_image.show()
