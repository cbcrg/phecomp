#!/usr/bin/env Rscript

#############################################################
### Jose A Espinosa. CSN/CB-CRG Group. November 2013      ###
#############################################################
### A simple script to plot the results of the HMM        ###
### evaluation of sequences of development week using the ###
### model estimated using the habituation data. Called    ###
### directly by the bash routine                          ###
### In this case we will plot the overall results of each ###
### comparison using a boxplot                            ###
#############################################################

# Example of execution
# boxPlotsEvalHMMAuto.R --tblEval=/Users/jespinosa/phecomp/20131106_HMM/20130610_HMMfourSignal/results4/20120502_FDF_CRG_HabFiltWs1800/evaluation/evalfour1800.tbl path2plot=/Users/jespinosa/phecomp/debugging/intModelFiles

# To use this script in ant first export this:
# export R_LIBS="/software/R/packages"

# write("prints to stderr", stderr())

##Getting HOME directory
home <- Sys.getenv ("HOME")
wd<-getwd()

library (ggplot2)
library (plyr)
library(reshape)

#####################
### VARIABLES
#Reading arguments
args <- commandArgs (TRUE) #if not it doesn't start to count correctly

## Default setting when no arguments passed
if ( length(args) < 1) {
  args <- c("--help")
}

## Help section
if("--help" %in% args) {
  cat("
      boxPlotsEvalHMMAuto
 
      Arguments:
      --tblEval=someValue    - character, path to table file
      --path2plot=someValue  - character, path to dump plots
      --labCase=someValue    - character, name of case group
      --labCtrl=someValue    - character, name of ctrl group
      --ctrlGroup=odd, even  - character, group that is control
      --help                 - print this text
 
      Example:
      ./test.R --tblEval=\"/foo/tbl.txt\" --path2plot=\"/foo/plots\" --labCase=\"HF diet\" --labCtrl=\"SC diet\" --ctrlGroup=\"odd/even\"\n\n")
 
  q (save="no")
}

#####################
##Loading functions
# source ("/Users/jespinosa/phecomp/lib/R/plotParameters.R")

# Use to parse arguments beginning by --
parseArgs <- function(x) 
  {
    strsplit (sub ("^--", "", x), "=")
  }

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
############# END functions

#Parsing arguments
argsDF <- as.data.frame (do.call("rbind", parseArgs(args)))
argsL <- as.list (as.character(argsDF$V2))
names (argsL) <- argsDF$V1
# print (argsL)

## tblEval mandatory
{
  if (is.null (argsL$tblEval)) 
    {
      stop ("[FATAL]: Path to table not provided as a parameter")
    }
  else
    {
      path2TblScores <- argsL$tblEval
    }
}

{
  if (is.null (argsL$path2plot)) 
    {
      print ("[Warning]: Plots will be dump in wd as not path was provided")
      path2plot <- wd  
    }
  else
    {
      path2plot <- argsL$path2plot
    }
}

setwd (path2plot)

# path2TblScores <- "/Users/jespinosa/phecomp/20131106_HMM/20130610_HMMfourSignal/results4/20120502_FDF_CRG_HabFiltWs1800/evaluation/evalfour1800.tbl"
path2TblScores <- "/Users/jespinosa/phecomp/20130610_HMMfourSignal/resultsMunchen/20120502_FDF_CRG_hab_filt/20120502_FDF_CRG_hab_DevW1_W2_filtWs300/evaluation/evalfour300.tbl"
# print (path2plot)
# print (path2TblScores)

df.scoresEval <- read.table (paste (path2TblScores, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=T)

# Assign control and case group
{
  if (is.null (argsL$labCase)) 
    {
      labelCase <- "HF diet"
    }
  else
    {
      labelCase <- argsL$labCase 
    }
}

{
  if (is.null (argsL$labCtrl)) 
    {
      labelCtrl <- "SC diet"
    }
  else
    {
      labelCtrl <- argsL$labCtrl 
    }
}

{
  if (is.null (argsL$ctrlGroup) || argsL$ctrlGroup != "even") 
    {
      ctrlGroup <- "odd"
    }
  else
    {
      ctrlGroup <- argsL$ctrlGroup 
    }
}

df.scoresEval <- labelGroups (df.scoresEval, ctrlGroup = ctrlGroup, labelCase = labelCase, labelCtrl=labelCtrl)

## Control first in boxplot
# High-Fat group
df.scoresEval$diet <- factor(df.scoresEval$diet,
                      levels = c('SC diet','HF diet'), ordered = TRUE)

source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

boxPlots <- ggplot (df.scoresEval, aes (diet, score, fill =diet)) + 
                   geom_boxplot (size =0.3) + labs (y = "score = log (p)\n") +
                   geom_jitter(position = position_jitter(width = 0), size=2.5, color="black") +                   
                   scale_fill_manual(name = "Group", values = c("darkgreen", "red")) +
                   theme (legend.position = "none") 


boxPlots

boxPlotsBlack <- ggplot (df.scoresEval, aes (diet, score, fill =diet)) +   
  geom_boxplot (size =1, color='white', outlier.colour='white') + labs (y = "score = log (p)\n") +
  scale_fill_manual (name = "Group", values = c("green", "red")) +
  theme(legend.position="none")
  

source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublicationBlack.R")

boxPlotsBlack
tblMeans <- ddply (df.scoresEval, ~diet, summarise, mean = mean (score), sd = sd (score))

# write (paste (gsub (" ", "", tblMeans$diet [1], fixed=TRUE), "\t", gsub (" ", "", tblMeans$diet [2], fixed=TRUE), "\t", tblMeans$mean [1], "\t",tblMeans$mean [2], "\t", tblMeans$sd [1], "\t", tblMeans$sd [2]), stdout())
write (paste (gsub (" ", "", tblMeans$diet [1], fixed=TRUE), gsub (" ", "", tblMeans$diet [2], fixed=TRUE), tblMeans$mean [1], tblMeans$mean [2], tblMeans$sd [1], tblMeans$sd [2], tblMeans$mean [1] - tblMeans$mean [2], sep="\t"), stdout())


# + guides(fill=FALSE)
                
                   #scale_fill_manual(name = "Group", values = c("green", "brown"), labels = c ("Control", "Free Choice")) +
                   #scale_fill_manual (name = "Group", values = c ("green", "brown")) +
#                    opts (title = "Boxplots % of delta weight by development week") + facet_grid (week~phase)