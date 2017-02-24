#######################################################################
### Jose A Espinosa. CSN/CB-CRG Group. February 2017                ###
#######################################################################
### ROUTINE TO PRODUCE HEATMAPS OF EXPERIMENT trisomic free choice  ###
### eating chocolate chow.                                          ###
### In this script we analyze data corresponding to a batch of mice ###
### with a free choice between chocolate and SC. The experiment is  ###
### performed in two batches and both experiments have both wt and  ###
### and ts65dn animals. In this script we compared within each of   ###
### the genotypes the behavior on the choc channel vs the behavior  ###
### of the SC channel.                                              ###
#######################################################################

##Loading libraries
library (ggplot2)
library (plyr)
library (reshape) #melt
library (gtools) #foldchange

##Getting HOME directory
home <- Sys.getenv("HOME")

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/heatMapFunctions.R")

#########################
# I have to separate HABITUATION AND DEVELOPMENT INTO DIFFERENT TABLES BECAUSE HABITUATION LAST MORE THAN ONE WEEK
###########
# DEVELOPMENT
###### 
## Load the data
## Groups are only separated by genotype WT and ts65dn with same diet
##############
## WT animals
## 5, 7, 11, 13, 17 (batch1) 19, 21, 33, 35 (batch2) 
##############
## TS 65dn
## 2, 4, 8, 10, 18 (batch1) 22, 26, 30, 32, 34 (batch2) 

## DATA 
weekStatsData_batch1 <- "/2017_phecomp_marta/data/heatmap_files/development_FC_batch1_filtTwoMinFilt.tbl"
df.weekStats_batch1 <- read.table (paste (home, weekStatsData_batch1, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)
head (df.weekStats_batch1)

weekStatsData_batch2 <- "/2017_phecomp_marta/data/heatmap_files/development_FC_batch2_filtTwoMinFilt.tbl"
df.weekStats_batch2 <- read.table (paste (home, weekStatsData_batch2, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)
head (df.weekStats_batch2)

df.weekStats_batch1_filt <- subset (df.weekStats_batch1, cage %in%  c(5, 7, 11, 13, 17, 2, 4, 8, 10, 18))
df.weekStats_batch2_filt <- subset (df.weekStats_batch2, cage %in%  c(19, 21, 33, 35, 22, 26, 30, 32, 34))

## batch 1 has 9 weeks while batch 2 8 weeks, 
## last week of batch removed
df.weekStats_batch1_filt <- subset (df.weekStats_batch1_filt, period < 9)

## dataframes are joined
df.weekStats <- rbind(df.weekStats_batch1_filt, df.weekStats_batch2_filt)

#Hard code
caseGroupLabel <- "ts65dn"  # CASE    == ts65dn
controlGroupLabel <- "wt"   # CONTROL == wt 

nAnimals <- 36
#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
# this is a fake assignation
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [c(5, 7, 11, 13, 17, 19, 21, 33, 35)] <- controlGroupLabel
df.miceGroup$group [c(2, 4, 8, 10, 18, 22, 26, 30, 32, 34)] <- caseGroupLabel

# Joining labels
df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")
# head (df.weekStats)
# tail (df.weekStats,100)
# df.weekStats$channel

### DEVELOPMENT

## CTRL WT 
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))
head (df.meanControl$channel)
## CASE ts65dn
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

## ojo filtro por water_1 en el grupo SC y por water_2 en el grupo HF, asi se comparan a la vez que los
## tipo de comida
## WT do eat SC and CD two separated heat maps
df.meanControl.SC <- df.meanControl [which (df.meanControl$channel == "food_sc" |  df.meanControl$channel == "water_1"),]
df.meanControl.CD <- df.meanControl [which (df.meanControl$channel == "food_cd" | df.meanControl$channel == "water_2"),]

# TS do eat SC and CD two separated heat maps
df.meanCase.SC <- df.meanCase [which (df.meanCase$channel == "food_sc" |  df.meanCase$channel == "water_1"),]
df.meanCase.CD <- df.meanCase [which (df.meanCase$channel == "food_cd" |  df.meanCase$channel == "water_2"),]

