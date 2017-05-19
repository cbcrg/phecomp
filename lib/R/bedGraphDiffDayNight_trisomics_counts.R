#!/usr/bin/env Rscript

#############################################################
### Jose A Espinosa. CSN/CB Group. April 2017             ###
#############################################################
### A script to read genome browser files in order to     ###
### statistically compare the night periods of the control###
### with respect to the case                              ###
### DATA FROM 20130130                                    ###
#############################################################

##Loading libraries
library (ggplot2)
library (plyr)
#install.packages("reshape")
library (reshape) #melt
library (gtools) #foldchange
library (plotrix) #std.error
library (grid) #unit function
library (gridExtra)
## In this case I treat the channels chocolate and SC separated

##Getting HOME directory
home <- Sys.getenv("HOME")

colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]

## Functions
## Functions for GB files reading
source ("/Users/jespinosa/git/phecomp/lib/R/f_readGBFiles.R")
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

#Path to folder with intervals files for each cage
# path2Tbls <- paste (home, "/2017_phecomp_marta/GB_indidividual_files", sep = "")
path2Tbls <- paste (home, "/2017_phecomp_marta/GB_individual_files_counts", sep = "")

## En lugar de hacer bedGraph hacer bedtools makewindows. 
## https://www.biostars.org/p/49163/
## y luego hacer un map count
## igual introducirlo como opcion en pergola

label_ctrl_wt <- "control_wt"
label_ctrl_wt <- "wt control"

#########################
### CONTROL DIET ONLY SC

## Wt control, only sc channel
pattern_food_sc_control_wt_1 <- "tr_[1,3,9]_dt_food_sc\\.bedGraph"
tbl_control_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_1, label=label_ctrl_wt, ws=1800)

pattern_food_sc_control_wt_2 <- "tr_[1][5]_dt_food_sc\\.bedGraph"
tbl_control_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_2, label=label_ctrl_wt, ws=1800)

pattern_food_sc_control_wt_3 <- "tr_[2][3,7,9]_dt_food_sc\\.bedGraph"
tbl_control_wt_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_3, label=label_ctrl_wt, ws=1800)

pattern_food_sc_control_wt_4 <- "tr_[3][1]_dt_food_sc\\.bedGraph"
tbl_control_wt_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_4, label=label_ctrl_wt, ws=1800)

tbl_control_wt <- rbind (tbl_control_wt_1, tbl_control_wt_2, tbl_control_wt_3, tbl_control_wt_4)
tail (tbl_control_wt)

tbl_control_wt$genotype <- "wt"
tbl_control_wt$diet <- "SC"
mean_wt_ctrl.byWeek <- with (tbl_control_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts control, only sc channel
label_ctrl_ts <- "control_ts"
label_ctrl_ts <- "ts control"

pattern_food_sc_control_ts_1 <- "tr_[6]_dt_food_sc\\.bedGraph"
tbl_control_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_1, label=label_ctrl_ts, ws=1800)

pattern_food_sc_control_ts_2 <- "tr_[1][2,4,6]_dt_food_sc\\.bedGraph"
tbl_control_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_2, label=label_ctrl_ts, ws=1800)

pattern_food_sc_control_ts_3 <- "tr_[2][0,4]_dt_food_sc\\.bedGraph"
tbl_control_ts_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_3, label=label_ctrl_ts, ws=1800)

pattern_food_sc_control_ts_4 <- "tr_[3][6]_dt_food_sc\\.bedGraph"
tbl_control_ts_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_4, label=label_ctrl_ts, ws=1800)

tbl_control_ts <- rbind (tbl_control_ts_1, tbl_control_ts_2, tbl_control_ts_3, tbl_control_ts_4)
head (tbl_control_ts)

tbl_control_ts$genotype <- "trisomic"
tbl_control_ts$diet <- "SC"
# mean_ts_ctrl.byWeek <- with (tbl_control_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

