from PIL import Image
import sys
import json

def convert_data_to_image(data, width, height):
    # Create an empty image canvas

    new_data = json.loads(sys.argv[1])

    # Access the elements in the nested lists

    for pixel in new_data:
        print(pixel['x'])
        print(pixel['y'])
        print(pixel['color'])

    # inner_list = outer_list[1][0][1]            # [["list",[["int",0],["int",1],["str","red"]]]]
    # int1 = inner_list[0][1]                     # ["int",0]
    # int2 = inner_list[1][1]                     # ["int",1]
    # string_value = inner_list[2][1]             # ["str","red"]

    # print(string_value)

    # # Extract the actual values from the elements
    # int1_value = int(int1[1])                   # 0 (converted to int)
    # int2_value = int(int2[1])                   # 1 (converted to int)
    # string_value = string_value[1]              # "red"

    # # Print the extracted values
    # print("Integer 1:", int1_value)
    # print("Integer 2:", int2_value)
    # print("String:", string_value)


    return
    img = Image.new('RGB', (width, height), color='white')
    pixels = img.load()

    # Map data points to image pixels
    for item in data:
        x, y, color = item['x'], item['y'], item['color']
        pixels[x, y] = tuple(color)  # Set the pixel color based on the data

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

# # Save the image
# resulting_image.save("output_image.png")

# # Optionally, display the image
# resulting_image.show()
