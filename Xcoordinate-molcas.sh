#! /bin/bash
#####################################################################################
# This script is used to extract coordinates of molecules from Molcas calculation   #
# Output files should have extensions of .out or .log    			    #
# Change the NR and tail -n to appropriate value for your situation                 #
# Author: Le-Nhan Pham Univeristy of Dalat Vietnam				    #
#####################################################################################

# Definition of extraction fucntion. 

coordinate() 
{
awk '/Cartesian\ coordinates\ in\ Angstrom:/{p=1}p{print}/Nuclear\ repulsion\ energy\ |close/{p=0}' $file_name | tail -10 | awk '/Cartesian\ coordinates\ in\ Angstrom:/{p=1}p{print}/Nuclear\ repulsion\ energy\ |close/{p=0}' | awk 'NR>=5 && NR<=8 { print }'
}


#Execute extraction function

echo 'Coordinates extracted from Molcas calculation usually from optimization calculations'
echo 'Change the NR and tail -n to appropriate values in the script for your situation '

for file_name in $(ls *.log); do
	echo $file_name
	coordinate
done

for file_name in $(ls *.out); do
	echo $file_name
	coordinate
done
