for input in `ls *.cif`; do

	obabel $input -O ${input%.*}.xyz   
done

    