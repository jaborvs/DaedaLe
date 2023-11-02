#!/bin/sh

json_string="$1"
win="$2"
index="$3"

echo "Executing bash file"

python3 PathGenerator.py "$json_string" "$win" "$index"