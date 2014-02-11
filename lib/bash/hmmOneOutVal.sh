###########################################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. Jan 2014                                         ### 
###########################################################################################
### Code : 28.01                                                                        ###
### HMM one out evaluation                                                              ###
### This script takes all the cages in a file leaving one out                           ###
### It estimates the model with the 17 cages and evaluates the sequence                 ###
### that was left out                                                                   ###
###########################################################################################
### IN VARIABLES                                                                        ###
### path2intFileFilt=file.........File: intervals files to be analyzed                  ###
### par2int2browser=mode..........Mode: 'value/duration/velocity...' variable to bin    ###
### winSize=int....................Int:  by default 300, size of window time            ###
### iniLight=int...................Int: '6,7' should be set to 7 if files are recorded  ###
###                                      during winter or to 6 otherwise                ###
### resDir=path...................Path: path to results dumping folder                  ###
### resDir=path...................Path: path to results dumping folder                  ###
###########################################################################################


## Export the environment
#$ -V

# Your job name
#$ -N hmmBinarySignalNoQsubIn.sh

# Join stdout and stderr
#$ -j y

# Queue variables
typeQ="short"
nameQ="cn-el6"
# time format HH:MM:SS
timeQ="-l h_rt=04:00:00"
amount_of_memoryG=8

## Setting source files paths
bashCommonDir=/users/cn/jespinosa/lib/bash/
bashScDir=/users/cn/jespinosa/phecomp/lib/bash/
bashGitDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/bash/
# perlScDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/perl/

## Variables
scriptName=$(basename "$0")
wDir=$PWD
defDumpDir="/users/cn/jespinosa/phecomp/20130610_HMM/"

## Some generic functions
source ${bashGitDir}generalFunctions.sh

die () {
    echo -e >&2 "$@"
    exit 1
}

# Checking IN arguments

# PATH2INTFILEFILT
# Variables are provided by the qsub call
# if [[ -z "${path2intFileFilt}" || -z "${intFile2Eval}" ]]
if [[ -z "${path2intFileFilt}" ]]
then
    die "FATAL ERROR: The script ${scriptName} needs at least 2 arguments: path to int file for trainning and path to int file to evaluate\n" 1>&2     
else    
  echo -e "Int file for trainning is  ${path2intFileFilt}\n" 1>&2 
fi

# Name of the int file
fileAndExt=${path2intFileFiltered##*/}
fileName=`echo $fileAndExt | cut -d . -f1`

# PAR2INT2BROWSER
## Choose parameter to be analized with genome browser
if [[ -z "$par2int2browser" ]]
then
    field2Window="-window Value"
    echo -e "INFO: Parameter to be analyzed by int2browser.pl set to default (value)\n" 1>&2 
else
  case $par2int2browser in
    value|Value ) 	 	
	  field2Window="-window Value"
	  echo -e "INFO: selected option \"$par2int2browser\" for int2browser\n" 1>&2
	  ;;
    duration|Duration ) 	 	
	  field2Window="-window Duration"
	  echo -e "INFO: selected option \"$par2int2browser\" for int2browser\n" 1>&2
	  ;;
    interTime|intertime|Intertime ) 	 	
	  field2Window="-window interTime"
	  echo -e "INFO: selected option \"$par2int2browser\" for int2browser\n" 1>&2
	  ;;
    velocity|Velocity ) 	 	
	  field2Window="-window Velocity"
	  echo -e "INFO: selected option \"$par2int2browser\" for int2browser\n" 1>&2
	  ;;
    *) 
      echo -e "FATAL: Unknown option \"$par2int2browser\" provided to int2browser inside function genBrowCall\n" 1>&2
      exit 1
      ;;
    
  esac
fi

# WINSIZE
# If winSize is not defined by user by default it will be 300 seconds
winSize=${winSize-300}
echo -e "INFO: win size set to: ${winSize}\n" 1>&2

