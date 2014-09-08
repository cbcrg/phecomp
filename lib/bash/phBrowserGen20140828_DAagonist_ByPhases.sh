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
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20140828_DAagonistOnHF_exp/data/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder

## Ary with habituation and development files for paper
## By the moment these are all files
aryMtbFilesDev=( $( ls ${mtbFilesDir}*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_all" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh
