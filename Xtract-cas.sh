#! /bin/bash

#####################################################################################
# This script is used to extract CASPT2 energies of roots n (n=1-4) from Molcas.    #
# Output files should have extensions of .out or .log                               #
# Author: Le-Nhan Pham Univeristy of Dalat Vietnam				    #
#####################################################################################



#Check status functions through status files

checkstatus()
{
       	# concatenate the status file and the output file if the calculations are successful 
	landing_output=`tail -5 $file_name | grep "Happy landing "`
	
        if [ -f ${file_name%.*}.status ]; then
	        landing_status=`tail -1 ${file_name%.*}.status | grep "Happy landing"`
		if [ "$landing_status" == "Happy landing " ] && [ "$landing_status" != "$landing_output" ] ; then 
			echo "$landing_status" >> $file_name
		fi
	fi
}



# Extraction fucntion


extract()
{
	caspt2r1=`grep "CASPT2 Root  1" $file_name | tail -1 | awk '{print $7}'`
	caspt2r2=`grep "CASPT2 Root  2" $file_name | tail -1 | awk '{print $7}'`
	caspt2r3=`grep "CASPT2 Root  3" $file_name | tail -1 | awk '{print $7}'`
	caspt2r4=`grep "CASPT2 Root  4" $file_name | tail -1 | awk '{print $7}'`
	mcpdft=`grep "Total MC-PDFT energy" $file_name | tail -1 | awk '{print $4}'`
	lowest_freq=`grep "Frequency:" $file_name | tail -1 | awk '{print $2}'`


	# Checking output process
	jobdone=`tail -20 $file_name| grep 'Happy landing'`
	if [ "not$jobdone" == "not" ]; then
		jobdone=`tail -20 $file_name| grep Error`
		if [ "not$jobdone" != "not" ]; then
	                status="ERROR"
		else
			status="CHECK"
		fi
	else
		status="OK!"
	fi

	# Check number of roots in CASPT2 calculations
	num_of_root=$(grep "CASPT2 Root" $file_name |tail -1| awk '{print $4}')

	# print out extracted values including file_name
	     printf "%25s %5s %16s %16s %16s %16s %16s %13s %7s\n" " $file_name |" "$num_of_root |" "$caspt2r1 |" "$caspt2r2 |" "$caspt2r3 |" "$caspt2r4 |" "$mcpdft |" "$lowest_freq |" "$status |"
}



# call function in all available output
awk 'BEGIN {print "         ATTENTION: If there are more than 4 roots (NRs > 4) in your CASPT2 calculations, extract higher ROOTs yourself!\n"}'
awk 'BEGIN { printf "%25s %5s %16s %16s %16s %16s %16s %13s %7s\n", "Output name |", "NRs |" , "CASPT2 Root 1 |", "CASPT2 Root 2 |",  "CASPT2 Root 3 |",  "CASPT2 Root 4 |", "      MC-PDFT |",  "Lowest Freq |",  "Status|"
             printf "%25s %5s %16s %16s %16s %16s %16s %13s %7s\n", "----------- |", "--- |",  "------------- |", "------------- |",  "------------- |",  "------------- |", "------------- |",  "----------- |",  "------|" }'


# Execution of function

for file_name  in `ls *log`; do
        checkstatus
        extract
done

exit 0












