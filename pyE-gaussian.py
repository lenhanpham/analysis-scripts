#!/usr/bin/env python3
"""
Gaussian Output Data Extractor

This script extracts thermodynamic data from Gaussian `.log` files, calculates Gibbs free energy,
and writes the results to both the terminal and a file. The output includes key properties such as
electronic energy, zero-point energy, thermal corrections, and phase correction terms.

Author: (adapted to Python from the bash script by AI)
Affiliation: Flinders University
Date: [Today's Date]
Version: 1.0

Usage:
    python script.py -t TEMPERATURE -c CONCENTRATION -col COLUMN

Arguments:
    -t, --temp       Temperature in Kelvin (default: 298.15 K)
    -c, --cm         Concentration in M (default: 1 M)
    -col, --column   Column to sort by (default: 2)

Output:
    Results are written to `<current_directory>.results` and displayed on the terminal.
    The output includes:
        - File name
        - Gibbs free energy in kJ/mol
        - Lowest frequency
        - Gibbs free energy in Hartree
        - Nuclear repulsion energy
        - SCF energy
        - Zero-point energy
        - Status (DONE/ERROR/UNDONE)
        - Phase correction flag (YES/NO)
        - Number of Gaussian rounds

Dependencies:
    - Python 3.x
    - Standard libraries: os, re, math, argparse, sys

Notes:
    - Ensure all `.log` files are in the current directory.
    - The script assumes standard Gaussian output formatting.
"""
import os
import re
import math
from argparse import ArgumentParser
import sys
import time
from datetime import datetime

# Constants
R = 8.314462618  # J/K/mol
Po = 101325  # 1 atm in N/m^2
kB = 0.000003166811563  # Boltzmann constant in Hartree/K

def parse_args():
    parser = ArgumentParser(description="Extract Gaussian output data.")
    parser.add_argument("-t", "--temp", type=float, default=298.15, help="Temperature in Kelvin (default: 298.15)")
    parser.add_argument("-c", "--cm", type=float, default=1, help="Concentration in M (default: 1)")
    parser.add_argument("-col", "--column", type=int, default=2, help="Column to sort by (default: 2)")
    return parser.parse_args()

def extract(file_name, temp, C, Po):
    start_time = time.time()
    
    # Pre-compile regex patterns for better performance
    scf_pattern = re.compile(r"SCF Done.*?=\s+(-?\d+\.\d+)")
    freq_pattern = re.compile(r"Frequencies\s+--\s+(.*)")
    
    file_read_start = time.time()
    # Read file content more efficiently
    with open(file_name, "r") as f:
        content = []
        copyright_count = 0
        scf = zpe = tcg = etg = ezpe = nucleare = None
        scfEqui = scftd = None
        negative_freqs = []
        positive_freqs = []
        status = "UNDONE"
        phaseCorr = "NO"
        
        # Store all SCF values to get the last one
        scf_values = []
        
        for line in f:
            # Only store last 10 lines for status check
            content.append(line)
            if len(content) > 10:
                content.pop(0)
                
            # Count copyright lines while reading
            if "Copyright" in line:
                copyright_count += 1
                
            # Use regex for faster pattern matching
            if "SCF Done" in line:
                match = scf_pattern.search(line)
                if match:
                    scf_values.append(float(match.group(1)))
            elif "Total Energy, E(CIS" in line:
                scftd = float(line.split()[4])
            elif "After PCM corrections, the energy is" in line:
                scfEqui = float(line.split()[6])
            elif "Zero-point correction" in line:
                zpe = float(line.split()[2])
            elif "Thermal correction to Gibbs Free Energy" in line:
                tcg = float(line.split()[6])
            elif "Sum of electronic and thermal Free Energies" in line:
                etg = float(line.split()[7])
            elif "Sum of electronic and zero-point Energies" in line:
                ezpe = float(line.split()[6])
            elif "nuclear repulsion energy" in line:
                nucleare = float(line.split()[3])
            elif "Frequencies" in line:
                match = freq_pattern.search(line)
                if match:
                    # Split and convert frequencies to float
                    freqs = [float(x) for x in match.group(1).split()]
                    # Separate negative and positive frequencies
                    for freq in freqs:
                        if freq < 0:
                            negative_freqs.append(freq)
                        else:
                            positive_freqs.append(freq)
            elif "Kelvin.  Pressure" in line:
                temp = float(line.split()[1])
            elif "scrf" in line:
                phaseCorr = "YES"
    
    file_read_time = time.time() - file_read_start

    calc_start = time.time()
    # Get the last SCF value
    scf = scf_values[-1] if scf_values else None
    
    # Get the lowest frequency following the bash script logic
    if negative_freqs:
        # Get the last negative frequency if any exist
        lf = negative_freqs[-1]
    else:
        # Get the smallest positive frequency if no negative frequencies
        lf = min(positive_freqs) if positive_freqs else 0
    
    # Set defaults and calculate values
    scf = scfEqui if scfEqui else (scftd if scftd else scf)
    etg = etg or 0.0
    nucleare = nucleare or 0
    zpe = zpe or 0
    temp = temp or args.temp

    # Phase correction
    try:
        GphaseCorr = R * temp * math.log(C * R * temp / Po) * 0.0003808798033989866 / 1000
    except ValueError:
        GphaseCorr = 0.0

    GibbsFreeHartree = etg + GphaseCorr if phaseCorr == "YES" and etg != 0.0 else etg
    etgkj = GibbsFreeHartree * 2625.5002

    # Determine status
    if any("Normal termination" in line for line in content):
        status = "DONE"
    elif any("Error termination" in line for line in content):
        status = "ERROR"

    # Format filename
    if len(file_name) > 53:
        file_name = file_name[-53:]
    
    calc_time = time.time() - calc_start
    total_time = time.time() - start_time

    return (f"{file_name:>53} {etgkj:>18.6f} {lf:>10.2f} {GibbsFreeHartree:>18.6f} "
            f"{nucleare:>18.6f} {scf:>18.6f} {zpe:>10.6f} {status:>8} {phaseCorr:>6} "
            f"{copyright_count:>6}\n", file_read_time, calc_time, total_time)

