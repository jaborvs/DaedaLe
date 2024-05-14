from PIL import Image
from PIL import ImageColor

import os
import sys
import json

def convert_data_to_image():

    with open(sys.argv[1], 'r') as data_file:
        data = json.loads(data_file.read())
    size = json.loads(sys.argv[2])

    img = Image.new('RGB', (size['width'] * 5, size['height'] * 5), color='white')
    pixels = img.load()

    for item in data:
        x, y, color = item['x'], item['y'], ImageColor.getcolor(item['c'], "RGB")
        pixels[x, y] = color

    return img
print('hello')
index = json.loads(sys.argv[3])['index']
resulting_image = convert_data_to_image()

if index > 1 and sys.argv[4]: os.remove(f"../bin/output_image{index - 1}.png")
resulting_image.save(f"../bin/output_image{index}.png", quality=100, subsampling=0)