#Formatting data frame with shape for heat map
df.meanControl.SC.m <- melt (df.meanControl.SC, id.vars=c("channel", "group", "period"))
df.meanControl.CD.m <- melt (df.meanControl.CD, id.vars=c("channel", "group", "period"))
df.meanCase.SC.m <- melt (df.meanCase.SC, id.vars=c("channel", "group", "period"))
df.meanCase.CD.m <- melt (df.meanCase.CD, id.vars=c("channel", "group", "period"))

length (df.meanCase.SC.m$channel)
length (df.meanCase.CD.m$channel)
length (df.meanControl.SC.m$channel)
length (df.meanControl.CD.m$channel)

## Comparing each of the diets within each of the genotypes
df.meanControl.CD.m$foldChange <- foldchange (df.meanControl.CD.m$value, df.meanControl.SC.m$value)
df.meanCase.CD.m$foldChange <- foldchange (df.meanCase.CD.m$value, df.meanCase.SC.m$value)

#Removing underscores from labels for the plotting
df.meanControl.CD.m$variable <-  gsub ("_", " ", df.meanControl.CD.m$variable, ignore.case = TRUE)
df.meanCase.CD.m$variable <-  gsub ("_", " ", df.meanCase.CD.m$variable, ignore.case = TRUE)

df.meanControl.CD.m$varOrder [which (df.meanControl.CD.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanControl.CD.m$varOrder [which (df.meanControl.CD.m$variable == "Rate")] <-  "b"
df.meanControl.CD.m$varOrder [which (df.meanControl.CD.m$variable == "Avg Duration")] <-  "c"
df.meanControl.CD.m$varOrder [which (df.meanControl.CD.m$variable == "Number")] <-  "d"
df.meanControl.CD.m$varOrder [which (df.meanControl.CD.m$variable == "Avg Intake")] <-  "e"

df.meanControl.CD.m$orderOut [which (df.meanControl.CD.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanControl.CD.m$orderOut [which (df.meanControl.CD.m$variable == "Rate")] <-  "2"
df.meanControl.CD.m$orderOut [which (df.meanControl.CD.m$variable == "Avg Duration")] <-  "3"
df.meanControl.CD.m$orderOut [which (df.meanControl.CD.m$variable == "Number")] <-  "4"
df.meanControl.CD.m$orderOut [which (df.meanControl.CD.m$variable == "Avg Intake")] <-  "5"

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

## Ordering
df.meanControl.CD.m <- df.meanControl.CD.m [with (df.meanControl.CD.m, order (period, channel, orderOut)),]
df.meanCase.CD.m <- df.meanCase.CD.m [with (df.meanCase.CD.m, order (period, channel, orderOut)),]

df.meanControl.CD.m$stars <- ""
df.meanCase.CD.m$stars <- ""

# heatMapPlotter (df.meanControl.CD.m, main="                   ts65dn choc food vs sc\n",   weekNotation = "N", legPos="right", xlab="\n", ylab="\n")
# heatMapPlotter (df.meanCase.CD.m, main="                   ts65dn choc food vs sc\n",   weekNotation = "N", legPos="right", xlab="\n", ylab="\n")

#### Significance as stars
## CASE=> ts65dn
### SIGNIFICANCE RESULTS
#do to df.weekStats one only with water and SC events and a second one with water and CM
df.weekStats.case <- df.weekStats [which (df.weekStats$group == "ts65dn"),]

df.weekStats.case$chType <- df.weekStats.case$channel
df.weekStats.case$chType <-  gsub ("food_sc", "food", df.weekStats.case$chType, ignore.case = TRUE)
df.weekStats.case$chType <-  gsub ("food_cd", "food", df.weekStats.case$chType, ignore.case = TRUE)

df.weekStats.case$chType <-  gsub ("water_1", "water", df.weekStats.case$chType, ignore.case = TRUE)
df.weekStats.case$chType <-  gsub ("water_2", "water", df.weekStats.case$chType, ignore.case = TRUE)

unique(df.weekStats.case$channel)

sigResults.case.CDvsSC <- c()

#### Test any individual comparison
# type = "food"
# channel1 = "food_sc"
# channel2 = "food_cd"
# d <- subset (df.weekStats.case, period == 1 & chType==type, 
#              select = c(period, channel, group, cage, 
#                         Avg_Intermeal_Duration, Rate, 
#                         Number, Avg_Intake, Avg_Duration))
# d1 <- subset (df.weekStats.case, period == 1 & chType==type & channel==channel1, 
#               select = c(period, channel, group, cage, 
#                          Avg_Intermeal_Duration, Rate, 
#                          Number, Avg_Intake, Avg_Duration))
# d2 <- subset (df.weekStats.case, period == 1 & chType==type & channel==channel2, 
#               select = c(period, channel, group, cage, 
#                          Avg_Intermeal_Duration, Rate, 
#                          Number, Avg_Intake, Avg_Duration))
# d1$Avg_Intermeal_Duration
# d1$channel
# d2$Avg_Intermeal_Duration
# d2$channel
# foldchange(mean(d1$Avg_Intermeal_Duration), mean(d2$Avg_Intermeal_Duration))
# 
# unlist (wilcox.test (d$Avg_Intermeal_Duration~d$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
######## TEST finished


### chType is food and water!!! and channel are water_1, water_2 and food_sc, food_cd
for (p in unique (df.weekStats.case$period))
{
  print (p)
  for (ch in unique (df.weekStats.case$chType))
  {
    print (ch)
    df.subset <- subset (df.weekStats.case, period == p & chType == ch, 
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
#                               unlist (t.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])                              
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvg_Intermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    sigResults.case.CDvsSC <- rbind (sigResults.case.CDvsSC, rAvg_Intermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.case.CDvsSC) <- c (1:length (sigResults.case.CDvsSC [,1] ))
df.sigResults.case.CDvsSC <- as.data.frame(sigResults.case.CDvsSC, stringsAsFactors=F)
colnames (df.sigResults.case.CDvsSC) <- c("channel", "group", "period", "variable","significance")
df.sigResults.case.CDvsSC
#order the data by period
df.sigResults.case.CDvsSC$period <- as.numeric (df.sigResults.case.CDvsSC$period)
df.sigResults.case.CDvsSC$week <-df.sigResults.case.CDvsSC$period
df.sigResults.case.CDvsSC$week <- with (df.sigResults.case.CDvsSC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.case.CDvsSC$variable <-  gsub ("_", " ", df.sigResults.case.CDvsSC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.case.CDvsSC$chVar <- df.sigResults.case.CDvsSC$variable
#fold change have to be numeric to make the function work
df.sigResults.case.CDvsSC$significance <- as.numeric (df.sigResults.case.CDvsSC$significance)
#Volver a poner el campo como food_cd
# df.sigResults.case.CDvsSC$ch
df.sigResults.case.CDvsSC$channel <-  gsub ("food", "food_cd", df.sigResults.case.CDvsSC$channel, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.case.CDvsSC$varOrder<- "dummy"
df.sigResults.case.CDvsSC$varOrder [which ( df.sigResults.case.CDvsSC$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.case.CDvsSC$varOrder [which ( df.sigResults.case.CDvsSC$variable == "Rate")] <-  "b"
df.sigResults.case.CDvsSC$varOrder [which ( df.sigResults.case.CDvsSC$variable == "Avg Duration")] <-  "c"
df.sigResults.case.CDvsSC$varOrder [which ( df.sigResults.case.CDvsSC$variable == "Number")] <-  "d"
df.sigResults.case.CDvsSC$varOrder [which ( df.sigResults.case.CDvsSC$variable == "Avg Intake")] <-  "e"
df.sigResults.case.CDvsSC$orderOut<- "dummy"
df.sigResults.case.CDvsSC$orderOut [which ( df.sigResults.case.CDvsSC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.case.CDvsSC$orderOut [which ( df.sigResults.case.CDvsSC$variable == "Rate")] <-  "2"
df.sigResults.case.CDvsSC$orderOut [which ( df.sigResults.case.CDvsSC$variable == "Avg Duration")] <-  "3"
df.sigResults.case.CDvsSC$orderOut [which ( df.sigResults.case.CDvsSC$variable == "Number")] <-  "4"
df.sigResults.case.CDvsSC$orderOut [which ( df.sigResults.case.CDvsSC$variable == "Avg Intake")] <-  "5"

#ordering
df.sigResults.case.CDvsSC <-  df.sigResults.case.CDvsSC [with ( df.sigResults.case.CDvsSC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.case.CDvsSC$variable [which ( df.sigResults.case.CDvsSC$variable == "Number" &  df.sigResults.case.CDvsSC$channel == "food_cd")] <-  "Meal Number"
df.sigResults.case.CDvsSC$variable [which ( df.sigResults.case.CDvsSC$variable == "Number" &  df.sigResults.case.CDvsSC$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
# df.sigResults.case.CDvsSC.Dev <- df.sigResults.case.CDvsSC [df.sigResults.case.CDvsSC$period > 1 & df.sigResults.case.CDvsSC$period < 10,]
# df.sigResults.case.CDvsSC.Dev$period <- df.sigResults.case.CDvsSC.Dev$period - 7
df.meanCase.CD.m$significance <- df.sigResults.case.CDvsSC$significance
df.meanCase.CD.m$stars <- cut(df.sigResults.case.CDvsSC$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

### do not show variables in plot
# df.meanCase.CD.m$variable <- ""
df.meanCase.CD.m$period <-df.meanCase.CD.m$period +1
heatMapPlotter (df.meanCase.CD.m, main="              ts65dn choc food vs sc\n",
                weekNotation = "N", legPos="right", xlab="\n", ylab="\n")

# ggsave (file=paste(home, "/2017_phecomp_marta/heatmaps/", "ts65_freeChoice_CHOCvsSC.tiff", sep=""), 
#         width=7, height=4.5, dpi=300)

#############
#############
#### Significance as stars
## Control => wt
### SIGNIFICANCE RESULTS
#do to df.weekStats one only with water and SC events and a second one with water and CM
df.weekStats.control <- df.weekStats [which (df.weekStats$group == "wt"),]

df.weekStats.control$chType <- df.weekStats.control$channel
df.weekStats.control$chType <-  gsub ("food_sc", "food", df.weekStats.control$chType, ignore.case = TRUE)
df.weekStats.control$chType <-  gsub ("food_cd", "food", df.weekStats.control$chType, ignore.case = TRUE)

df.weekStats.control$chType <-  gsub ("water_1", "water", df.weekStats.control$chType, ignore.case = TRUE)
df.weekStats.control$chType <-  gsub ("water_2", "water", df.weekStats.control$chType, ignore.case = TRUE)

unique(df.weekStats.control$channel)

sigResults.control.CDvsSC <- c()

#### Test any individual comparison
# type = "food"
# channel1 = "food_sc"
# channel2 = "food_cd"
# d <- subset (df.weekStats.control, period == 1 & chType==type, 
#              select = c(period, channel, group, cage, 
#                         Avg_Intermeal_Duration, Rate, 
#                         Number, Avg_Intake, Avg_Duration))
# d1 <- subset (df.weekStats.control, period == 1 & chType==type & channel==channel1, 
#               select = c(period, channel, group, cage, 
#                          Avg_Intermeal_Duration, Rate, 
#                          Number, Avg_Intake, Avg_Duration))
# d2 <- subset (df.weekStats.control, period == 1 & chType==type & channel==channel2, 
#               select = c(period, channel, group, cage, 
#                          Avg_Intermeal_Duration, Rate, 
#                          Number, Avg_Intake, Avg_Duration))
# d1$Avg_Intermeal_Duration
# d1$channel
# d2$Avg_Intermeal_Duration
# d2$channel
# foldchange(mean(d1$Avg_Intermeal_Duration), mean(d2$Avg_Intermeal_Duration))
# 
# unlist (wilcox.test (d$Avg_Intermeal_Duration~d$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
######## TEST finished


### chType is food and water!!! and channel are water_1, water_2 and food_sc, food_cd
for (p in unique (df.weekStats.control$period))
{
  print (p)
  for (ch in unique (df.weekStats.control$chType))
  {
    print (ch)
    df.subset <- subset (df.weekStats.control, period == p & chType == ch, 
                         select = c(period, channel, group, cage, Avg_Intermeal_Duration, Rate, Number, Avg_Intake, Avg_Duration))
    print ("--------")
    print (df.subset)
    #The first columns with categorical data do not need to be include in signif calculation
    signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
                            function (x)
                            {
                              #wilcox test
#                               unlist (wilcox.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
                              #t test
                              unlist (t.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, controlGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, controlGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, controlGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, controlGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvg_Intermeal <- c (ch, controlGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    sigResults.control.CDvsSC <- rbind (sigResults.control.CDvsSC, rAvg_Intermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.control.CDvsSC) <- c (1:length (sigResults.control.CDvsSC [,1] ))
df.sigResults.control.CDvsSC <- as.data.frame(sigResults.control.CDvsSC, stringsAsFactors=F)
colnames (df.sigResults.control.CDvsSC) <- c("channel", "group", "period", "variable","significance")
df.sigResults.control.CDvsSC
#order the data by period
df.sigResults.control.CDvsSC$period <- as.numeric (df.sigResults.control.CDvsSC$period)
df.sigResults.control.CDvsSC$week <-df.sigResults.control.CDvsSC$period
df.sigResults.control.CDvsSC$week <- with (df.sigResults.control.CDvsSC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.control.CDvsSC$variable <-  gsub ("_", " ", df.sigResults.control.CDvsSC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.control.CDvsSC$chVar <- df.sigResults.control.CDvsSC$variable
#fold change have to be numeric to make the function work
df.sigResults.control.CDvsSC$significance <- as.numeric (df.sigResults.control.CDvsSC$significance)
#Volver a poner el campo como food_cd
# df.sigResults.control.CDvsSC$ch
df.sigResults.control.CDvsSC$channel <-  gsub ("food", "food_cd", df.sigResults.control.CDvsSC$channel, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.control.CDvsSC$varOrder<- "dummy"
df.sigResults.control.CDvsSC$varOrder [which ( df.sigResults.control.CDvsSC$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.control.CDvsSC$varOrder [which ( df.sigResults.control.CDvsSC$variable == "Rate")] <-  "b"
df.sigResults.control.CDvsSC$varOrder [which ( df.sigResults.control.CDvsSC$variable == "Avg Duration")] <-  "c"
df.sigResults.control.CDvsSC$varOrder [which ( df.sigResults.control.CDvsSC$variable == "Number")] <-  "d"
df.sigResults.control.CDvsSC$varOrder [which ( df.sigResults.control.CDvsSC$variable == "Avg Intake")] <-  "e"
df.sigResults.control.CDvsSC$orderOut<- "dummy"
df.sigResults.control.CDvsSC$orderOut [which ( df.sigResults.control.CDvsSC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.control.CDvsSC$orderOut [which ( df.sigResults.control.CDvsSC$variable == "Rate")] <-  "2"
df.sigResults.control.CDvsSC$orderOut [which ( df.sigResults.control.CDvsSC$variable == "Avg Duration")] <-  "3"
df.sigResults.control.CDvsSC$orderOut [which ( df.sigResults.control.CDvsSC$variable == "Number")] <-  "4"
df.sigResults.control.CDvsSC$orderOut [which ( df.sigResults.control.CDvsSC$variable == "Avg Intake")] <-  "5"

#ordering
df.sigResults.control.CDvsSC <-  df.sigResults.control.CDvsSC [with ( df.sigResults.control.CDvsSC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.control.CDvsSC$variable [which ( df.sigResults.control.CDvsSC$variable == "Number" &  df.sigResults.control.CDvsSC$channel == "food_cd")] <-  "Meal Number"
df.sigResults.control.CDvsSC$variable [which ( df.sigResults.control.CDvsSC$variable == "Number" &  df.sigResults.control.CDvsSC$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
# df.sigResults.control.CDvsSC.Dev <- df.sigResults.control.CDvsSC [df.sigResults.control.CDvsSC$period > 1 & df.sigResults.control.CDvsSC$period < 10,]
# df.sigResults.control.CDvsSC.Dev$period <- df.sigResults.control.CDvsSC.Dev$period - 7
df.meanControl.CD.m$significance <- df.sigResults.control.CDvsSC$significance
df.meanControl.CD.m$stars <- cut(df.sigResults.control.CDvsSC$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

### do not show variables in plot
# df.meanControl.CD.m$variable <- ""
df.meanControl.CD.m$period <-df.meanControl.CD.m$period +1
heatMapPlotter (df.meanControl.CD.m, main="                   WT choc food vs sc\n",   
                weekNotation = 'N', legPos="right", xlab="\n", ylab="\n")

# ggsave (file=paste(home, "/2017_phecomp_marta/heatmaps/", "wt_freeChoice_CHOCvsSC.tiff", sep=""), 
#         width=7, height=4.5, dpi=300)
