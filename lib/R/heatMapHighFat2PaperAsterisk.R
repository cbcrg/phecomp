###########################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Jul 2013       ###
###########################################################
### ROUTINE TO REMAKE HEATMAPS USING ALL WEEKS OF HF    ###
### AND CUTTING THE CM EXPERIMENT TO HAVE THE SAME      ###
### NUMBER OF DEVELOPMENT WEEKS AS IN HF EXPERIMENT     ###
###########################################################

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

###### HIGH FAT GROUP 
#We use all the HF data
#weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20120502to0706_FDF_CRG_HabDevFilt_DelCage6InterMealMinSep120Nature2.tbl"
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20120502to0706_FDF_CRG_HabDevFilt_DelCage6_TwoMinFilt.tbl"
df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)
head (df.weekStats)

#Hard code
caseGroupLabel <- "forcedDiet"
controlGroupLabel <- "control"
nAnimals <- 18

#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [which (cage %% 2 != 0)] <- controlGroupLabel
df.miceGroup$group [which (cage %% 2 == 0)] <- caseGroupLabel

df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")

##Labels version for paper
##CTRL
#df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, period=period), mean))
#with intermeal interval
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

##CASE
#df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, period=period), mean))
#with intermeal interval
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

# Correction if we take into account that 20 per cent of the food was on the floor of the cage
#df.meanCase$Avg_Intake <- df.meanCase$Avg_Intake * 0.80

#Formatting data frame with shape for heat map
df.meanControl.m <- melt (df.meanControl, id.vars=c("channel", "group", "period"))
df.meanCase.m <- melt (df.meanCase, id.vars=c("channel", "group", "period"))

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
# df.meanCase.m$variable [which (df.meanCase.m$variable == "Number" & df.meanCase.m$channel == "food")] <-  "Meal Number"
# df.meanCase.m$variable [which (df.meanCase.m$variable == "Number" & df.meanCase.m$channel == "water")] <-  "Drink Number"


#Filtering habituation phase
# df.meanCase.m.Dev <- df.meanCase.m [df.meanCase.m$period != 1 & df.meanCase.m$period < 9,]
df.meanCase.m.Dev <- df.meanCase.m [df.meanCase.m$period != 1 & df.meanCase.m$period < 10,]
df.meanCase.m.Dev$period
tail(df.meanCase.m.Dev)

#Forced diet heat map
df.meanCase.m$stars <- ""

# setwd("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures/fig3ANDfigS1Dev/20150109_includingInterMealInterv")
heatMapPlotter (df.meanCase.m, main="Fold Change Force diet vs Control",  weekNotation=T)

##############
# Significance

sigResults <- c()
sigResults <- pValueCalc (df.weekStats)
row.names (sigResults) <- c (1:length (sigResults [,1] ))
df.sigResults <- as.data.frame(sigResults, stringsAsFactors=F)
colnames (df.sigResults) <- c("channel", "group", "period", "variable","significance")

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
df.sigResults$significance <- as.numeric (df.sigResults$significance)

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

#Ordering by week too
df.sigResults <- df.sigResults [with ( df.sigResults, order (period, channel, orderOut) ),]

#Filtering habituation phase
df.sigResults.Dev <- df.sigResults [df.sigResults$period != 1 & df.sigResults$period < 10, ]

df.sigResults.Dev

setwd ("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures/fig4ANDfigS4Dev")


df.meanCase.m.Dev$variable <- ""

df.meanCase.m.Dev$stars <- cut(df.sigResults.Dev$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))
tail (df.meanCase.m.Dev)
head (df.sigResults.Dev)

heatMapPlotter (df.meanCase.m.Dev, main="\n",  weekNotation="N", legPos="right", xlab="\n", ylab="\n")
ggsave (file=paste(home, "/Dropbox (CRG)/2013phecomp2shareFinal/drafts_paper/figures_20151110/fig3/", "fig3.tiff", sep=""), 
        width=5.5, height=4.5, dpi=400)

###### HABITUATION PHASE
df.meanCase.m.habPhase <- df.meanCase.m [df.meanCase.m$period == 1,]

#widthCol is used to specify for each column the percentage of the total width used
#in this case only one column (habituation phase)
widthCol <- rep (0.09,length (unique (df.meanCase.m.habPhase$week)))
df.meanCase.m.habPhase$stars <- ""
df.meanCase.m.habPhase$variable <- ""
# heatMapPlotterHab (df.meanCase.m.habPhase, main="\n",  weekNotation="N", legPos="none",
#                 xlab="\nHabituation Phase", ylab="Eating Behavior                          Drinking Behavior\n", widthCol=widthCol)

heatMapPlotterHab (df.meanCase.m.habPhase, main="\n",  weekNotation="N", legPos="none",
                   xlab="\n", ylab="\n")

ggsave (file=paste(home, "/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures_20151110/fig3/", "fig3_hab.tiff", sep=""), 
        width=5.5, height=4.5, dpi=400)

