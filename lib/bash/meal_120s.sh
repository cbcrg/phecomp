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
	# This way if the merged colors have the same color it is shown but if they have different colors it will be shown as black
	# distinct takes a list of the possible values in the field
	# col 4 = label
	# col 5 = value
	# col 6 = strand
	# col 9 = color => collapse will give the color even if they are repeated
	# this way whenever they are joined the color will not be shown, otherwise 
	# with unique was misleading, because intervals with same color intensity maintained
	# this color intensity
	mergeBed -i ${track} -d 120 -S + -c 4,5,6,9 -o distinct,sum,distinct,collapse -delim ";" > ${filename}_joined.bed
	
	awk '{OFS="\t"; print $1,$2,$3,$4,$5,$6,$2,$3,$7}' ${filename}_joined.bed > ${filename}_joined_all.bed
	
done
	
