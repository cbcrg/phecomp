#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. December 2013                          ### 
#################################################################################
### Code : 05.12                                                              ###
### This script process files from experiment 20130130_FCSC                   ###
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
amount_of_memoryG=8

## Variables
scriptName=$(basename "$0")
wDir=$PWD

## Mtb files of this experiment are in this folder 
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20130130_FCSC_CRG/20130130_FCSC_CRG/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder
resDir="/users/cn/jespinosa/phecomp/processedData/"

## Ary with habituation files
aryMtbFilesHab=( $( ls ${mtbFilesDir}20130[0-2][0,3]*.mtb ) )
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHab[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_hab" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with development files
aryMtbFilesDev=( $( ls ${mtbFilesDir}20130[2-5]*.mtb | grep -v "20130204_FCSC_CRG_c12.mtb" | grep -v "20130204_FCSC_CRG_c6.mtb" | grep -v "20130207_FCSC_CRG_c12_newMice" | grep -v "20130207_FCSC_CRG_c6_newMice" ) )
# mtb2GB.sh -f "${aryMtbFilesDev[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t dev -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_dev" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with 1st week of development files
aryMtbFilesDevW1=( $( ls ${mtbFilesDir}201302[1]*.mtb | grep -v "20130218" ) )
# mtb2GB.sh -f "${aryMtbFilesDevW1[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t devW_1 -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDevW1[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_devW_1" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh


## Ary with first and second week of development files
aryMtbFilesDevW1_2=( $( ls ${mtbFilesDir}201302[1-2]*.mtb | grep -v "2013022[5-9]" ) )
# mtb2GB.sh -f "${aryMtbFilesDevW1_2[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t devW_1_2 -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDevW1_2[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_devW_1_2" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with all files
aryMtbFilesAll=( $( ls ${mtbFilesDir}*.mtb ) )
# mtb2GB.sh -f "${aryMtbFilesAll[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t all -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesAll[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_all" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with hab and first two weeks of development
aryMtbFilesHabW1_W2=( $( ls ${mtbFilesDir}20130[0-2]*.mtb | grep -v "20130225" ) )
# mtb2GB.sh -f "${aryMtbFilesAll[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t all -p value  -w 1800
qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHabW1_W2[*]}" -v dumpDir=${resDir} -v iniLight=6  -v phaseTag="_hab_DevW1_W2" -v par2int2browser="value"  -v winSize=1800 -v filterIni=8 -v runMtb=F ${bashScDir}mtb2GBNoQsubIn.sh
