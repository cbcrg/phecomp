#! /bin/bash

#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. January 2013                          ### 
#################################################################################
### Code : 28.01                                                              ###
### This script call hmmOneOutVal so many times as set                        ### 
#################################################################################

## Export the environment
#$ -V

## Setting source files paths
bashGitDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/bash/

## Some generic functions
source ${bashGitDir}generalFunctions.sh

# Queue variables
typeQ="short"
nameQ="cn-el6"
# time format HH:MM:SS
timeQ="-l h_rt=04:00:00"
amount_of_memoryG=8

## Variables
scriptName=$(basename "$0")
wDir=$PWD

defDumpDir="/users/cn/jespinosa/phecomp/20130610_HMM/"

binMode=four
resDir=${defDumpDir}"20130610_HMM${binMode}Signal/"
checkCreateDir $resDir
resDir=${resDir}"hmmOneOutValSecond/"
checkCreateDir ${resDir}

## Experiment HF May 2012
intFile2Val="/users/cn/jespinosa/phecomp/20130610_HMM/data/intFiles/20120502_FDF_CRG_hab_filt.int"

# Setting a folder for each int file to be analyzed
fileAndExt=${intFile2Val##*/}
fileName=`echo $fileAndExt | cut -d . -f1`

resDirFile=${resDir}"${fileName}/"
checkCreateDir ${resDirFile}

summaryTableAllRuns=${resDirFile}"summaryTableAllRuns.tbl"
echo -e "cage\tscore\trun" > ${summaryTableAllRuns}

###### FROM HERE
# for run in {1..30}
for run in {1..30}
do
  echo "INFO: Execution of one out routine $run\n" 1>&2
  resDirRun=${resDirFile}"run${run}/"
  checkCreateDir $resDirRun
  
  export path2intFileFilt=${intFile2Val}
  export par2int2browser="value"
  export binMode=${binMode}
  export resDir=${resDirRun} 
  export evalTbl=${summaryTableAllRuns}
  export run=${run}
  
  ${bashGitDir}hmmOneOutVal.sh
   
done


# ${bashGitDir}hmmOneOutVal.sh 
# > ${resDir}"hmmOneOutVal.stdout" 2> ${resDir}"hmmOneOutVal.err" 
# 
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${resDir} -e ${resDir} -v path2intFileFilt=${intFile2Val},par2int2browser="value",binMode=${binMode} ${bashGitDir}hmmOneOutVal.sh 1>&2
#  -v iniLight=6  -v path2intFileFiltered=${intFile}


resDir=${defDumpDir}"20130610_HMM${binMode}Signal/"
checkCreateDir $resDir
resDir=${resDir}"hmmOneOutVal/"
checkCreateDir ${resDir}

## Experiment Free Choice CD SC January 2013
intFile2Val="/users/cn/jespinosa/phecomp/20130610_HMM/data/intFiles/20130130_FCSC_CRG_hab_filt.int"
# Setting a folder for each int file to be analyzed
fileAndExt=${intFile2Val##*/}
fileName=`echo $fileAndExt | cut -d . -f1`

resDirFile=${resDir}"${fileName}/"
checkCreateDir ${resDirFile}

summaryTableAllRuns=${resDirFile}"summaryTableAllRuns.tbl"
echo -e "cage\tscore\trun" > ${summaryTableAllRuns}

####### FROM HERE
for run in {1..30}
# for run in {1..2}
do
  echo "INFO: Execution of one out routine $run\n" 1>&2
  resDirRun=${resDirFile}"run${run}/"
  checkCreateDir $resDirRun
  
  export path2intFileFilt=${intFile2Val}
  export par2int2browser="value"
  export binMode=${binMode}
  export resDir=${resDirRun} 
  export evalTbl=${summaryTableAllRuns}
  export run=${run}
  
  ${bashGitDir}hmmOneOutVal.sh
  
  
done






