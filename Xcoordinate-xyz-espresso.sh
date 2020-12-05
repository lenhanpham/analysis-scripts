#####################################################################################
# This script is used to extract coordinates of systems from Quantum Espresso       #
# Output files should have extensions of .out                       			    #
# Author: Le Nhan Pham Deakin Uni https://lenhanpham.github.io/      				#
#####################################################################################


countlines()
{
nlines=$(grep 'Begin final coordinates' $file_name  | wc -l) 
}

#### print out lines between two patterns, and then delete the first and last lines sed '1d' and sed '$d' 

xcoordinate1()
{
sed -n '/Begin final coordinates/,/End\ final\ coordinates/p' $file_name | \
sed -n '/ATOMIC_POSITIONS/,/End\ final\ coordinates/p' | sed '1d' | sed '$d' 
}


#### print out all lines between two patterns, and step by step remove the repeated pattens but the last, and extract lines between two last patterns 
#### this is for the case of two repeated patterns 

xcoordinate2()
{
sed -n '/Begin final coordinates/,/End\ final\ coordinates/p' $file_name | \
sed -n '/ATOMIC_POSITIONS/,/End\ final\ coordinates/p' | sed '1d' | \
sed -n '/ATOMIC_POSITIONS/,/End\ final\ coordinates/p' | sed '1d' | sed '$d'  
}


if [ ! -d "final-coor" ]; then 
	mkdir "final-coor" 
fi 

isjobdone()
{
	if [ $(grep -c "JOB DONE."  $file_name) -ge 1 ]; then 
		true 
	else 
		false 
	fi 	
}

for file_name in `ls *.out`; do 
   if [ $(grep -c "JOB\ DONE."  $file_name) -ge 1 ]; then 
	countlines 
	if (( $nlines == 1 )); then
		xcoordinate1 > ${file_name%.*}.xyz 
	else 
		xcoordinate2 > ${file_name%.*}.xyz 
	fi 
	mv ${file_name%.*}.xyz ./final-coor/ 
    fi  
done 

