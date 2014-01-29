#! /bin/bash

###############################################################################
###Jose Espinosa-Carrasco. CB/NPMMD-CRG. Jan 2013                           ### 
###############################################################################
### Code : 25.01                                                            ###
###                                                                         ###
### Misc functions bash                                                     ###
###                                                                         ###
### This script will be used to include bash functions commonly used in my  ###
### scripts as die, check parameters...                                     ###
### To include just call the script from the running script                 ###
### source ${bashCommonDir}generalFunctions.sh                              ###
###############################################################################

## Functions
checkParam () {
  param=$1
  scriptN=$2

  if [ -z "$param" ]
  # Checks if any params.
  then
  echo "FATAL ERROR: No parameter passed $param passed to $scriptN." 1>&2
  exit 1
  else
  echo "Param is $1" 1>&2
  echo "$1" # returning the value to set the variable
  fi
}

# This function check the parameter if it is empty set the variable to default
checkParamSet2Def () {
  param=$1
  defParam=$2
  scriptN=$3
  
  if [ -z "$param" ]
  # Checks if any params.
  then
  echo "WARNING: No parameter passed $param passed to $scriptN. Thus value is set to default $defParam" 1>&2
  echo "defParam"
  else
  echo "Param is $1" 1>&2
  echo "$1" # returning the value to set the variable
  fi
}

die() {
  echo "FATAL ERROR: $* (status $?)" 1>&2
  #add a function to send a mail when ever an error has ocurred!!!
  exit 1
} 

checkCreateDir () {
  dir2check=$1

  if [ -d $dir2check ];
  then
    echo -e "Dir $dir2check already exists!\n" 1>&2 
  else 
    mkdir "$dir2check" || die "mkdir ${dir2check} inside checkCreateDir failed"
    echo -e "Working dir $dir2check successfully created!\n" 1>&2 
  fi  
}
