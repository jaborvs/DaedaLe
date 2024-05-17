from PIL import Image
from PIL import ImageColor

import os
import sys
import json

def convert_data_to_image():
    with open(sys.argv[1], 'r') as data_file:
        data = json.loads(data_file.read())
    size = json.loads(sys.argv[2])

    img = Image.new('RGBA', (size['width'] * 5, size['height'] * 5), color='white')
    pixels = img.load()

    for item in data:
        x, y = item['x'], item['y'] 
        color_code = item['c']
        if color_code == '......':
            continue
        else:
            color = ImageColor.getcolor(color_code, "RGB")
        pixels[x, y] = color

    return img


index = json.loads(sys.argv[3])['index']
resulting_image = convert_data_to_image()

if index > 1 and sys.argv[4]: os.remove(f"../bin/output_image{index - 1}.png")
resulting_image.save(f"../bin/output_image{index}.png", quality=100, subsampling=0)