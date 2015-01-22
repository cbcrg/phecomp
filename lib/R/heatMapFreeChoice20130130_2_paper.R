###########################################################
### Jose A Espinosa. CSN/CB-CRG Group. Feb 2014         ###
###########################################################
### HEAT MAPS OF EXPERIMENT 20130130 FREE CHOICE        ###
### WITHOUT TAKING INTO ACCOUNT DAY AND NIGHT           ###
###########################################################

##Loading libraries
library (ggplot2)
library (plyr)
#install.packages("reshape")
library (reshape) #melt
#install.packages("gtools")
library (gtools) #foldchange

##Getting HOME directory
home <- Sys.getenv("HOME")
# weekStatsData <- args[5]

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/heatMapFunctions.R")


###### FREE CHOICE GROUP
##Load the data
##FREE CHOICE
##data before test

#HABITUATION
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20130130_FCSC_CRG_hab_filt_TwoMinFilt.tbl"

## SC and CM of free choice are joint
# weekStatsData <- "/phecomp/20121128_heatMapPhecomp/20130130_FCSC_CRG/tblFiles/20130130_FCSC_CRG_all_filtTwoMinFiltAllFoodAnootatedAsSCTwoMinFilt.tbl"

df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)

#Hard code
caseGroupLabel <- "freeChoice"
controlGroupLabel <- "control"

nAnimals <- 18
#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [which (cage %% 2 != 0)] <- caseGroupLabel
df.miceGroup$group [which (cage %% 2 == 0)] <- controlGroupLabel

df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")
head (df.weekStats)
tail (df.weekStats)
df.weekStats$channel

### HABITUATION
#CASE
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#CTRL
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

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

df.meanCase.m.Hab <- df.meanCase.m [df.meanCase.m$period == 1,]

#widthCol is used to specify for each column the percentage of the total width used
#in this case only one column (habituation phase)
# widthCol <- rep (0.1,length (unique (df.meanCase.m.Hab$week)))
widthCol <- rep (0.09,length (unique (df.meanCase.m.Hab$week)))

heatMapPlotterHab (df.meanCase.m.Hab, main="\n",  weekNotation="N", legPos="none",
                   xlab="\nHabituation Phase", ylab="Eating Behavior                          Drinking Behavior\n", widthCol=widthCol)

#####################################
### Habituation significance

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
#df.sigResults$variable [which ( df.sigResults$variable == "Number" &  df.sigResults$channel == "food")] <-  "Meal Number"
#df.sigResults$variable [which ( df.sigResults$variable == "Number" &  df.sigResults$channel == "water")] <-  "Drink Number"

#Filtering only first habituation week
df.sigResults.Hab <- df.sigResults [df.sigResults$period == 1, ]
heatMapPlotterHab (df.sigResults.Hab, main="\n",  weekNotation="N", legPos="none", mode="pvalues", xlab="\nHabituation Phase", ylab="Eating Behavior                          Drinking Behavior\n")


####################################
###### FREE CHOICE GROUP
##Load the data
##FREE CHOICE
##data before test

## SC and CM of free choice are joint
# weekStatsData <- "/phecomp/20121128_heatMapPhecomp/20130130_FCSC_CRG/tblFiles/20130130_FCSC_CRG_all_filtTwoMinFiltAllFoodAnootatedAsSCTwoMinFilt.tbl"

#DEVELOPMENT
# weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20130207to0408_FCSC_CRG_DevPhFilter_TwoMinFilt.tbl"
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20130207to0408_FCSC_CRG_DevPhFilter_NotTwoMinFilt.tbl"
# Without animal 1 and 9
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20130207to0408_FCSC_CRG_DevPhFilter_NotTwoMinFilt_without_1_9.tbl"
df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)

#Hard code
caseGroupLabel <- "freeChoice"
controlGroupLabel <- "control"

