#! /bin/bash
##############################################################################################################
# This script is used to extract energies from Gaussian calculations				     			         #
#      	     											                                                     #
# Output files should have extensions of .out	                                                 	         #
# Author: Le-Nhan Pham Deakin Uni	https://lenhanpham.github.io/                                            #
##############################################################################################################

# function for data extraction
extract()
{
       	scf=$(grep "SCF Done" $file_name | tail -1 | awk '{print $5}')
	zpe=$(grep "Zero-point correction" $file_name |tail -1  | awk '{print $3}')
	tcg=$(grep "Thermal correction to Gibbs Free Energy" $file_name |tail -1|awk '{print $7}')
	etg=$(grep "Sum of electronic and thermal Free Energies" $file_name | tail -1|awk '{print $8}')
	ezpe=$(grep "Sum of electronic and zero-point Energies" $file_name | tail -1|awk '{print $7}')
#	lf=$(grep "Low frequencies" $file_name | tail -1 |awk '{print $4}'` # | sed s/-//)
	lf=$(grep "Frequencies" $file_name | head -1 |awk '{print $3}')

	# check status of output
	n=$(tail -10 $file_name|grep Normal)
	if [ "k$n" == "k" ]; then
		n=$(tail -10 $file_name|grep Error)
		if [ "k$n" != "k" ]; then
	                askt="ERROR"
		else
			askt="UNFINISHED"
		fi
	else
		askt="DONE"
	fi

	# print out deserved information
	printf "%40s %15s %20s %15s %15s %15s %15s\n" "$file_name"  "$ezpe" "$scf" "$zpe" "$etg" "$lf" "$askt"

	
}

# call function in all available output
awk 'BEGIN { printf "%40s %15s %20s %15s %15s %15s %15s\n", "Output name", "E+ZPE", "SCFE",  "ZPE",  "ETG",  "Low FC",  "Status"
             printf "%40s %15s %20s %15s %15s %15s %15s\n", "-----------", "-----","----", "----", "---",  "-------", "------" }'

#for file_name  in `ls *.out`; do
#	extract
#done
#echo " "
for file_name  in `ls *log`; do
        extract
done

exit 0












