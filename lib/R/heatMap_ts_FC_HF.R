#######################################################################
### Jose A Espinosa. CSN/CB-CRG Group. February 2017                ###
#######################################################################
### ROUTINE TO PRODUCE HEATMAPS OF EXPERIMENT trisomic free choice  ###
### eating high-fat food (HF).                                      ###
### In this script we analyze data corresponding to a batch of mice ###
### with a free choice between HF and SC. The experiment is         ###
### performed in only one batch and consists in both wt and ts65dn  ###
### animals. In this script we compared within each of the genotypes###
### the behavior on the HF channel vs the behavior of the SC        ###
### channel.                                                        ###
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

# setwd ("")

#########################
# I have to separate HABITUATION AND DEVELOPMENT INTO DIFFERENT TABLES BECAUSE HABITUATION LAST MORE THAN ONE WEEK
###########
# DEVELOPMENT
###### 
## Load the data
## Groups are only separated by genotype WT and ts65dn with same a free-choice diet of SC and HF
##############
## WT animals
## 1, 3, 5, 7, 9, 11, 13, 15, 17, 
##############
## TS 65dn
## 2, 4, 6, 8, 10, 12, 14, 16, 18
### Animal 10 deleted--> 46

## DATA 
weekStatsData <- "/2017_phecomp_marta/data/heatmap_files/development_HF_FC_filtTwoMinFilt.tbl"

df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)
head (df.weekStats)

#Hard code
caseGroupLabel <- "ts65dn"  # CASE    == ts65dn
controlGroupLabel <- "wt"   # CONTROL == wt 

nAnimals <- 18 + 36
#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [c(37, 39, 41, 43, 45, 47, 49, 51, 53)] <- controlGroupLabel

### 10 (46) deleted because the channel was firing
# df.miceGroup$group [c(38, 40, 42, 44, 46, 48, 50, 52, 54)] <- caseGroupLabel
df.miceGroup$group [c(38, 40, 42, 44, 48, 50, 52, 54)] <- caseGroupLabel

## Joining labels
## removing animals 10 (46) trisomic (case)
df.weekStats <- subset (df.weekStats, cage!=46)
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
## WT do eat SC and FAT two separated heat maps
df.meanControl.SC <- df.meanControl [which (df.meanControl$channel == "food_sc" |  df.meanControl$channel == "water_1"),]
df.meanControl.FAT <- df.meanControl [which (df.meanControl$channel == "food_fat" | df.meanControl$channel == "water_2"),]

# TS do eat SC and FAT two separated heat maps
df.meanCase.SC <- df.meanCase [which (df.meanCase$channel == "food_sc" |  df.meanCase$channel == "water_1"),]
df.meanCase.FAT <- df.meanCase [which (df.meanCase$channel == "food_fat" |  df.meanCase$channel == "water_2"),]

#Formatting data frame with shape for heat map
df.meanControl.SC.m <- melt (df.meanControl.SC, id.vars=c("channel", "group", "period"))
df.meanControl.FAT.m <- melt (df.meanControl.FAT, id.vars=c("channel", "group", "period"))
df.meanCase.SC.m <- melt (df.meanCase.SC, id.vars=c("channel", "group", "period"))
df.meanCase.FAT.m <- melt (df.meanCase.FAT, id.vars=c("channel", "group", "period"))

length (df.meanCase.SC.m$channel)
length (df.meanCase.FAT.m$channel)
length (df.meanControl.SC.m$channel)
length (df.meanControl.FAT.m$channel)

## Comparing each of the diets within each of the genotypes
df.meanControl.FAT.m$foldChange <- foldchange (df.meanControl.FAT.m$value, df.meanControl.SC.m$value)
df.meanCase.FAT.m$foldChange <- foldchange (df.meanCase.FAT.m$value, df.meanCase.SC.m$value)

#Removing underscores from labels for the plotting
df.meanControl.FAT.m$variable <-  gsub ("_", " ", df.meanControl.FAT.m$variable, ignore.case = TRUE)
df.meanCase.FAT.m$variable <-  gsub ("_", " ", df.meanCase.FAT.m$variable, ignore.case = TRUE)

