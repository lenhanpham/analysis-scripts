#! /bin/bash
##
#### This script is written by Le Nhan Pham #####
##### Le Nhan Pham, Flinders Uni #####

### temperature and concentration can be specified to meet the experimental conditions 
### Usage: Xtract-gaussian.sh -t TEMPERATURE -c CONCENTRATION -col column_to_be_sorted 
### if no temperature is set, 298.15 will be used.
### Gibbs free energy of Phase change correction from gas phase Po = 1 atm = 101325 N/m2 to solution 
### with concentration C = 1M = 1000 mol/m3, , R=8.314462618 J.K-1.mol-1
### Delta_G_corr=RT*ln(P/Po) = RT*ln(nRT/VPo) = RT*ln((n/V)*(RT/Po)) = RT*ln(C*RT/Po)
currdir=$(pwd)
cd $currdir 
R=8.314462618
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -t|--temp)
    temp="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--cm)
    CM="$2"
    shift # past argument
    shift # past value
    ;;
    -col|--column)
    column="$2"
    shift # past argument
    shift # past value
    ;;
    *)
    shift # past argument
    ;;
esac
done
if [ -z "$column" ]
then
  column=2
fi
if [ -z $CM ]; then 
	CM=1
fi
C=$(echo "$CM*1000" | bc 2>/dev/null |  awk '{printf "%0.0f", $0}')

### 1 atm = 101325 n/m2; 1 bar = 100000 n/m2
Po=101325 
kB=0.000003166811563
# function for data extraction
extract()
{
    scf=$(grep "SCF Done" $file_name | tail -1 | awk '{print $5}')
	scftd=$(grep "Total Energy, E(CIS" $file_name | tail -1 | awk '{print $5}') 
	scfEqui=$(grep "After PCM corrections, the energy is" $file_name | tail -1 | awk '{print $7}')
	if [ ! -z "$scfEqui" ]; then 
		scf=$scfEqui
	elif [ -z "$scfEqui" ] && [ ! -z "$scftd" ]; then
		scf=$scftd
	fi 
	zpe=$(grep "Zero-point correction" $file_name |tail -1  | awk '{print $3}')
	tcg=$(grep "Thermal correction to Gibbs Free Energy" $file_name |tail -1|awk '{print $7}')
	etg=$(grep "Sum of electronic and thermal Free Energies" $file_name | tail -1|awk '{print $8}')
	ezpe=$(grep "Sum of electronic and zero-point Energies" $file_name | tail -1|awk '{print $7}')
	countround=$(grep "Copyright" $file_name | wc -l)
	# Use grep to find lines with 'Frequencies', then use sed to replace '--' with ' ', and awk to print negative values
	negative_freqs=$(grep 'Frequencies' $file_name | sed 's/--/ /g' | awk '{for(i=1;i<=NF;i++) if ($i < 0) print $i}')
	# Get the last negative frequency
	lf=$(echo "$negative_freqs" | tail -n 1)
	# If no negative frequencies were found, print the smallest positive frequency
	if [ -z "$lf" ]; then
    	positive_freqs=$(grep 'Frequencies' $file_name | sed 's/--/ /g' | awk '{for(i=2;i<=NF;i++) if ($i > 0) print $i}')
    	lf=$(echo "$positive_freqs" | sort -n | head -n 1)
	fi
	nucleare=$(grep "nuclear repulsion energy" $file_name | tail -1 | awk '{print $4}')
         
        temp=$(grep "Kelvin.  Pressure" $file_name | tail -n 1 | awk '{print $2}')
        if [ -z $temp ]; then
                temp=298.15 
        fi     
        GphaseCorr=$(echo "scale=30; (($R*$temp*l($C*$R*$temp/$Po)*0.0003808798033989866/1000))" | bc -l 2>/dev/null |  awk '{printf "%.30f", $0}') 
	scrf=$(grep "scrf" $file_name | head -1 | awk '{print substr($0,0,5);}') 
	if [ -z "$scrf" ]; then
		GibbsFreeHartree=$etg
		phaseCorr="NO"
	else
		### Phase correction term 7.96 kJ/mol = 0.003031803235 au
		GibbsFreeHartree=$(echo "scale=30; ($etg+$GphaseCorr)" | bc 2>/dev/null |  awk '{printf "%.30f", $0}')
		GibbsFreeHartreePrinted=$(echo "$GibbsFreeHartree" |  awk '{printf "%.6f", $0}')

		phaseCorr="YES"
	fi 
	etgev=$(echo "scale=30; $GibbsFreeHartree*27.211396641308" | bc 2>/dev/null |  awk '{printf "%.6f", $0}') 
	etgkj=$(echo "scale=30; $GibbsFreeHartree*2625.5002" | bc 2>/dev/null |  awk '{printf "%.6f", $0}')
	# check status of output
	n=$(tail -10 $file_name|grep Normal)
	if [ -z "$n" ]; then
		n=$(tail -10 $file_name|grep Error)
		en=$(tail -10 $file_name|grep "Error on")
		if [[ ! -z $n && -z $en ]]; then
	                askt="ERROR"
		else
			askt="UNDONE"
		fi
	else
		askt="DONE"
	fi
	### total characters in file names
	totalchar=$(printf "$file_name" | wc -m)
	if [ $totalchar -gt 53 ]; then
		startingCut=$(($totalchar-52))
		file_name=$(printf "$file_name" | cut -c $startingCut-) 	
	fi
	# print out deserved information
	printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s %6s\n" "$file_name" "$etgkj" "$lf" "$GibbsFreeHartreePrinted" "$nucleare" "$scf" "$zpe" "$askt" "$phaseCorr" "$countround"
	
}
prinheader(){
# call function in all available output
awk 'BEGIN { printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s %6s\n", "Output name",  "ETG kJ/mol", "Low FC", "ETG a.u", "Nuclear E au", "SCFE", "ZPE ", "Status", "PCorr", "Round"
             printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s %6s\n", "-----------",  "----------", "------", "-------", "------", "----", "----", "------",  "------",  "------" }' 
}
#for file_name  in `ls *.out`; do
#	extract
#done
#echo " "
extractE(){
for file_name  in `ls *log`; do
        extract
done
}
if [ -f "$(basename $(pwd)).results" ]; then 
	rm $(basename $(pwd)).results 
fi  
lastFile=$(ls *.log | tail -1)
lastTemp=$(grep "Kelvin.  Pressure" $lastFile | tail -n 1 | awk '{print $2}')
lastGphaseCorr=$(echo "scale=12; (($R*$lastTemp*l($C*$R*$lastTemp/$Po)*0.0003808798033989866/1000))" | bc -l 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-20) 
printf "Temperature in $lastFile: $lastTemp K. Make sure that temperature has been used in your input.\n" | tee $(basename $(pwd)).results 
printf "The concentration for phase correction: $CM M or $C mol/m3 \n" | tee -a $(basename $(pwd)).results 
printf "Last Gibbs free correction for phase changing from 1 atm to 1 M: $lastGphaseCorr au \n" | tee -a $(basename $(pwd)).results 
prinheader | tee -a $(basename $(pwd)).results
extractE | sort -n -k$column 2>&1 | tee -a $(basename $(pwd)).results 
exit 0






