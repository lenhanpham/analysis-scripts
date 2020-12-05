#! /bin/bash

##############################################################################################################
# This script is used to extract energies from Molpro single point calculations rccsd(t), rks, uks, mrci      #
# nevpt2 and optimization energy at levels of restricted DFT and unrestricted DFT (rks and uks)    	          #
# Output files should have extensions of .out	                                                 	          #
# Author: Le-Nhan Pham Univeristy of Dalat Vietnam	https://lenhanpham.github.io/			                  #
##############################################################################################################


# Extraction fucntion
extract()
{
	rccsdt=`grep "\!RHF-RCCSD(T) energy" $file_name | tail -1 | awk '{print $3}' | grep ".*" | cut -c 1-16`
	oprks=`grep "RKS-SCF00" $file_name | head -1 | awk '{print $2}' | sed 's/ENERGY\=//'`
	opuks=`grep "UKS-SCF00" $file_name | head -1 | awk '{print $2}' | sed 's/ENERGY\=//'`
	rks=`grep "\!RKS STATE .* Energy" $file_name | tail -1 | awk '{print $5}'   | grep ".*" | cut -c 1-16`
	uks=`grep "\!UKS STATE .* Energy" $file_name | tail -1 | awk '{print $5}'   | grep ".*" | cut -c 1-16`	
	mrci=`grep "\!MRCI STATE .* Energy" $file_name | tail -1 | awk '{print $5}' | grep ".*" | cut -c 1-16`
	nevpt=`grep "\!NEVPT2 STATE .* Energy" $file_name | tail -1 | awk '{print $5}' | grep ".*" | cut -c 1-16`
	f12a=`grep "!RHF-RCCSD(T)-F12a energy" $file_name | tail -1 | awk '{print $3}' | grep ".*" | cut -c 1-16`


	# Checking output process
	jobdone=`tail -1 $file_name| grep 'Variable memory released'`
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
	     printf "%25s %18s %18s %18s %18s %18s %18s %18s %18s %8s\n" " $file_name |" "$rccsdt |" "$f12a |" "$oprks |" "$opuks |" "$rks |" "$uks |" "$mrci |" "$nevpt |" "$status |"
}



# call function in all available output
awk 'BEGIN {print "                          ATTENTION: If both OPT and SP values simultaneously appear in output files, OPT values are the final energies of optimizations\n"}'
awk 'BEGIN { printf "%25s %18s %18s %18s %18s %18s %18s %18s %18s %8s\n", "Output name |", "        RCCSD(T) |", "   RCCSD(T)-F12a |" , "         RKS OPT |", "         UKS OPT |",  "          RKS SP |",  "          UKS SP |",  "            MRCI |",  "          NEVPT2 |",  "Status |"
             printf "%25s %18s %18s %18s %18s %18s %18s %18s %18s %8s\n", "----------- |", "-----------------|", "-----------------|" , "-----------------|", "-----------------|",  "-----------------|",  "-----------------|",  "-----------------|",  "-----------------|",  "------ |" }'


# Execution of function
for file_name  in `ls *.out`; do
	extract
done













