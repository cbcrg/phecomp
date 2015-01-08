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
library (gtools) #foldchange

##Getting HOME directory
home <- Sys.getenv("HOME")
# weekStatsData <- args[5]

##Loading functions
source ("/Users/jespinosa/phecomp/lib/R/heatMapFunctions.R")

setwd ("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures/fig4ANDfigS4Dev")

###### FREE CHOICE GROUP
##Load the data
##FREE CHOICE
##data before test
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/20130130_FCSC_CRG/tblFiles/20130130_FCSC_CRG_all_filtTwoMinFilt.tbl"
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
df.weekStats$channel

#Free choice do not have cd food in first week problems of matching for foldchange calculation, I filter first week out
df.weekStats <- df.weekStats [df.weekStats$period != 1,]

#Number of meals normalized for a single channel (in free choice animals we only have one channel for SC and one for CM)
head (df.weekStats [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control") , ])
# df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control")] <- df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "control")] / 2

#############
#CASE
df.meanCase <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, period=period), mean))

#CTRL
df.meanControl <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, period=period), mean))

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

df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Rate")] <-  "a"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Avg Duration")] <-  "b"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Number")] <-  "c"
df.meanCase.SC.m$varOrder [which (df.meanCase.SC.m$variable == "Avg Intake")] <-  "d"

df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Rate")] <-  "1"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Avg Duration")] <-  "2"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Number")] <-  "3"
df.meanCase.SC.m$orderOut [which (df.meanCase.SC.m$variable == "Avg Intake")] <-  "4"

df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Rate")] <-  "a"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Avg Duration")] <-  "b"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Number")] <-  "c"
df.meanCase.CD.m$varOrder [which (df.meanCase.CD.m$variable == "Avg Intake")] <-  "d"

df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Rate")] <-  "1"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Avg Duration")] <-  "2"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Number")] <-  "3"
df.meanCase.CD.m$orderOut [which (df.meanCase.CD.m$variable == "Avg Intake")] <-  "4"

#Ordering
df.meanCase.SC.m <- df.meanCase.SC.m [with (df.meanCase.SC.m, order (period, channel, orderOut)),]
df.meanCase.CD.m <- df.meanCase.CD.m [with (df.meanCase.CD.m, order (period, channel, orderOut)),]

# Changing label Number by Number of Meals and Number of Drinks
df.meanCase.SC.m$variable [which (df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "food_sc")] <-  "Meal Number"
df.meanCase.SC.m$variable [which (df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "water")] <-  "Drink Number"

# Changing label Number by Number of Meals and Number of Drinks
df.meanCase.CD.m$variable [which (df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "food_cd")] <-  "Meal Number"
df.meanCase.CD.m$variable [which (df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "water")] <-  "Drink Number"



setwd ("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures/fig4ANDfigS4Dev")
heatMapPlotter (df.meanCase.SC.m, main="Free-Choice SC\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")
heatMapPlotter (df.meanCase.CD.m, main="Free-Choice CM\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")


## Comparing CD food of CM mice vs SC food of CM mice
df.meanCase.CDvsSC.m <- df.meanCase.CD.m
df.meanCase.CDvsSC.m$foldChange <- foldchange (df.meanCase.CDvsSC.m$value, df.meanCase.SC.m$value)

#I want to insert this order Avg Intake, number, avg duration and rate, so the order is the same as in the other plots
# ggplot takes inverse order so I have to label this way rate, avg duration, number, avg intake
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Rate")] <-  "a"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Avg Duration")] <-  "b"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Number")] <-  "c"
df.meanCase.CDvsSC.m$varOrder [which (df.meanCase.CDvsSC.m$variable == "Avg Intake")] <-  "d"

df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Rate")] <-  "1"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Avg Duration")] <-  "2"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Number")] <-  "3"
df.meanCase.CDvsSC.m$orderOut [which (df.meanCase.CDvsSC.m$variable == "Avg Intake")] <-  "4"

