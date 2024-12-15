#!/bin/bash

# Define the output file
output_file="python_catalog_list.txt"

# Clear the output file if it already exists
> "$output_file"

# Use find to locate all .py files in the current directory and one level of subdirectories
find . -maxdepth 2 -type f -name "*.py" | while read -r file; do
    # Write the full path of each Python file to the output file
    echo "$file" >> "$output_file"
done

echo "Python scripts have been cataloged in $output_file"