#########################
### FREE CHOICE SC + CM
## wt free choice SC channel
label_FC_sc_wt <- "FC_wt_sc"
label_FC_sc_wt <- "wt FC SC"

pattern_FC_sc_wt_1 <- "tr_[5,7]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_1, label=label_FC_sc_wt, ws=1800)

pattern_FC_sc_wt_2 <- "tr_[1][1,3,7,9]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_2, label=label_FC_sc_wt, ws=1800)

pattern_FC_sc_wt_3 <- "tr_[2][1]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_3, label=label_FC_sc_wt, ws=1800)

pattern_FC_sc_wt_4 <- "tr_[3][3,5]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_4, label=label_FC_sc_wt, ws=1800)

tbl_FC_sc_wt <- rbind (tbl_FC_sc_wt_1, tbl_FC_sc_wt_2, tbl_FC_sc_wt_3, tbl_FC_sc_wt_4)
head (tbl_FC_sc_wt)

tbl_FC_sc_wt$genotype <- "wt"
tbl_FC_sc_wt$diet <- "SC+CM"
# mean_wt_FC_sc.byWeek <- with (tbl_FC_sc_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## wt free choice CD channel
label_FC_cd_wt <- "FC_wt_cd"
label_FC_cd_wt <- "wt FC CM"

pattern_FC_cd_wt_1 <- "tr_[5,7]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_1, label=label_FC_cd_wt, ws=1800)

pattern_FC_cd_wt_2 <- "tr_[1][1,3,7,9]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_2, label=label_FC_cd_wt, ws=1800)

pattern_FC_cd_wt_3 <- "tr_[2][1]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_3, label=label_FC_cd_wt, ws=1800)

pattern_FC_cd_wt_4 <- "tr_[3][3,5]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_4, label=label_FC_cd_wt, ws=1800)

tbl_FC_cd_wt <- rbind (tbl_FC_cd_wt_1, tbl_FC_cd_wt_2, tbl_FC_cd_wt_3, tbl_FC_cd_wt_4)
head (tbl_FC_cd_wt)

tbl_FC_cd_wt$genotype <- "wt"
tbl_FC_cd_wt$diet <- "SC+CM"
# mean_wt_FC_cd.byWeek <- with (tbl_FC_cd_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts free choice SC channel
label_FC_sc_ts <- "FC_ts_sc"
label_FC_sc_ts <- "ts FC SC"

## deleting cage 4 because cd channel has very high values
# pattern_FC_sc_ts_1 <- "tr_[2,4,8]_dt_food_sc\\.bedGraph"
pattern_FC_sc_ts_1 <- "tr_[2,8]_dt_food_sc\\.bedGraph"
tbl_FC_sc_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_1, label=label_FC_sc_ts, ws=1800)

pattern_FC_sc_ts_2 <- "tr_[1][0,8]_dt_food_sc\\.bedGraph" 
tbl_FC_sc_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_2, label=label_FC_sc_ts, ws=1800)

pattern_FC_sc_ts_3 <- "tr_[2][2,6]_dt_food_sc\\.bedGraph" 
tbl_FC_sc_ts_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_3, label=label_FC_sc_ts, ws=1800)

pattern_FC_sc_ts_4 <- "tr_[3][0,2,4]_dt_food_sc\\.bedGraph" 
tbl_FC_sc_ts_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_4, label=label_FC_sc_ts, ws=1800)

tbl_FC_sc_ts <- rbind (tbl_FC_sc_ts_1, tbl_FC_sc_ts_2, tbl_FC_sc_ts_3, tbl_FC_sc_ts_4)
tbl_FC_sc_ts <- subset (tbl_FC_sc_ts, Filename!="tr_4_dt_food_sc.bedGraph")
head (tbl_FC_sc_ts)

tbl_FC_sc_ts$genotype <- "trisomic"
tbl_FC_sc_ts$diet <- "SC+CM"

# mean_ts_FC_sc.byWeek <- with (tbl_FC_sc_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts free choice choc channel
label_FC_cd_ts <- "FC_ts_cd"
label_FC_cd_ts <- "ts FC CM"

