#! /bin/bash

#####################################################################################
# This script is used to extract Vibrational frequency from Molcas optimization     #
# Output files should have extensions of .out or .log                               #
# Author: Le-Nhan Pham Univeristy of Dalat Vietnam	https://lenhanpham.github.io/   #
#####################################################################################


# Extraction fucntion
extract()
{
	grep "Frequency:" $file_name | tail -1 | awk '{print}'
}

# Checking output process
check()
{
	jobdone=`tail -20 $file_name| grep 'Happy landing!'`
	if [ "not$jobdone" == "not" ]; then
		jobdone=`tail -20 $file_name| grep 'Error'`
		if [ "not$jobdone" != "not" ]; then
	                status="ERROR"
		else
			status="CHECK"
		fi
	else
		status="OK!"
	fi
}
# Execution of function
for file_name  in `ls *.out`; do
	check
	echo "$file_name $status"
	extract
done

for file_name  in `ls *.log`; do
	check
	echo "$file_name $status"
	extract
done












