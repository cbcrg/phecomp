#!/usr/bin/env bash

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/intermeal_duration/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

for track_HF in ${path2files}*food_fat*.bed
do
	filename=$(basename "$track_HF")
	filename="${filename%.*}"
	echo -e "Track of HF is ${filename}"
	bedtools complement -i ${track_HF} -g ${path2files}all_mice.chromsizes | awk '{OFS="\t"; print $1,$2,$3,$3-$2}' > ${filename}.HF.compl
	
done

#for bed in ./*food_fat*.bed; do bedtools complement -i ${bed} -g /Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/coverageBamFiles/all_mice.chromsizes | awk '{OFS="\t"; #print $1,$2,$3,$3-$2}' > ${bed}.HF.compl; awk '{OFS="\t"; print $1,$2,$3}' ${bed}.HF.compl > ${bed}.HF.bed; done