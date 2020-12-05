#! /bin/bash

##############################################################################################################
# This script is used to extract energies from Molpro single point calculations rccsd(t), rks, uks, mrci      #
# nevpt2 and optimization energy at levels of restricted DFT and unrestricted DFT (rks and uks)    	          #
# Output files should have extensions of .out	                                                 	          #
# Author: Le-Nhan Pham Univeristy of Dalat Vietnam	https://lenhanpham.github.io/                             #
##############################################################################################################


# Extraction fucntion
extract()
{
	rccsdt=`grep "\!RHF-RCCSD(T) energy" $file_name | head -1 | awk '{print $3}' | grep ".*" | cut -c 1-16`
	f12a=`grep "!RHF-RCCSD(T)-F12a energy" $file_name | tail -1 | awk '{print $3}' | grep ".*" | cut -c 1-16`
	rccsdtdk=`grep "\!RHF-RCCSD(T) energy" $file_name | tail -1 | awk '{print $3}' | grep ".*" | cut -c 1-16`
	rccsdtdk_f12=`echo "scale=8; $f12a + ($rccsdtdk - $rccsdt)" | bc`

	# Checking output process
	jobdone=`tail -1 $file_name| grep 'diagnostic completed successfully'`
	if [ "not$jobdone" == "not" ]; then
		jobdone=`tail -20 $file_name| grep ?Error`
		if [ "not$jobdone" != "not" ]; then
	                status="ERROR"
		else
		jobdone=`tail -20 $file_name| grep ERROR`
			if [ "not$jobdone" != "not" ]; then
	                status="ERROR"
			else		
			status="CHECK"
			fi
		fi
	else
		status="OK!"
	fi

	# print out extracted values including file_name
	     printf "%25s %18s %18s %18s %18s %8s\n" " $file_name |" "$rccsdt |" "$f12a |" "$rccsdtdk |" "$rccsdtdk_f12 |" "$status |"
}



# call function in all available output
awk 'BEGIN {print "                   Energies calculated from RCCSD(T), RCCSD(T)-F12a and RCCSD(T)-DK\n"}'
awk 'BEGIN { printf "%25s %18s %18s %18s %18s %8s\n", "Output name |", "        RCCSD(T) |", "   RCCSD(T)-F12a |" , "     RCCSD(T)-DK |", "RCCSD(T)-F12a-DK |", "Status |"
             printf "%25s %18s %18s %18s %18s %8s\n", "----------- |", "-----------------|", "-----------------|" , "-----------------|", "-----------------|", "------ |" }'


# Execution of function
for file_name  in `ls *.out`; do
	extract
done













