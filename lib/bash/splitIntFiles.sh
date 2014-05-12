#! /bin/bash

#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. May 2014                              ### 
#################################################################################
### Code : 12.05                                                              ###
### This script produces increasingly bigger bin files to see how is the      ### 
### evolution of probability along the time when running rHMM.pl              ### 
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

for winSize in $(seq $stepSize $stepSize $linesFile)
do
	echo $winSize
	sed -n "1,$winSize p" $file > "file_"$winSize
done