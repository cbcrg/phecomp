#!/usr/bin/env bash

###########################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. March 2015                                       ### 
###########################################################################################
### Using bedtools on meals converted to bed file by pergola generates the complement   ###
### of these meals and intersect them with habituation and development                  ###
###########################################################################################
###                                                                                     ###
###########################################################################################

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/intermeal_duration/data/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

bed2intermeals () {
	track=$1
	
	filename=$(basename "$track_HF")
	filename="${filename%.*}"
	
	echo -e "Track of HF is ${filename}"
	
	return 0
}

for track in ${path2files}tr*.bed
do
	filename=$(basename "$track")
	filename="${filename%.*}"
	
	bedtools complement -i ${track} -g ${path2files}all_mice.chromsizes | awk '{OFS="\t"; print $1,$2,$3,$3-$2}' > ${filename}_compl.bedGraph
	echo -e "Track is ${filename}_compl.bedGraph"
	awk '{OFS="\t"; print $1,$2,$3,"\"\"",$4,"+",$2,$3,"178,254,178"}' ${filename}_compl.bedGraph > ${filename}_compl.bed
	
	# Get the intermeal intervals of habituation
	bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
	
	# Get the intermeal intervals of development
	bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_dev.bed > ${filename}"_compl_dev.bed"
	
done