#!/usr/bin/env bash

###########################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. March 2015                                       ### 
###########################################################################################
### Using bedtools to join bouts in a meal                                              ###
###########################################################################################
###                                                                                     ###
###########################################################################################

# Calling the script
# ~/git/phecomp/lib/bash/meal_120s.sh

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/meal_120s/data/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

for track in ${path2files}tr*.bed
do
	filename=$(basename "$track")
	filename="${filename%.*}"
	
	# This way merged I take the color of first meal when they are different 
	#mergeBed -i ${track} -d 120 -S + -c 4,5,6,9 -o distinct,sum,distinct,distinct -delim " " > ${filename}_joined.bed
	# This way merged if merged colors have the same color it is shown but if they have different colors it will be shown as black
	mergeBed -i ${track} -d 120 -S + -c 4,5,6,9 -o distinct,sum,distinct,distinct -delim ";" > ${filename}_joined.bed
	
	awk '{OFS="\t"; print $1,$2,$3,$4,$5,$6,$2,$3,$7}' ${filename}_joined.bed > ${filename}_joined_all.bed
	
done
	