## deleting cage 4 because cd channel has very high values
# pattern_FC_cd_ts_1 <- "tr_[2,4,8]_dt_food_cd\\.bedGraph"
pattern_FC_cd_ts_1 <- "tr_[2,8]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_1, label=label_FC_cd_ts, ws=1800)

pattern_FC_cd_ts_2 <- "tr_[1][0,8]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_2, label=label_FC_cd_ts, ws=1800)

pattern_FC_cd_ts_3 <- "tr_[2][2,6]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_3, label=label_FC_cd_ts, ws=1800)

pattern_FC_cd_ts_4 <- "tr_[3][0,2,4]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_4 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_4, label=label_FC_cd_ts, ws=1800)

tbl_FC_cd_ts <- rbind (tbl_FC_cd_ts_1, tbl_FC_cd_ts_2, tbl_FC_cd_ts_3, tbl_FC_cd_ts_4)
head (tbl_FC_cd_ts_2)
tbl_FC_cd_ts$genotype <- "trisomic"
tbl_FC_cd_ts$diet <- "SC+CM"

# subset (tbl_FC_cd_ts, week==3 & value > 0.2 & phase=="day") 
## I have to delete also the sc channel of this guy 
## I deleted it above, by no including it
tbl_FC_cd_ts <- subset (tbl_FC_cd_ts, Filename!="tr_4_dt_food_cd.bedGraph")
# mean_ts_FC_cd.byWeek <- with (tbl_FC_cd_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

###########################
### FREE CHOICE SC + HF
## wt free choice SC channel
label_FC_HF_sc_wt <- "FC_HF_wt_sc"
label_FC_HF_sc_wt <- "wt FC HF SC"

pattern_FC_HF_sc_wt_1 <- "tr_[3][7,9]_dt_food_sc\\.bedGraph"
# 7,39,41,43,45,47,49,51,53]_dt_food_sc\\.bedGraph"
tbl_FC_HF_sc_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_sc_wt_1, label=label_FC_HF_sc_wt, ws=1800)

pattern_FC_HF_sc_wt_2 <- "tr_[4][1,3,5,7,9]_dt_food_sc\\.bedGraph"
tbl_FC_HF_sc_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_sc_wt_2, label=label_FC_HF_sc_wt, ws=1800)

pattern_FC_HF_sc_wt_3 <- "tr_[5][1,3]_dt_food_sc\\.bedGraph"
tbl_FC_HF_sc_wt_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_sc_wt_3, label=label_FC_HF_sc_wt, ws=1800)

tbl_FC_HF_sc_wt <- rbind (tbl_FC_HF_sc_wt_1, tbl_FC_HF_sc_wt_2, tbl_FC_HF_sc_wt_3)
head (tbl_FC_HF_sc_wt)
tail (tbl_FC_HF_sc_wt)

tbl_FC_HF_sc_wt$genotype <- "wt"
tbl_FC_HF_sc_wt$diet <- "SC+HF"
# mean_wt_FC_HF_sc.byWeek <- with (tbl_FC_HF_sc_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## wt free choice HF channel
label_FC_HF_hf_wt <- "FC_HF_wt_hf"
label_FC_HF_hf_wt <- "wt FC HF HF"

pattern_FC_HF_hf_wt_1 <- "tr_[3][7,9]_dt_food_fat\\.bedGraph"
tbl_FC_HF_hf_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_hf_wt_1, label=label_FC_HF_hf_wt, ws=1800)

pattern_FC_HF_hf_wt_2 <- "tr_[4][1,3,5,7,9]_dt_food_fat\\.bedGraph"
tbl_FC_HF_hf_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_hf_wt_2, label=label_FC_HF_hf_wt, ws=1800)

pattern_FC_HF_hf_wt_3 <- "tr_[5][1,3]_dt_food_fat\\.bedGraph"
tbl_FC_HF_hf_wt_3 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_hf_wt_3, label=label_FC_HF_hf_wt, ws=1800)

