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

## Wt control, only sc channel
pattern_food_sc_control_wt_1 <- "tr_[1,3,9]_dt_food_sc\\.bedGraph"
tbl_control_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_1, label=label_ctrl_wt, ws=1800)
pattern_food_sc_control_wt_2 <- "tr_[15,23,27,29,31]_dt_food_sc\\.bedGraph"
tbl_control_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_wt_2, label=label_ctrl_wt, ws=1800)
tbl_control_wt <- rbind (tbl_control_wt_1, tbl_control_wt_2)
head (tbl_control_wt)

tbl_control_wt$genotype <- "wt"
tbl_control_wt$diet <- "SC"
mean_wt_ctrl.byWeek <- with (tbl_control_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts control, only sc channel
label_ctrl_ts <- "control_ts"
label_ctrl_ts <- "ts control"

pattern_food_sc_control_ts_1 <- "tr_[6]_dt_food_sc\\.bedGraph"
tbl_control_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_1, label=label_ctrl_ts, ws=1800)
pattern_food_sc_control_ts_2 <- "tr_[12,14,16,20,24,36]_dt_food_sc\\.bedGraph"
tbl_control_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_food_sc_control_ts_2, label=label_ctrl_ts, ws=1800)
tbl_control_ts <- rbind (tbl_control_ts_1, tbl_control_ts_2)
head (tbl_control_ts)

tbl_control_ts$genotype <- "trisomic"
tbl_control_ts$diet <- "SC"
mean_ts_ctrl.byWeek <- with (tbl_control_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## wt free choice SC channel
label_FC_sc_wt <- "FC_wt_sc"
label_FC_sc_wt <- "wt FC SC"

pattern_FC_sc_wt_1 <- "tr_[5,7]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_1, label=label_FC_sc_wt, ws=1800)
pattern_FC_sc_wt_2 <- "tr_[11,13,17,19,21,33,35]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_wt_2, label=label_FC_sc_wt, ws=1800)
tbl_FC_sc_wt <- rbind (tbl_FC_sc_wt_1, tbl_FC_sc_wt_2)
head (tbl_FC_sc_wt)

tbl_FC_sc_wt$genotype <- "wt"
tbl_FC_sc_wt$diet <- "SC+CM"
mean_wt_FC_sc.byWeek <- with (tbl_FC_sc_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## wt free choice CD channel
label_FC_cd_wt <- "FC_wt_cd"
label_FC_cd_wt <- "wt FC CD"

pattern_FC_cd_wt_1 <- "tr_[5,7]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_1, label=label_FC_cd_wt, ws=1800)
pattern_FC_cd_wt_2 <- "tr_[11,13,17,19,21,33,35]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_wt_2, label=label_FC_cd_wt, ws=1800)
tbl_FC_cd_wt <- rbind (tbl_FC_cd_wt_1, tbl_FC_cd_wt_2)
head (tbl_FC_cd_wt)

tbl_FC_cd_wt$genotype <- "wt"
tbl_FC_cd_wt$diet <- "SC+CM"
mean_wt_FC_cd.byWeek <- with (tbl_FC_cd_wt, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts free choice SC channel
label_FC_sc_ts <- "FC_ts_sc"
label_FC_sc_ts <- "ts FC SC"

pattern_FC_sc_ts_1 <- "tr_[2,4,8]_dt_food_sc\\.bedGraph"
tbl_FC_sc_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_1, label=label_FC_sc_ts, ws=1800)
pattern_FC_sc_ts_2 <- "tr_[10,18,22,26,30,32,34]_dt_food_sc\\.bedGraph"
tbl_FC_sc_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_ts_2, label=label_FC_sc_ts, ws=1800)
tbl_FC_sc_ts <- rbind (tbl_FC_sc_ts_1, tbl_FC_sc_ts_2)
tbl_FC_sc_ts <- subset (tbl_FC_sc_ts, Filename!="tr_4_dt_food_sc.bedGraph")
head (tbl_FC_sc_ts)
tbl_FC_sc_ts$genotype <- "trisomic"
tbl_FC_sc_ts$diet <- "SC+CM"
mean_ts_FC_sc.byWeek <- with (tbl_FC_sc_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## ts free choice choc channel
label_FC_cd_ts <- "FC_ts_cd"
label_FC_cd_ts <- "ts FC CD"

pattern_FC_cd_ts_1 <- "tr_[2,4,8]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_1 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_1, label=label_FC_cd_ts, ws=1800)
pattern_FC_cd_ts_2 <- "tr_[10,18,22,26,30,32,34]_dt_food_cd\\.bedGraph"
tbl_FC_cd_ts_2 <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_ts_2, label=label_FC_cd_ts, ws=1800)
tbl_FC_cd_ts <- rbind (tbl_FC_cd_ts_1, tbl_FC_cd_ts_2)
head (tbl_FC_cd_ts)
tbl_FC_cd_ts$genotype <- "trisomic"
tbl_FC_cd_ts$diet <- "SC+CM"

# subset (tbl_FC_cd_ts, week==3 & value > 0.2 & phase=="day") 
tbl_FC_cd_ts <- subset (tbl_FC_cd_ts, Filename!="tr_4_dt_food_cd.bedGraph")
mean_ts_FC_cd.byWeek <- with (tbl_FC_cd_ts, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# Join the three tables 
meanAll.byWeek <- rbind (mean_wt_ctrl.byWeek, mean_ts_ctrl.byWeek, mean_wt_FC_sc.byWeek, mean_wt_FC_cd.byWeek,
                         mean_ts_FC_sc.byWeek, mean_ts_FC_cd.byWeek)

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
colors <- cb_palette

meanAll.byWeek_dev$groupPhase <- factor(meanAll.byWeek_dev$groupPhase, levels = c("wt control day", "wt control night", 
                                                                                  "wt FC SC day", "wt FC SC night",
                                                                                  "wt FC CD day", "wt FC CD night",
                                                                                  "ts control day", "ts control night",
                                                                                  "ts FC SC day", "ts FC SC night",
                                                                                  "ts FC CD day","ts FC CD night"))
meanAll.byWeek_dev$genotype <- factor(meanAll.byWeek_dev$genotype, levels=c("wt", "trisomic"))

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
colors <- rep(c("#999999", "#E69F00", "#56B4E9",
                "#009E73", "#F0E442", "#0072B2"), 2) 

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
    name="",
    values = colors) + # , labels=labs_plot) + 
    theme (legend.key.height = unit (2, "line")) + #distance between lines in legend 
    theme(plot.title = element_text(hjust = 0.5))

gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet)
gAllByWeek_grid

# ggsave (gAllByWeek_grid, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype.png", sep=""))
ggsave (gAllByWeek_grid, file=paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_ts_by_genotype.tiff", sep=""), 
        width=12, height=7, dpi=400)