# INILIGHT
# This variable should be set to 7 if files are recorded during winter or to 6 otherwise
iniLight=${iniLight-6}
[[ "$iniLight"  == 6 ||  "$iniLight"  == 7 ]] || die "FATAL: IniLight parameter can only be set to 6 or 7\n" 1>&2
iniLight="-iniLight "${iniLight}

# BINMODE
# This variable should be set to binary or four the only supported modes by the moment
# By default is set to four
binMode=${binMode-four}
[[ "$binMode"  == "binary" ||  "$binMode"  == "four" ]] || die "FATAL: binMode parameter can only be set to binary or four\n" 1>&2
                   
if [ ${binMode} = "binary" ]
then
  winCh2comb="1234"
else
  winCh2comb="12,34" 
fi

echo -e "INFO: bin mode set to: $winCh2comb\n" 1>&2

if [ -z "$resDir" ]
then
  resDir=${defDumpDir}"20130610_HMM${binMode}Signal/"
  checkCreateDir $resDir
  resDir=${resDir}"hmmOneOutVal/" 
  checkCreateDir $resDir
else
  checkCreateDir $resDir
fi

if [ -z "$resDir" ]
then
  evalTbl=${resDir}"evalOneCgOut.tbl"
  echo -e "cage\tscore" > ${evalTbl}
fi
  

# if [[ -z "${resDir}" || -z "${outputDir}" || -z "${path2GenBrowser}" ]]
# then
#     die "FATAL ERROR: The script ${scriptName} needs the paths to dump the results\n" 1>&2     
# else
#   echo -e "resDir: ${resDir}\n" 1>&2 
#   echo -e "outputDir: ${outputDir}\n" 1>&2
#   echo -e "path2GenBrowser: ${path2GenBrowser}\n" 1>&2
# fi    


######################################################################################
## 1 -> binned hmm format file
## First we generate the hmm file with the binning corresponding a genome browser file
## 1.1 -> Single file containing all cages



# Name of the int file evaluated
# intFile2EvalAndExt=${intFile2Eval##*/}
# intFileNameEval=`echo $intFile2EvalAndExt | cut -d . -f1`

path2GenOutput=${resDir}
nameHmmFile="${binMode}HmmFile"
pathHmmFile=${resDir}${nameHmmFile}".hmm"
errorGBrowser=${resDir}"GBrowser"".err"
optInt2browser="${field2Window} -winMode binning -binMode $binMode -winFile ${nameHmmFile} -ws ${winSize} -wss ${winSize} -winFormat rhmm -rhmmFile single -outdata no -winCh2comb ${winCh2comb} -winCombMode additive ${iniLight}"

# Generation of bin file with hmm file in order to estimate the model (baum-welch) and decode states by rhmm.pl 
${bashScDir}int2browserCallFromQsub.sh "${path2intFileFilt}" "${optInt2browser}" ${path2GenOutput} "${errorGBrowser}" > ${resDir}GBbinedFiles.stout 2> ${resDir}GBbinedFiles.err

# Starting models for baum-welch optimization
if [ ${binMode} = "binary" ]
then
  hmmModel="/users/cn/jespinosa/phecomp/20130610_HMM/20130610_HMMbinarySignal/modelsHMM/ST_2_Bin_2_BEGIN_END.inmodel"
else
  hmmModel="/users/cn/jespinosa/phecomp/20130610_HMM/20130610_HMMfourSignal/modelsHMM/ST_2_Bin_4_BEGIN_END.inmodel" 
fi

