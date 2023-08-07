from PIL import Image
from PIL import ImageColor

import os
import sys
import json

def convert_data_to_image():

    data = json.loads(sys.argv[1])
    size = json.loads(sys.argv[2])

    img = Image.new('RGB', (size['width'] * 5, size['height'] * 5), color='white')
    pixels = img.load()

    # Map data points to image pixels
    for item in data:
        x, y, color = item['x'], item['y'], ImageColor.getcolor(item['c'], "RGB")
        pixels[x, y] = color  # Set the pixel color based on the data

    return img


# Convert data to image
index = json.loads(sys.argv[3])['index']
resulting_image = convert_data_to_image()

# resulting_image = resulting_image.resize((300,300), Image.BICUBIC)

# Save the image
if index > 1: os.remove(f"Interface/output_image{index - 1}.png")
resulting_image.save(f"Interface/output_image{index}.png", quality=100, subsampling=0)

# # Optionally, display the image
# resulting_image.show()