def main():
    start_time = time.time()
    args = parse_args()
    C = int(args.cm * 1000)

    # Get current directory name once
    output_filename = f"{os.path.basename(os.getcwd())}.results"
    if os.path.exists(output_filename):
        os.remove(output_filename)

    # Use list comprehension for better performance
    file_search_start = time.time()
    log_files = [f for f in os.listdir() if f.endswith(".log")]
    file_search_time = time.time() - file_search_start
    
    if not log_files:
        print("No .log files found in the current directory.")
        sys.exit(1)

    # Process files and sort results
    processing_start = time.time()
    results = [extract(f, args.temp, C, Po) for f in log_files]
    processing_time = time.time() - processing_start
    
    # Separate timing data from results
    output_lines = [r[0] for r in results]
    file_read_times = [r[1] for r in results]
    calc_times = [r[2] for r in results]
    total_file_times = [r[3] for r in results]
    
    sorting_start = time.time()
    try:
        output_lines.sort(key=lambda x: float(x.split()[args.column - 1]))
    except ValueError:
        print(f"Warning: Sorting failed for column {args.column}. Ensure the column contains numeric values.")
    sorting_time = time.time() - sorting_start

    # Write output efficiently
    writing_start = time.time()
    header = f"{'Output name':>53} {'ETG kJ/mol':>18} {'Low FC':>10} {'ETG a.u':>18} {'Nuclear E au':>18} {'SCFE':>18} {'ZPE ':>10} {'Status':>8} {'PCorr':>6} {'Round':>6}\n"
    separator = f"{'-' * 53:>53} {'-' * 18:>18} {'-' * 10:>10} {'-' * 18:>18} {'-' * 18:>18} {'-' * 18:>18} {'-' * 10:>10} {'-' * 8:>8} {'-' * 6:>6} {'-' * 6:>6}\n"

    with open(output_filename, "w") as f:
        f.write(header + separator + "".join(output_lines))

    print(header + separator + "".join(output_lines))
    print(f"Results written to {output_filename}")
    writing_time = time.time() - writing_start
    
    total_time = time.time() - start_time
    
    # Print timing information
    print("\nPerformance Statistics:")
    print(f"Total execution time: {total_time:.4f} seconds")
    print(f"File search time: {file_search_time:.4f} seconds")
    print(f"File processing time: {processing_time:.4f} seconds")
    print(f"Sorting time: {sorting_time:.4f} seconds")
    print(f"Writing time: {writing_time:.4f} seconds")
    print("\nPer-file averages:")
    print(f"Average file read time: {sum(file_read_times)/len(file_read_times):.4f} seconds")
    print(f"Average calculation time: {sum(calc_times)/len(calc_times):.4f} seconds")
    print(f"Average total processing time per file: {sum(total_file_times)/len(total_file_times):.4f} seconds")
    print(f"Number of files processed: {len(log_files)}")

if __name__ == "__main__":
    main()
