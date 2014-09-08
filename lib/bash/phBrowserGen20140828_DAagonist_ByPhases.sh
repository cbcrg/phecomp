#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. June 2014                              ### 
#################################################################################
### Code : 03.06                                                              ###
### This script process files from experiment 20140318_TS_CRG_HF              ###
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
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20140318_TS_CRG_HF/20140318_TS_CRG_HF_corrected/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder

## Ary with habituation files
## Habituation last until 20140404 this file included
aryMtbFilesHab=( $( ls ${mtbFilesDir}20140[3-4]*.mtb | grep -v "201404[1-2]" | grep -v "20140408" ) ) 
qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHab[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_hab" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with habituation and development files for paper
## By the moment these are all files
aryMtbFilesDev=( $( ls ${mtbFilesDir}*.mtb ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_habDev" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with development files
aryMtbFilesDev=( $( ls ${mtbFilesDir}2014*.mtb | grep -v "/20140318_TS_CRG_HF/20140318_TS_CRG_HF_corrected/201403" | grep -v "/20140318_TS_CRG_HF/20140318_TS_CRG_HF_corrected/2014040[0-4]" ) )
qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_dev" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