nAnimals <- 18
#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [which (cage %% 2 != 0)] <- caseGroupLabel
df.miceGroup$group [which (cage %% 2 == 0)] <- controlGroupLabel

df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")
tail (df.weekStats)
df.weekStats$channel

#Free choice do not have cd food in first week problems of matching for foldchange calculation, I filter first week out
#habituation is out
#df.weekStats <- df.weekStats [df.weekStats$period != 1,]

#Number of meals normalized for a single channel (in free choice animals we only have one channel for SC and one for CM)
head (df.weekStats [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control") , ])
# df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control")] <- df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control")] / 2

#############
#CASE
#############
#CASE
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#CTRL
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#CASE do eat SC and CD two separated heat maps
df.meanCase.SC <- df.meanCase [which (df.meanCase$channel == "food_sc" |  df.meanCase$channel == "water"),]
df.meanCase.CD <- df.meanCase [which (df.meanCase$channel == "food_cd" |  df.meanCase$channel == "water"),]

#Formatting data frame with shape for heat map
df.meanCase.SC.m <- melt (df.meanCase.SC, id.vars=c("channel", "group", "period"))
df.meanCase.CD.m <- melt (df.meanCase.CD, id.vars=c("channel", "group", "period"))

df.meanControl.m <- melt (df.meanControl, id.vars=c("channel", "group", "period"))
length (df.meanCase.SC.m$channel)
length (df.meanCase.CD.m$channel)
length (df.meanControl.m$channel)

df.meanCase.SC.m$foldChange <- foldchange (df.meanCase.SC.m$value, df.meanControl.m$value)
df.meanCase.CD.m$foldChange <- foldchange (df.meanCase.CD.m$value, df.meanControl.m$value)

df.meanCase.SC.m <- df.meanCase.SC.m [which (df.meanCase.SC.m$foldChange != "NaN") ,]
df.meanCase.CD.m <- df.meanCase.CD.m [which (df.meanCase.CD.m$foldChange != "NaN") ,]

#Changing Labels for paper figure
#With current labels is not needed
# df.meanCase.SC.m
# filterFoodSC <- df.meanCase.SC.m == "food_sc"
# df.meanCase.SC.m [filterFoodSC] <- "food"

#Removing underscores from labels for the plotting
df.meanCase.SC.m$variable <-  gsub ("_", " ", df.meanCase.SC.m$variable, ignore.case = TRUE)
df.meanCase.CD.m$variable <-  gsub ("_", " ", df.meanCase.CD.m$variable, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake

df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Rate")] <-  "b"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Avg Duration")] <-  "c"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Number")] <-  "d"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Avg Intake")] <-  "e"

df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Rate")] <-  "2"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Avg Duration")] <-  "3"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Number")] <-  "4"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Avg Intake")] <-  "5"

df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Rate")] <-  "b"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Avg Duration")] <-  "c"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Number")] <-  "d"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Avg Intake")] <-  "e"

df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Rate")] <-  "2"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Avg Duration")] <-  "3"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Number")] <-  "4"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Avg Intake")] <-  "5"

#Ordering
df.meanCase.SC.m <- df.meanCase.SC.m [with (df.meanCase.SC.m, order (period, channel, orderOut)),]
df.meanCase.CD.m <- df.meanCase.CD.m [with (df.meanCase.CD.m, order (period, channel, orderOut)),]

# Changing label Number by Number of Meals and Number of Drinks
df.meanCase.SC.m$variable [which (df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "food_sc")] <-  "Meal Number"
df.meanCase.SC.m$variable [which (df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "water")] <-  "Drink Number"

# Changing label Number by Number of Meals and Number of Drinks
#df.meanCase.CD.m$variable [which (df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "food_cd")] <-  "Meal Number"
#df.meanCase.CD.m$variable [which (df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "water")] <-  "Drink Number"