tbl_FC_HF_hf_wt <- rbind (tbl_FC_HF_hf_wt_1, tbl_FC_HF_hf_wt_2, tbl_FC_HF_hf_wt_3)
head (tbl_FC_HF_hf_wt)

tbl_FC_HF_hf_wt$genotype <- "wt"
tbl_FC_HF_hf_wt$diet <- "SC+HF"

## HF night have a peak at week 3
# tbl_FC_HF_hf_wt[tbl_FC_HF_hf_wt$week == 3 & tbl_FC_HF_hf_wt$value > 3,]
# tbl_FC_HF_hf_wt <- subset (tbl_FC_HF_hf_wt, !(grepl("tr_41_", Filename)))
## Several cages having high values

# mean_wt_FC_HF_hf.byWeek <- with (tbl_FC_HF_hf_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts free choice HF SC channel
label_FC_HF_sc_ts <- "FC_HF_ts_SC"
label_FC_HF_sc_ts <- "ts FC HF SC"

pattern_FC_HF_sc_ts_1 <- "tr_[4][0,2,4,6,8]_dt_food_sc\\.bedGraph"
tbl_FC_HF_sc_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_sc_ts_1, label=label_FC_HF_sc_ts, ws=1800)

pattern_FC_HF_sc_ts_2 <- "tr_[5][0,2,4]_dt_food_sc\\.bedGraph"
tbl_FC_HF_sc_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_sc_ts_2, label=label_FC_HF_sc_ts, ws=1800)

tbl_FC_HF_sc_ts <- rbind (tbl_FC_HF_sc_ts_1, tbl_FC_HF_sc_ts_2)
head (tbl_FC_HF_sc_ts)

tbl_FC_HF_sc_ts$genotype <- "trisomic"
tbl_FC_HF_sc_ts$diet <- "SC+HF"
# mean_ts_FC_HF_sc.byWeek <- with (tbl_FC_HF_sc_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
## week 5 ts FC HF SC day high values
##tr_40_dt_food_sc.bedGraph chr1  3000600 3002400 12.1000000 night    
##tr_40_dt_food_sc.bedGraph chr1  3022200 3024000 13.9009585 night 

## ESTE OK 
# tbl_FC_HF_sc_ts[tbl_FC_HF_sc_ts$week == 5 & tbl_FC_HF_sc_ts$value > 2,]
# tbl_FC_HF_sc_ts <- subset (tbl_FC_HF_sc_ts, !(grepl("tr_42_", Filename)))

## ts free choice HF channel
label_FC_HF_hf_ts <- "FC_HF_ts_hf"
label_FC_HF_hf_ts <- "ts FC HF HF"

pattern_FC_HF_hf_ts_1 <- "tr_[4][0,2,4,6,8]_dt_food_fat\\.bedGraph"
tbl_FC_HF_hf_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_hf_ts_1, label=label_FC_HF_hf_ts, ws=1800)

pattern_FC_HF_hf_ts_2 <- "tr_[5][0,2,4]_dt_food_fat\\.bedGraph"
tbl_FC_HF_hf_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_HF_hf_ts_2, label=label_FC_HF_hf_ts, ws=1800)

tbl_FC_HF_hf_ts <- rbind (tbl_FC_HF_hf_ts_1, tbl_FC_HF_hf_ts_2)
head (tbl_FC_HF_hf_ts)

tbl_FC_HF_hf_ts$genotype <- "trisomic"
tbl_FC_HF_hf_ts$diet <- "SC+HF"
head(tbl_FC_HF_hf_ts,48)

### the problem is in a wt animal
# tbl_FC_HF_hf_ts <- subset (tbl_FC_HF_hf_ts, !(grepl("tr_42_", Filename)))
# tbl_FC_HF_hf_ts[tbl_FC_HF_hf_ts$week == 3 & tbl_FC_HF_hf_ts$value > 1,]
### This file has very high values during week three both in day and night 
## I don't read the cage 42
# tr_42_dt_food_fat.bedGraph

