#!/bin/sh

json_string="$1"
size="$2"
index="$3"

python3 ImageGenerator.py "$json_string" "$size" "$index"