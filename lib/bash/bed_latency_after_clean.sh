#!/usr/bin/env bash

###########################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. March 2015                                       ### 
###########################################################################################
### Using bedtools to get the latency to the first meal after a stop                    ###
###########################################################################################
### Based on                                                                            ###
### https://www.biostars.org/p/17162/                                                   ###
### http://bedtools.readthedocs.org/en/latest/content/tools/flank.html                  ###
###                                                                                     ###
###########################################################################################

# Calling the script
# ~/git/phecomp/lib/bash/bed_latency_after_clean.sh

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file/data/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

# OJO all the bed files have to be sorted--> the implementation of pergola right now sort the files by the start of interval
# Now in principle not needed because pergola orders before dumping
# sort the files_data file 
# cat files_data.bed | sort -k1,1 -k2,2n > files_data_sorted.bed

# I get the first half half an hour after starting the recording
# -l upstream -r downstream
# I need or complement or window, otherwise I get the region just after the end of the file 
bedtools complement -i ${path2files}files_data.bed -g ${path2files}all_mice.chromsizes | awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' > ${path2files}files_data_comp.bed

##################################################
# Closest event two the end of the cleaning period

for track in ${path2files}tr*.bed
do
	filename=$(basename "$track")
	filename="${filename%.*}"
	
	#lantency to first meal	
	bedtools closest -a ${path2files}files_data_comp.bed -b ${track} -s -D a -t first -iu > ${filename}"_latency.bed"
done

${RScDir}bed_latency_after_clean.R

exit 0
