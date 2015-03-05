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
weekStatsData <- "/phecomp/20121128_heatMapPhecomp/tblFiles/20131029_to1213_ts65dn_devTwoMinFilt.tbl"

df.weekStats <- read.table (paste (home, weekStatsData, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=F)

## ASSIGNING DIET
#Hard code
caseGroupLabel <- "freeChoice"
controlGroupLabel <- "SC"

## Free choice animals in this experiment are c2,c4,c5,c7,c10,c11,c13,c16,c17,c18
FCAnimals <- c (2,4,5,7,10,11,13,16,17,18)

#FCAnimals <- c (2,4,5,7,10,11,13,14,16,17) #FAKE for developping!!!!!!!!
nAnimals <- 18

#Label by experimental group (control, free choice, force diet...)
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals))
group [FCAnimals] <- caseGroupLabel

df.miceGroup <- data.frame (cage, group)

df.weekStats <- merge (df.weekStats, df.miceGroup, by.x= "cage", by.y = "cage")

## ASSIGNING GENOTYPE
#Hard code
wtGroupLabel <- "wt"
mutGroupLabel <- "ts65dn"

nAnimals <- 18
#Label by genotype group (wt, ts65dn...)
cage <- c (1 : nAnimals)
genotype <- c (rep (wtGroupLabel, nAnimals/2), rep (mutGroupLabel, nAnimals/2))
df.miceGen <- data.frame (cage, genotype)
df.miceGen$genotype [which (cage %% 2 != 0)] <- wtGroupLabel
df.miceGen$genotype [which (cage %% 2 == 0)] <- mutGroupLabel

df.weekStats <- merge (df.weekStats, df.miceGen, by.x= "cage", by.y = "cage")

head (df.weekStats)


#Number of meals normalized for a single channel (in free choice animals we only have one channel for SC and one for CM)
head (df.weekStats [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "SC") , ])
# df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "SC")] <- df.weekStats$Number [which (df.weekStats$channel == "food_sc" & df.weekStats$group == "SC")] / 2

### ALGUNOS CONTROLES TIENEN FOOD_CD
## para borrar una vez el test este hecho #del
#### table2StudyChannels<-df.weekStats [which (df.weekStats$period == 1),]

#############
#SC and wt
df.mean_SC_wt <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel & df.weekStats$genotype == wtGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, genotype=genotype, period=period), mean))

#SC and ts65dn
df.mean_SC_ts65 <- with (df.weekStats [which (df.weekStats$group == controlGroupLabel & df.weekStats$genotype == mutGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, genotype=genotype, period=period), mean))

#############
#Free choice and wt
df.mean_FC_Wt <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel & df.weekStats$genotype == wtGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, genotype=genotype, period=period), mean))

#Free choice and ts65dn
df.mean_FC_ts65 <- with (df.weekStats [which (df.weekStats$group == caseGroupLabel & df.weekStats$genotype == mutGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, genotype=genotype, period=period), mean))

## FREE CHOICE HAVE TWO FOOD CHANNELS -> 2 SEPARATED HEATMAPS
df.mean_FC_Wt.SC <- df.mean_FC_Wt [which (df.mean_FC_Wt$channel == "food_sc" |  df.mean_FC_Wt$channel == "water"),]
df.mean_FC_ts65.SC <- df.mean_FC_ts65 [which (df.mean_FC_ts65$channel == "food_sc" |  df.mean_FC_ts65$channel == "water"),]
df.mean_FC_Wt.CD <- df.mean_FC_Wt [which (df.mean_FC_Wt$channel == "food_cd" |  df.mean_FC_Wt$channel == "water"),]
df.mean_FC_ts65.CD <- df.mean_FC_ts65 [which (df.mean_FC_ts65$channel == "food_cd" |  df.mean_FC_ts65$channel == "water"),]