df.meanControl.FAT.m$varOrder [which (df.meanControl.FAT.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanControl.FAT.m$varOrder [which (df.meanControl.FAT.m$variable == "Rate")] <-  "b"
df.meanControl.FAT.m$varOrder [which (df.meanControl.FAT.m$variable == "Avg Duration")] <-  "c"
df.meanControl.FAT.m$varOrder [which (df.meanControl.FAT.m$variable == "Number")] <-  "d"
df.meanControl.FAT.m$varOrder [which (df.meanControl.FAT.m$variable == "Avg Intake")] <-  "e"

df.meanControl.FAT.m$orderOut [which (df.meanControl.FAT.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanControl.FAT.m$orderOut [which (df.meanControl.FAT.m$variable == "Rate")] <-  "2"
df.meanControl.FAT.m$orderOut [which (df.meanControl.FAT.m$variable == "Avg Duration")] <-  "3"
df.meanControl.FAT.m$orderOut [which (df.meanControl.FAT.m$variable == "Number")] <-  "4"
df.meanControl.FAT.m$orderOut [which (df.meanControl.FAT.m$variable == "Avg Intake")] <-  "5"

df.meanCase.FAT.m$varOrder [which (df.meanCase.FAT.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanCase.FAT.m$varOrder [which (df.meanCase.FAT.m$variable == "Rate")] <-  "b"
df.meanCase.FAT.m$varOrder [which (df.meanCase.FAT.m$variable == "Avg Duration")] <-  "c"
df.meanCase.FAT.m$varOrder [which (df.meanCase.FAT.m$variable == "Number")] <-  "d"
df.meanCase.FAT.m$varOrder [which (df.meanCase.FAT.m$variable == "Avg Intake")] <-  "e"

df.meanCase.FAT.m$orderOut [which (df.meanCase.FAT.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanCase.FAT.m$orderOut [which (df.meanCase.FAT.m$variable == "Rate")] <-  "2"
df.meanCase.FAT.m$orderOut [which (df.meanCase.FAT.m$variable == "Avg Duration")] <-  "3"
df.meanCase.FAT.m$orderOut [which (df.meanCase.FAT.m$variable == "Number")] <-  "4"
df.meanCase.FAT.m$orderOut [which (df.meanCase.FAT.m$variable == "Avg Intake")] <-  "5"

## Ordering
df.meanControl.FAT.m <- df.meanControl.FAT.m [with (df.meanControl.FAT.m, order (period, channel, orderOut)),]
df.meanCase.FAT.m <- df.meanCase.FAT.m [with (df.meanCase.FAT.m, order (period, channel, orderOut)),]

df.meanControl.FAT.m$stars <- ""
df.meanCase.FAT.m$stars <- ""

heatMapPlotter (df.meanCase.FAT.m, main="         ts65dn high-fat food vs sc\n",   weekNotation = "N", legPos="right", xlab="\n", ylab="\n")

#### Significance as stars
## CASE=> ts65dn
### SIGNIFICANCE RESULTS
#do to df.weekStats one only with water and SC events and a second one with water and CM
df.weekStats.case <- df.weekStats [which (df.weekStats$group == "ts65dn"),]

df.weekStats.case$chType <- df.weekStats.case$channel
df.weekStats.case$chType <-  gsub ("food_sc", "food", df.weekStats.case$chType, ignore.case = TRUE)
df.weekStats.case$chType <-  gsub ("food_fat", "food", df.weekStats.case$chType, ignore.case = TRUE)

df.weekStats.case$chType <-  gsub ("water_1", "water", df.weekStats.case$chType, ignore.case = TRUE)
df.weekStats.case$chType <-  gsub ("water_2", "water", df.weekStats.case$chType, ignore.case = TRUE)

unique(df.weekStats.case$channel)

sigResults.case.FATvsSC <- c()

#### Test any individual comparison
# type = "food"
# channel1 = "food_sc"
# channel2 = "food_fat"
# d <- subset (df.weekStats.case, period == 1 & chType==type, 
#               select = c(period, channel, group, cage, 
#                          Avg_Intermeal_Duration, Rate, 
#                          Number, Avg_Intake, Avg_Duration))
# d1 <- subset (df.weekStats.case, period == 1 & chType==type & channel==channel1, 
#            select = c(period, channel, group, cage, 
#                       Avg_Intermeal_Duration, Rate, 
#                       Number, Avg_Intake, Avg_Duration))
# d2 <- subset (df.weekStats.case, period == 1 & chType==type & channel==channel2, 
#              select = c(period, channel, group, cage, 
#                         Avg_Intermeal_Duration, Rate, 
#                         Number, Avg_Intake, Avg_Duration))
# d1$Avg_Intermeal_Duration
# d1$channel
# d2$Avg_Intermeal_Duration
# d2$channel
# foldchange(mean(d1$Avg_Intermeal_Duration), mean(d2$Avg_Intermeal_Duration))
# 
# unlist (wilcox.test (d$Avg_Intermeal_Duration~d$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
######## TEST finished


### chType is food and water!!! and channel are water_1, water_2 and food_sc, food_fat
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
                              #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvg_Intermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    sigResults.case.FATvsSC <- rbind (sigResults.case.FATvsSC, rAvg_Intermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.case.FATvsSC) <- c (1:length (sigResults.case.FATvsSC [,1] ))
df.sigResults.case.FATvsSC <- as.data.frame(sigResults.case.FATvsSC, stringsAsFactors=F)
colnames (df.sigResults.case.FATvsSC) <- c("channel", "group", "period", "variable","significance")
df.sigResults.case.FATvsSC
#order the data by period
df.sigResults.case.FATvsSC$period <- as.numeric (df.sigResults.case.FATvsSC$period)
df.sigResults.case.FATvsSC$week <-df.sigResults.case.FATvsSC$period
df.sigResults.case.FATvsSC$week <- with (df.sigResults.case.FATvsSC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.case.FATvsSC$variable <-  gsub ("_", " ", df.sigResults.case.FATvsSC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.case.FATvsSC$chVar <- df.sigResults.case.FATvsSC$variable
#fold change have to be numeric to make the function work
df.sigResults.case.FATvsSC$significance <- as.numeric (df.sigResults.case.FATvsSC$significance)
#Volver a poner el campo como food_cd
# df.sigResults.case.FATvsSC$ch
df.sigResults.case.FATvsSC$channel <-  gsub ("food", "food_fat", df.sigResults.case.FATvsSC$channel, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.case.FATvsSC$varOrder<- "dummy"
df.sigResults.case.FATvsSC$varOrder [which ( df.sigResults.case.FATvsSC$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.case.FATvsSC$varOrder [which ( df.sigResults.case.FATvsSC$variable == "Rate")] <-  "b"
df.sigResults.case.FATvsSC$varOrder [which ( df.sigResults.case.FATvsSC$variable == "Avg Duration")] <-  "c"
df.sigResults.case.FATvsSC$varOrder [which ( df.sigResults.case.FATvsSC$variable == "Number")] <-  "d"
df.sigResults.case.FATvsSC$varOrder [which ( df.sigResults.case.FATvsSC$variable == "Avg Intake")] <-  "e"
df.sigResults.case.FATvsSC$orderOut<- "dummy"
df.sigResults.case.FATvsSC$orderOut [which ( df.sigResults.case.FATvsSC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.case.FATvsSC$orderOut [which ( df.sigResults.case.FATvsSC$variable == "Rate")] <-  "2"
df.sigResults.case.FATvsSC$orderOut [which ( df.sigResults.case.FATvsSC$variable == "Avg Duration")] <-  "3"
df.sigResults.case.FATvsSC$orderOut [which ( df.sigResults.case.FATvsSC$variable == "Number")] <-  "4"
df.sigResults.case.FATvsSC$orderOut [which ( df.sigResults.case.FATvsSC$variable == "Avg Intake")] <-  "5"

#ordering
df.sigResults.case.FATvsSC <-  df.sigResults.case.FATvsSC [with ( df.sigResults.case.FATvsSC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.case.FATvsSC$variable [which ( df.sigResults.case.FATvsSC$variable == "Number" &  df.sigResults.case.FATvsSC$channel == "food_cd")] <-  "Meal Number"
df.sigResults.case.FATvsSC$variable [which ( df.sigResults.case.FATvsSC$variable == "Number" &  df.sigResults.case.FATvsSC$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
# df.sigResults.case.FATvsSC.Dev <- df.sigResults.case.FATvsSC [df.sigResults.case.FATvsSC$period > 1 & df.sigResults.case.FATvsSC$period < 10,]
# df.sigResults.case.FATvsSC.Dev$period <- df.sigResults.case.FATvsSC.Dev$period - 7
df.meanCase.FAT.m$significance <- df.sigResults.case.FATvsSC$significance
df.meanCase.FAT.m$stars <- cut(df.sigResults.case.FATvsSC$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

### do not show variables in plot
# df.meanCase.FAT.m$variable <- ""
df.meanCase.FAT.m$period <-df.meanCase.FAT.m$period +1

heatMapPlotter (df.meanCase.FAT.m, main="         ts65dn high-fat food vs sc\n",   weekNotation = "N", legPos="right", xlab="\n", ylab="\n")
# ggsave (file=paste(home, "/2017_phecomp_marta/heatmaps/", "ts65_freeChoice_HFvsSC_without10.tiff", sep=""), 
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
df.weekStats.control$chType <-  gsub ("food_fat", "food", df.weekStats.control$chType, ignore.case = TRUE)

df.weekStats.control$chType <-  gsub ("water_1", "water", df.weekStats.control$chType, ignore.case = TRUE)
df.weekStats.control$chType <-  gsub ("water_2", "water", df.weekStats.control$chType, ignore.case = TRUE)

unique(df.weekStats.control$channel)

sigResults.control.FATvsSC <- c()

#### Test any individual comparison
type = "food"
channel1 = "food_sc"
channel2 = "food_fat"
d <- subset (df.weekStats.control, period == 1 & chType==type, 
             select = c(period, channel, group, cage, 
                        Avg_Intermeal_Duration, Rate, 
                        Number, Avg_Intake, Avg_Duration))
d1 <- subset (df.weekStats.control, period == 1 & chType==type & channel==channel1, 
              select = c(period, channel, group, cage, 
                         Avg_Intermeal_Duration, Rate, 
                         Number, Avg_Intake, Avg_Duration))
d2 <- subset (df.weekStats.control, period == 1 & chType==type & channel==channel2, 
              select = c(period, channel, group, cage, 
                         Avg_Intermeal_Duration, Rate, 
                         Number, Avg_Intake, Avg_Duration))
d1$Avg_Intermeal_Duration
d1$channel
d2$Avg_Intermeal_Duration
d2$channel
foldchange(mean(d1$Avg_Intermeal_Duration), mean(d2$Avg_Intermeal_Duration))

unlist (wilcox.test (d$Avg_Intermeal_Duration~d$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
######## TEST finished


### chType is food and water!!! and channel are water_1, water_2 and food_sc, food_fat
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
                              unlist (wilcox.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
                              #t test
                              #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                            }))
    print (as.numeric(signWater ["Number","p.value"]))
    #         ch <- "food_cd"
    rNmeals <- c (ch, controlGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
    rAvgDuration <- c (ch, controlGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
    rAvgIntake <- c (ch, controlGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
    rRate <- c (ch, controlGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
    rAvg_Intermeal <- c (ch, controlGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    sigResults.control.FATvsSC <- rbind (sigResults.control.FATvsSC, rAvg_Intermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.control.FATvsSC) <- c (1:length (sigResults.control.FATvsSC [,1] ))
df.sigResults.control.FATvsSC <- as.data.frame(sigResults.control.FATvsSC, stringsAsFactors=F)
colnames (df.sigResults.control.FATvsSC) <- c("channel", "group", "period", "variable","significance")
df.sigResults.control.FATvsSC
#order the data by period
df.sigResults.control.FATvsSC$period <- as.numeric (df.sigResults.control.FATvsSC$period)
df.sigResults.control.FATvsSC$week <-df.sigResults.control.FATvsSC$period
df.sigResults.control.FATvsSC$week <- with (df.sigResults.control.FATvsSC, reorder (week, period,))

#removing underscores for plotting
df.sigResults.control.FATvsSC$variable <-  gsub ("_", " ", df.sigResults.control.FATvsSC$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.control.FATvsSC$chVar <- df.sigResults.control.FATvsSC$variable
#fold change have to be numeric to make the function work
df.sigResults.control.FATvsSC$significance <- as.numeric (df.sigResults.control.FATvsSC$significance)
#Volver a poner el campo como food_cd
# df.sigResults.control.FATvsSC$ch
df.sigResults.control.FATvsSC$channel <-  gsub ("food", "food_fat", df.sigResults.control.FATvsSC$channel, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.control.FATvsSC$varOrder<- "dummy"
df.sigResults.control.FATvsSC$varOrder [which ( df.sigResults.control.FATvsSC$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.control.FATvsSC$varOrder [which ( df.sigResults.control.FATvsSC$variable == "Rate")] <-  "b"
df.sigResults.control.FATvsSC$varOrder [which ( df.sigResults.control.FATvsSC$variable == "Avg Duration")] <-  "c"
df.sigResults.control.FATvsSC$varOrder [which ( df.sigResults.control.FATvsSC$variable == "Number")] <-  "d"
df.sigResults.control.FATvsSC$varOrder [which ( df.sigResults.control.FATvsSC$variable == "Avg Intake")] <-  "e"
df.sigResults.control.FATvsSC$orderOut<- "dummy"
df.sigResults.control.FATvsSC$orderOut [which ( df.sigResults.control.FATvsSC$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.control.FATvsSC$orderOut [which ( df.sigResults.control.FATvsSC$variable == "Rate")] <-  "2"
df.sigResults.control.FATvsSC$orderOut [which ( df.sigResults.control.FATvsSC$variable == "Avg Duration")] <-  "3"
df.sigResults.control.FATvsSC$orderOut [which ( df.sigResults.control.FATvsSC$variable == "Number")] <-  "4"
df.sigResults.control.FATvsSC$orderOut [which ( df.sigResults.control.FATvsSC$variable == "Avg Intake")] <-  "5"

#ordering
df.sigResults.control.FATvsSC <-  df.sigResults.control.FATvsSC [with ( df.sigResults.control.FATvsSC, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.control.FATvsSC$variable [which ( df.sigResults.control.FATvsSC$variable == "Number" &  df.sigResults.control.FATvsSC$channel == "food_cd")] <-  "Meal Number"
df.sigResults.control.FATvsSC$variable [which ( df.sigResults.control.FATvsSC$variable == "Number" &  df.sigResults.control.FATvsSC$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
# df.sigResults.control.FATvsSC.Dev <- df.sigResults.control.FATvsSC [df.sigResults.control.FATvsSC$period > 1 & df.sigResults.control.FATvsSC$period < 10,]
# df.sigResults.control.FATvsSC.Dev$period <- df.sigResults.control.FATvsSC.Dev$period - 7
df.meanControl.FAT.m$significance <- df.sigResults.control.FATvsSC$significance
df.meanControl.FAT.m$stars <- cut(df.sigResults.control.FATvsSC$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

### do not show variables in plot
# df.meanControl.FAT.m$variable <- ""
df.meanControl.FAT.m$period <-df.meanControl.FAT.m$period +1

heatMapPlotter (df.meanControl.FAT.m, main="                   WT high-fat food vs sc\n",   weekNotation = 'N', legPos="right", xlab="\n", ylab="\n")

# ggsave (file=paste(home, "/2017_phecomp_marta/heatmaps/", "wt_freeChoice_HFvsSC.tiff", sep=""), 
#         width=7, height=4.5, dpi=300)
