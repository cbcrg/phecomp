#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. November 2014                          ### 
#################################################################################
### Code : 07.11                                                              ###
### This script process files from experiment 20140908_TsAndWt_FC             ###
### Experiment consists en 4 groups                                           ###
### Trisomics (ts65Dn) with free choice and not (even, pares para los amigos) ###
### Controls of trisomics (not c57bl/6j) with free choice and not (odd)       ###
### FC:5,7,11,13,17,2,4,8,10,18                                               ###
### SC:1,3,9,15,6,12,14,16                                                    ###
#################################################################################

###Setting Source files paths
bashScDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/bash/

## Functions
source ${bashScDir}generalFunctions.sh

# Queue variables
nameQ="short-sl65"
# time format HH:MM:SS
timeQ="-l h_rt=04:00:00"

## Variables
scriptName=$(basename "$0")
wDir=$PWD


## Mtb files of this experiment are in this folder 
mtbFilesDir="/users/cn/jespinosa/phecomp/data/CRG/20140908_TS_WT_FC_CRG/20140908_TS_WT_FC_CRG_corrected/"
mtbLogFolder=${mtbFilesDir}"logFiles/"
checkCreateDir $mtbLogFolder

## Ary with habituation files
## Still summer iniLight=6

aryMtbFilesHab=( $( ls ${mtbFilesDir}*habituation*.mtb ) ) 
qsub -q $nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHab[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_hab" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

## Ary with development files
## Still summer at the beginning iniLight=6 
## changed on 26 of October iniLight=7
qsub -q $nameQ $timeQ -cwd -o ${mtbLogFolder} -e ${mtbLogFolder} -v aryMtbFiles="${aryMtbFilesHab[*]}" -v dumpDir="/users/cn/jespinosa/phecomp/processedData/" -v iniLight=6  -v phaseTag="_dev" -v par2int2browser="value"  -v winSize=300 ${bashScDir}mtb2GBNoQsubIn.sh