#Formatting data frame with shape for heat map
df.mean_SC_wt.m <- melt (df.mean_SC_wt, id.vars=c("channel", "group", "genotype","period"))
df.mean_SC_ts65.m <- melt (df.mean_SC_ts65, id.vars=c("channel", "group", "genotype","period"))
df.mean_FC_Wt.SC.m <- melt (df.mean_FC_Wt.SC, id.vars=c("channel", "group", "genotype","period"))
df.mean_FC_ts65.SC.m <- melt (df.mean_FC_ts65.SC, id.vars=c("channel", "group", "genotype","period"))
df.mean_FC_Wt.CD.m <- melt (df.mean_FC_Wt.CD, id.vars=c("channel", "group", "genotype","period"))
df.mean_FC_ts65.CD.m <- melt (df.mean_FC_ts65.CD, id.vars=c("channel", "group", "genotype","period"))

#Do length matches then bingo!!!
length (df.mean_SC_wt.m$value)
length (df.mean_SC_ts65.m$value)
length (df.mean_FC_Wt.SC.m$value)
length (df.mean_FC_ts65.SC.m$value)
length (df.mean_FC_Wt.CD.m$value)
length (df.mean_FC_ts65.CD.m$value)

# FOLD CHANGE CALCULATION

######### Ts65 vs Ts65
####Ts65 - FC diet ??? channel CD VERSUS Ts65 - FC diet ??? channel SC #OK
foldCh_FC_CD_ts65_vs_FC_SC_ts65 <- df.mean_FC_ts65.CD.m
foldCh_FC_CD_ts65_vs_FC_SC_ts65$foldChange <- foldchange (df.mean_FC_ts65.CD.m$value, df.mean_FC_ts65.SC.m$value)

