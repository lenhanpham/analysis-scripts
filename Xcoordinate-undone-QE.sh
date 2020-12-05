#####################################################################################
# This script is used to extract coordinates of undone jobs from Quantum Espresso   #
# Output files should have extensions of .out                       		    #
# Author: Le Nhan Pham Deakin Uni https://lenhanpham.github.io/      		    #
#####################################################################################


#### tac output and then print out all lines in from beginning of tac output to ATOMIC_POSITIONS, and then tac, and print out all lines from beginning of the new tac output to "NEW-OLD atomic charge density approx. for the potential"  



xcoorundone()
{
tac $file_name | awk '/ATOMIC_POSITIONS/ {exit} 1' | tac | awk '/NEW-OLD atomic charge density approx. for the potential/ {exit} 1' | awk '/Writing output data file/ {exit} 1' | sed '${/^$/d}' |  sed '${/^$/d}'  |  sed '${/^$/d}' |  sed '${/^$/d}'|  sed '${/^$/d}'  |  sed '${/^$/d}'   
}




if [ ! -d "undone-coor" ]; then 
	mkdir "undone-coor" 
fi 


for file_name in `ls *.out`; do 
	n=$(tail -10 $file_name|grep JOB\ DONE.) 
	if [ "k$n" == "k" ]; then 
		xcoorundone > ${file_name%.*}.xyz 
		mv ${file_name%.*}.xyz undone-coor 
	fi 
done 


