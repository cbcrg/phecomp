#! /bin/bash

#################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. November 2013                          ### 
#################################################################################
### Code : 19.11                                                              ###
### This script generates GB files for different representation from a set of ###
### mtb files, eventually some steps can be not performed                     ###
### The difference betweeen this script and mtb2GB is that this script has    ###
### is aimed to be call by qsub and for this reason qsub inside the file are  ###
### avoided
#################################################################################	

## Export the environment of gridengine. Is the alternative to what I have done with the old cluster exported one by one
# source /users/cn/jespinosa/.bashrc
# Trying this it should have the same behavior
#$ -V

# Your job name
#$ -N mtb2GBNoQsubIn.sh

###Setting Source files paths
bashCommonDir=/users/cn/jespinosa/lib/bash/
bashScDir=/users/cn/jespinosa/phecomp/lib/bash/
oldPerlScDir=/users/cn/jespinosa/phecomp/bin/
perlScDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/perl/
## Variables
scriptName=$(basename "$0")
wDir=$PWD

## Functions
source ${bashCommonDir}generalFunctions.sh

die () {
    echo -e >&2 "$@"
    exit 1
}


if [[ -z "${aryMtbFiles}" || -z "${dumpDir}" || -z ${phaseTag} ]]
then
    die "FATAL ERROR: The script ${scriptName} needs at least 3 arguments: ary with mtb files folder to dump results and tag for phase\n" 1>&2     
else
  echo -e "Folder to dump results is  ${dumpDir}\n" 1>&2 
  echo -e "Tag for phase is ${phaseTag}\n" 1>&2
fi


# This variable should be set to 7 if files are recorded during winter or to 6 otherwise
iniLight=${iniLight-6}
[[ "$iniLight"  == 6 ||  "$iniLight"  == 7 ]] || die "[FATAL]: IniLight parameter can only be set to 6 or 7\n"
iniLight="-iniLight "${iniLight}
echo -e "[INFO]: Inilight = $iniLight\n" 1>&2 

aryMtbFiles=($aryMtbFiles)

# Checking mtb files
if [ ! -f "${aryMtbFiles[0]}" ]  
then
    die "[FATAL]: Mtb files are not correctly specified:\n ${aryMtbFiles[0]}\n"
else
  echo "List of mtb files:" 1>&2 
  printf -- '%s\n' "${aryMtbFiles[@]}" 1>&2
  echo -e "\n" 1>&2
fi


expNameDir=`dirname "${aryMtbFiles[0]}"`
expName=`basename ${expNameDir}` 

outDir=${dumpDir-/users/cn/jespinosa/phecomp/processedData/}
outExpDir=${outDir}${expName}"/"

#Checking output file, otherwise created
if [ ! -d "${outExpDir}" ]  
then
    checkCreateDir ${outExpDir}
else
    echo "[INFO]: Experiment directory ${outExpDir} already exists!" 1>&2 
fi

outIntFilDir=${outExpDir}"intFiles/"

#Checking output file, otherwise created
if [ ! -d "${outIntFilDir}" ]  
then
    checkCreateDir ${outIntFilDir}    
else
    echo "[INFO]: Int files ${outIntFilDir} directory already exists!" 1>&2 
fi