#Ordering
df.meanCase.CDvsSC.m <- df.meanCase.CDvsSC.m [with (df.meanCase.CDvsSC.m, order (period, channel, orderOut) ),]

# Changing label Number by Number of Meals and Number of Drinks
df.meanCase.CDvsSC.m$variable [which (df.meanCase.CDvsSC.m$variable == "Number" & df.meanCase.CDvsSC.m$channel == "food_cd")] <-  "Meal Number"
df.meanCase.CDvsSC.m$variable [which (df.meanCase.CDvsSC.m$variable == "Number" & df.meanCase.CDvsSC.m$channel == "water")] <-  "Drink Number"

heatMapPlotter (df.meanCase.CDvsSC.m, main="Free-Choice CM\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Eating Behavior                          Drinking Behavior\n")






# ### SIGNIFICANCE RESULTS
# #do to df.weekStats one only with water and SC events and a second one with water and CM
# df.weekStats.SC <- df.weekStats [which (df.weekStats$channel == "food_sc" |  df.weekStats$channel == "water"),]
# 
# sigResults.SC <- c()
# sigResults.SC <- pValueCalc (df.weekStats.SC)
# 
# row.names (sigResults.SC) <- c (1:length (sigResults.SC [,1] ))
# df.sigResults.SC <- as.data.frame(sigResults.SC, stringsAsFactors=F)
# colnames (df.sigResults.SC) <- c("channel", "group", "period", "variable","foldChange")
# df.sigResults.SC
# #order the data by period
# df.sigResults.SC$period <- as.numeric (df.sigResults.SC$period)
# df.sigResults.SC$week <-df.sigResults.SC$period
# df.sigResults.SC$week <- with (df.sigResults.SC, reorder (week, period,))
# 
# #removing underscores for plotting
# df.sigResults.SC$variable <-  gsub ("_", " ", df.sigResults.SC$variable, ignore.case = TRUE)
# #Merging channel and variable
# # df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
# df.sigResults.SC$chVar <- df.sigResults.SC$variable
# #fold change have to be numeric to make the function work
# df.sigResults.SC$foldChange <- as.numeric (df.sigResults.SC$foldChange)
# 
# ############
# ## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
# ## First df.meanCase.m has to be created
# # to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# # to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
# #OJO la tabla df.meanCase.SC.m tiene que tener anotado el channel como food_sc y no solo como food y Avg Intake y Avg duration no tienen que tener underscore
# for (i in c (1: length (df.sigResults.SC [,1])))
# {
#   print (i)
#   foldChange <- df.meanCase.SC.m [df.meanCase.SC.m$channel == df.sigResults.SC$channel [i] 
#                                   & df.meanCase.SC.m$group == df.sigResults.SC$group [i]
#                                   & df.meanCase.SC.m$period == df.sigResults.SC$period [i]
#                                   & df.meanCase.SC.m$variable == df.sigResults.SC$variable [i], "foldChange"]
#   #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
#   print (foldChange)
#   if (length (foldChange) == 0) print (i) 
#   if (foldChange < 0) {print (as.numeric (-df.sigResults.SC$foldChange [i]))}
#   if (foldChange < 0) {df.sigResults.SC$foldChange [i] <- as.numeric(-df.sigResults.SC$foldChange [i]) -1  }
# }
# 
# df.sigResults.SC.Dev <- df.sigResults.SC [df.sigResults.SC$period > 8 & df.sigResults.SC$period < 16,]
# df.sigResults.SC.Dev$period <- df.sigResults.SC.Dev$period - 7
# heatMapPlotter (df.sigResults.SC, main="Free-choice SC\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
# heatMapPlotter (df.sigResults.SC.Dev, main="Free-choice SC\n",   weekNotation = "N", mode="pvalues", legPos="right", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
# 
# ####### CD CHANNEL
# # CD channel
# #here I have to get for food not only the free choice CD but also the controls with SC to make the comparison possible
# df.weekStats.CD <- df.weekStats [which (df.weekStats$channel == "food_cd" |  df.weekStats$channel == "water" | (df.weekStats$channel == "food_sc"  & df.weekStats$group == "control") ),]
# 
# df.weekStats.CD$chType <-  gsub ("food_sc", "food", df.weekStats.CD$channel, ignore.case = TRUE)
# df.weekStats.CD$chType <-  gsub ("food_cd", "food", df.weekStats.CD$chType, ignore.case = TRUE)
# 
# sigResults.CD <- c()
# for (p in unique (df.weekStats.CD$period))
# {
#   for (ch in unique (df.weekStats.CD$chType))
#   {
#     print (ch)
#     df.subset <- subset (df.weekStats.CD, period == p & chType == ch, 
#                          select = c(period, channel, group, cage, Rate, Number, Avg_Intake, Avg_Duration))
#     print ("--------")
#     print (df.subset)
#     #The first columns with categorical data do not need to be include in signif calculation
#     signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
#                             function (x)
#                             {
#                               #wilcox test
#                               unlist (wilcox.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
#                               #t test
#                               #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
#                             }))
#     print (as.numeric(signWater ["Number","p.value"]))
#     #         ch <- "food_cd"
#     rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
#     rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
#     rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
#     rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
#     
#     sigResults.CD <- rbind (sigResults.CD, rRate, rNmeals, rAvgIntake, rAvgDuration)
#   }
# }
# # warnings ()
# # head (sigResults.CD,80)
# row.names (sigResults.CD) <- c (1:length (sigResults.CD [,1] ))
# df.sigResults.CD <- as.data.frame(sigResults.CD, stringsAsFactors=F)
# colnames (df.sigResults.CD) <- c("channel", "group", "period", "variable","foldChange")
# df.sigResults.CD
# #order the data by period
# df.sigResults.CD$period <- as.numeric (df.sigResults.CD$period)
# df.sigResults.CD$week <-df.sigResults.CD$period
# df.sigResults.CD$week <- with (df.sigResults.CD, reorder (week, period,))
# 
# #removing underscores for plotting
# df.sigResults.CD$variable <-  gsub ("_", " ", df.sigResults.CD$variable, ignore.case = TRUE)
# #Merging channel and variable
# # df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
# df.sigResults.CD$chVar <- df.sigResults.CD$variable
# #fold change have to be numeric to make the function work
# df.sigResults.CD$foldChange <- as.numeric (df.sigResults.CD$foldChange)
# 
# #Volver a poner el campo como food_cd
# df.sigResults.CD$channel <-  gsub ("food", "food_cd", df.sigResults.CD$channel, ignore.case = TRUE)
# ############
# ## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
# ## First df.meanCase.m has to be created
# # to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# # to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
# for (i in c (1: length (df.sigResults.CD [,1])))
# {
#   print (i)
#   foldChange <- df.meanCase.CD.m [df.meanCase.CD.m$channel == df.sigResults.CD$channel [i] 
#                                   & df.meanCase.CD.m$group == df.sigResults.CD$group [i]
#                                   & df.meanCase.CD.m$period == df.sigResults.CD$period [i]
#                                   & df.meanCase.CD.m$variable == df.sigResults.CD$variable [i], "foldChange"]
#   #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
#   print (foldChange)
#   if (foldChange < 0) {print (as.numeric (-df.sigResults.CD$foldChange [i]))}
#   if (foldChange < 0) {df.sigResults.CD$foldChange [i] <- as.numeric(-df.sigResults.CD$foldChange [i]) -1  }
# }
# 
# #Filtering habituation phase
# df.sigResults.CD.Dev <- df.sigResults.CD [df.sigResults.CD$period > 8 & df.sigResults.CD$period < 16,]
# df.sigResults.CD.Dev$period <- df.sigResults.CD.Dev$period - 7
# 
# # heatMapPlotter (df.sigResults.CD.Dev, main="Free choice Diet CD vs Control SC",   mode="pvalues")
# heatMapPlotter (df.sigResults.CD, main="Free-choice CM\n",   weekNotation = "N", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
# heatMapPlotter (df.sigResults.CD.Dev, main="Free-choice CM\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment phase (weeks)",ylab="Food                                                  Water\n")
# 
# # heatMapPlotter (df.sigResults4devWeeks, main="",  weekNotation=T, legPos="none", mode="pvalues")
# 
# #######################
# ## Significant results CD channel CM mice vs SC channel CM mice
# 
# ####### CD channel CM mice vs SC channel CM mice
# #here I have to get for 2 food channels only for the free choice to make the comparison possible
# df.weekStats.CDvsSC <- df.weekStats [which (df.weekStats$channel == "food_cd" |  df.weekStats$channel == "water" & df.weekStats$group == "freeChoice" | (df.weekStats$channel == "food_sc"  & df.weekStats$group == "freeChoice") ),]
# #Duplication of water rows to make possible the comparison, should be always fold change of 0 (Black)
# df.weekStats.CDvsSC.Water2<- df.weekStats [which (df.weekStats$channel == "water" & df.weekStats$group == "freeChoice"),]
# head (df.weekStats.CDvsSC)
# head (df.weekStats.CDvsSC.Water2)
# df.weekStats.CDvsSC.Water2$channel <- "water2"
# df.weekStats.CDvsSC <- rbind (df.weekStats.CDvsSC, df.weekStats.CDvsSC.Water2 )
# 
# df.weekStats.CDvsSC$chType <-  gsub ("food_sc", "food", df.weekStats.CDvsSC$channel, ignore.case = TRUE)
# df.weekStats.CDvsSC$chType <-  gsub ("food_cd", "food", df.weekStats.CDvsSC$chType, ignore.case = TRUE)
# df.weekStats.CDvsSC$chType <-  gsub ("water2", "water", df.weekStats.CDvsSC$chType, ignore.case = TRUE)
# sigResults.CDvsSC <- c()
# for (p in unique (df.weekStats.CDvsSC$period))
# {
#   
#   for (ch in unique (df.weekStats.CDvsSC$chType))
#   {
#     print (ch)
#     df.subset <- subset (df.weekStats.CDvsSC, period == p & chType == ch, 
#                          select = c(period, channel, group, cage, Rate, Number, Avg_Intake, Avg_Duration))
#     print ("--------")
#     print (df.subset)
#     #The first columns with categorical data do not need to be include in signif calculation
#     signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
#                             function (x)
#                             {
#                               #wilcox test
#                               unlist (wilcox.test (x~df.subset$channel) [c ("estimate", "p.value", "statistic", "conf.int")])
#                               #t test
#                               #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
#                             }))
#     print (as.numeric(signWater ["Number","p.value"]))
#     #         ch <- "food_cd"
#     rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
#     rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
#     rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
#     rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
#     
#     sigResults.CDvsSC <- rbind (sigResults.CDvsSC, rRate, rNmeals, rAvgIntake, rAvgDuration)
#   }
# }
# # warnings ()
# # head (sigResults.CD,80)
# row.names (sigResults.CDvsSC) <- c (1:length (sigResults.CDvsSC [,1] ))
# df.sigResults.CDvsSC <- as.data.frame(sigResults.CDvsSC, stringsAsFactors=F)
# colnames (df.sigResults.CDvsSC) <- c("channel", "group", "period", "variable","foldChange")
# df.sigResults.CDvsSC
# #order the data by period
# df.sigResults.CDvsSC$period <- as.numeric (df.sigResults.CDvsSC$period)
# df.sigResults.CDvsSC$week <-df.sigResults.CDvsSC$period
# df.sigResults.CDvsSC$week <- with (df.sigResults.CDvsSC, reorder (week, period,))
# 
# #removing underscores for plotting
# df.sigResults.CDvsSC$variable <-  gsub ("_", " ", df.sigResults.CDvsSC$variable, ignore.case = TRUE)
# #Merging channel and variable
# # df.sigResults$chVar <- paste (df.sigResults$channel, df.sigResults$variable, sep = "_")
# df.sigResults.CDvsSC$chVar <- df.sigResults.CDvsSC$variable
# #fold change have to be numeric to make the function work
# df.sigResults.CDvsSC$foldChange <- as.numeric (df.sigResults.CDvsSC$foldChange)
# #Volver a poner el campo como food_cd
# df.sigResults.CDvsSC$channel <-  gsub ("food", "food_cd", df.sigResults.CDvsSC$channel, ignore.case = TRUE)
# ############
# ## Combine the table with the fold change with the table of the significancies in order to set the negative fold change
# ## First df.meanCase.m has to be created
# # to yellow significancies and the positive to blue -->  the trick is to set the significancies related to a negative fold change
# # to negative values, eg 0.001 --> -0.001 and use the yellow scale for the negative values 
# 
# for (i in c (1: length (df.meanCase.CDvsSC.m [,1])))
# {
#   print (i)
#   foldChange <- df.meanCase.CDvsSC.m [df.meanCase.CDvsSC.m$channel == df.sigResults.CDvsSC$channel [i] 
#                                       & df.meanCase.CDvsSC.m$group == df.sigResults.CDvsSC$group [i]
#                                       & df.meanCase.CDvsSC.m$period == df.sigResults.CDvsSC$period [i]
#                                       & df.meanCase.CDvsSC.m$variable == df.sigResults.CDvsSC$variable [i], "foldChange"]
#   #                    & df.meanCase.m$variable == df.sigResults$variable [i], 6]
#   print (foldChange)
#   if (foldChange < 0) {print (as.numeric (-df.sigResults.CDvsSC$foldChange [i]))}
#   if (foldChange < 0) {df.sigResults.CDvsSC$foldChange [i] <- as.numeric(-df.sigResults.CDvsSC$foldChange [i]) -1  }
# }
# df.sigResults.CDvsSC$foldChange
# 
# #Filtering habituation phase
# df.sigResults.CDvsSC.Dev <- df.sigResults.CDvsSC [df.sigResults.CDvsSC$period > 8 & df.sigResults.CDvsSC$period < 16,]
# df.sigResults.CDvsSC.Dev$period <- df.sigResults.CDvsSC.Dev$period - 7
# 
# # heatMapPlotter (df.sigResults.CD.Dev, main="Free choice Diet CD vs Control SC",   mode="pvalues")
# heatMapPlotter (df.sigResults.CDvsSC, main="Free-choice CM\n",   weekNotation = "N", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
# heatMapPlotter (df.sigResults.CDvsSC.Dev, main="Free-choice CM\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment phase (weeks)",ylab="Food                                                  Water\n")
# 
# df.sigResults.CDvsSC.Dev [which (df.sigResults.CDvsSC.Dev$variable =="Number" & df.sigResults.CDvsSC.Dev$channel == "food_cd"),]
# 

#########################################################
## COMPARACION TODOS LOS MEALS DE FREE CHOICE JUNTOS CONTRA TODOS LOS MEALS DE CONTROLES
## HAY UN FOLD CHANGE INCREASE???

df.meanCase.SC.m [df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "food_sc",]
df.meanCase.CD.m [df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "food_cd",]
df.meanControl.m [df.meanControl.m$variable == "Number" & df.meanControl.m$channel == "food_sc",]


allMealsFreeChoice <- df.meanCase.SC.m [df.meanCase.SC.m$variable == "Number" & df.meanCase.SC.m$channel == "food_sc",5] + df.meanCase.CD.m [df.meanCase.CD.m$variable == "Number" & df.meanCase.CD.m$channel == "food_cd",5]
df.meanControl.m [df.meanControl.m$variable == "Number" & df.meanControl.m$channel == "food_sc",5]
foldchange (allMealsFreeChoice, df.meanControl.m [df.meanControl.m$variable == "Number" & df.meanControl.m$channel == "food_sc",5])

#########################################################