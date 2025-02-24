#!/usr/bin/env python3
"""
Enhanced version of OSET-E-gaussian script
Original author: Le Nhan Pham
Python conversion with improvements
"""

import argparse
import math
import glob
import os
from pathlib import Path
import re
from typing import Dict, Tuple, Optional
import sys

# Constants
R = 8.314462618  # J.K-1.mol-1
PO = 101325      # 1 atm in N/m2
KB = 0.000003166811563

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Process Gaussian output files')
    parser.add_argument('-t', '--temp', type=float, default=298.15,
                       help='Temperature in Kelvin (default: 298.15)')
    parser.add_argument('-c', '--cm', type=float, default=1.0,
                       help='Concentration in M (default: 1.0)')
    return parser.parse_args()

def calculate_phase_correction(temp: float, cm: float) -> float:
    """Calculate Gibbs free energy phase correction."""
    c = cm * 1000  # Convert M to mol/m3
    return (R * temp * math.log(c * R * temp / PO) * 0.0003808798033989866 / 1000)

def extract_value(content: str, pattern: str) -> Optional[str]:
    """Extract value using regex pattern from content."""
    if pattern == 'scrf':
        match = re.search(pattern, content)
        return match is not None
    else:
        # Find all matches and take the last one for all patterns
        matches = re.findall(pattern, content)
        return matches[-1] if matches else None

def process_log_file(filepath: str) -> Dict[str, str]:
    """Process a single log file and extract relevant data."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    patterns = {
        'scf': r'SCF Done:.*?=\s*([-]?\d+\.\d+)',
        'scftd': r'Total Energy, E\(CIS/TDA\) =\s*([-]?\d+\.\d+)',
        'scfEqui': r'After PCM corrections, the energy is\s*([-]?\d+\.\d+)',
        'scfLR': r'Total energy after correction\s+=\s*([-]?\d+\.\d+)',  # Updated pattern
        'volume': r'GePol: Cavity volume\s*=\s*(\d+\.\d+)',
        'scrf': r'scrf'
    }
    
    results = {}
    for key, pattern in patterns.items():
        value = extract_value(content, pattern)
        if key == 'scrf':
            results[key] = value
        else:
            results[key] = str(value) if value is not None else ''
    
    # Check completion status
    if 'Normal termination' in content[-1000:]:
        results['status'] = 'DONE'
    elif 'Error termination' in content[-1000:]:
        results['status'] = 'ERROR'
    else:
        results['status'] = 'UNDONE'
    
    # Use TDDFT energy if available
    if results['scftd']:
        results['final_energy'] = results['scftd']
    else:
        results['final_energy'] = results['scf']
    
    # Phase correction check
    results['phase_corr'] = 'YES' if results['scrf'] else 'NO'
    
    return results

def write_output(content: str, file_handle=None):
    """Write content to both stdout and file if provided."""
    print(content, end='')  # Write to terminal
    if file_handle:
        file_handle.write(content)  # Write to file

def natural_sort_key(s):
    """
    Return a key that can be used for natural sorting of strings containing numbers.
    For example: root-1, root-2, root-10 will be sorted correctly instead of root-1, root-10, root-2
    """
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split('([0-9]+)', s)]

def main():
    args = parse_arguments()
    temp, cm = args.temp, args.cm
    
    # Calculate phase correction
    gphase_corr = calculate_phase_correction(temp, cm)
    
    # Output file setup
    output_file = f"{Path.cwd().name}-{temp}.results"
    with open(output_file, 'w', encoding='utf-8') as f:
        # Write header information
        header_info = (
            f"Temperature: {temp} K. Make sure that temperature = {temp} has been used in your input.\n"
            f"The concentration for phase correction: {cm} M or {cm * 1000} mol/m3\n"
            f"Gibbs free correction for phase changing from 1 atm to 1 M: {gphase_corr:.12f} au\n\n"
        )
        write_output(header_info, f)
        
        # Process all log files
        results = []
        log_files = glob.glob("*.log")
        
        # Determine energy label first
        if log_files:
            first_data = process_log_file(log_files[0])
            energy_label = 'E_TD' if first_data.get('scftd') else 'E_SCF'
        else:
            energy_label = 'E_SCF'  # default if no files found
        
        # Write table header with dynamic energy label
        header = f"{'Output name':>100s} {'SCFE PCM corr':>20s} {'SCFE LR corr':>20s} {energy_label:>20s} {'Volume A^3':>20s} {'Status':>10s} {'PCorr':>6s}\n"
        separator = "-" * 196 + "\n"
        write_output(header + separator, f)
        
        # Process all log files
        for log_file in glob.glob("*.log"):
            data = process_log_file(log_file)
            
            # Format filename if too long
            filename = log_file[-99:] if len(log_file) > 99 else log_file
            
            # Prepare row data
            row = {
                'filename': filename,
                'scfEqui': data.get('scfEqui', ''),
                'scfLR': data.get('scfLR', ''),
                'energy': data.get('final_energy', ''),
                'volume': data.get('volume', ''),
                'status': data.get('status', ''),
                'phase_corr': data.get('phase_corr', '')
            }
            results.append(row)
        
        # Sort results using natural sort
        for row in sorted(results, key=lambda x: natural_sort_key(x['filename'])):
            output_line = (f"{row['filename']:>100s} {row['scfEqui']:>20s} {row['scfLR']:>20s} "
                         f"{row['energy']:>20s} {row['volume']:>20s} {row['status']:>10s} "
                         f"{row['phase_corr']:>6s}\n")
            write_output(output_line, f)

if __name__ == "__main__":
    main()
