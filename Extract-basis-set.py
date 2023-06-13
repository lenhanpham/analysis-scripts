"""
 @author Le Nhan Pham
 @website https://lenhanpham.github.io/
 @create date 2023-06-13 12:12:19
 @modify date 2023-06-13 12:12:19
"""

import sys

def extract_data(text, element):
    """
    Extract basis set for a specific element from the full basis set file.
	This is useful when multiple types of bais sets need to be used like def2-svpd and def2-tzvp
	for different elements

    Args:
        text (str): The text to extract data from.
        element (str): The name of the element to extract data for.

    Returns:
        str: The extracted data as a string.
    """
    data = []
    lines = text.split('\n')
    start = False
    symbol = '-' + element + ' '
    for line in lines:
        if line.startswith(symbol):
            start = True
            data.append(line)
        elif line.startswith('****'):
            start = False
            if data:
                data.append(line)
                break
        elif start:
            data.append(line)
    return '\n'.join(data) + '\n'

# Get the input filename and element name from the command line arguments
filename = sys.argv[1]
element = sys.argv[2]

# Generate the output filename by appending '.txt' to the element name
output_filename = element + '.txt'

# Read the text from the input file
with open(filename, 'r') as f:
    text = f.read()

# Extract the data for the specified element
result = extract_data(text, element)

# Write the extracted data to the output file
with open(output_filename, 'w') as f:
    f.write(result)
