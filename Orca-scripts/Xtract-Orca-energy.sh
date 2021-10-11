#! /bin/bash

##############################################################################################################
# This script is used to extract energies from ORCA calculations				         #
#      	     											                                 #
# Output files should have extensions of .out	                                         #
# Author: Le Nhan Pham, website: https://lenhanpham.github.io, IFM, Deakin University	 #
##############################################################################################################


# Extraction fucntion
extract() 
{
for file_name  in `ls *.inp`; do 
     scfenergy=`egrep -a "Total Energy       :" ${file_name%.inp}.out | tail -1 | awk '{print $6}' | grep ".*" | cut -c 1-16`
	 optenergyeh=`egrep -a "Electronic energy                ..." ${file_name%.inp}.out | tail -1 | head -1 | awk '{print $4}' | grep ".*"`
	 optenergyev=$(echo "scale=8; $optenergyeh*27.211396641308" | bc 2>/dev/null | cut -c 1-16)    
     zpeeh=`egrep -a "Zero point energy" ${file_name%.inp}.out |  awk '{print $5}'` 
	 zpeev=$(echo "scale=8; $zpeeh*27.211396641308" | bc 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-16)  
	 ecorrectedzpe=$(echo "scale=8; $optenergyev+$zpeev" | bc 2>/dev/null ) 
	 totalteeh=`egrep -a "Total thermal energy" ${file_name%.inp}.out | tail -1 | awk '{print $4}' | grep ".*"` 
     totalteev=$(echo "scale=8; $totalteeh*27.211396641308" | bc 2>/dev/null | cut -c 1-16)   
     speeh=`egrep -a "FINAL SINGLE POINT ENERGY" ${file_name%.inp}.out | tail -1 | awk '{print $5}' | grep ".*"` 
     speev=$(echo "scale=8; $speeh*27.211396641308" | bc 2>/dev/null | cut -c 1-16)  

	# Checking output process
	jobdone=`tail -20 ${file_name%.inp}.out| grep 'ORCA TERMINATED NORMALLY'`
	notconverge=$(grep 'optimization did not converge' ${file_name%.inp}.out)
    joberror=`tail -20 ${file_name%.inp}.out| grep 'ORCA finished by error'`
	if [ "not$jobdone" != "not" ]; then 
	    if [ "not$notconverge" != "not" ]; then 
           status="NOTCV" 
        else
		   status="OK!" 
        fi 
    elif [ "not$joberror" != "not" ]; then 
	       status="ERROR"
    else 
          status="CHECK" 
	fi

	# print out extracted values including file_name
	     printf "%35s %21s %21s %21s %17s %21s %12s %8s\n" " ${file_name%.inp} |" "$ecorrectedzpe |" "$speev |" "$totalteev |" "$scfenergy |" "$optenergyev |" "$zpeev |" "$status |"   

done 
}


header(){
# call function in all available output
awk 'BEGIN {print "                                            ATTENTION: If both Eopt and Final  SPE values simultaneously appear in output files,\n                                            Eopt values are the final energies of optimizations. All values are in eV.\n"}'
awk 'BEGIN { printf "%35s %21s %21s %21s %17s %21s %12s %8s\n", "Output name |", "Eopt (Ee, ZPE)      |",  " Final  SPE         |",  " Eopt (Ee, ZPE, Et) |",  "Escf (no disp.) |", "   Eopt (Ee)        |", "     ZPE  |" , "Status |"
             printf "%35s %21s %21s %21s %17s %21s %12s %8s\n", "----------- |", "--------------------|",  "--------------------|",  "--------------------|",  "----------------|", "--------------------|", "----------|" , "------ |" }'
}

# Execution of function
	header 2>&1 | tee $(basename $(pwd)).results 

	extract | sort -r -k3 2>&1 | tee -a $(basename $(pwd)).results 














