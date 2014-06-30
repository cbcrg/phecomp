#! /bin/bash

#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. May 2014                              ### 
#################################################################################
### Code : 27.06                                                              ###
### This script split int files into equal window size files.                 ### 
### This way the probability of each window can be calculated using rHMM.pl   ### 
###                                                                           ###
###                                                                           ###
###                                                                           ###
#################################################################################

## Export the environment
#$ -V
file=$1

# Smallest file will have 2 hours of experiment
# As the binning is of 300 seconds --> 2 h = 24 lines of file
ws=300
splitSize=2
stepSize=$(( splitSize * 3600 / ws ))

linesFile=$(wc -l < "$file")
# lastLine=`cat $file | tail -1`
# cage=${lastLine##*cage;}
secondLine=`cat $file | head -2`
cage=${secondLine##*cage;}
fileName=`echo $fileAndExt | cut -d . -f1`
cage=${cage%;chN*}
firstLine=1

for winSize in $(seq $stepSize $stepSize $linesFile)
do
	echo -e "Lines to include from $firstLine to $winSize"
	
	# I have to keep the first line of the file with the format
	head -1 $file > "c"_$cage"_s_"$winSize 
	# sleep 2
	sed -n "$firstLine,$winSize p" $file >> "c"_$cage"_s_"$winSize
	firstLine=$(( firstLine + stepSize ))
done