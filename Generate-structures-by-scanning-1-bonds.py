from rdkit import Chem
from rdkit.Chem import AllChem
import numpy as np
import os

# Read the initial molecule
mol_file_name = 'RI.mol'
mol = Chem.MolFromMolFile(mol_file_name, removeHs=False)  # Include hydrogen atoms

# Check the number of atoms in the molecule
num_atoms = mol.GetNumAtoms()
print(f"Number of atoms in the molecule: {num_atoms}")

# Define the atoms that define the bond
halogen = 106
atom1_index = 0   # Index of the first atom defining the bond (Carbon), adjusted to start from 0
atom2_index = min(num_atoms - 1, halogen # Ensure atom index is within range, adjusted to start from 0

# Define the atoms in each fragment
fragment1_atoms = list(range(0, 17))  # Atom indices of fragment 1, adjusted to start from 0
fragment2_atoms = list(range(17, num_atoms))  # Atom indices of fragment 2

# Calculate the vector along the bond
atom1_coords = mol.GetConformer().GetAtomPosition(atom1_index)
atom2_coords = mol.GetConformer().GetAtomPosition(atom2_index)
bond_vector = np.array(atom2_coords) - np.array(atom1_coords)
bond_length = np.linalg.norm(bond_vector)
unit_bond_vector = bond_vector / bond_length

# User-provided starting distance
starting_distance = bond_length

# Extract the filename without extension
mol_filename = os.path.splitext(mol_file_name)[0]

# Loop to increase the distance along the bond
for step in range(20):
    # Calculate the distance for this step
    distance = starting_distance + 0.5 * step

    # Copy the original molecule
    new_mol = Chem.Mol(mol)

    # Calculate the translation vector along the bond
    translation_vector = unit_bond_vector * (distance - bond_length)
    
    # Move fragment 2 along the bond
    for atom_index in fragment2_atoms:
        atom_position = new_mol.GetConformer().GetAtomPosition(atom_index)
        new_position = atom_position + translation_vector
        new_mol.GetConformer().SetAtomPosition(atom_index, new_position)

    # Save the modified molecule coordinates with the original filename as prefix
    output_file_name = f'{mol_filename}_{distance:.3f}.mol'
    Chem.MolToMolFile(new_mol, output_file_name)