# Moving current version of mtb2int.pl to make sure we are using last updated script
cp /users/cn/jespinosa/workspace/workspace/phecomp/lib/perl/*.pl ${oldPerlScDir} || die "FATAL ERROR: perl script couldn't be moved from developing folder" 

#############################################
## int file generation
# mtb2int options
optMtb2int="-startTime file tac -rename cages 1 -out"

#path to files
path2IntFile=${outIntFilDir}${expName}${phaseTag}".int"
# path2IntFileFilter=${outIntFilDir}${expName}${phaseTag}"_filt.int"
errorLog=${outIntFilDir}${expName}${phaseTag}".err"
ctrlMtb2intFile=${outIntFilDir}${expName}${phaseTag}"end1.tmp"

if [ "${runMtb}" == "F" -a -f "${path2IntFile}" ]
then
   echo "[INFO]: mtb2int not called as runMtb option is set to $runMtb" 1>&2
else
  # qsub -q $typeQ,$nameQ $timeQ -cwd -o ${errorLog} -e ${errorLog} ${bashScDir}mtb2intCallFromQsub.sh "${optMtb2int}" ${path2IntFile} ${ctrlMtb2intFile} "${aryMtbFiles[@]}"
  ${bashScDir}mtb2intCallFromQsub.sh "${optMtb2int}" ${path2IntFile} ${ctrlMtb2intFile} "${aryMtbFiles[@]}" > ${errorLog} 2> ${errorLog} 
  rm ${ctrlMtb2intFile}
fi

#############################################
## int file filtering
# int2combo options
#optInt2combo="-tag field Value max 0.02 -filter action rm -out"

# Setting whether first part of mtb file should be filtered out
int='^[0-9]+$'
tagIniFile=""

if [[ -z $filterIni ]]
then 
  optInt2combo="-tag field Value max 0.02 -filter action rm -annotate interInterval meals -out"
  path2IntFileFilter=${outIntFilDir}${expName}${phaseTag}"_filt.int"
  echo -e "[INFO]: Initial part of mtb file not removed\n" 1>&2 
elif ! [[ $filterIni =~ $int ]]
then
  optInt2combo="-tag field Value max 0.02 -filter action rm -annotate interInterval meals -out"
  path2IntFileFilter=${outIntFilDir}${expName}${phaseTag}"_filt.int"  
  echo -e "[WARNING]: filterIni is not an integer." 1>&2
  echo -e "[INFO]: Thus Initial part of mtb file won't be removed\n" 1>&2 
else
  optInt2combo="-tag field Value max 0.02 -filter action rm -annotate interInterval meals -iniFileTag time2tag $filterIni -iniFilter -out"
  echo -e "[INFO]: First $filterIni hours of each mtb file will be removed\n" 1>&2 
  path2IntFileFilter=${outIntFilDir}${expName}${phaseTag}"_filt_iniFile$filterIni.int"
  tagIniFile="iniFile$filterIni"
fi

#path to files
ctrlInt2comboFiltFile=${outIntFilDir}${expName}${phaseTag}"end2.tmp"
errorLog=${outIntFilDir}${expName}${phaseTag}"Filter.err"

# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${errorLog} -e ${errorLog} ${bashScDir}int2comboCallFromQsub.sh ${path2IntFile} "${optInt2combo}" ${path2IntFileFilter} ${ctrlInt2comboFiltFile}
${bashScDir}int2comboCallFromQsub.sh ${path2IntFile} "${optInt2combo}" ${path2IntFileFilter} ${ctrlInt2comboFiltFile} > ${errorLog} 2> ${errorLog}

rm ${ctrlInt2comboFiltFile}

echo -e "INFO: Mtb files processed to int files and filtered\n" 1>&2 

#############################################
## GB files generation
## Choose parameter to be analized with genome browser
if [[ -z "$par2int2browser" ]]
then
    field2Window="-window Value"
    echo -e "INFO: Parameter to be analyzed by int2browser.pl set to default (value)\n" 1>&2 
else
  case $par2int2browser in
    value|Value ) 	 	
	  field2Window="-window Value"
	  echo -e "INFO: selected option \"${par2int2browser}\" for int2browser\n" 1>&2 
	  ;;
    duration|Duration ) 	 	
	  field2Window="-window Duration"
	  echo -e "INFO: selected option \"${par2int2browser}\" for int2browser\n" 1>&2 
	  ;;
    interTime|intertime|Intertime ) 	 	
	  field2Window="-window interTime"
	  echo -e "INFO: selected option \"${par2int2browser}\" for int2browser\n" 1>&2 
	  ;;
    velocity|Velocity ) 	 	
	  field2Window="-window Velocity"
	  echo -e "INFO: selected option \"${par2int2browser}\" for int2browser\n" 1>&2 
	  ;;
    *) 
      echo -e "FATAL: Unknown option \"${par2int2browser}\" provided to int2browser inside function genBrowCall\n" 1>&2 
      exit 1
      ;;
    
  esac
fi

# If winSize is not defined by user by default it will be 1800 seconds
winSize=${winSize-1800}
echo -e "INFO: win size set to: ${winSize}\n" 1>&2 

cDate=$(date +%F)
cDate=${cDate//-/}

outGBFilDir=${outExpDir}"GBfiles/"

#Checking output file, otherwise created
if [ ! -d "${outGBFilDir}" ]  
then
    checkCreateDir ${outGBFilDir}    
else
    echo "[INFO]: Int files ${outGBFilDir} directory already exists!" 1>&2 
fi

path2GenBrowser=${outGBFilDir}${cDate}${phaseTag}${tagIniFile}"/"
checkCreateDir ${path2GenBrowser} 

## Setting paths for int2browser
path2GenBrSplit=${path2GenBrowser}"splitCh/"
path2GenBrCombCh=${path2GenBrowser}"combCh/"
path2GenBrCombChSign=${path2GenBrowser}"signCombCh/"
path2GenBrGroups=${path2GenBrowser}"signGroup/"
path2GenBrTblPh=${path2GenBrowser}"tblPh/"

checkCreateDir $path2GenBrSplit
checkCreateDir $path2GenBrCombCh
checkCreateDir $path2GenBrCombChSign
checkCreateDir $path2GenBrGroups
checkCreateDir $path2GenBrTblPh

# Eventually do this in parallel with a qsub call
errorSplitChGBrowser=${path2GenBrSplit}${expName}"FilterGBrowserSplitCh"".err"
errorCombChGBrowser=${path2GenBrSplit}${expName}"FilterGBrowserCombCh"".err"
errorCombChSign=${path2GenBrSplit}${expName}"FilterGBrowserCombChSign"".err"
errorGroups=${path2GenBrSplit}${expName}"FilterGBrowserGroups"".err"
errorTblPh=${path2GenBrSplit}${expName}"FilterGBrowserTblPh"".err"

# -window Value -iniLight 8 -allFiles genomeBrowser -outdata no -out splitCh "${iniLight}
# Analised field given by variable field2Window
								  
# optInt2browserSplitCh=${field2Window}" -allFiles genomeBrowser -outdata no -out splitCh "${iniLight}
optInt2browserSplitCh=${field2Window}"" "${iniLight}" -allFiles genomeBrowser -ws ${winSize} -wss ${winSize} -outdata no "${iniLight}
optInt2browserCombCh=${field2Window}" -winMode discrete -winFile combCh -ws ${winSize} -wss ${winSize} -winCh2comb 12,34 -outdata no "${iniLight}
optInt2browserCombChSign=${field2Window}" -winMode discrete -winFile signCombCh -ws ${winSize} -wss ${winSize} -winCh2comb 12,34 -winCombMode sign -outdata no "${iniLight}
optInt2browserGroups=${field2Window}" -winMode discrete -winFile groupDistro -ws ${winSize} -wss ${winSize} -winCh2comb 12,34 -winCombMode sign -winCage2comb -caseGroup odd -outdata no "${iniLight}
optInt2browserTblPhJoinedCh=${field2Window}" -winMode discrete -winFile dailyAverageJoinedCh -ws ${winSize} -wss ${winSize} -winCh2comb 12,34 -winCage2comb -caseGroup odd -winJoinPhase -winJoinPhFormat table -outdata no "${iniLight}
optInt2browserTblPh=${field2Window}" -winMode discrete -winFile dailyAverage -ws ${winSize} -wss ${winSize} -winCage2comb -caseGroup odd -winJoinPhase -winJoinPhFormat table -outdata no "${iniLight}

# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserSplitCh}" ${path2GenBrSplit} "${errorSplitChGBrowser}"   
# 
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserCombCh}" ${path2GenBrCombCh} "${errorCombChGBrowser}"
# 
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserCombChSign}" ${path2GenBrCombChSign} "${errorCombChSign}"
# 
# ## Call to generate two bedGraph files one corresponding each of the groups control and case
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserGroups}" ${path2GenBrGroups} "${errorGroups}"
# 
# ## Call to generate the daily average intake for each interval of 30 minutes
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserTblPh}" ${path2GenBrTblPh} "${errorTblPh}"      
# 
# # Samething joining channels
# qsub -q $typeQ,$nameQ $timeQ -cwd -o ${path2GenBrowser} -e ${path2GenBrowser} ${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserTblPhJoinedCh}" ${path2GenBrTblPh} "${errorTblPh}"      

${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserSplitCh}" "/users/cn/jespinosa/phecomp/processedData/20140908_TS_WT_FC_CRG_corrected/GBfiles/20141108_hab/splitCh/" "${errorSplitChGBrowser}" > ${path2GenBrowser}"GBsplitCh.out" 2> ${path2GenBrowser}"GBsplitCh.err"

# ${bashScDr}int2browserCallFromQsub.sh "/users/cn/jespinosa/phecomp/processedData/20140908_TS_WT_FC_CRG_corrected/intFiles/20140908_TS_WT_FC_CRG_corrected_hab_filt.int" 
#									  "-window value -allFiles genomeBrowser -outdata no -out splitCh" 
#									  "/users/cn/jespinosa/phecomp/processedData/20140908_TS_WT_FC_CRG_corrected/GBfiles/20141108_hab/splitCh/" 
#									  "/users/cn/jespinosa/phecomp/processedData/20140908_TS_WT_FC_CRG_corrected/GBfiles/20141108_hab/splitCh/test.err"
	
${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserCombCh}" ${path2GenBrCombCh} "${errorCombChGBrowser}" > ${path2GenBrowser}"GBcombCh.out" 2> ${path2GenBrowser}"GBcombCh.err"

${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserCombChSign}" ${path2GenBrCombChSign} "${errorCombChSign}" > ${path2GenBrowser}"GBcombSign.out" 2> ${path2GenBrowser}"GBcombSign.err"

## Call to generate two bedGraph files one corresponding each of the groups control and case
${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserGroups}" ${path2GenBrGroups} "${errorGroups}" > ${path2GenBrowser}"GBgroups.out" 2> ${path2GenBrowser}"GBgroups.err"

## Call to generate the daily average intake for each interval of 30 minutes
${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserTblPh}" ${path2GenBrTblPh} "${errorTblPh}" > ${path2GenBrowser}"GBtbl.out" 2> ${path2GenBrowser}"GBtbl.err"

# Samething joining channels
${bashScDir}int2browserCallFromQsub.sh "${path2IntFileFilter}" "${optInt2browserTblPhJoinedCh}" ${path2GenBrTblPh} "${errorTblPh}" > ${path2GenBrowser}"GBtblJoinedCh.out" 2> ${path2GenBrowser}"GBtblJoinedCh.err"

echo "toma ya!!!!***************" 1>&2 


# echo ${expName}

exit 1