## tambien podria primero juntar todo y calcular la media solo una vez
# tbl_before_mean <- rbind(tbl_FC_HF_hf_ts, tbl_FC_HF_sc_ts)
# mean_two_gr <- with (tbl_before_mean, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# mean_two_gr

# mean_ts_FC_HF_hf.byWeek <- with (tbl_FC_HF_hf_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## Join the tables 
# meanAll.byWeek <- rbind (mean_wt_ctrl.byWeek, mean_ts_ctrl.byWeek, mean_wt_FC_sc.byWeek, mean_wt_FC_cd.byWeek,
#                          mean_ts_FC_sc.byWeek, mean_ts_FC_cd.byWeek, 
#                          mean_wt_FC_HF_sc.byWeek,mean_wt_FC_HF_hf.byWeek,
#                          mean_ts_FC_HF_sc.byWeek, mean_ts_FC_HF_hf.byWeek)


tbl_all <- rbind(tbl_control_wt, tbl_control_ts, 
                 tbl_FC_sc_wt, tbl_FC_cd_wt, tbl_FC_sc_ts, tbl_FC_cd_ts, 
                 tbl_FC_HF_sc_wt, tbl_FC_HF_hf_wt, tbl_FC_HF_sc_ts, tbl_FC_HF_hf_ts)

## Delete week 8 of the rest of groups because in HF grous only seven weeks were recorded
tbl_all <- rbind (subset (tbl_all, diet != "SC+HF"), subset (tbl_all, diet == "SC+HF" & week < 8))

#####################
#####################
## Filter by z-score
## for each group
# library (dplyr)
# 
# head (tbl_all)
# z_scale <- function (x) {(x - mean(x)) / sd(x)}
# 
# scaled_data <- 
#   tbl_all %>%
#   group_by(group) %>%
#   mutate(zscore = z_scale(value))
# 
# scaled_data <- as.data.frame(scaled_data)
# 
# tail(scaled_data)
# head(scaled_data)
# tbl_all <- scaled_data
# tbl_all <- tbl_all [tbl_all$zscore < 3 ,]

#####################
#####################
## approach taking into account the overall z score
# tbl_all$zscore <- abs(scale(tbl_all$value))
# length(tbl_all [tbl_all$zscore > 3 ,1]) # 1927 values deleted
# tbl_all <- tbl_all [tbl_all$zscore < 3 ,]

