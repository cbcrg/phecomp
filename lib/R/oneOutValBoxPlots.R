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

#Habituation table
path2OneOutTbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsOneOut/20120502_FDF_hab/tblEvalOneOut.tbl"
title = "Model trainned without a cage during habituation \n and cages evaluated during same period"
#Development table 
path2OneOutTbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/oldResults/resultsOneOut/20120502_FDF_dev/tblEvalOneOutDev.tbl"
title = "Model trainned without a cage during habituation \n and cages evaluated during development"

df.oneOutEval <- read.table (path2OneOutTbl, sep="\t", dec=".", header=T, stringsAsFactors=T)
df.oneOutEval$cage <- df.oneOutEval$evalCage

ctrlGroup <- "odd"
labelCtrl <- "SC diet"
labelCase <- "HF diet"

df.oneOutEval <- labelGroups (df.oneOutEval, ctrlGroup = ctrlGroup, labelCase = labelCase, labelCtrl=labelCtrl)
head (df.oneOutEval)

df.oneOutEvalFilt <- df.oneOutEval [df.oneOutEval[,"cageOut"] != df.oneOutEval[,"cage"], ]
# Here I keep the value of the cage that has been filtered out for the trainning
df.oneOutEvalValue <- df.oneOutEval [df.oneOutEval[,"cageOut"] == df.oneOutEval[,"cage"], ]

boxPlots <- ggplot (df.oneOutEvalFilt, aes (diet, score, fill =diet)) + 
            geom_boxplot() + labs (y = "score = log (p)\n") +
            #scale_y_continuous(limits=c(-4500,-1200)) + 
            scale_fill_manual(name = "Group", values = c("red", "green")) +
            labs (title = title) +
            # add the point of animals not used for the training 
            geom_point (data=df.oneOutEvalValue, 
                        aes(x=diet, y=score), 
                        color="black", size=3) +
            facet_wrap (~cageOut)
boxPlots
df.oneOutEvalValue <-df.oneOutEvalValue [df.oneOutEvalValue[,"cageOut"] != 11, ]

boxPlotsAnimalNotUsedTraining <- ggplot (df.oneOutEvalValue, aes (diet, score, fill =diet)) + 
                                 geom_boxplot() + labs (y = "score = log (p)\n") +
                                 #scale_y_continuous(limits=c(-4500,-2500)) + 
                                 scale_fill_manual(name = "Group", values = c("red", "green")) +
                                 labs (title = title)   
boxPlotsAnimalNotUsedTraining + geom_point (position = position_jitter(width = 0.3), color="blue", size=3)
boxPlotsAnimalNotUsedTraining + geom_jitter ()

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