heatMapPlotter (df.meanCase.CD.m, main="Free-Choice SC\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

#La semana 0 va fuera porque solo es media semana y no es representativa
#Only 8 weeks
# df.meanCase.SC.m.Dev <- df.meanCase.SC.m [df.meanCase.SC.m$period != 1 & df.meanCase.SC.m$period < 9,]
# df.meanCase.CD.m.Dev <- df.meanCase.CD.m [df.meanCase.CD.m$period != 1 & df.meanCase.CD.m$period < 9,]
df.meanCase.SC.m.Dev <- df.meanCase.SC.m [df.meanCase.SC.m$period != 1 & df.meanCase.SC.m$period < 10,]
df.meanCase.CD.m.Dev <- df.meanCase.CD.m [df.meanCase.CD.m$period != 1 & df.meanCase.CD.m$period < 10,]

# En la semana 3 los valores de avg intermeal duration son muy parecidos
df.meanCase.SC.m.week3 <- df.meanCase.SC.m [df.meanCase.SC.m$period == 3 & df.meanCase.SC.m$variable == "Avg Intermeal Duration",]
df.meanCase.CD.m.week3 <- df.meanCase.CD.m [df.meanCase.CD.m$period == 3 & df.meanCase.SC.m$variable == "Avg Intermeal Duration",]
foldchange (df.meanCase.CD.m.week3$value,df.meanCase.SC.m.week3$value )

heatMapPlotter (df.meanCase.SC.m.Dev, main="SC channel\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")
heatMapPlotter (df.meanCase.CD.m.Dev, main="CM channel\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")


## Comparing CD food of CM mice vs SC food of CM mice
df.meanCase.CDvsSC.m <- df.meanCase.CD.m
df.meanCase.CDvsSC.m$foldChange <- foldchange (df.meanCase.CDvsSC.m$value, df.meanCase.SC.m$value)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Rate")] <-  "b"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Avg Duration")] <-  "c"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Number")] <-  "d"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Avg Intake")] <-  "e"

df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Rate")] <-  "2"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Avg Duration")] <-  "3"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Number")] <-  "4"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Avg Intake")] <-  "5"

