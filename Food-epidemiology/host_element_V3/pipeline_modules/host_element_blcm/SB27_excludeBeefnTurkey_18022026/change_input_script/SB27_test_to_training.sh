#!/bin/bash

input_file=$1
output_file=$2

awk 'BEGIN {FS=","; OFS=","} {if ($1 ~ /^"SB27/) {$2 = 1} print}' "$input_file" > "$output_file" 