foldCh_FC_CD_ts65_vs_FC_SC_ts65$variable <-  gsub ("_", " ", foldCh_FC_CD_ts65_vs_FC_SC_ts65$variable, ignore.case = TRUE)
foldCh_FC_CD_ts65_vs_FC_SC_ts65 <- foldCh_FC_CD_ts65_vs_FC_SC_ts65 [with (foldCh_FC_CD_ts65_vs_FC_SC_ts65, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_ts65_vs_FC_SC_ts65, main="ts65dn FreeChoice CD channel vs ts65dn FreeChoice SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

####Ts65 - FC diet ??? channel SC VERSUS Ts65 - SC diet ??? channel SC #OK
foldCh_FC_SC_ts65_vs_SC_SC_ts65 <- df.mean_FC_ts65.SC.m
foldCh_FC_SC_ts65_vs_SC_SC_ts65$foldChange <- foldchange (df.mean_FC_ts65.SC.m$value, df.mean_SC_ts65.m$value)

foldCh_FC_SC_ts65_vs_SC_SC_ts65$variable <-  gsub ("_", " ", foldCh_FC_SC_ts65_vs_SC_SC_ts65$variable, ignore.case = TRUE)
foldCh_FC_SC_ts65_vs_SC_SC_ts65 <- foldCh_FC_SC_ts65_vs_SC_SC_ts65 [with (foldCh_FC_SC_ts65_vs_SC_SC_ts65, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_SC_ts65_vs_SC_SC_ts65, main="ts65dn FreeChoice SC channel vs ts65dn SC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")


#### Ts65 - FC diet ??? channel CD vs Ts65 - SC diet ??? channel SC #OK
foldCh_FC_CD_ts65_vs_SC_SC_ts65 <- df.mean_FC_ts65.CD.m
foldCh_FC_CD_ts65_vs_SC_SC_ts65$foldChange <- foldchange (df.mean_FC_ts65.CD.m$value, df.mean_SC_ts65.m$value)

foldCh_FC_CD_ts65_vs_SC_SC_ts65$variable <-  gsub ("_", " ", foldCh_FC_CD_ts65_vs_SC_SC_ts65$variable, ignore.case = TRUE)
foldCh_FC_CD_ts65_vs_SC_SC_ts65 <- foldCh_FC_CD_ts65_vs_SC_SC_ts65 [with (foldCh_FC_CD_ts65_vs_SC_SC_ts65, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_ts65_vs_SC_SC_ts65, main="ts65dn FreeChoice CD channel vs ts65dn SC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

######### wt vs wt
####wt - FC diet ??? channel CD vs wt - FC diet ??? channel SC #OK
foldCh_FC_CD_Wt_vs_FC_SC_Wt <- df.mean_FC_Wt.CD.m
foldCh_FC_CD_Wt_vs_FC_SC_Wt$foldChange <- foldchange (df.mean_FC_Wt.CD.m$value, df.mean_FC_Wt.SC.m$value)

foldCh_FC_CD_Wt_vs_FC_SC_Wt$variable <-  gsub ("_", " ", foldCh_FC_CD_Wt_vs_FC_SC_Wt$variable, ignore.case = TRUE)
foldCh_FC_CD_Wt_vs_FC_SC_Wt <- foldCh_FC_CD_Wt_vs_FC_SC_Wt [with (foldCh_FC_CD_Wt_vs_FC_SC_Wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_Wt_vs_FC_SC_Wt, main="wt FreeChoice CD channel vs wt FreeChoice SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")


####wt - FC diet ??? channel SC vs wt - SC diet ??? channel SC #OK
foldCh_FC_SC_Wt_vs_SC_SC_Wt <- df.mean_FC_Wt.SC.m
foldCh_FC_SC_Wt_vs_SC_SC_Wt$foldChange <- foldchange ( df.mean_FC_Wt.SC.m$value,  df.mean_SC_wt.m$value)

foldCh_FC_SC_Wt_vs_SC_SC_Wt$variable <-  gsub ("_", " ", foldCh_FC_SC_Wt_vs_SC_SC_Wt$variable, ignore.case = TRUE)
foldCh_FC_SC_Wt_vs_SC_SC_Wt <- foldCh_FC_SC_Wt_vs_SC_SC_Wt [with (foldCh_FC_SC_Wt_vs_SC_SC_Wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_SC_Wt_vs_SC_SC_Wt, main="Wt FreeChoice SC channel vs Wt SC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

####wt - FC diet ??? channel CD vs wt - SC diet ??? channel SC #OK
foldCh_FC_CD_Wt_vs_SC_SC_Wt <- df.mean_FC_Wt.CD.m
foldCh_FC_CD_Wt_vs_SC_SC_Wt$foldChange <- foldchange (df.mean_FC_Wt.CD.m$value, df.mean_SC_wt.m$value)

foldCh_FC_CD_Wt_vs_SC_SC_Wt$variable <-  gsub ("_", " ", foldCh_FC_CD_Wt_vs_SC_SC_Wt$variable, ignore.case = TRUE)
foldCh_FC_CD_Wt_vs_SC_SC_Wt <- foldCh_FC_CD_Wt_vs_SC_SC_Wt [with (foldCh_FC_CD_Wt_vs_SC_SC_Wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_Wt_vs_SC_SC_Wt, main="Wt FreeChoice CD channel vs Wt SC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

#########Ts65  vs wt 
####ts65dn - SC diet ??? channel SC vs ts65dn - SC diet ??? channel SC #OK
foldCh_SC_SC_ts65_vs_SC_SC_wt <- df.mean_SC_ts65.m
foldCh_SC_SC_ts65_vs_SC_SC_wt$foldChange <- foldchange (df.mean_SC_ts65.m$value, df.mean_SC_wt.m$value)

foldCh_SC_SC_ts65_vs_SC_SC_wt$variable <-  gsub ("_", " ", foldCh_SC_SC_ts65_vs_SC_SC_wt$variable, ignore.case = TRUE)

foldCh_SC_SC_ts65_vs_SC_SC_wt <- foldCh_SC_SC_ts65_vs_SC_SC_wt [with (foldCh_SC_SC_ts65_vs_SC_SC_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_SC_SC_ts65_vs_SC_SC_wt, main="ts65dn SC diet SC channel vs wt SC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

####ts65dn - FC diet ??? channel SC vs wt - FC diet ??? channel SC #OK
foldCh_FC_SC_ts65_vs_FC_SC_wt <- df.mean_FC_ts65.SC.m
foldCh_FC_SC_ts65_vs_FC_SC_wt$foldChange <- foldchange (df.mean_FC_ts65.SC.m$value, df.mean_FC_Wt.SC.m$value)

foldCh_FC_SC_ts65_vs_FC_SC_wt$variable <-  gsub ("_", " ", foldCh_FC_SC_ts65_vs_FC_SC_wt$variable, ignore.case = TRUE)

foldCh_FC_SC_ts65_vs_FC_SC_wt <- foldCh_FC_SC_ts65_vs_FC_SC_wt [with (foldCh_FC_SC_ts65_vs_FC_SC_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_SC_ts65_vs_FC_SC_wt, main="ts65dn FC diet SC channel vs wt FC diet SC channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

#### ESTE ES EL QUE NO COINCIDE #WATER esta abajo y comida arriba cuidaoooo TODO DESORDENADO PERO CREO QUE DENTRO DE LA FUNCION SE HACE
####ts65dn - FC diet ??? channel CD vs wt - FC diet ??? channel CD #OK
foldCh_FC_CD_ts65_vs_FC_CD_wt <- df.mean_FC_ts65.CD.m
foldCh_FC_CD_ts65_vs_FC_CD_wt$foldChange <- foldchange (df.mean_FC_ts65.CD.m$value, df.mean_FC_Wt.CD.m$value)

foldCh_FC_CD_ts65_vs_FC_CD_wt$variable <-  gsub ("_", " ", foldCh_FC_CD_ts65_vs_FC_CD_wt$variable, ignore.case = TRUE)
foldCh_FC_CD_ts65_vs_FC_CD_wt <- foldCh_FC_CD_ts65_vs_FC_CD_wt [with (foldCh_FC_CD_ts65_vs_FC_CD_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_ts65_vs_FC_CD_wt, main="ts65dn FC diet CD channel vs wt FC diet CD channel \n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

#### ts65dn - FC diet ??? channel SC vs wt - SC diet ??? channel SC #OK
foldCh_FC_SC_ts65_vs_FC_SC_wt <- df.mean_FC_ts65.SC.m
foldCh_FC_SC_ts65_vs_FC_SC_wt$foldChange <- foldchange (df.mean_FC_ts65.SC.m$value, df.mean_SC_wt.m$value)

foldCh_FC_SC_ts65_vs_FC_SC_wt$variable <-  gsub ("_", " ", foldCh_FC_SC_ts65_vs_FC_SC_wt$variable, ignore.case = TRUE)
foldCh_FC_SC_ts65_vs_FC_SC_wt <- foldCh_FC_CD_ts65_vs_FC_SC_wt [with (foldCh_FC_SC_ts65_vs_FC_SC_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_SC_ts65_vs_FC_SC_wt, main="FreeChoice SC channel ts65dn vs SC diet SC channel wt\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")


#### ts65dn - FC diet ??? channel CD vs wt - FC diet ??? channel SC #OK
foldCh_FC_CD_ts65_vs_FC_SC_wt <- df.mean_FC_ts65.CD.m
foldCh_FC_CD_ts65_vs_FC_SC_wt$foldChange <- foldchange (df.mean_FC_ts65.CD.m$value, df.mean_FC_Wt.SC.m$value)

foldCh_FC_CD_ts65_vs_FC_SC_wt$variable <-  gsub ("_", " ", foldCh_FC_CD_ts65_vs_FC_SC_wt$variable, ignore.case = TRUE)
foldCh_FC_CD_ts65_vs_FC_SC_wt <- foldCh_FC_CD_ts65_vs_FC_SC_wt [with (foldCh_FC_CD_ts65_vs_FC_SC_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_ts65_vs_FC_SC_wt, main="FreeChoice CD channel ts65dn vs FC diet SC channel wt\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

















####ts65dn - FC diet ??? channel SC vs wt - SC diet ??? channel SC





######### Ts65 FC diet vs Wt FC diet
#### FC CD channel ts65 vs FC CD channel wt

##First developed keep as template
#### SCts65_vs_SCwt
foldCh_SCts65_vs_SCwt <- df.mean_SC_ts65.m
foldCh_SCts65_vs_SCwt$foldChange <- foldchange (df.mean_SC_ts65.m$value, df.mean_SC_wt.m$value)
# foldCh_SCts65_vs_SCwt <- foldCh_SCts65_vs_SCwt [,-3]

# df.meanCase.SC.m$variable <-  gsub ("_", " ", df.meanCase.SC.m$variable, ignore.case = TRUE)

foldCh_SCts65_vs_SCwt$variable <-  gsub ("_", " ", foldCh_SCts65_vs_SCwt$variable, ignore.case = TRUE)

# este era el bueno
# foldCh_SCts65_vs_SCwt$variable <- as.character (foldCh_SCts65_vs_SCwt$variable)
class (foldCh_SCts65_vs_SCwt$variable)
# class(df.meanCase.CD.m$variable)

foldCh_SCts65_vs_SCwt <- foldCh_SCts65_vs_SCwt [with (foldCh_SCts65_vs_SCwt, order (period, channel,variable)),]

heatMapPlotter (foldCh_SCts65_vs_SCwt, main="SC diet SC channel ts65dn vs SC diet SC channel wt\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")
##First developed keep as template













#### FC CD channel ts65 vs FC SC channel wt
foldCh_FC_CD_ts65_vs_FC_SC_wt <- df.mean_FC_ts65.CD.m
foldCh_FC_CD_ts65_vs_FC_SC_wt$foldChange <- foldchange (df.mean_FC_ts65.CD.m$value, df.mean_FC_Wt.SC.m$value)

foldCh_FC_CD_ts65_vs_FC_SC_wt$variable <-  gsub ("_", " ", foldCh_FC_CD_ts65_vs_FC_SC_wt$variable, ignore.case = TRUE)
foldCh_FC_CD_ts65_vs_FC_SC_wt <- foldCh_FC_CD_ts65_vs_FC_SC_wt [with (foldCh_FC_CD_ts65_vs_FC_SC_wt, order (period, channel,variable)),]

heatMapPlotter (foldCh_FC_CD_ts65_vs_FC_SC_wt, main="FreeChoice CD channel ts65dn vs FreeChoice SC channel wt\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")





######
### OLD


df.mean_SC_ts65.m$foldChange <- foldchange (df.mean_SC_ts65.m$value, df.mean_SC_wt.m$value)




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

df.meanCase.SC.m <- df.meanCase.SC.m [with (df.meanCase.SC.m, order (period, channel,variable)),]
df.meanCase.CD.m <- df.meanCase.CD.m [with (df.meanCase.CD.m, order (period, channel,variable)),]

heatMapPlotter (df.meanCase.SC.m, main="Free-Choice SC vs. Control SC\n",weekNotation=T)
heatMapPlotter (df.meanCase.CD.m, main="Free-Choice CM\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

#Filtering only weeks after chocolated has been changed
df.meanCase.SC.m.Dev <- df.meanCase.SC.m [df.meanCase.SC.m$period > 8 & df.meanCase.SC.m$period < 16,]
df.meanCase.SC.m.Dev$period <- df.meanCase.SC.m.Dev$period - 7
df.meanCase.CD.m.Dev <- df.meanCase.CD.m [df.meanCase.CD.m$period > 8 & df.meanCase.CD.m$period < 16,]
df.meanCase.CD.m.Dev$period <- df.meanCase.CD.m.Dev$period - 7

setwd ("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures/fig4ANDfigS4Dev")
heatMapPlotter (df.meanCase.SC.m.Dev, main="Free-Choice SC\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")
heatMapPlotter (df.meanCase.CD.m.Dev, main="Free-Choice CM\n",  weekNotation="N", legPos="right",
                xlab="\nDevelopment Phase (weeks)", ylab="Food                                          Water\n")

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

df.sigResults.SC.Dev <- df.sigResults.SC [df.sigResults.SC$period > 8 & df.sigResults.SC$period < 16,]
df.sigResults.SC.Dev$period <- df.sigResults.SC.Dev$period - 7
heatMapPlotter (df.sigResults.SC, main="Free-choice SC\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
heatMapPlotter (df.sigResults.SC.Dev, main="Free-choice SC\n",   weekNotation = "N", mode="pvalues", legPos="right", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")

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
                            select = c(period, channel, group, cage, Rate, Number, Avg_Intake, Avg_Duration))
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
                                                              
        sigResults.CD <- rbind (sigResults.CD, rRate, rNmeals, rAvgIntake, rAvgDuration)
      }
  }
# warnings ()
# head (sigResults.CD,80)
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

#Filtering habituation phase
df.sigResults.CD.Dev <- df.sigResults.CD [df.sigResults.CD$period > 8 & df.sigResults.CD$period < 16,]
df.sigResults.CD.Dev$period <- df.sigResults.CD.Dev$period - 7

# heatMapPlotter (df.sigResults.CD.Dev, main="Free choice Diet CD vs Control SC",   mode="pvalues")
heatMapPlotter (df.sigResults.CD, main="Free-choice CM\n",   weekNotation = "N", mode="pvalues", xlab="\nDevelopment Phase (weeks)",ylab="Food                                                  Water\n")
heatMapPlotter (df.sigResults.CD.Dev, main="Free-choice CM\n",   weekNotation = "N", legPos="right", mode="pvalues", xlab="\nDevelopment phase (weeks)",ylab="Food                                                  Water\n")

# heatMapPlotter (df.sigResults4devWeeks, main="",  weekNotation=T, legPos="none", mode="pvalues")

##############################
#FUNCTIONS
heatMapPlotter <- function (table, main="Fold Change Force diet vs Control", weekNotation=F)
  {
      #Change weeks by Development and habituation notation
      if (weekNotation == T)
        {           
          table$week <- paste ("Dev Phase", table$period-1, sep = " ") 
          #table$week <- paste ("Dev Phase", table$period, sep = " ") 
 
          levels(table$week) <- c (levels(table$week), "Dev Phase")          
          #table$week  [table$week == "Dev Phase 0"] <- 'Habituation'            
        }
      else
        {
          table$week <- paste ("week", table$period, sep = "_")
        }
      #table$week <-table$period
      table$period <- as.numeric (table$period)
      table$week <- with (table, reorder (week, period,))
          
      #Merging channel and variable
      #table$chVar <- paste (table$channel, table$variable, sep = " ")
      #Capitalizing channel name
      table$chVar <- paste (sapply (table$channel, simpleCap), table$variable, sep = " ")
             
      (p <- ggplot(table, aes(week, chVar)) + geom_tile(aes(fill = foldChange),
            colour = "white") + 
            scale_fill_gradientn (colours = c('green', 'green', 'green', 'black', 'black', 'red', 'red', 'red'),
                                  values   = c(-10,  -3, -3, 0, 0, 3, 3, 10), guide = "colorbar", limits=c(-3,3),
                                  labels = c("<-3","-2","-1","0", "1", "2", ">3"), name ="Fold Change",                            
                                  rescaler = function(x,...) x,
                                  oob = identity)+ opts (title = main))#with legend
                                  #oob = identity)+ opts (title = main, legend.position = "none"))#no legend
                                        
      base_size <- 9
      p + theme_grey (base_size = base_size) + labs(x = "",
                    y = "") + scale_x_discrete(expand = c(0, 0)) +
                    scale_y_discrete(expand = c(0, 0)) + 
                    opts (axis.ticks = theme_blank(), 
                    axis.text.x = theme_text(size = base_size * 1.4, angle = 330,
                    #1.2, angle = 330,                     
                    #hjust = 0, colour = "grey50", face = "bold"), #labels=c("Control", "Treat 1", "Treat 2")),
                    hjust = 0, face = "bold"),                         
                    #axis.text.y = theme_text (size = base_size * 1.2,hjust = 0, colour = "grey50"))
                    legend.text = theme_text (size=base_size * 1.2),      
                    legend.title = theme_text (size = base_size *1.2, face = "bold"),      
                    legend.hjust = theme_text (hjust=c(0, 0.5, 1)),
                    plot.title = theme_text (size=base_size * 1.5, face="bold"),
                    #axis.text.y = theme_text (size = base_size * 1.4,hjust = 0, colour = "grey50", face = "bold"))
                    axis.text.y = theme_text (size = base_size * 1.4,hjust = 0, face = "bold")) 
                    
  }

# Function to capitalize each word beginning of a string
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
      sep="", collapse=" ")
}

heatMapPlotter <- function (table, main="", weekNotation=F, legPos="right", mode="default", xlab="", ylab="")
  {
      #Change weeks by Development and habituation notation
      if (weekNotation == T)
        {           
          table$week <- paste ("Dev Phase", table$period-1, sep = " ") 
          #table$week <- paste ("Dev Phase", table$period, sep = " ") 
 
          levels(table$week) <- c (levels(table$week), "Dev Phase")          
          #table$week  [table$week == "Dev Phase 0"] <- 'Habituation'
          angleY = 330
        }
      else
        {
          #only numbers on the y axis of the plot
          if (weekNotation == "N")
            {
#               table$week <- table$period-1 
              table$week <- table$period
              levels(table$week) <- c (levels(table$week))
              angleY = 0
            }
          else
            {
              table$week <- paste ("week", table$period, sep = "_")
              angleY = 330
            }
        }
      
      #Checking mode for setting suitable color scale
      if (mode == "pvalues")
        {           
          colorsSc = c ('black', 'black', 'black', 'yellow', 'cyan', 'black','black',  'black')
#           valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
          valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
          limitsSc= c (-0.06,0.06)
          breaksSc   = c (-0.05, -0.01, 0.01, 0.05)
          labelsSc = c (">0.05", "0.01", "0.01", ">0.05")
          legName = "p-value"          
        }
      else
        {
          colorsSc = c ('green', 'green', 'green', 'black', 'black', 'red', 'red', 'red')
          valuesSc   = c (-10,  -3, -3, 0, 0, 3, 3, 10)
          limitsSc= c (-3,3)
          breaksSc = c (-3, -2, -1, 0, 1, 2, 3)
          labelsSc = c ("<-3","-2","-1","0", "1", "2", ">3")
          legName = "Fold Change"
        }
      
      #table$week <-table$period
      table$period <- as.numeric (table$period)
      table$week <- with (table, reorder (week, period,))
          
      #Merging channel and variable
      #table$chVar <- paste (table$channel, table$variable, sep = " ")
      
      #Capitalizing channel name
      table$chVar <- paste (sapply (table$channel, simpleCap), table$variable, sep = " ")
      #Capitalizing variable for labels
      
      table$variable <-sapply (table$variable, simpleCap)
      #lo que hacemos asignar el orden como nosotros lo queremos en este caso como aparece en la tabla
      table$variable<- factor (table$variable, labels=unique (paste (sapply (table$variable, simpleCap))),ordered=T)
      #print (factor (table$variable, labels=unique (paste (sapply (table$variable, simpleCap))),ordered=T) )
      print (table$variable)      
      print (rep (0.5,length (unique (table$week))))
      (p <- ggplot (table, aes (week, chVar)) + geom_tile (aes (fill = foldChange),
            colour = "white") + #scale_y_discrete (labels = foodWaterOut(table$chVar)) +
            scale_fill_gradientn (guide = "colorbar",
                                  colours = colorsSc,
                                  values = valuesSc,
                                  limits = limitsSc,
                                  breaks   = breaksSc,
                                  labels = labelsSc,
                                  name = legName,
                                  rescaler = function(x,...) x,
#                                   oob = identity)+ opts (title = main))#with legend
                                  oob = identity) + opts (title = main, legend.position = "none"))#no legend
                                        
      base_size <- 9
      p + theme_grey (base_size = base_size) + labs (x = xlab,
                    y = ylab) + scale_x_discrete (expand = c(0, 0)) +
                    scale_y_discrete (expand = c(0, 0), labels = table$variable) + 
                    opts (axis.ticks = theme_blank(),
                          legend.position = legPos,
                          panel.border = theme_blank(),
                          panel.background = theme_blank(),
                          axis.title.x =  theme_text (size = base_size * 1.4, face = "bold"),
                          axis.title.y =  theme_text (size = base_size * 1.4, face = "bold", angle = 90),
                          axis.text.x = theme_text(size = base_size * 1.4, angle = angleY,
                          #1.2, angle = 330,                     
                          #hjust = 0, colour = "grey50", face = "bold"), #labels=c("Control", "Treat 1", "Treat 2")),
                          hjust = 0, face = "bold"),                           
                          #axis.text.y = theme_text (size = base_size * 1.2,hjust = 0, colour = "grey50"))
                          legend.text = theme_text (size = base_size * 1.2),      
                          legend.title = theme_text (size = base_size *1.2, face = "bold"),      
                          legend.hjust = theme_text (hjust=c(0, 0.5, 1)),
                          plot.title = theme_text (size=base_size * 1.5, face="bold"),
                          #axis.text.y = theme_text (size = base_size * 1.4,hjust = 0, colour = "grey50", face = "bold"))
                          axis.text.y = theme_text (size = base_size * 1.4,hjust = 0, face = "bold"))                          
  }
