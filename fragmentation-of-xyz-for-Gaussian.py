# write a python function to read a text file and then split all lines to words
import sys
import os 

#xyzfile = "Pre-KetylRad-Olefin-0.xyz"
#newxyz = "Pre-KetylRad-Olefin-0-frag.xyz"

xyzfile = sys.argv[1]
newxyz = os.path.splitext(os.path.basename(xyzfile))[0] + "-frag.xyz"

def read_file_split_lines(file_path):
    with open(file_path, 'r') as file:
        lines = [line.split() for line in file.readlines()[2:]]
    return lines

def add_frag(lines, indices, addItems=",1"):
    for index in indices:
        lines[index].append(addItems)
    return lines




lines = read_file_split_lines(xyzfile)
totalAtoms = len(lines)

frag1 = range(0, 26, 1)
frag2 = range(26,totalAtoms,1)

addFrag1 = add_frag(lines, frag1, ",1")
addFrag2 = add_frag(addFrag1, frag2, ",2")

with open(newxyz, 'w') as xyzFrag:
        xyzFrag.write(str(totalAtoms)+"\n")
        xyzFrag.write(newxyz+"\n")
        for line in addFrag2:
            xyzFrag.write("{:<4s}{:>14.7f}{:>14.7f}{:>14.7f}{:>4s}\n".format(str(line[0]), float(line[1]), float(line[2]), float(line[3]), str(line[4])))

