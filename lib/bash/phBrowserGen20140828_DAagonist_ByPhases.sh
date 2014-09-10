#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. September 2014                         ### 
#################################################################################
### Code : 08.09                                                              ###
### This script process files from experiment 20140828_DAagonist_CRG          ###
###                                                                           ###
#################################################################################	

###Setting Source files paths
bashCommonDir=/users/cn/jespinosa/lib/bash/
bashScDir=/users/cn/jespinosa/phecomp/lib/bash/

## Functions
source ${bashCommonDir}generalFunctions.sh

# Queue variables
typeQ="short"
nameQ="cn-el6"
# time format HH:MM:SS
timeQ="-l h_rt=04:00:00"
amount_of_memoryG=16

## Variables
scriptName=$(basename "$0")
wDir=$PWD

## Mtb files of this experiment are in this folder 
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20140828_DAagonist_HF_FC/20140828_DAagonist_HF_FC/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder

## Ary with habituation and development files for paper
## By the moment these are all files bars each 5 minutes
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_all_5min" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh
# 
# # # each 30 min 
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_all_30min" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# # # each 15 min
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_all_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# # # each 10 min
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_all_10min" -v par2int2browser="value"  -v winSize=600 ${bashScDir}mtb2GBNoQsubIn.sh
# 
# ## Ary with habituation and development files for paper
# ## Only files with food I filtered out starvation periods because I have problems with signal coming from the 
# # introduction of the food at the end of this period
# ## Bars each 15 minutes
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*.mtb | grep -v "_2hStarvation" ) )
# 
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_noStarv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
# 
# #####################
# # each 15 min by file
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*29082014_CRG_agonistDA_SC_c*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140829_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
# 
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*01092014_CRG_agonistDA_HF_*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140901_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*03092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140903_Starv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*03092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140903_afterStarv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*04092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140904_Starv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*04092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140904_afterStarv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*05092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140905_Starv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*05092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140905_afterStarv_15min" -v par2int2browser="value"  -v winSize=900 ${bashScDir}mtb2GBNoQsubIn.sh
#  

## Each periood of 12 hours as I am starting at 8:00 the GB files I will get info by phase
# aryMtbFilesDev=( $( ls ${mtbFilesDir}*.mtb ) )
aryMtbFilesDev=( $( ls ${mtbFilesDir}*29082014_CRG_agonistDA_SC_c*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140829_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh

aryMtbFilesDev=( $( ls ${mtbFilesDir}*01092014_CRG_agonistDA_HF_*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140901_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*03092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140903_Starv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*03092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140903_afterStarv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*04092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140904_Starv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*04092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140904_afterStarv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*05092014_CRG_agonistDA_HF_2hStarvation_*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140905_Starv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
aryMtbFilesDev=( $( ls ${mtbFilesDir}*05092014_CRG_agonistDA_HF_after2hStarvation_c*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_20140905_afterStarv_circa" -v par2int2browser="value"  -v winSize=43200 ${bashScDir}mtb2GBNoQsubIn.sh
 
