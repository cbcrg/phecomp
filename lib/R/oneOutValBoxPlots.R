#############################################################
### Jose A Espinosa. CSN/CB-CRG Group. June 2014          ###
#############################################################
### Plotting the results of the one out validation with   ###
### all the scatter plot correspoding to each run leaving ###
### one animal out                                        ###
#############################################################

##Getting HOME directory
home <- Sys.getenv ("HOME")
wd<-getwd()

##Libraries
library (ggplot2)
library (plyr)
library(reshape)

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

path2OneOutTbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsOneOut/20120502_FDF_hab/tblEvalOneOut.tbl"
df.oneOutEval <- read.table (path2OneOutTbl, sep="\t", dec=".", header=T, stringsAsFactors=T)
df.oneOutEval

#####################
##Loading functions
labelGroups <- function (df.data, ctrlGroup = "odd", labelCase = "HF diet", labelCtrl="SC diet")
{    
  df.data$diet <- labelCtrl
  
  if (ctrlGroup == "odd")
  {       
    df.data$diet [which (df.data$cage%% 2 == 0)] <- labelCase    
  }
  else 
  {        
    df.data$diet [which (df.data$cage%% 2 != 0)] <- labelCase
  }
  
  return (df.data)
}