#Ordering
df.meanCase.CDvsSC.m <- df.meanCase.CDvsSC.m [with (df.meanCase.CDvsSC.m, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
#df.meanCase.CDvsSC.m$variable [which (df.meanCase.CDvsSC.m$variable == "Number" & df.meanCase.CDvsSC.m$channel == "food_cd")] <-  "Meal Number"
#df.meanCase.CDvsSC.m$variable [which (df.meanCase.CDvsSC.m$variable == "Number" & df.meanCase.CDvsSC.m$channel == "water")] <-  "Drink Number"

#La semana 0 va fuera porque solo es media semana y no es representativa
#Only 8 weeks
# df.meanCase.CDvsSC.m.Dev <- df.meanCase.CDvsSC.m [df.meanCase.CDvsSC.m$period != 1 & df.meanCase.CDvsSC.m$period < 9,]
df.meanCase.CDvsSC.m.Dev <- df.meanCase.CDvsSC.m [df.meanCase.CDvsSC.m$period != 1 & df.meanCase.CDvsSC.m$period < 10,]

heatMapPlotter (df.meanCase.CDvsSC.m.Dev, main="CM vs SC channel\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")



### SIGNIFICANCE
### SIGNIFICANCE RESULTS
#do to df.weekStats one only with water and SC events and a second one with water and CM
df.weekStats.SC <- df.weekStats [which (df.weekStats$channel == "food_sc" |  df.weekStats$channel == "water"),]

sigResults.SC <- c()
sigResults.SC <- pValueCalc (df.weekStats.SC)

row.names (sigResults.SC) <- c (1:length (sigResults.SC [,1] ))
df.sigResults.SC <- as.data.frame(sigResults.SC, stringsAsFactors=F)
colnames (df.sigResults.SC) <- c("channel", "group", "period", "variable","foldChange")
df.sigResults.SC
#order the data by period
df.sigResults.SC$period <- as.numeric (df.sigResults.SC$period)
df.sigResults.SC$week <-df.sigResults.SC$period
df.sigResults.SC$week <- with (df.sigResults.SC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.SC$variable <-  gsub ("_", " ", df.sigResults.SC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.SC$chVar <- df.sigResults.SC$variable
#fold change have to be numeric to make the function work
df.sigResults.SC$foldChange <- as.numeric (df.sigResults.SC$foldChange)

############
## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
## First df.meanCase.m has to be created
# to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
#OJO la tabla df.meanCase.SC.m tiene que tener anotado el channel como food_sc y no solo como food y Avg Intake y Avg duration no tienen que tener underscore
for (i in c (1: length (df.sigResults.SC [,1])))
{
  print (i)
  foldChange <- df.meanCase.SC.m [df.meanCase.SC.m$channel == df.sigResults.SC$channel [i] 
                                  & df.meanCase.SC.m$group == df.sigResults.SC$group [i]
                                  & df.meanCase.SC.m$period == df.sigResults.SC$period [i]
                                  & df.meanCase.SC.m$variable == df.sigResults.SC$variable [i], "foldChange"]
  #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
  print (foldChange)
  if (length (foldChange) == 0) print (i) 
  if (foldChange < 0) {print (as.numeric (-df.sigResults.SC$foldChange [i]))}
  if (foldChange < 0) {df.sigResults.SC$foldChange [i] <- as.numeric(-df.sigResults.SC$foldChange [i]) -1  }
}


#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.SC$varOrder<- "dummy"
df.sigResults.SC$varOrder [which ( df.sigResults.SC$variable =="Avg Intermeal Duration")] <-  "a"
df.sigResults.SC$varOrder [which ( df.sigResults.SC$variable == "Rate")] <-  "b"
df.sigResults.SC$varOrder [which ( df.sigResults.SC$variable == "Avg Duration")] <-  "d"
df.sigResults.SC$varOrder [which ( df.sigResults.SC$variable == "Number")] <-  "d"
df.sigResults.SC$varOrder [which ( df.sigResults.SC$variable == "Avg Intake")] <-  "e"
df.sigResults.SC$orderOut<- "dummy"
df.sigResults.SC$orderOut [which ( df.sigResults.SC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.SC$orderOut [which ( df.sigResults.SC$variable == "Rate")] <-  "2"
df.sigResults.SC$orderOut [which ( df.sigResults.SC$variable == "Avg Duration")] <-  "3"
df.sigResults.SC$orderOut [which ( df.sigResults.SC$variable == "Number")] <-  "4"
df.sigResults.SC$orderOut [which ( df.sigResults.SC$variable == "Avg Intake")] <-  "5"

#Old command to order
#  df.sigResults.SC <-  df.sigResults.SC [with ( df.sigResults.SC, order (period, channel, variable)),]
df.sigResults.SC <-  df.sigResults.SC [with ( df.sigResults.SC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.SC$variable [which ( df.sigResults.SC$variable == "Number" &  df.sigResults.SC$channel == "food_sc")] <-  "Meal Number"
df.sigResults.SC$variable [which ( df.sigResults.SC$variable == "Number" &  df.sigResults.SC$channel == "water")] <-  "Drink Number"

#La semana 0 va fuera porque solo es media semana y no es representativa
#Only 8 weeks
df.meanCase.SC.m.Dev <- df.meanCase.SC.m [df.meanCase.SC.m$period != 1 & df.meanCase.SC.m$period < 9,]
df.sigResults.SC.Dev <- df.sigResults.SC [df.sigResults.SC$period != 1 & df.sigResults.SC$period < 10,]

# heatMapPlotter (df.sigResults.SC, main="Free-choice SC\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
heatMapPlotter (df.sigResults.SC, main="Free-choice SC\n",   weekNotation = "N", mode="pvalues", legPos="right", xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

###########
#Comparison of joined channels SC and choc of free choice with controls
heatMapPlotter (df.sigResults.SC.Dev, main="SC channel\n",   weekNotation = "N", mode="pvalues", legPos="right", xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")


####### CD CHANNEL
# CD channel
#here I have to get for food not only the free choice CD but also the controls with SC to make the comparison possible
df.weekStats.CD <- df.weekStats [which (df.weekStats$channel == "food_cd" |  df.weekStats$channel == "water" | (df.weekStats$channel == "food_sc"  & df.weekStats$group == "control") ),]

df.weekStats.CD$chType <-  gsub ("food_sc", "food", df.weekStats.CD$channel, ignore.case = TRUE)
df.weekStats.CD$chType <-  gsub ("food_cd", "food", df.weekStats.CD$chType, ignore.case = TRUE)

sigResults.CD <- c()

for (p in unique (df.weekStats.CD$period))
{
  for (ch in unique (df.weekStats.CD$chType))
  {
    print (ch)
    df.subset <- subset (df.weekStats.CD, period == p & chType == ch, 
                         select = c(period, channel, group, cage, Avg_Intermeal_Duration, Rate, Number, Avg_Intake, Avg_Duration))
    print ("--------")
    print (df.subset)
    #The first columns with categorical data do not need to be include in signif calculation
    signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
                            function (x)
                            {
                              #wilcox test
                              unlist (wilcox.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                              #t test
                              #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvgIntermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    
    sigResults.CD <- rbind (sigResults.CD, rAvgIntermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

row.names (sigResults.CD) <- c (1:length (sigResults.CD [,1] ))
df.sigResults.CD <- as.data.frame(sigResults.CD, stringsAsFactors=F)
colnames (df.sigResults.CD) <- c("channel", "group", "period", "variable","foldChange")
df.sigResults.CD

#order the data by period
df.sigResults.CD$period <- as.numeric (df.sigResults.CD$period)
df.sigResults.CD$week <-df.sigResults.CD$period
df.sigResults.CD$week <- with (df.sigResults.CD, reorder (week, period,))

#removing underscores for plotting
df.sigResults.CD$variable <-  gsub ("_", " ", df.sigResults.CD$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.CD$chVar <- df.sigResults.CD$variable
#fold change have to be numeric to make the function work
df.sigResults.CD$foldChange <- as.numeric (df.sigResults.CD$foldChange)

#Volver a poner el campo como food_cd
df.sigResults.CD$channel <-  gsub ("food", "food_cd", df.sigResults.CD$channel, ignore.case = TRUE)

############
## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
## First df.meanCase.m has to be created
# to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
for (i in c (1: length (df.sigResults.CD [,1])))
{
  print (i)
  foldChange <- df.meanCase.CD.m [df.meanCase.CD.m$channel == df.sigResults.CD$channel [i] 
                                  & df.meanCase.CD.m$group == df.sigResults.CD$group [i]
                                  & df.meanCase.CD.m$period == df.sigResults.CD$period [i]
                                  & df.meanCase.CD.m$variable == df.sigResults.CD$variable [i], "foldChange"]
  #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
  print (foldChange)
  if (foldChange < 0) {print (as.numeric (-df.sigResults.CD$foldChange [i]))}
  if (foldChange < 0) {df.sigResults.CD$foldChange [i] <- as.numeric(-df.sigResults.CD$foldChange [i]) -1  }
}

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.CD$varOrder<- "dummy"
df.sigResults.CD$varOrder [which ( df.sigResults.CD$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.CD$varOrder [which ( df.sigResults.CD$variable == "Rate")] <-  "b"
df.sigResults.CD$varOrder [which ( df.sigResults.CD$variable == "Avg Duration")] <-  "c"
df.sigResults.CD$varOrder [which ( df.sigResults.CD$variable == "Number")] <-  "d"
df.sigResults.CD$varOrder [which ( df.sigResults.CD$variable == "Avg Intake")] <-  "e"
df.sigResults.CD$orderOut<- "dummy"
df.sigResults.CD$orderOut [which ( df.sigResults.CD$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.CD$orderOut [which ( df.sigResults.CD$variable == "Rate")] <-  "2"
df.sigResults.CD$orderOut [which ( df.sigResults.CD$variable == "Avg Duration")] <-  "3"
df.sigResults.CD$orderOut [which ( df.sigResults.CD$variable == "Number")] <-  "4"
df.sigResults.CD$orderOut [which ( df.sigResults.CD$variable == "Avg Intake")] <-  "5"

#Old command to order
#  df.sigResults.CD <-  df.sigResults.CD [with ( df.sigResults.CD, order (period, channel, variable)),]
df.sigResults.CD <-  df.sigResults.CD [with ( df.sigResults.CD, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.CD$variable [which ( df.sigResults.CD$variable == "Number" &  df.sigResults.CD$channel == "food_cd")] <-  "Meal Number"
df.sigResults.CD$variable [which ( df.sigResults.CD$variable == "Number" &  df.sigResults.CD$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
df.sigResults.CD.Dev <- df.sigResults.CD [df.sigResults.CD$period > 1 & df.sigResults.CD$period < 10,]
# df.sigResults.CD.Dev$period <- df.sigResults.CD.Dev$period - 7

# heatMapPlotter (df.sigResults.CD.Dev, main="Free choice Diet CD vs Control SC",   mode="pvalues")
# heatMapPlotter (df.sigResults.CD, main="Free-choice CM\n",   weekNotation = "N", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
heatMapPlotter (df.sigResults.CD.Dev, main="Free-choice CM\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

#####################
#####################

#####################################################
## Comparing CD food of CM mice vs SC food of CM mice
# Has to be done before any variable name is changed
df.meanCase.CDvsSC.m <- df.meanCase.CD.m
df.meanCase.CDvsSC.m$foldChange <- foldchange (df.meanCase.CDvsSC.m$value, df.meanCase.SC.m$value)

df.weekStats.CDvsSC <- df.weekStats [which (df.weekStats$channel == "food_cd" |  df.weekStats$channel == "water" & df.weekStats$group == "freeChoice" | (df.weekStats$channel == "food_sc"  & df.weekStats$group == "freeChoice") ),]
#Duplication of water rows to make possible the comparison, should be always fold change of 0 (Black)
df.weekStats.CDvsSC.Water2<- df.weekStats [which (df.weekStats$channel == "water" & df.weekStats$group == "freeChoice"),]
head (df.weekStats.CDvsSC)
head (df.weekStats.CDvsSC.Water2)
df.weekStats.CDvsSC.Water2$channel <- "water2"
df.weekStats.CDvsSC <- rbind (df.weekStats.CDvsSC, df.weekStats.CDvsSC.Water2 )

df.weekStats.CDvsSC$chType <-  gsub ("food_sc", "food", df.weekStats.CDvsSC$channel, ignore.case = TRUE)
df.weekStats.CDvsSC$chType <-  gsub ("food_cd", "food", df.weekStats.CDvsSC$chType, ignore.case = TRUE)
df.weekStats.CDvsSC$chType <-  gsub ("water2", "water", df.weekStats.CDvsSC$chType, ignore.case = TRUE)
sigResults.CDvsSC <- c()
for (p in unique (df.weekStats.CDvsSC$period))
{
  
  for (ch in unique (df.weekStats.CDvsSC$chType))
  {
    print (ch)
    df.subset <- subset (df.weekStats.CDvsSC, period == p & chType == ch, 
                         select = c(period, channel, group, cage, Avg_Intermeal_Duration, Rate, Number, Avg_Intake, Avg_Duration))
    print ("--------")
    print (df.subset)
    #The first columns with categorical data do not need to be include in signif calculation
    signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
                            function (x)
                            {
                              #wilcox test
                              unlist (wilcox.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
                              #t test
                              #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvg_Intermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    sigResults.CDvsSC <- rbind (sigResults.CDvsSC, rAvg_Intermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}
# warnings ()
# head (sigResults.CD,80)
row.names (sigResults.CDvsSC) <- c (1:length (sigResults.CDvsSC [,1] ))
df.sigResults.CDvsSC <- as.data.frame(sigResults.CDvsSC, stringsAsFactors=F)
colnames (df.sigResults.CDvsSC) <- c("channel", "group", "period", "variable","foldChange")
df.sigResults.CDvsSC
#order the data by period
df.sigResults.CDvsSC$period <- as.numeric (df.sigResults.CDvsSC$period)
df.sigResults.CDvsSC$week <-df.sigResults.CDvsSC$period
df.sigResults.CDvsSC$week <- with (df.sigResults.CDvsSC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.CDvsSC$variable <-  gsub ("_", " ", df.sigResults.CDvsSC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.CDvsSC$chVar <- df.sigResults.CDvsSC$variable
#fold change have to be numeric to make the function work
df.sigResults.CDvsSC$foldChange <- as.numeric (df.sigResults.CDvsSC$foldChange)
#Volver a poner el campo como food_cd
df.sigResults.CDvsSC$channel <-  gsub ("food", "food_cd", df.sigResults.CDvsSC$channel, ignore.case = TRUE)
############
## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
## First df.meanCase.m has to be created
# to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 

for (i in c (1: length (df.meanCase.CDvsSC.m [,1])))
{
  print (i)
  foldChange <- df.meanCase.CDvsSC.m [df.meanCase.CDvsSC.m$channel == df.sigResults.CDvsSC$channel [i] 
                                      & df.meanCase.CDvsSC.m$group == df.sigResults.CDvsSC$group [i]
                                      & df.meanCase.CDvsSC.m$period == df.sigResults.CDvsSC$period [i]
                                      & df.meanCase.CDvsSC.m$variable == df.sigResults.CDvsSC$variable [i], "foldChange"]
  #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
  print (foldChange)
  if (foldChange < 0) {print (as.numeric (-df.sigResults.CDvsSC$foldChange [i]))}
  if (foldChange < 0) {df.sigResults.CDvsSC$foldChange [i] <- as.numeric(-df.sigResults.CDvsSC$foldChange [i]) -1  }
}

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.CDvsSC$varOrder<- "dummy"
df.sigResults.CDvsSC$varOrder [which ( df.sigResults.CDvsSC$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.CDvsSC$varOrder [which ( df.sigResults.CDvsSC$variable == "Rate")] <-  "b"
df.sigResults.CDvsSC$varOrder [which ( df.sigResults.CDvsSC$variable == "Avg Duration")] <-  "c"
df.sigResults.CDvsSC$varOrder [which ( df.sigResults.CDvsSC$variable == "Number")] <-  "d"
df.sigResults.CDvsSC$varOrder [which ( df.sigResults.CDvsSC$variable == "Avg Intake")] <-  "e"
df.sigResults.CDvsSC$orderOut<- "dummy"
df.sigResults.CDvsSC$orderOut [which ( df.sigResults.CDvsSC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.CDvsSC$orderOut [which ( df.sigResults.CDvsSC$variable == "Rate")] <-  "2"
df.sigResults.CDvsSC$orderOut [which ( df.sigResults.CDvsSC$variable == "Avg Duration")] <-  "3"
df.sigResults.CDvsSC$orderOut [which ( df.sigResults.CDvsSC$variable == "Number")] <-  "4"
df.sigResults.CDvsSC$orderOut [which ( df.sigResults.CDvsSC$variable == "Avg Intake")] <-  "5"

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