meanAll.byWeek <- with (tbl_all, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# meanAnimalByWeekHF <- with (tblHF , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

meanAll.byWeek$mean <- meanAll.byWeek$value [,1]
meanAll.byWeek$std.error <- meanAll.byWeek$value [,2]
head(meanAll.byWeek)
## Plotting all
# str (meanAll.byWeek)

## Weeks should be numeric to plot lines
meanAll.byWeek$week <- as.numeric (meanAll.byWeek$week)

meanAll.byWeek$mean - meanAll.byWeek$std.error
meanAll.byWeek$groupPhase <- paste (meanAll.byWeek$group, meanAll.byWeek$phase)
meanAll.byWeek$ymax <- meanAll.byWeek$mean + meanAll.byWeek$std.error
meanAll.byWeek$ymin <- meanAll.byWeek$mean - meanAll.byWeek$std.error

# unique(meanAll.byWeek$week)

## I filter last week of the development nto complete 
# meanAll.byWeek_dev <- meanAll.byWeek [ meanAll.byWeek$week < 9, ]
meanAll.byWeek_dev <- meanAll.byWeek [ meanAll.byWeek$week < 8, ] # high-fat has not 8 weeks
pd <- position_dodge(.1)
cb_palette <- c("#999999", "#E69F00", "#56B4E9",
                "#009E73", "#F0E442", "#0072B2", 
                "#D55E00", "#CC79A7", "#000000", 
                "#00009B", "lightgreen", "darkred")
colors <- rep(cb_palette,4)

meanAll.byWeek_dev$groupPhase <- factor(meanAll.byWeek_dev$groupPhase, levels = c("wt control day", "wt control night", 
                                                                                  "wt FC SC day", "wt FC SC night",
                                                                                  "wt FC CM day", "wt FC CM night",
                                                                                  "ts control day", "ts control night",
                                                                                  "ts FC SC day", "ts FC SC night",
                                                                                  "ts FC CM day","ts FC CM night",
                                                                                  # repeat last four colors
                                                                                  "wt FC HF SC day", "wt FC HF SC night",
                                                                                  "wt FC HF HF day", "wt FC HF HF night",
                                                                                  "ts FC HF SC day", "ts FC HF SC night",
                                                                                  "ts FC HF HF day", "ts FC HF HF night"
))
meanAll.byWeek_dev$genotype <- factor(meanAll.byWeek_dev$genotype, levels=c("wt", "trisomic"))
tail(meanAll.byWeek_dev)
meanAll.byWeek_dev [meanAll.byWeek_dev$week==3 && meanAll.byWeek_dev$groupPhase == "ts FC HF HF night", ]

# gAllByWeek <- ggplot (meanAll.byWeek_dev, aes(x = week, y = mean, colour = groupPhase)) +
gAllByWeek <- ggplot (meanAll.byWeek_dev, aes(x = week, y = mean, colour = groupPhase)) + 
    scale_x_continuous (breaks=c(1:10)) + 
    labs (title = "Number of meals during\n30 min periods\n") +  
    labs (x = "\nDevelopment Weeks", y = "Number of meals/30 min\n", fill = NULL) + 
    geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
    geom_line (size=1)  + 
    geom_point () #+
#     scale_y_continuous (limits = c(0, 0.6)) 

# labs_plot <- c("ts FC CM day", "Ts FC CM night",
#                "ts FC SC day", "Ts FC SC night",
#                "wt FC CM day", "wt FC CM night",
#                "wt FC SC day", "wt FC SC night",
#                "ts control day", "ts control night", 
#                "wt control day", "wt control night")  

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
    name="",
    values = colors) +# , labels=labs_plot) + 
    theme (legend.key.height = unit (2, "line")) + #distance between lines in legend 
    theme(plot.title = element_text(hjust = 0.5))
gAllByWeek 

# ggsave (gAllByWeek, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts.png", sep=""))
# ggsave (gAllByWeek, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts.tiff", sep=""), 
#         width=12, height=7, dpi=400)

gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ .)

cb_palette <- c("#999999", "#E69F00", "#56B4E9",
                "#009E73", "#F0E442", "#0072B2")
colors <- c(rep(c("#999999", "#E69F00", "#56B4E9",
                  "#009E73", "#F0E442", "#0072B2"), 2), 
            rep(c("#56B4E9", "#009E73", "#F0E442", "#0072B2"), 2))

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
    name="",
    values = colors) + # , labels=labs_plot) + 
    theme (legend.key.height = unit (2, "line")) + #distance between lines in legend 
    theme(plot.title = element_text(hjust = 0.5))

gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet)
gAllByWeek_grid

# ggsave (gAllByWeek_grid, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype.png", sep=""))
# ggsave (gAllByWeek_grid, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype.tiff", sep=""), 
#         width=12, height=7, dpi=400)

########################################
########################################
## new version of the plot with shapes and less colors
vector_gr = c("wt control day", "wt control night", 
              "wt FC SC day", "wt FC SC night",
              "wt FC CM day", "wt FC CM night",
              "ts control day", "ts control night",
              "ts FC SC day", "ts FC SC night",
              "ts FC CM day","ts FC CM night",
              # repeat last four colors
              "wt FC HF SC day", "wt FC HF SC night",
              "wt FC HF HF day", "wt FC HF HF night",
              "ts FC HF SC day", "ts FC HF SC night",
              "ts FC HF HF day", "ts FC HF HF night")

