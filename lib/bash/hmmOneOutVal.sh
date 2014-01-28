###############################################################################
###Jose Espinosa-Carrasco. CB/CSN-CRG. Jan 2014                             ### 
###############################################################################
### Code : 28.01                                                            ###
### HMM one out evaluation                                                  ###
### This script takes all the cages in a file leaving one out               ###
### It estimates the model with the 17 cages and evaluates the sequence     ###
### that was left out                                                       ###    
###############################################################################

## Export the environment
#$ -V

# Your job name
#$ -N hmmBinarySignalNoQsubIn.sh

# Join stdout and stderr
#$ -j y

## Setting source files paths
bashCommonDir=/users/cn/jespinosa/lib/bash/
bashScDir=/users/cn/jespinosa/phecomp/lib/bash/
bashGitDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/bash/
# perlScDir=/users/cn/jespinosa/workspaceEclipse/phecomp/lib/perl/

## Some generic functions
source ${bashCommonDir}generalFunctions.sh