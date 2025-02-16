from PIL import Image, ImageColor
import os
import sys
import json
import traceback

### Functions #################################################################

def log_error(e):
    print("=== ARGS ===\n")
    print(repr(sys.argv[0]) + "\n")
    print(repr(sys.argv[1]) + "\n")
    print(repr(sys.argv[2]) + "\n")
    print("=== ERROR ===\n")
    print(traceback.format_exc() + "\n")

def convert_data_to_image(data, size):
    img = Image.new('RGB', (size['width'] * 5, size['height'] * 5), color='white')
    pixels = img.load()

    for item in data:
        x, y = item['x'], item['y']
        color_code = item['c']
        if color_code == '#------':
            continue
        else:
            color = ImageColor.getcolor(color_code, "RGB")
        pixels[x, y] = color

    return img

### Script ####################################################################

try:
    level_json_path = sys.argv[1]
    rm_prev_img_bool = sys.argv[2]
    
    print("test")

    if level_json_path.startswith("/c:/"):
        level_json_path = level_json_path[1:]

    with open(level_json_path, 'r') as level_json_file:
        level_json = json.loads(level_json_file.read())

    data = level_json['data']
    size = level_json['size']
    index = level_json['index']

    if index > 1 and rm_prev_img_bool: 
        os.remove(f"../bin/output_image{index - 1}.png")

    resulting_image = convert_data_to_image(data, size)
    resulting_image.save(f"../bin/output_image{index}.png", quality=100, subsampling=0)

except Exception as e:
    log_error(e)