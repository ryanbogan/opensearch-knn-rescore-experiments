#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <key-value_file> <input_file>"
    exit 1
fi

key_value_file="$1"
input_file="$2"

# Read the key-value file and store the data in an associative array
declare -A key_value_dict
while IFS=" = " read -r key value; do
    key_value_dict["$key"]="$value"
done < "$key_value_file"

# Read the input file, replace the lines, and overwrite the input file
temp_file="$(mktemp)"
while read -r line; do
    for key in "${!key_value_dict[@]}"; do
        if [[ "$line" == "$key"* ]]; then
            echo "$key = ${key_value_dict[$key]}"
            continue 2
        fi
    done
    echo "$line"
done < "$input_file" > "$temp_file"

# Overwrite the input file with the modified content
mv "$temp_file" "$input_file"

echo "Input file $input_file has been updated."
