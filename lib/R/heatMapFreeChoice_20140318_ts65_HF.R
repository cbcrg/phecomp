#####################################################################
### Jose A Espinosa. CSN/CB-CRG Group. March 2015                 ###
#####################################################################
### ROUTINE TO PRODUCE HEATMAPS OF EXPERIMENT 20140318_TS_CRG_HF  ###
#####################################################################

##Loading libraries
library (ggplot2)
library (plyr)
#install.packages("reshape")
library (reshape) #melt
library (gtools) #foldchange

##Getting HOME directory
home <- Sys.getenv("HOME")
# weekStatsData <- args[5]

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/heatMapFunctions.R")

setwd ("/Users/jespinosa/phecomp/20121128_heatMapPhecomp/figures/20140318_TS_CRG_HF")

###### 
## Load the data
## Groups are only separated by genotype WT and ts65dn with same diet HF
##############
## WT animals
## 1, 3, 5, 7, 9, 11, 13, 15, 16, 17, 18
##############
## TS 65dn
## 2, 4, 6, 8, 10, 12, 14, 16

## DATA 
## int2combo.pl 20140318_TS_CRG_HF_corrected_dev_filtTwoMinFilt.int -bin -annotate interInterval meals -period period week -stat output R labels compulse> ../tblFiles/20140318_TS_CRG_HF_corrected_dev_filtTwoMinFilt.tbl
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20140318_TS_CRG_HF_corrected_dev_filtTwoMinFilt.tbl"

df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)

#Hard code
caseGroupLabel <- "ts65dn"  # CASE    == ts65dn
controlGroupLabel <- "wt"   # CONTROL == wt 

nAnimals <- 18
#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [c(1, 3, 5, 7, 9, 11, 13, 15, 16, 17, 18)] <- controlGroupLabel
df.miceGroup$group [c(2, 4, 6, 8, 10, 12, 14, 16)] <- caseGroupLabel
  
# Joining labels
df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")
head (df.weekStats)
tail (df.weekStats,100)
df.weekStats$channel

### HABITUATION
#CASE ts65dn
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#CTRL
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#Formatting data frame with shape for heat map
df.meanControl.m <- melt (df.meanControl, id.vars=c("channel", "group", "period"))
df.meanCase.m <- melt (df.meanCase, id.vars=c("channel", "group", "period"))

# Intermeal duration for water not calculated
#
df.meanCase.m$foldChange <- foldchange (df.meanCase.m$value,df.meanControl.m$value)

length(df.meanCase.m$value)
length(df.meanControl.m$value)
df.meanCase.m$week <-df.meanCase.m$period
df.meanCase.m$week <- paste ("week", df.meanCase.m$period, sep = "_")   

#Ordering week column as period
df.meanCase.m$period <- as.numeric (df.meanCase.m$period)
df.meanCase.m$week <- with (df.meanCase.m, reorder (week, period,))

