#####################################################################
### Jose A Espinosa. CSN/CB-CRG Group. Feb 2017                   ###
#####################################################################
### ROUTINE TO PRODUCE HEATMAPS OF EXPERIMENT 20140318_TS_CRG_HF  ###
### In this script we analyze data corresponding to a batch of    ###
### high-fat forced animals. The group consists in wt and ts65dn  ###
### mice. In this script we compared each of this genotypes with  ###
### its feeding behavior during the habituation                   ###
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

#############
#HABITUATION
#############
## Load the data
## Groups are only separated by genotype WT and ts65dn with same diet HF
##############
## WT animals
## 1, 3, 5, 7, 9, 11, 13, 15, 16, 17, 18
##############
## TS 65dn
## 2, 4, 6, 8, 10, 12, 14, 16

weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20140318_TS_CRG_HF_corrected_hab_filtTwoMinFilt.tbl"

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
tail (df.weekStats)
df.weekStats$channel

hab_df.weekStats <- subset(df.weekStats, period == 3)

hab_df.weekStats_1 <- hab_df.weekStats
hab_df.weekStats_1$period <- 1
hab_df.weekStats_2 <- hab_df.weekStats
hab_df.weekStats_2$period <- 2
hab_df.weekStats_3 <- hab_df.weekStats
hab_df.weekStats_3$period <- 3
hab_df.weekStats_4 <- hab_df.weekStats
hab_df.weekStats_4$period <- 4
hab_df.weekStats_5 <- hab_df.weekStats
hab_df.weekStats_5$period <- 5
hab_df.weekStats_6 <- hab_df.weekStats
hab_df.weekStats_6$period <- 6
hab_df.weekStats_7 <- hab_df.weekStats
hab_df.weekStats_7$period <- 7
hab_df.weekStats_8 <- hab_df.weekStats
hab_df.weekStats_8$period <- 8

hab_df.weekStats <- rbind(hab_df.weekStats_1, hab_df.weekStats_2, 
                              hab_df.weekStats_3, hab_df.weekStats_4,
                              hab_df.weekStats_5, hab_df.weekStats_6,
                              hab_df.weekStats_7, hab_df.weekStats_8)
head (hab_df.weekStats)

