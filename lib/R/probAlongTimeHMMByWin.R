##################################################################
### Jose A Espinosa. CSN/CB-CRG Group. Jun 2014                ###
##################################################################
### This script plots the probability of each cage along time  ###
### in window of time.                                         ###
### I use data to estimate a model for example habituation     ###
### then I calculate the probability of a sequence of events   ###
### produced by each animal during a given window time (for    ###
### example 2 hours, 12 hours or 24 hours                      ###
##################################################################

##Getting HOME directory
home <- Sys.getenv ("HOME")
wd<-getwd()

setwd ("/Users/jespinosa/phecomp/20140627_probOfWindowInt")

##Libraries
library (ggplot2)
library (plyr)
library(reshape)

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

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

## HIGH FAT
#Table window of 2 hours
path2Tbl <- ""
windowSize <- "2"
#Table window of 12 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20120502_FDF_habDevW1_W2_step12h/prob/tableResults.tbl"
windowSize <- "12"
#Table window of 24 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20120502_FDF_habDevW1_W2_step24h/prob/tableResults.tbl"
windowSize <- "24"

## FREE-CHOICE
#Table window of 2 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step2h/prob/tableResults.tbl"
windowSize <- "2"
#Table window of 12 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step12h/prob/tableResults.tbl"
windowSize <- "12"
#Table window of 24 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step24h/prob/tableResults.tbl"
windowSize <- "24"

df.probWin <- read.table (paste (home, path2Tbl, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=T)

head (df.probWin)
# time in days
df.probWin$time <- df.probWin$step * 300 / (3600*24)

## Labeling of the groups 
# HIGH FAT
df.probWin <- labelGroups (df.probWin)
group = "High-Fat Diet"
title = paste ("Model estimated on habituation,\nposterior probability on windows of", windowSize, "hours\n", group, "\n", sep =" " )

# FREE-CHOICE
df.probWin <- labelGroups (df.probWin, ctrlGroup = "even", labelCase = "FC diet")
group = "Free-Choice Diet"
title = paste ("Model estimated on habituation,\nposterior probability on windows of", windowSize, "hours\n", group, "\n", sep =" " )


df.probWin$cage <- as.factor (df.probWin$cage)
df.probWin$diet <- as.factor (df.probWin$diet)

probLinesPlot <- ggplot(df.probWin, aes(x=time, y=evalScore, group=cage)) + geom_point(aes(colour=diet), size = 4) +
  scale_color_manual (values=c("red", "green")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlot + theme (plot.background = element_rect(fill = 'black', colour = 'black'),
                       axis.title.x = element_text (color='white'),
                       axis.title.y = element_text (color='white'),
                       plot.title = element_text (color='white', size=base_size * 2),
                       axis.text.x = element_text (color='white'),
                       axis.text.y = element_text (color='white'),                       
                       legend.title = element_text (color='white'),
                       legend.text = element_text (color='white'),
                       legend.background = element_rect(fill = 'black'),
                       legend.key = element_rect(fill = 'black') 
                       ) 

## Two plots one with light periods and one with night periods
# Only when we are working with step size = 12 h
df.probWinStep12h <- df.probWin       
df.probWinStep12h$time - as.integer (df.probWinStep12h$time)
            
df.probWinStep12h$phase <-  sapply (df.probWinStep12h$time, y <- function (x) { if (x - as.integer (x) == 0) return ("Dark phase") else {return ("Light phase")}})
df.probWinStep12h$dietPhase <- paste (df.probWinStep12h$diet, df.probWinStep12h$phase, sep="-")
probLinesPlot <- ggplot(df.probWinStep12h, aes(x=time, y=evalScore, group=cage)) + geom_point(aes(colour=dietPhase), size = 4) +
  scale_color_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)

probLinesPlot + theme (plot.background = element_rect(fill = 'black', colour = 'black'),
                       axis.title.x = element_text (color='white'),
                       axis.title.y = element_text (color='white'),
                       plot.title = element_text (color='white', size=base_size * 2),
                       axis.text.x = element_text (color='white'),
                       axis.text.y = element_text (color='white'),                       
                       legend.title = element_text (color='white'),
                       legend.text = element_text (color='white'),
                       legend.background = element_rect(fill = 'black'),
                       legend.key = element_rect(fill = 'black') 
) 
colors()[117]
colors()[47]