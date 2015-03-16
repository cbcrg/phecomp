#!/usr/bin/env bash

path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/data/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

# OJO all the bed files have to be sorted--> the implementation of pergola right now sort the files by the start of interval
# sort the files_data file
# cat files_data.bed | sort -k1,1 -k2,2n > files_data_sorted.bed

### Window option of bedtools report overlapping regions plus window, not only window -->  thus I need first complement
# Get the complement of files_data.sorted.bed
# bedtools complement -i files_data.sorted.bed -g /Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/coverageBamFiles/all_mice.chromsizes > files_data_comp.bed

# awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' files_data_comp.bed > files_data_comp_all_fields.bed

# bedtools flank -i files_data_comp_all_fields.bed -g /Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/coverageBamFiles/all_mice.chromsizes -l 0 -r 1800  -s > files_30min.bed

# bedtools flank -i files_data_comp_all_fields.bed -g /Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/coverageBamFiles/all_mice.chromsizes -l 0 -r 86400 > files_24h.bed

# bedtools flank -i files_24h.bed -g /Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/coverageBamFiles/all_mice.chromsizes -l 0 -r 1800 > files_24_plus_30min.bed

# I put everything in the script

time_after_clean=1800
time_after_clean_lab="30min"

t_day_s=86400
t_day_s_lab="24h"

### Create complement of files bed, empty regions
## DOWNSTREAM, AFTER THE CLEAN
bedtools complement -i ${path2files}files_data.bed -g ${path2files}all_mice.chromsizes > ${path2files}files_data_comp.bed

awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' ${path2files}files_data_comp.bed > ${path2files}files_data_comp_all_fields.bed


bedtools flank -i ${path2files}files_data_comp_all_fields.bed -g ${path2files}all_mice.chromsizes -l 0 -r $time_after_clean  -s > ${path2files}files_${time_after_clean_lab}.bed

bedtools flank -i ${path2files}files_${time_after_clean_lab}.bed -g ${path2files}all_mice.chromsizes -l 0 -r $time_after_clean > ${path2files}files_${t_day_s_lab}_plus_${time_after_clean_lab}.bed


t_l_23h_30min=$(( t_day_s - time_after_clean ))
t_l_23h_30min_lab="23h30min_less"
t_day_less_s_lab="24h_less"

## UPSTREAM, BEFORE THE CLEAN

bedtools flank -i ${path2files}files_${time_after_clean_lab}.bed -g ${path2files}all_mice.chromsizes -l $t_l_23h_30min -r 0 > ${path2files}files_${t_l_23h_30min_lab}.bed

# In order to take the upstream region, the 24 hours before the stop I have to use as input the files data sor
bedtools flank -i ${path2files}files_${t_l_23h_30min_lab}.bed -g ${path2files}all_mice.chromsizes -l $time_after_clean -r 0 > ${path2files}files_${t_day_less_s_lab}.bed


createBedFilesAnalyze () {
	track=$1
	track2map=$2
	tag=$3
	
	# out_name=`echo $track | cut -d . -f1`
	filename=$(basename "$track")
	filename="${filename%.*}"
	echo -e "Generated file is ${filename}${tag}.bed"
	# bedtools intersect -a ${track} -b ${path2files}files_24_plus_30min.bed > ${filename}${tag}"_raw.bed"
	bedtools intersect -a ${track} -b ${track2map} > ${filename}${tag}"_raw.bed"
	
	#bedtools coverage -a ${track} -b ${path2files}files_24_plus_30min.bed | sort -k1,1 -k2,2n > ${filename}${tag}"_cov.bed"
	bedtools coverage -a ${track} -b ${track2map} | sort -k1,1 -k2,2n > ${filename}${tag}"_cov.bed"
	
	#bedtools map -a ${path2files}files_24_plus_30min.bed -b ${track} -c 5 -o mean -null 0 > ${filename}${tag}"_mean.bed"
	bedtools map -a ${track2map} -b ${track} -c 5 -o mean -null 0 > ${filename}${tag}"_mean.bed"
	
	#bedtools map -a ${path2files}files_24_plus_30min.bed -b ${track} -c 5 -o sum -null 0 > ${filename}${tag}"_sum.bed"
	bedtools map -a ${track2map} -b ${track} -c 5 -o sum -null 0 > ${filename}${tag}"_sum.bed"
}


for track in ${path2files}tr*.bed
do
	createBedFilesAnalyze ${track} ${path2files}files_${time_after_clean_lab}.bed "_30min"
	createBedFilesAnalyze ${track} ${path2files}files_${t_day_s_lab}_plus_${time_after_clean_lab}.bed "_24h"
	createBedFilesAnalyze ${track} ${path2files}files_${t_day_less_s_lab}.bed "_24h_less"
done

# Rscript starting_regions_file_vs_24h.R --tag="mean"
Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="mean" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/"
Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="sum" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/"
	

#######  bedtools map -a ./data/files_30min_after_clean.bed -b tr_ctrl_dt_food_sc_30min_raw.sorted.bed -c 5 -o mean

# Coverage during the first hour after cleaning
#tag="_30min"
#
#for track in ${path2files}tr*.bed
#do
#	# out_name=`echo $track | cut -d . -f1`
#	filename=$(basename "$track")
#	filename="${filename%.*}"
#	echo -e "Generated file is ${filename}${tag}.bed"
#	
#	bedtools intersect -a ${track} -b ${path2files}files_30min.bed > ${filename}${tag}"_raw.bed"
#	bedtools coverage -a ${track} -b ${path2files}files_30min.bed | sort -k1,1 -k2,2n > ${filename}${tag}"_cov.bed"
#	bedtools map -a ${path2files}files_30min.bed -b ${track} -c 5 -o mean -null 0 > ${filename}${tag}"_mean.bed"
#	bedtools map -a ${path2files}files_30min.bed -b ${track} -c 5 -o sum -null 0 > ${filename}${tag}"_sum.bed"
#	
#	# bedtools coverage -a ${track} -b files_first_30min.bed | sort -k1,1 -k2,2n > Ctrl_first_30min_cov.bed
#
#done
#
## Coverage during the first hour after cleaning
#tag="_24h"
#
#for track in ${path2files}tr*.bed
#do
#	# out_name=`echo $track | cut -d . -f1`
#	filename=$(basename "$track")
#	filename="${filename%.*}"
#	echo -e "Generated file is ${filename}${tag}.bed"
#	bedtools intersect -a ${track} -b ${path2files}files_24_plus_30min.bed > ${filename}${tag}"_raw.bed"
#	bedtools coverage -a ${track} -b ${path2files}files_24_plus_30min.bed | sort -k1,1 -k2,2n > ${filename}${tag}"_cov.bed"
#	bedtools map -a ${path2files}files_24_plus_30min.bed -b ${track} -c 5 -o mean -null 0 > ${filename}${tag}"_mean.bed"
#	bedtools map -a ${path2files}files_24_plus_30min.bed -b ${track} -c 5 -o sum -null 0 > ${filename}${tag}"_sum.bed"
#done
#
#
#

exit 0
# bedtools intersect -a tr_1_dt_food_sc.bed -b phases_dark.bed > tr_1_dt_food_sc_dark.bed

# bedtools window -a tr_HF_dt_food_fat_food_sc.bed -b files_data.bed -l 0 -r 3600 > downStream_files.bed

# Plots in R
# "/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/starting_regions_file_vs_24h.R"