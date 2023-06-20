#! /bin/bash
##
#### This script is written by Le Nhan Pham #####
##### Deakin Uni, IFM #####


### temperature and concentration can be specified to meet the experimental conditions 
### Usage: Xtract-gaussian.sh -t TEMPERATURE -c CONCENTRATION  
### if no temperature is set, 298.15 will be used.

### Gibbs free energy of Phase change correction from gas phase Po = 1 atm = 101325 N/m2 to solution 
### with concentration C = 1M = 1000 mol/m3, , R=8.314462618 J.K-1.mol-1
### Delta_G_corr=RT*ln(P/Po) = RT*ln(nRT/VPo) = RT*ln((n/V)*(RT/Po)) = RT*ln(C*RT/Po)
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
    *)
    shift # past argument
    ;;
esac
done

if [ -z $temp ]; then
temp=298.15 
fi

if [ -z $CM ]; then 
	CM=1
fi

C=$(echo "$CM*1000" | bc 2>/dev/null |  awk '{printf "%0.0f", $0}')


### 1 atm = 101325 n/m2; 1 bar = 100000 n/m2
Po=101325 

kB=0.000003166811563

GphaseCorr=$(echo "scale=12; (($R*$temp*l($C*$R*$temp/$Po)*0.0003808798033989866/1000))" | bc -l 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-20) 



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
	nucleare=$(grep "nuclear repulsion energy" $file_name | tail -1 | awk '{print $4}')
	
	scrf=$(grep "scrf" $file_name | head -1 | awk '{print substr($0,0,5);}') 
	if [ -z "$scrf" ]; then
		GibbsFreeHartree=$etg
		phaseCorr="NO"
	else
		### Phase correction term 7.96 kJ/mol = 0.003031803235 au
		GibbsFreeHartree=$(echo "scale=8; ($etg+$GphaseCorr)" | bc 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-16)
		phaseCorr="YES"
	fi 

	etgev=$(echo "scale=8; $GibbsFreeHartree*27.211396641308" | bc 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-16) 
	etgkj=$(echo "scale=8; $GibbsFreeHartree*2625.5002" | bc 2>/dev/null |  awk '{printf "%f", $0}' | cut -c 1-16)

	# check status of output
	n=$(tail -10 $file_name|grep Normal)
	if [ "k$n" == "k" ]; then
		n=$(tail -10 $file_name|grep Error)
		if [ "k$n" != "k" ]; then
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
	printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s\n" "$file_name" "$etgkj" "$lf" "$GibbsFreeHartree" "$nucleare" "$scf" "$zpe" "$askt" "$phaseCorr"

	
}

prinheader(){
# call function in all available output
awk 'BEGIN { printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s\n", "Output name",  "ETG kJ/mol", "Low FC", "ETG a.u", "Nuclear E au", "SCFE", "ZPE ", "Status", "PCorr"
             printf "%53s %18s %10s %18s %18s %18s %10s %8s %6s\n", "-----------",  "----------", "------", "-------", "------", "----", "----", "------",  "------" }' 
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

if [ -f "$(basename $(pwd))-$temp.results" ]; then 
	rm $(basename $(pwd))-$temp.results 
fi  


printf "Temperature: $temp K. Make sure that temperature = $temp has been used in your input.\n" | tee $(basename $(pwd))-$temp.results 
printf "The concentration for phase correction: $CM M or $C mol/m3 \n" | tee -a $(basename $(pwd))-$temp.results 
printf "Gibbs free correction for phase changing from 1 atm to 1 M: $GphaseCorr au \n" | tee -a $(basename $(pwd))-$temp.results 

prinheader | tee -a $(basename $(pwd))-$temp.results

extractE | sort -n -k2 2>&1 | tee -a $(basename $(pwd))-$temp.results 

exit 0