### HABITUATION
#CASE ts65dn
hab_df.meanCase <- with (hab_df.weekStats [which (hab_df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#CTRL
hab_df.meanControl <- with (hab_df.weekStats [which (hab_df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#Formatting data frame with shape for heat map
hab_df.meanControl.m <- melt (hab_df.meanControl, id.vars=c("channel", "group", "period"))
hab_df.meanCase.m <- melt (hab_df.meanCase, id.vars=c("channel", "group", "period"))

#########################
# I have to separate HABITUATION AND DEVELOPMENT INTO DIFFERENT TABLES BECAUSE HABITUATION LAST MORE THAN ONE WEEK
###########
# DEVELOPMENT
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
# caseGroupLabel <- "ts65dn"  # CASE    == ts65dn
# controlGroupLabel <- "wt"   # CONTROL == wt 
# 
# nAnimals <- 18
# #Label by experimental group (control, free choice, force diet...)
# cage <- c (1 : nAnimals)
# group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
# df.miceGroup <- data.frame (cage, group)
# df.miceGroup$group [c(1, 3, 5, 7, 9, 11, 13, 15, 16, 17, 18)] <- controlGroupLabel
# df.miceGroup$group [c(2, 4, 6, 8, 10, 12, 14, 16)] <- caseGroupLabel

# Joining labels
df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")
# head (df.weekStats)
# tail (df.weekStats,100)
# df.weekStats$channel

### DEVELOPMENT
#CASE ts65dn
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

### WT CTRL
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate, Avg_Intermeal_Duration), list(channel=channel, group=group, period=period), mean))

#Formatting data frame with shape for heat map
df.meanControl.m <- melt (df.meanControl, id.vars=c("channel", "group", "period"))
df.meanCase.m <- melt (df.meanCase, id.vars=c("channel", "group", "period"))

#### order by period to calculate fold change
# df.meanControl.m <- df.meanControl.m [with (df.meanControl.m, order (period, channel) ),]
# hab_df.meanControl.m <- hab_df.meanControl.m [with (hab_df.meanControl.m, order (period, channel) ),]

## fold change comparison wt development vs first week of habituation
df.meanControl.m$foldChange <- foldchange (df.meanControl.m$value, hab_df.meanControl.m$value)
head (df.meanControl.m)
head (hab_df.meanControl.m)

length(df.meanControl.m$value)
length(hab_df.meanControl.m$value)

df.meanControl.m$week <-df.meanControl.m$period
df.meanControl.m$week <- paste ("week", df.meanControl.m$period, sep = "_")   

## Ordering week column as period
df.meanControl.m$period <- as.numeric (df.meanControl.m$period)
df.meanControl.m$week <- with (df.meanControl.m, reorder (week, period,))

## Merging channel and variable
df.meanControl.m$variable <-  gsub ("_", " ", df.meanControl.m$variable, ignore.case = TRUE)

## I want to insert this order Avg Intake, number, avg duration and rate, so the order 
## is the same as in the other plots
df.meanControl.m$varOrder [which (df.meanControl.m$variable == "Avg Intermeal Duration")] <-  "a"
df.meanControl.m$varOrder [which (df.meanControl.m$variable == "Rate")] <-  "b"
df.meanControl.m$varOrder [which (df.meanControl.m$variable == "Avg Duration")] <-  "c"
df.meanControl.m$varOrder [which (df.meanControl.m$variable == "Number")] <-  "d"
df.meanControl.m$varOrder [which (df.meanControl.m$variable == "Avg Intake")] <-  "e"

df.meanControl.m$orderOut [which (df.meanControl.m$variable == "Avg Intermeal Duration")] <-  "1"
df.meanControl.m$orderOut [which (df.meanControl.m$variable == "Rate")] <-  "2"
df.meanControl.m$orderOut [which (df.meanControl.m$variable == "Avg Duration")] <-  "3"
df.meanControl.m$orderOut [which (df.meanControl.m$variable == "Number")] <-  "4"
df.meanControl.m$orderOut [which (df.meanControl.m$variable == "Avg Intake")] <-  "5"

## Old command to order
# df.meanControl.m <- df.meanControl.m [with (df.meanControl.m, order (period, channel, variable)),]
df.meanControl.m <- df.meanControl.m [with (df.meanControl.m, order (period, channel, orderOut) ),]

df.meanControl.m.Dev <- df.meanControl.m
df.meanControl.m.Dev$period <- df.meanControl.m.Dev$period + 1
df.meanControl.m.Dev$stars <- ""

## I fake the difference between the water channels of habituation and development
## habituation as water_1
## development as water_2
hab_df.weekStats$channel <- gsub ("water", "water_1", hab_df.weekStats$channel)
df.weekStats$channel <- gsub ("water", "water_2", df.weekStats$channel)

df.weekStats_hab_dev <- rbind (hab_df.weekStats, df.weekStats)

df.weekStats_hab_dev$chType <-  gsub ("food_sc", "food", df.weekStats_hab_dev$channel, ignore.case = TRUE)
df.weekStats_hab_dev$chType <-  gsub ("food_fat", "food", df.weekStats_hab_dev$chType, ignore.case = TRUE)

df.weekStats_hab_dev$chType <-  gsub ("water_1", "water", df.weekStats_hab_dev$chType, ignore.case = TRUE)
df.weekStats_hab_dev$chType <-  gsub ("water_2", "water", df.weekStats_hab_dev$chType, ignore.case = TRUE)

df.weekStats_hab_dev_ctrl <- subset(df.weekStats_hab_dev, group == "wt")
sigResults.control <- c()

#### Test any individual comparison
type = "water"
channel1 = "water_1"
channel2 = "water_2"
d <- subset (df.weekStats_hab_dev_ctrl, period == 7 & chType==type, 
             select = c(period, channel, group, cage, 
                        Avg_Intermeal_Duration, Rate, 
                        Number, Avg_Intake, Avg_Duration))
d1 <- subset (df.weekStats_hab_dev_ctrl, period == 7 & chType==type & channel==channel1, 
              select = c(period, channel, group, cage, 
                         Avg_Intermeal_Duration, Rate, 
                         Number, Avg_Intake, Avg_Duration))
d2 <- subset (df.weekStats_hab_dev_ctrl, period == 7 & chType==type & channel==channel2, 
              select = c(period, channel, group, cage, 
                         Avg_Intermeal_Duration, Rate, 
                         Number, Avg_Intake, Avg_Duration))
d2
d1$Avg_Duration
d1$channel
d2$Avg_Duration
# d2$channel
foldchange(mean(d2$Avg_Duration), mean(d1$Avg_Duration))
# 
unlist (wilcox.test (d$Avg_Duration~d$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
######## TEST finished

for (p in unique (df.weekStats_hab_dev_ctrl$period))
{
  for (ch in unique (df.weekStats_hab_dev_ctrl$chType))
  {
    print (p)
    print (ch)
    df.subset <- subset (df.weekStats_hab_dev_ctrl, period == p & chType == ch, 
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
    rAvgIntermeal <- c (ch, controlGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    
    sigResults.control <- rbind (sigResults.control, rAvgIntermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.control) <- c (1:length (sigResults.control [,1] ))
df.sigResults.control <- as.data.frame(sigResults.control, stringsAsFactors=F)
colnames (df.sigResults.control) <- c("channel", "group", "period", "variable","significance")
df.sigResults.control
#order the data by period
df.sigResults.control$period <- as.numeric (df.sigResults.control$period)
df.sigResults.control$week <-df.sigResults.control$period
df.sigResults.control$week <- with (df.sigResults.control, reorder (week, period,))

## removing underscores for plotting
df.sigResults.control$variable <-  gsub ("_", " ", df.sigResults.control$variable, ignore.case = TRUE)
## Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.control$chVar <- df.sigResults.control$variable
## fold change have to be numeric to make the function work
df.sigResults.control$significance <- as.numeric (df.sigResults.control$significance)

## I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
## ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.control$varOrder<- "dummy"
df.sigResults.control$varOrder [which ( df.sigResults.control$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.control$varOrder [which ( df.sigResults.control$variable == "Rate")] <-  "b"
df.sigResults.control$varOrder [which ( df.sigResults.control$variable == "Avg Duration")] <-  "c"
df.sigResults.control$varOrder [which ( df.sigResults.control$variable == "Number")] <-  "d"
df.sigResults.control$varOrder [which ( df.sigResults.control$variable == "Avg Intake")] <-  "e"
df.sigResults.control$orderOut<- "dummy"
df.sigResults.control$orderOut [which ( df.sigResults.control$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.control$orderOut [which ( df.sigResults.control$variable == "Rate")] <-  "2"
df.sigResults.control$orderOut [which ( df.sigResults.control$variable == "Avg Duration")] <-  "3"
df.sigResults.control$orderOut [which ( df.sigResults.control$variable == "Number")] <-  "4"
df.sigResults.control$orderOut [which ( df.sigResults.control$variable == "Avg Intake")] <-  "5"

## ordering
df.sigResults.control <-  df.sigResults.control [with ( df.sigResults.control, order (period, channel, orderOut) ),]

## Changing label Number by Number of Meals and Number of Drinks
df.sigResults.control$variable [which ( df.sigResults.control$variable == "Number" &  df.sigResults.control$channel == "food_cd")] <-  "Meal Number"
df.sigResults.control$variable [which ( df.sigResults.control$variable == "Number" &  df.sigResults.control$channel == "water")] <-  "Drink Number"
head (df.sigResults.control)
head (df.meanControl.m.Dev)

## Filtering habituation phase
df.meanControl.m.Dev$significance <- df.sigResults.control$significance
df.meanControl.m.Dev$stars <- cut(df.sigResults.control$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

heatMapPlotter (df.meanControl.m.Dev, main="           wt HF forced food vs habituation\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

# ggsave(paste(home, "/2017_phecomp_marta/heatmaps/", "wt_HF_forced_vs_hab.tiff", sep=""), 
#        width=7, height=4.5, dpi=300)
## strange results explained: 
## period = 7 
## cage = 7
## Avg duration = 616.50 --> outlier that is why the fold change is very red but not significance 
## 28.37  42.66  35.11 616.50  41.88  38.69  68.31  39.69  40.04  35.41

# CASE ts65dn
## fold change comparison wt development vs first week of habituation
df.meanCase.m$foldChange <- foldchange (df.meanCase.m$value, hab_df.meanCase.m$value)
head (df.meanCase.m)
head (hab_df.meanCase.m)

length(df.meanCase.m$value)
length(hab_df.meanCase.m$value)

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

df.meanCase.m.Dev <- df.meanCase.m
df.meanCase.m.Dev$period <- df.meanCase.m.Dev$period + 1
df.meanCase.m.Dev$stars <- ""

# hab_df.weekStats$channel <- gsub ("water", "water_1", hab_df.weekStats$channel)
# df.weekStats$channel <- gsub ("water", "water_2", df.weekStats$channel)
# 
# df.weekStats_hab_dev <- rbind (hab_df.weekStats, df.weekStats)
# 
# df.weekStats_hab_dev$chType <-  gsub ("food_sc", "food", df.weekStats_hab_dev$channel, ignore.case = TRUE)
# df.weekStats_hab_dev$chType <-  gsub ("food_fat", "food", df.weekStats_hab_dev$chType, ignore.case = TRUE)
# 
# df.weekStats_hab_dev$chType <-  gsub ("water_1", "water", df.weekStats_hab_dev$chType, ignore.case = TRUE)
# df.weekStats_hab_dev$chType <-  gsub ("water_2", "water", df.weekStats_hab_dev$chType, ignore.case = TRUE)

df.weekStats_hab_dev_case <- subset(df.weekStats_hab_dev, group == "ts65dn")
sigResults.case <- c()

for (p in unique (df.weekStats_hab_dev_case$period))
{
  for (ch in unique (df.weekStats_hab_dev_case$chType))
  {
    print (p)
    print (ch)
    df.subset <- subset (df.weekStats_hab_dev_case, period == p & chType == ch, 
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
    rAvgIntermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
    
    sigResults.case <- rbind (sigResults.case, rAvgIntermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
  }
}

# warnings()

row.names (sigResults.case) <- c (1:length (sigResults.case [,1] ))
df.sigResults.case <- as.data.frame(sigResults.case, stringsAsFactors=F)
colnames (df.sigResults.case) <- c("channel", "group", "period", "variable","significance")
df.sigResults.case
#order the data by period
df.sigResults.case$period <- as.numeric (df.sigResults.case$period)
df.sigResults.case$week <-df.sigResults.case$period
df.sigResults.case$week <- with (df.sigResults.case, reorder (week, period,))

#removing underscores for plotting
df.sigResults.case$variable <-  gsub ("_", " ", df.sigResults.case$variable, ignore.case = TRUE)
#Merging channel and variable
# df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
df.sigResults.case$chVar <- df.sigResults.case$variable
#fold change have to be numeric to make the function work
df.sigResults.case$significance <- as.numeric (df.sigResults.case$significance)
#Volver a poner el campo como food_cd
# df.sigResults.case$ch
df.sigResults.case$channel <-  gsub ("food", "food_cd", df.sigResults.case$channel, ignore.case = TRUE)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.sigResults.case$varOrder<- "dummy"
df.sigResults.case$varOrder [which ( df.sigResults.case$variable == "Avg Intermeal Duration")] <-  "a"
df.sigResults.case$varOrder [which ( df.sigResults.case$variable == "Rate")] <-  "b"
df.sigResults.case$varOrder [which ( df.sigResults.case$variable == "Avg Duration")] <-  "c"
df.sigResults.case$varOrder [which ( df.sigResults.case$variable == "Number")] <-  "d"
df.sigResults.case$varOrder [which ( df.sigResults.case$variable == "Avg Intake")] <-  "e"
df.sigResults.case$orderOut<- "dummy"
df.sigResults.case$orderOut [which ( df.sigResults.case$variable == "Avg Intermeal Duration")] <-  "1"
df.sigResults.case$orderOut [which ( df.sigResults.case$variable == "Rate")] <-  "2"
df.sigResults.case$orderOut [which ( df.sigResults.case$variable == "Avg Duration")] <-  "3"
df.sigResults.case$orderOut [which ( df.sigResults.case$variable == "Number")] <-  "4"
df.sigResults.case$orderOut [which ( df.sigResults.case$variable == "Avg Intake")] <-  "5"

#ordering
df.sigResults.case <-  df.sigResults.case [with ( df.sigResults.case, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.sigResults.case$variable [which ( df.sigResults.case$variable == "Number" &  df.sigResults.case$channel == "food_cd")] <-  "Meal Number"
df.sigResults.case$variable [which ( df.sigResults.case$variable == "Number" &  df.sigResults.case$channel == "water")] <-  "Drink Number"

#Filtering habituation phase
# df.sigResults.case.Dev <- df.sigResults.case [df.sigResults.case$period > 1 & df.sigResults.case$period < 10,]
# df.sigResults.case.Dev$period <- df.sigResults.case.Dev$period - 7
df.meanCase.m.Dev$significance <- df.sigResults.case$significance
df.meanCase.m.Dev$stars <- cut(df.sigResults.case$significance, breaks=c(-Inf, 0.001, 0.01, 0.05, Inf), label=c("***", "**", "*", ""))

heatMapPlotter (df.meanCase.m.Dev, main="           ts65dn HF forced food vs habituation\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")

# ggsave(paste(home, "/2017_phecomp_marta/heatmaps/", "ts65_HF_forced_vs_hab.tiff", sep=""), 
#              width=7, height=4.5, dpi=300)
