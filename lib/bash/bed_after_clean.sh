#!/usr/bin/env bash

# Calling the script
# ~/git/phecomp/lib/bash/bed_after_clean.sh

# Data for pergola paper
#path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/data/"
# Data for validation paper
path2files="/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/data_bed_format/"

RScDir="/Users/jespinosa/git/phecomp/lib/R/"

# OJO all the bed files have to be sorted--> the implementation of pergola right now sort the files by the start of interval
# sort the files_data file
# cat files_data.bed | sort -k1,1 -k2,2n > files_data_sorted.bed

# Generate all the bed files in order to perform the analysis
time_after_clean=1800
time_after_clean_lab="30min"

t_day_s=86400
t_day_s_lab="24h"

### Create complement of files bed, empty regions
## DOWNSTREAM, AFTER THE CLEAN
bedtools complement -i ${path2files}files_data.bed -g ${path2files}all_mice.chromsizes > ${path2files}files_data_comp.bed

awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' ${path2files}files_data_comp.bed > ${path2files}files_data_comp_all_fields.bed


bedtools flank -i ${path2files}files_data_comp_all_fields.bed -g ${path2files}all_mice.chromsizes -l 0 -r $time_after_clean  -s > ${path2files}files_${time_after_clean_lab}.bed

bedtools flank -i ${path2files}files_data_comp_all_fields.bed -g ${path2files}all_mice.chromsizes -l 0 -r $t_day_s  -s > ${path2files}files_${t_day_s_lab}.bed

bedtools flank -i ${path2files}files_${t_day_s_lab}.bed -g ${path2files}all_mice.chromsizes -l 0 -r $time_after_clean > ${path2files}files_${t_day_s_lab}_plus_${time_after_clean_lab}.bed


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
	
	# Get raw bed files with overlaping regions of target files
	bedtools intersect -a ${track} -b ${track2map} > ${filename}${tag}"_raw.bed"
	
	# Get the coverage of the overlaping regions
	bedtools coverage -a ${track} -b ${track2map} | sort -k1,1 -k2,2n > ${filename}${tag}"_cov.bed"
	
	# Get the mean of the overlaping regions
	bedtools map -a ${track2map} -b ${track} -c 5 -o mean -null 0 > ${filename}${tag}"_mean.bed"
	
	# Get the summatory of the overlaping regions
	bedtools map -a ${track2map} -b ${track} -c 5 -o sum -null 0 > ${filename}${tag}"_sum.bed"
	
	# Get the counts of the overlaping regions
	bedtools map -a ${track2map} -b ${track} -c 5 -o count -null 0 > ${filename}${tag}"_count.bed"
	
	# Get the maximum of the overlaping regions
	bedtools map -a ${track2map} -b ${track} -c 5 -o max -null 0 > ${filename}${tag}"_max.bed"
}

for track in ${path2files}tr*.bed
do
	createBedFilesAnalyze ${track} ${path2files}files_${time_after_clean_lab}.bed "_30min"
	createBedFilesAnalyze ${track} ${path2files}files_${t_day_s_lab}_plus_${time_after_clean_lab}.bed "_24h"
	createBedFilesAnalyze ${track} ${path2files}files_${t_day_less_s_lab}.bed "_24h_less"
done

# Rscript starting_regions_file_vs_24h.R --tag="mean"
#Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="mean" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/20151103_result/"
#Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="sum" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/20151103_result/"
#Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="count" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/20151103_result/"
#Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="max" --path2files="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/" --path2plot="/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h/20151103_result/"

path2tbl="/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/"
path2res="/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/20151103_result/"

Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="mean" --path2files=${path2tbl} --path2plot=${path2res}
Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="sum" --path2files=${path2tbl} --path2plot=${path2res}
Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="count" --path2files=${path2tbl} --path2plot=${path2res}
Rscript ${RScDir}starting_regions_file_vs_24h.R --tag="max" --path2files=${path2tbl} --path2plot=${path2res}

exit 0
