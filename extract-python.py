
#!/usr/bin/env python
import os
import re
import math
import csv
import glob

# Compile regular expressions once
scf_pattern = re.compile(r"SCF Done")
zpe_pattern = re.compile(r"Zero-point correction")
tcg_pattern = re.compile(r"Thermal correction to Gibbs Free Energy")
etg_pattern = re.compile(r"Sum of electronic and thermal Free Energies")
ezpe_pattern = re.compile(r"Sum of electronic and zero-point Energies")
lf_pattern = re.compile(r"Frequencies")
scrf_pattern = re.compile(r"scrf")

def extract(file_name):
    with open(file_name) as f:
        scf = None
        zpe = None
        tcg = None
        etg = None
        ezpe = None
        lf = None
        scrf = None
        for line in f:
            if scf_pattern.search(line):
                scf = line.split()[4]
            elif zpe_pattern.search(line):
                zpe = line.split()[2]
            elif tcg_pattern.search(line):
                tcg = line.split()[6]
            elif etg_pattern.search(line):
                etg = line.split()[7]
            elif ezpe_pattern.search(line):
                ezpe = line.split()[6]
            elif lf_pattern.search(line) and not lf:
                lf = line.split()[2]
            elif scrf_pattern.search(line) and not scrf:
                scrf = line[:5]
        if not scrf:
            GibbsFreeHartree = etg
            phaseCorr = "NO"
        else:
            # Add a check to make sure etg is not None
            if etg is not None:
                GibbsFreeHartree = "{:.8f}".format(float(etg) + 0.003031803235)[:16]
            else:
                GibbsFreeHartree = None
            phaseCorr = "YES"

        if GibbsFreeHartree is not None:
            etgev = "{:.8f}".format(float(GibbsFreeHartree) * 27.211396641308)[:16]
            etgkj = "{:.8f}".format(float(GibbsFreeHartree) * 2625.5002)[:16]
        else:
            etgev = None
            etgkj = None

        n = None
        for line in f:
            if "Normal" in line:
                n = line
            elif "Error" in line:
                n = line
        if not n:
            askt = "UNDONE"
        elif "Error" in n:
            askt = "ERROR"
        else:
            askt = "DONE"
        return [file_name, etgkj, lf, GibbsFreeHartree, etg, etgev, scf, zpe, askt, phaseCorr]

# Use a generator to yield the results
def extractE():
    for file_name in glob.glob("*.log"):
        yield extract(file_name)

# Use the csv module to write the results to a file
with open(os.path.basename(os.getcwd()) + ".results", "w") as f:
    writer = csv.writer(f, delimiter=" ")
    for result in sorted(extractE(), key=lambda x: x[1]):
        writer.writerow(result)