for cage in $(seq 1 1 18)
do
  resDirCage=$resDir"cage"$cage"/"
  checkCreateDir $resDirCage
  pathHmmFileNocage=$resDirCage${nameHmmFile}"NoCage"$cage."hmm"
  pathHmmFileCage=$resDirCage${nameHmmFile}"Cage"$cage."hmm"
  eval "cat $pathHmmFile | grep \"comment\" > $pathHmmFileNocage"
  eval "cat $pathHmmFile | grep \"#d\" | grep -v \"cage;$cage;\" >> $pathHmmFileNocage"
  eval "cat $pathHmmFile | grep \"#d\" | grep \"cage;$cage;\" >> $pathHmmFileCage"
  # 2 -> baum-welch and decoding
  ## We use rhmm to estimate the model using the remaining cages

  while [ ! -f ${pathHmmFileNocage} ]  
  do
    echo -e "Waiting for bin rhmm file\n" 1>&2	
    sleep 5
  done 

  fileAndExt=${pathHmmFileNocage##*/}
  fileName=`echo $fileAndExt | cut -d . -f1`
  nameDecodedFile=${fileName}".decoded"
  echo -e "INFO: name of decoded file is $nameDecodedFile\n" 1>&2	
  path2decodedFile=${resDirCage}${nameDecodedFile}
  
  rhmmOpt="-action bw -out trained -nrounds 10 -nit 1000 -evaluate viterbi -outdata "${nameDecodedFile}
  
  errorRhmm=${resDirCage}"rhmm.err"
  
  qsub -q $typeQ,$nameQ $timeQ -cwd -o ${errorRhmm} -e ${errorRhmm} -v hmmDataFile=${pathHmmFileNocage},hmmModelFile=${hmmModel},dumpPath=${resDirCage},rhmmOpt="${rhmmOpt}",logError=${errorRhmm} ${bashScDir}rhmmCallFromQsub.sh
done

for cage in $(seq 1 1 18)
do
  resDirCage=$resDir"cage"$cage"/"
  hmmModelTrainned=${resDirCage}trained*.model
  pathHmmFileCage=$resDirCage${nameHmmFile}"Cage"$cage."hmm"
  pathHmmFileCageError=$resDirCage${nameHmmFile}"Cage"$cage."err"
  
  echo -e "INFO: evaluation of sequence of $cage will start\n" 1>&2

  while [ ! -f ${hmmModelTrainned} ]  
  do
    echo -e "Waiting for trainned model for cage $cage --- file ${hmmModelTrainned} \n" 1>&2	
    sleep 30
  done 

  rhmmEvalOpt="-evaluation sequence -output no -outmodel no"
  errorEvalRhmm=${resDirCage}"rhmmEval.err"

  qsub -q $typeQ,$nameQ $timeQ -cwd -o ${pathHmmFileCageError} -e ${pathHmmFileCageError} -v hmmDataFile=${pathHmmFileCage} -v  hmmModelFile=${hmmModelTrainned} -v dumpPath=${resDirCage} -v rhmmOpt="${rhmmEvalOpt}" -v logError=${errorEvalRhmm} ${bashScDir}rhmmCallFromQsub.sh

done


for cage in $(seq 1 1 18)
do
  resDirCage=$resDir"cage"$cage"/"
  evalFile=${resDirCage}*Cage$cage*.eval
  
  echo -e "File to get eval value********************\n" 1>&2
  echo -e "${evalFile}\n" 1>&2

  while [ ! -f ${evalFile} ]  
  do
    echo -e "Waiting for evaluation score for cage $cage\n" 1>&2	
    sleep 30
  done 
  
  evalScore=`cat ${evalFile}`

  echo -e "eval Score is -----> ${evalScore}\n" 1>&2
  #sino es null
  if [[ ! -z "$run" ]]
  then
    echo -e "$cage\t$evalScore\t$run" >> ${evalTbl}
  else
    echo -e "$cage\t$evalScore" >> ${evalTbl}
  fi
  
  evalScore=0

done


# Aqui coger el valor y ponerlo en la tabla
# for cage in $(seq 1 1 18)
# do
#   evalValue=`cat ${hmmEvalFile}`
#   fileNameHmm=`basename ${hmmEvalFile}`
#   cage=${fileNameHmm##*cage}
#   cage=${cage%ch*}
#   echo -e "cage\tscore" >> ${evalTbl}
# done