colors <- c(rep(c("#999999", "#E69F00", "#56B4E9",
                  "#009E73", "#F0E442", "#0072B2"), 2), 
            rep(c("#56B4E9", "#009E73", "#F0E442", "#0072B2"), 2))
colors <- c(rep("#E69F00", 4),  rep("#999999", 2), 
            rep("#E69F00", 4), rep("#999999", 2), 
            rep("#E69F00", 2), rep("#0072B2",2),
            rep("#E69F00", 2), rep("#0072B2",2))

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
    name="",
    values = colors) + # , labels=labs_plot) + 
    theme (legend.key.height = unit (2, "line")) + #distance between lines in legend 
    theme(plot.title = element_text(hjust = 0.5))

# gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet, margins = TRUE)
# gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet, switch = "both")
gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet, switch = "y")

gAllByWeek_grid_simple <- gAllByWeek + 
    geom_point (aes(shape=groupPhase), fill="white",  size=4) +
    scale_shape_manual(values= rep(c(17, 15),10)) +
    facet_grid(genotype ~ diet, switch = "y") +
    theme_update(strip.text.x = element_text (size=base_size * 1.3, face="bold")) +
    theme(plot.title = element_text(hjust = 0.5), strip.text.y = element_text(angle = 270),
          panel.spacing.x = unit(4, "lines"), plot.margin = unit(c(0,4,0,0), "line"))

df_legend <- data.frame(c(0,1,2), c(2,4,8), c("SC","CM", "HF"))
colnames(df_legend) <- c("x", "y", "names")
df_legend$names <- factor(df_legend$names, levels = c("SC","CM", "HF"))

df_legend_shape <- data.frame(c(0,1), c(2,4), c("Day","Night"))
colnames(df_legend_shape) <- c("x", "y", "names_phase")

## Plot for extracting legend
gr_legend_p <- ggplot() + geom_point(data=df_legend, aes(x=x, y=y, colour = names), shape=15, size=5) +
    geom_point(data=df_legend_shape, aes(x=x, y=y, shape=names_phase), size=5) +
    scale_colour_manual (values=c("#E69F00","#999999","#0072B2")) + guides(color=guide_legend(title=NULL)) + 
    scale_shape_manual(values= c(17, 15)) +  guides(color=guide_legend(title=NULL)) +
    theme(legend.title=element_blank()) +
    theme(legend.position="bottom", legend.justification=c(1, 0)) +
    geom_blank()

## Extract legend
g_legend <- function(a.gplot){ 
    tmp <- ggplot_gtable(ggplot_build(a.gplot)) 
    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box") 
    legend <- tmp$grobs[[leg]] 
    return(legend)} 

legend_simple <- g_legend(gr_legend_p)

# png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype_counts_no_filtered.png", sep=""), width=1000, height=800 )
# png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype_counts_zscore_filt_by_group.png", sep=""), width=1000, height=800 )
# png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype_counts_overall_zscore_filt.png", sep=""), width=1000, height=800 )
png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype_counts_no_filtered_space.png", sep=""), width=1200, height=800 )

grid.newpage()
# grid.draw(legend_simple)
g <- grid.arrange(arrangeGrob(gAllByWeek_grid_simple + theme(legend.position="none"), nrow=1),
                  legend_simple, nrow=2,heights=c(10, 1))

dev.off()

