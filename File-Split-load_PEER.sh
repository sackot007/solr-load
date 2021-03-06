#!/usr/bin/bash

# Config param
# 20000 brings file to ~2MB for loading
num_lines_per_file=20000

echo "*****"

fname=$(ls Price*.dat)

echo ${fname}

curldel="curl \"http://localhost:8983/solr/skuprice_passive/update?stream.body=%3Cdelete%3E%3Cquery%3E*:*%3C/query%3E%3C/delete%3E&commit=true\""
eval $curldel
echo "Deleting Data completed"

total_lines=$(wc -l ${fname})
num_files=($total_lines/$num_lines_per_file)

split -l ${num_lines_per_file} ${fname} pricefilechunks/Chunk_${fname%.*}


echo "Total lines     = ${total_lines}"
echo "Lines  per file = ${num_files}"  

cd pricefilechunks

cwd=$(pwd)

echo "Current working Dir	="${cwd}
for FILECHUNK in $(ls Chunk_*);
do
	mv ${FILECHUNK} ${FILECHUNK}.csv
	echo "Solr load the file ->" ${FILECHUNK}.csv
	# Call Solr load with the file 
	curlCmd="curl \"http://localhost:8983/solr/skuprice_passive/update?stream.file=${cwd}/${FILECHUNK}.csv&stream.contentType=text/csv;charset=utf-8&wt=json&separator=%7C&fieldnames=productid,skucode,displayStartDate,displayEndDate,op,sp,ptype,promo&commit=true\""	
	eval $curlCmd
	echo "Done with file -> "${FILECHUNK}.csv
	rm ${FILECHUNK}.csv
	
	#mv -f ${FILECHUNK} pricefilechunks/${FILECHUNK}.csv
done

echo "Optimizing the index after load"
curlCmd="curl \"http://localhost:8983/solr/skuprice_passive/update?optimize=true\""	
eval $curlCmd
echo "Optimizing the index after load complete"


# Swap Active and Passive instances.
echo "Done with processing file chunks"
echo "Swap Active and Passive instances"

curlCmd="curl \"http://localhost:8983/solr/admin/cores?action=SWAP&core=skuprice&other=skuprice_passive\""
eval $curlCmd

exit 0  