#Merging channel and variable
#df.meanCase.m$chVar <- paste (df.meanCase.m$channel, df.meanCase.m$variable, sep = "_")
df.meanCase.m$variable <-  gsub ("_", " ", df.meanCase.m$variable, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
df.meanCase.m$varOrder [which (df.meanCase.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanCase.m$varOrder [which (df.meanCase.m$variable == "Rate")] <-  "b"
df.meanCase.m$varOrder [which (df.meanCase.m$variable == "Avg Duration")] <-  "c"
df.meanCase.m$varOrder [which (df.meanCase.m$variable == "Number")] <-  "d"
df.meanCase.m$varOrder [which (df.meanCase.m$variable == "Avg Intake")] <-  "e"

df.meanCase.m$orderOut [which (df.meanCase.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanCase.m$orderOut [which (df.meanCase.m$variable == "Rate")] <-  "2"
df.meanCase.m$orderOut [which (df.meanCase.m$variable == "Avg Duration")] <-  "3"
df.meanCase.m$orderOut [which (df.meanCase.m$variable == "Number")] <-  "4"
df.meanCase.m$orderOut [which (df.meanCase.m$variable == "Avg Intake")] <-  "5"


#Old command to order
# df.meanCase.m <- df.meanCase.m [with (df.meanCase.m, order (period, channel, variable)),]
df.meanCase.m <- df.meanCase.m [with (df.meanCase.m, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
# To plot significance this must be comment because meal number and drink number won't be recognized #Tag_sig
# df.meanCase.m$variable [which (df.meanCase.m$variable == "Number" & df.meanCase.m$channel == "food_fat")] <-  "Meal Number"
# df.meanCase.m$variable [which (df.meanCase.m$variable == "Number" & df.meanCase.m$channel == "water")] <-  "Drink Number"

df.meanCase.m.Hab <- df.meanCase.m [df.meanCase.m$period == 1,]

#widthCol is used to specify for each column the percentage of the total width used
#in this case only one column (habituation phase)
# widthCol <- rep (0.1,length (unique (df.meanCase.m.Hab$week)))
widthCol <- rep (0.09,length (unique (df.meanCase.m.Hab$week)))

heatMapPlotterHab (df.meanCase.m.Hab, main="\n",  weekNotation="N", legPos="none",
                   xlab="\nHabituation Phase", ylab="Eating Behavior                          Drinking Behavior\n", widthCol=widthCol)

#############
#DEVELOPMENT
#############

df.meanCase.m.Dev <- df.meanCase.m [df.meanCase.m$period > 1,]

heatMapPlotter (df.meanCase.m.Dev, main="High-Fat Diet\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

#####################################
### Significance

sigResults <- c()
sigResults <- pValueCalc (df.weekStats)
row.names (sigResults) <- c (1:length (sigResults [,1] ))
df.sigResults <- as.data.frame(sigResults, stringsAsFactors=F)
colnames (df.sigResults) <- c("channel", "group", "period", "variable","foldChange")

#order the data by period
df.sigResults$period <- as.numeric (df.sigResults$period)
df.sigResults$week <-df.sigResults$period
df.sigResults$week <- with (df.sigResults, reorder (week, period,))

#removing underscores for plotting
df.sigResults$variable <-  gsub ("_", " ", df.sigResults$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults$chVar <- df.sigResults$variable
#fold change have to be numeric to make the function work
df.sigResults$foldChange <- as.numeric (df.sigResults$foldChange)

############
## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
## First df.meanCase.m has to be created
# to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
for (i in c (1: length (df.sigResults [,1])))
{
  print (i)
  foldChange <- df.meanCase.m [df.meanCase.m$channel == df.sigResults$channel [i] 
                               & df.meanCase.m$group == df.sigResults$group [i]
                               & df.meanCase.m$period == df.sigResults$period [i]
                               & df.meanCase.m$variable == df.sigResults$variable [i], "foldChange"]
  print (foldChange)
  if (foldChange < 0) {print (as.numeric (-df.sigResults$foldChange [i]))}
  if (foldChange < 0) {df.sigResults$foldChange [i] <- as.numeric(-df.sigResults$foldChange [i]) -1  }
}

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults$varOrder<- "dummy"
df.sigResults$varOrder [which ( df.sigResults$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults$varOrder [which ( df.sigResults$variable == "Rate")] <-  "b"
df.sigResults$varOrder [which ( df.sigResults$variable == "Avg Duration")] <-  "c"
df.sigResults$varOrder [which ( df.sigResults$variable == "Number")] <-  "d"
df.sigResults$varOrder [which ( df.sigResults$variable == "Avg Intake")] <-  "e"
df.sigResults$orderOut<- "dummy"
df.sigResults$orderOut [which ( df.sigResults$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults$orderOut [which ( df.sigResults$variable == "Rate")] <-  "2"
df.sigResults$orderOut [which ( df.sigResults$variable == "Avg Duration")] <-  "3"
df.sigResults$orderOut [which ( df.sigResults$variable == "Number")] <-  "4"
df.sigResults$orderOut [which ( df.sigResults$variable == "Avg Intake")] <-  "5"

#Old command to order
#  df.sigResults <-  df.sigResults [with ( df.sigResults, order (period, channel, variable)),]
df.sigResults <-  df.sigResults [with ( df.sigResults, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults$variable [which ( df.sigResults$variable == "Number" &  df.sigResults$channel == "food_fat")] <-  "Meal Number"
df.sigResults$variable [which ( df.sigResults$variable == "Number" &  df.sigResults$channel == "water")] <-  "Drink Number"

#########
# Habituation 

#Filtering only first habituation week
df.sigResults.Hab <- df.sigResults [df.sigResults$period == 1, ]
heatMapPlotterHab (df.sigResults.Hab, main="\n",  weekNotation="N", legPos="none", mode="pvalues", xlab="\nHabituation Phase", ylab="Eating Behavior                          Drinking Behavior\n")

#########
# Development
df.sigResults.Dev <- df.sigResults [df.sigResults$period > 1, ]
heatMapPlotter (df.sigResults.Dev, main="High-Fat diet\n",  weekNotation="N", legPos="right", mode="pvalues", 
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                                  Water\n")





#ordering
df.sigResults.CDvsSC <-  df.sigResults.CDvsSC [with ( df.sigResults.CDvsSC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.CDvsSC$variable [which ( df.sigResults.CDvsSC$variable == "Number" &  df.sigResults.CDvsSC$channel == "food_cd")] <-  "Meal Number"
df.sigResults.CDvsSC$variable [which ( df.sigResults.CDvsSC$variable == "Number" &  df.sigResults.CDvsSC$channel == "water")] <-  "Drink Number"


#Filtering habituation phase
df.sigResults.CDvsSC.Dev <- df.sigResults.CDvsSC [df.sigResults.CDvsSC$period > 1 & df.sigResults.CDvsSC$period < 10,]
# df.sigResults.CDvsSC.Dev$period <- df.sigResults.CDvsSC.Dev$period - 7

# heatMapPlotter (df.sigResults.CD.Dev, main="Free choice Diet CD vs Control SC",   mode="pvalues")
# heatMapPlotter (df.sigResults.CDvsSC, main="Free-choice CM\n",   weekNotation = "N", mode="pvalues", xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")
heatMapPlotter (df.sigResults.CDvsSC.Dev, main="CM vs SC Channel (signficance level)\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment phase (weeks)",ylab="Eating Behavior                          Drinking Behavior\n")
















