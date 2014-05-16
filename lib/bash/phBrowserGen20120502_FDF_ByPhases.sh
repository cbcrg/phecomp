#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. December 2013                          ### 
#################################################################################
### Code : 03.12                                                              ###
### This script process files from experiment 20120502_FCSC                   ###
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
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder

## Ary with habituation files
aryMtbFilesHab=( $( ls ${mtbFilesDir}2012050*.mtb | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/20120509" ) ) 
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHab[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_hab" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with habituation and development files for paper
aryMtbFilesDev=( $( ls ${mtbFilesDir}20120*.mtb | grep -v "LAHFD" | grep -v "LASC" | grep -v "LA_to_food" | grep -v "adulteration" | grep -v "quinine" | grep -v "LA" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012071" ) )
# mtb2GB.sh -f "${aryMtbFilesDev[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t dev -p value  -w 1800
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_habDev" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with development files
aryMtbFilesDev=( $( ls ${mtbFilesDir}20120*.mtb | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012050[2-7]" | grep -v "LAHFD" | grep -v "LASC" | grep -v "LA_to_food" | grep -v "adulteration" | grep -v "quinine" | grep -v "LA" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012071" ) )
# mtb2GB.sh -f "${aryMtbFilesDev[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t dev -p value  -w 1800
# qsub -q $tcypeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_dev" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with 1st week of development files
aryMtbFilesDevW1=( $( ls ${mtbFilesDir}201205*.mtb | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/201205[2-3]" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012050[2-7]" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012051[5-9]" ) )
# mtb2GB.sh -f "${aryMtbFilesDevW1[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t devW_1 -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDevW1[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_devW_1" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh


## Ary with first and second week of development files
aryMtbFilesDevW1_2=( $( ls ${mtbFilesDir}201205*.mtb | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/201205[3]" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012050[2-7]" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012052[3-8]" ) )
# mtb2GB.sh -f "${aryMtbFilesDevW1_2[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t devW_1_2 -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDevW1_2[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_devW_1_2" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with all files
aryMtbFilesAll=( $( ls ${mtbFilesDir}*.mtb | grep -v "LAHFD" | grep -v "LASC" | grep -v "LA_to_food" | grep -v "adulteration" | grep -v "quinine" | grep -v "LA" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012071" ) )
# mtb2GB.sh -f "${aryMtbFilesAll[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t all -p value  -w 1800
qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesAll[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_allSplitChannels" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with habituation and first and second development week for paper
aryMtbFilesDev=( $( ls ${mtbFilesDir}201205*.mtb | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/201205[3]" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012052[3-8]" ) )
# mtb2GB.sh -f "${aryMtbFilesDev[*]}" -o "/users/cn/jespinosa/phecomp/processedData/" -i 6 -t dev -p value  -w 1800
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesDev[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_hab_DevW1_W2" -v par2int2browser="value"  -v winSize=1800 ${bashScDir}mtb2GBNoQsubIn.sh
