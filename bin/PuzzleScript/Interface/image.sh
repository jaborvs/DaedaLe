#!/bin/sh

json_string='$1'
size='$2'
index='$3'
remove='$4'

python3 ImageGenerator.py '$json_string' '$size' '$index' '$remove'