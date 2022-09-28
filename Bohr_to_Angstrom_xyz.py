#!/usr/bin/env python3
import sys

BOHR_TO_ANGSTROM = 0.52917721067

def get_lines(filename):

    f = open(filename, "r")
    lines = f.readlines()
    f.close()

    # All you "with"-haters can go fly a kite! :D
    return lines

def coordlines_to_data(line):

    tokens = line.split()

    x = float(tokens[1]) * BOHR_TO_ANGSTROM
    y = float(tokens[2]) * BOHR_TO_ANGSTROM
    z = float(tokens[3]) * BOHR_TO_ANGSTROM
    atom_type = tokens[0].title() 

    return (atom_type, x, y, z)


if __name__ == "__main__":

    coord_filename = sys.argv[1]

    lines = get_lines(coord_filename)

    #print(len(lines) - 1)
    #print(".xyz output generated from file:", coord_filename)
    print(lines[0], end = "")
    for line in lines[1:]:
        (atom_type, x, y, z) = coordlines_to_data(line)
        print(" %-2s    %20.12f %20.12f %20.12f" % (atom_type, x, y, z))