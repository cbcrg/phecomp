#!/usr/bin/env bash

###########################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. March 2015                                       ### 
###########################################################################################
### Using bedtools to get the latency to the first meal after a stop                    ###
###########################################################################################
###                                                                                     ###
###########################################################################################

# Calling the script
# ~/git/phecomp/lib/bash/bed_latency_after_clean.sh

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/data/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

# OJO all the bed files have to be sorted--> the implementation of pergola right now sort the files by the start of interval
# sort the files_data file
# cat files_data.bed | sort -k1,1 -k2,2n > files_data_sorted.bed


exit 0
