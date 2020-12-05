##############################################################################################################
# This script is used to update coordinates of Molcas inputs											     #
#     	     	 																						     #
# 																											 #
# Author: Le Nhan Pham Deakin Uni https://lenhanpham.github.io/                                              #
##############################################################################################################

get_element1()
{
cat $coor_file | head -n 3 | tail -n 1 | sed -e 's/$/\       Angstrom/g; s/Cr/Cr1/g' 
#cat $coor_file | head -n 4 | tail -n 1 | sed -e 's/$/\       Angstrom/g; s/Cr/Cr2/g' 
}

get_element2()
{
cat $coor_file | head -n 5 | tail -n 1 | sed -e 's/$/\       Angstrom/g; s/O/O1/g' 
cat $coor_file | head -n 7 | tail -n 1 | sed -e 's/$/\       Angstrom/g; s/O/O2/g'   
}


curr=`pwd`
large_sp=22-orbs 

if [ ! -d $large_sp ]; then mkdir $large_sp; fi 

cd $curr/Save
for coor_file in `ls *.xyz`; do 
	get_element1 > ${coor_file%.*.*}-1.tmp
	get_element2 > ${coor_file%.*.*}-2.tmp


#	tail -n +15 ../21-orbs/${coor_file%.*.*}.in > ${coor_file%.*.*}-r.tmp 
	#awk '/COPY/,/Imaginary/ {print}' ../21-orbs/${coor_file%.*.*}.in  > ${coor_file%.*.*}-r.tmp 
	
	#echo -en '\n' >> ${coor_file%.*.*}-r.tmp 
	#echo -en '\n' >> ${coor_file%.*.*}-r.tmp 

	cat ../$large_sp/gateway.part1 ${coor_file%.*.*}-1.tmp ../$large_sp/gateway.part2 ${coor_file%.*.*}-2.tmp ../$large_sp/gateway.part3 ../$large_sp/cas-remainer.in > ../$large_sp/${coor_file%.*.*}.in  

	rm ${coor_file%.*.*}-1.tmp ${coor_file%.*.*}-2.tmp #${coor_file%.*.*}-r.tmp 
done


cd $curr/$large_sp 
 

replace()
{
  if [ -f $spin$symmetry.in ]; then
  	sed -i -e "s/Spin\ =\ iiii/Spin\ =\ $spin/g" $spin$symmetry.in
  	sed -i -e "s/Symmetry\ =\ ssss/Symmetry\ =\ $sym/g" $spin$symmetry.in
  	sed -i -e "s/eee\ 2\ 0/$nelec\ 2\ 0/g" $spin$symmetry.in
  fi 
}



for spin in {3..6}; do
 if [ $(($spin%2)) -eq 0 ]
	then nelec=29
	else nelec=28
 fi

 for sym in 1 2 3 4; do
  case $sym in
    1) symmetry=ag
	replace
	;;
    2) symmetry=bg 
	replace
	;;
    3) symmetry=bu 
	replace
	;;
    4) symmetry=au 
	replace
	;;
   esac
 done
done
