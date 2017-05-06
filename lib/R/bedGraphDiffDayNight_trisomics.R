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

## In this case I treat the channels chocolate and SC separated

##Getting HOME directory
home <- Sys.getenv("HOME")

colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]

## Functions
## Functions for GB files reading
source ("/Users/jespinosa/git/phecomp/lib/R/f_readGBFiles.R")
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

#Path to folder with intervals files for each cage
path2Tbls <- paste (home, "/2017_phecomp_marta/GB_indidividual_files", sep = "")
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

tbl_all <- rbind(tbl_control_wt, tbl_control_ts, tbl_FC_sc_wt, tbl_FC_cd_wt, tbl_FC_sc_ts, tbl_FC_cd_ts, tbl_FC_HF_sc_wt,
                 tbl_FC_HF_hf_wt, tbl_FC_HF_sc_ts, tbl_FC_HF_hf_ts)

meanAll.byWeek <- with (tbl_all, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))


meanAll.byWeek$mean <- meanAll.byWeek$value [,1]
meanAll.byWeek$std.error <- meanAll.byWeek$value [,2]

## Plotting all
str (meanAll.byWeek)
# Weeks should be numeric to plot lines
meanAll.byWeek$week <- as.numeric (meanAll.byWeek$week)

meanAll.byWeek$mean - meanAll.byWeek$std.error
meanAll.byWeek$groupPhase <- paste (meanAll.byWeek$group, meanAll.byWeek$phase)
meanAll.byWeek$ymax <- meanAll.byWeek$mean + meanAll.byWeek$std.error
meanAll.byWeek$ymin <- meanAll.byWeek$mean - meanAll.byWeek$std.error

unique(meanAll.byWeek$week)
# I filter last week of the development nto complete 
meanAll.byWeek_dev <- meanAll.byWeek [ meanAll.byWeek$week < 9, ]
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
    labs (title = "Average intake during\n30 min periods\n") +  
    labs (x = "Development Weeks", y = "g/30 min\n", fill = NULL) + 
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

