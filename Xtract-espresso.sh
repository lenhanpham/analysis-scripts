#! /bin/bash

##############################################################################################################
# This script is used to extract energies from Quantum Epsresso calculations				     			 #
#      	     											                                                     #
# Output files should have extensions of .out	                                                 	         #
# Author: Le-Nhan Pham Deakin Uni			                                                                 #
##############################################################################################################


# Extraction fucntion
extract()
{
for file_name  in `ls *.out`; do 
	scfenergy=`egrep -a "^\!.*Ry$" $file_name | tail -1 | awk '{print $5}' | grep ".*" | cut -c 1-16`
	optenergy=`egrep -a "^ {4}.*Final.*Ry$" $file_name | tail -1 | awk '{print $4}' | grep ".*" | cut -c 1-16` 


	# Checking output process
	jobdone=`tail -20 $file_name| grep 'JOB DONE.'`
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
	     printf "%35s %21s %21s %8s\n" " $file_name |" "$scfenergy |" "$optenergy |" "$status |"

done 
}



# call function in all available output
awk 'BEGIN {print "             ATTENTION: If both OPT and SP values simultaneously appear in output files,\n                     OPT values are the final energies of optimizations\n"}'
awk 'BEGIN { printf "%35s %21s %21s %8s\n", "Output name |", "      Single SCF    |", "      OPT Energy    |" , "Status |"
             printf "%35s %21s %21s %8s\n", "----------- |", "--------------------|", "--------------------|" , "------ |" }'


# Execution of function

	extract | sort -r -k2 