########################
### Statistical analysis
# head(tbl_all, 20)
meanAnimalByWeek_ts <- with (tbl_all , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

meanAnimalByWeekHF <- with (tblHF , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# head (meanAnimalByWeekHF,20)
# head (meanAnimalByWeek_ts, 20)
# unique(tbl_all$group)

meanAnimalByWeek_ts$mean <- meanAnimalByWeek_ts$value [,1]
meanAnimalByWeek_ts$std.error <- meanAnimalByWeek_ts$value [,2]

####@@@@@
## http://stackoverflow.com/questions/5694664/repeated-measures-within-subjects-anova-in-r

meanAnimalByWeek_ts$groupAndPhase <- paste (meanAnimalByWeek_ts$group, meanAnimalByWeek_ts$phase, sep="")  
meanAnimalByWeek_ts$groupAndPhase <- as.factor (meanAnimalByWeek_ts$groupAndPhase)
meanAnimalByWeek_ts$week <- as.factor (meanAnimalByWeek_ts$week)
meanAnimalByWeek_ts$animal <- as.factor (meanAnimalByWeek_ts$animal)

aov.weekIntakes = aov (mean ~ groupAndPhase * week + Error (animal), data=meanAnimalByWeek_ts)
summary (aov.weekIntakes)

#### 
########################
########################
### tbl for statistics
### Writting data for spss
tbl_all_stats <- tbl_all
tbl_all_stats$mouse <- as.numeric (gsub("_dt_food_fat","", gsub ("_dt_food_cd","" , (gsub (".bedGraph" , "", gsub ("_dt_food_sc", "", gsub("tr_", "", tbl_all_stats$Filename)))))))

# tbl_stats <- data.frame()
# mouse <- as.numeric (gsub ("_dt_food_cd","" , (gsub (".bedGraph" , "", gsub ("_dt_food_sc", "", gsub("tr_", "", tbl_all$Filename))))))
# mouse <- as.numeric (gsub ("_dt_food_cd","" , (gsub (".bedGraph" , "", gsub ("_dt_food_sc", "", gsub("tr_", "", tbl_all$Filename))))))
# group <- tbl_all$genotype
# mean <- tbl_all$mean
# phase <- tbl_all$phase
# 
# tbl_all2stats <- tbl_all

head(tbl_all_stats)
# stats_mean <- with (tbl_all_stats, aggregate (cbind (value), list (group=group, phase=phase, week=week, genotype=genotype, diet=diet, mouse=mouse), FUN=function (x) c (mean=mean(x))))
stats_mean <- with (tbl_all_stats, aggregate (cbind (value), list (group=group, phase=phase, week=week, mouse=mouse), FUN=function (x) c (mean=mean(x))))
stats_mean <- stats_mean [ stats_mean$week < 8, ]

library("reshape2")
library(xlsx)

# stats_mean_export <- dcast (stats_mean, mouse + group + diet ~ phase + week, value.var="value")
stats_mean_export <- dcast (stats_mean, mouse + group ~ phase + week, value.var="value")
head(stats_mean_export)
write.xlsx(stats_mean_export, "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export_trisomics.xlsx", row.names =FALSE) 

library(foreign)

## http://stackoverflow.com/questions/25420570/how-to-export-a-dataset-to-spss
write.foreign(as.data.frame(stats_mean_export), "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export_trisomics.txt", "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export_trisomics.sps",   package="SPSS") 

## TO PERFORM THE ANOVA ON R USE BEDGRAPHDIFFDAYNIGHT_DYRK_COUNTS AS TEMPLATE
stats_mean$phase_week <- paste(stats_mean$phase, stats_mean$week, sep="_")
head(stats_mean)

################
################
# POST-hoc test
# for group
head (stats_mean)
stats_mean$group_phase <- paste(stats_mean$group, stats_mean$phase, sep="&")
unique(stats_mean$group_phase)

with (stats_mean, pairwise.t.test (value, group_phase,  p.adjust.method="bonf"))
# with (meanAnimalByWeekAnova, pairwise.t.test (mean, week ,  p.adjust.method="bonf"))

postHoc_group_phase <- as.data.frame(pairwise.t.test (stats_mean$value, stats_mean$group_phase,  p.adjust.method="bonf")$p.value)

write.xlsx(postHoc_group_phase, 
           "/Users/jespinosa/2017_phecomp_marta/results/anova_group_phase/posthoc_bonferroni_sign_ONLY_trisomics.xlsx", 
           row.names =TRUE) 

## Check bonferroni
with (stats_mean, aggregate (cbind (value), list (group_phase=group_phase), FUN=function (x) c (mean=mean(x))))

