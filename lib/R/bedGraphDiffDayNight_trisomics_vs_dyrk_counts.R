#!/usr/bin/env Rscript

#############################################################
### Jose A Espinosa. CB Group. April 2017                 ###
#############################################################
### A script to read genome browser files in order to     ###
### statistically compare the night periods of the control###
### with respect to the case                              ###
### DATA FROM dyrk mice                                   ###
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
path2Tbls <- paste (home, "/2017_phecomp_marta/GB_individual_files_counts", sep = "")

#########################
### FREE CHOICE SC + CM
## wt dyrk free choice SC channel
label_FC_sc_wt_dyrk <- "FC_wt_dyrk_sc"
label_FC_sc_wt_dyrk <- "wt_dyrk FC SC"

pattern_FC_sc_wt_dyrk_1 <- "tr_[6][2,3,6,8]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_dyrk_1 <- readGBTbl (path2Tbl=path2Tbls,pattern_FC_sc_wt_dyrk_1, label=label_FC_sc_wt_dyrk, ws=1800)

pattern_FC_sc_wt_dyrk_2 <- "tr_[7][0]_dt_food_sc\\.bedGraph"
tbl_FC_sc_wt_dyrk_2 <- readGBTbl (path2Tbl=path2Tbls,pattern_FC_sc_wt_dyrk_1, label=label_FC_sc_wt_dyrk, ws=1800)

tbl_FC_sc_wt_dyrk <- rbind (tbl_FC_sc_wt_dyrk_1, tbl_FC_sc_wt_dyrk_2)

head (tbl_FC_sc_wt_dyrk)

tbl_FC_sc_wt_dyrk$genotype <- "wt_dyrk"
tbl_FC_sc_wt_dyrk$diet <- "SC+CM"

## wt dyrk free choice CD channel
label_FC_cd_wt_dyrk <- "FC_wt_dyrk_cd"
label_FC_cd_wt_dyrk <- "wt_dyrk FC CM"

pattern_FC_cd_wt_dyrk_1 <- "tr_[6][2,3,6,8]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_dyrk_1 <- readGBTbl (path2Tbl=path2Tbls,pattern_FC_cd_wt_dyrk_1, label=label_FC_cd_wt_dyrk, ws=1800)

pattern_FC_cd_wt_dyrk_2 <- "tr_[7][0]_dt_food_cd\\.bedGraph"
tbl_FC_cd_wt_dyrk_2 <- readGBTbl (path2Tbl=path2Tbls,pattern_FC_cd_wt_dyrk_1, label=label_FC_cd_wt_dyrk, ws=1800)

tbl_FC_cd_wt_dyrk <- rbind (tbl_FC_cd_wt_dyrk_1, tbl_FC_cd_wt_dyrk_2)

head (tbl_FC_cd_wt_dyrk)

tbl_FC_cd_wt_dyrk$genotype <- "wt_dyrk"
tbl_FC_cd_wt_dyrk$diet <- "SC+CM"

## dyrk free choice SC channel
label_FC_sc_dyrk <- "FC_dyrk_sc"
label_FC_sc_dyrk <- "dyrk FC SC"

pattern_FC_sc_dyrk <- "tr_[6][1,5,7,9]_dt_food_sc\\.bedGraph"
tbl_FC_sc_dyrk <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_sc_dyrk, label=label_FC_sc_dyrk, ws=1800)

head (tbl_FC_sc_dyrk)

tbl_FC_sc_dyrk$genotype <- "dyrk"
tbl_FC_sc_dyrk$diet <- "SC+CM"

## dyrk free choice choc channel
label_FC_cd_dyrk <- "FC_dyrk_cd"
label_FC_cd_dyrk <- "dyrk FC CM"

pattern_FC_cd_dyrk <- "tr_[6][1,5,7,9]_dt_food_cd\\.bedGraph"
tbl_FC_cd_dyrk <- readGBTbl (path2Tbl=path2Tbls, pattern_FC_cd_dyrk, label=label_FC_cd_dyrk, ws=1800)

tbl_FC_cd_dyrk$genotype <- "dyrk"
tbl_FC_cd_dyrk$diet <- "SC+CM"

tbl_all <- rbind(tbl_FC_sc_wt_dyrk, tbl_FC_cd_wt_dyrk, tbl_FC_sc_dyrk, tbl_FC_cd_dyrk)

## Filter by z-score
# tbl_all$z <- ave(tbl_all$value, tbl_all$group, FUN=scale)
## scale --> returns z score
# tbl_all_value_byZscore <- tbl_all %>%
#     group_by(group) %>%
#     mutate(
# #         z = scale(value)        
#           value_byZscore = ifelse(abs(scale(value)) > 3, mean(value), value) 
#     )
# 
# length(tbl_all[,1])
# 
# tbl_all$value_byZscore <- as.vector(tbl_all_value_byZscore$value_byZscore)
# 
# length(tbl_all [tbl_all$value_byZscore != tbl_all$value, 1]) # 3195 deleted values
# 
# ## Delete the values bigger than 6 zscores is equal to substitute by the mean of the rest of the values
# tbl_all <- tbl_all [tbl_all$value_byZscore == tbl_all$value,]
# 
# 
# # impute.mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))
# 
# # tbl_all %>%
# #     group_by(group) %>%
# #     mutate(
# #         value = impute.mean(value),         
# #     )

## approach taking into account the overall z score
# tbl_all$zscore <- abs(scale(tbl_all$value))
# length(tbl_all [tbl_all$zscore > 3 ,1]) # 1927 values deleted
# tbl_all <- tbl_all [tbl_all$zscore < 3 ,]


######################
######################
## Join Free choice trisomic with dyrk
## trisomics should be read from its own script
tbl_all <- rbind(tbl_FC_sc_wt, tbl_FC_cd_wt, tbl_FC_sc_ts, tbl_FC_cd_ts, 
                 tbl_FC_sc_wt_dyrk, tbl_FC_cd_wt_dyrk, tbl_FC_sc_dyrk, tbl_FC_cd_dyrk)

###############################
## Zscore filtering if enable
# tbl_all$zscore <- abs(scale(tbl_all$value))
# length(tbl_all [tbl_all$zscore > 3 ,1]) # 1927 values deleted
# tbl_all <- tbl_all [tbl_all$zscore < 3 ,]

# tbl_all$zscore <- abs(scale(tbl_all$value))
# length(tbl_all [tbl_all$zscore > 3, 1]) # 5940 values deleted
# tbl_all <- tbl_all [tbl_all$zscore <= 3 ,]

meanAll.byWeek <- with (tbl_all, aggregate (cbind (value), list (phase=phase, group=group, week=week, genotype=genotype, diet=diet), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# meanAnimalByWeekHF <- with (tblHF , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

meanAll.byWeek$mean <- meanAll.byWeek$value [,1]
meanAll.byWeek$std.error <- meanAll.byWeek$value [,2]

## Plotting all
# str (meanAll.byWeek)
# Weeks should be numeric to plot lines
meanAll.byWeek$week <- as.numeric (meanAll.byWeek$week)
meanAll.byWeek$groupPhase <- paste (meanAll.byWeek$group, meanAll.byWeek$phase)
meanAll.byWeek$ymax <- meanAll.byWeek$mean + meanAll.byWeek$std.error
meanAll.byWeek$ymin <- meanAll.byWeek$mean - meanAll.byWeek$std.error

meanAll.byWeek_dev <- meanAll.byWeek [ meanAll.byWeek$week < 9, ]

#########
pd <- position_dodge(.1)

cb_palette <- c(rep("#E69F00", 2),  rep("#999999", 2), 
                rep("#E69F00", 2), rep("#999999", 2), 
                rep("#E69F00", 2), rep("#999999", 2),
                rep("#E69F00", 2), rep("#999999", 2),
                rep("#E69F00", 2), rep("#999999", 2),
                rep("#E69F00", 2), rep("#999999", 2))

colors <- rep(cb_palette,4)
# unique(meanAll.byWeek_dev$groupPhase)
meanAll.byWeek_dev$groupPhase <- factor(meanAll.byWeek_dev$groupPhase, levels = c("wt FC SC day", "wt FC SC night",
                                                                                  "wt FC CM day", "wt FC CM night",                                                                                  
                                                                                  "ts FC SC day", "ts FC SC night",
                                                                                  "ts FC CM day","ts FC CM night",
                                                                                  "wt_dyrk FC SC day", "wt_dyrk FC SC night",
                                                                                  "wt_dyrk FC CM day", "wt_dyrk FC CM night",
                                                                                  "dyrk FC SC day", "dyrk FC SC night",
                                                                                  "dyrk FC CM day", "dyrk FC CM night"
))

meanAll.byWeek_dev$genotype <- factor(meanAll.byWeek_dev$genotype, levels=c("wt", "trisomic", "wt_dyrk", "dyrk"))
tail(meanAll.byWeek_dev)

# gAllByWeek <- ggplot (meanAll.byWeek_dev, aes(x = week, y = mean, colour = groupPhase)) +
gAllByWeek <- ggplot (meanAll.byWeek_dev, aes(x = week, y = mean, colour = groupPhase)) + 
  scale_x_continuous (breaks=c(1:10)) + 
  labs (title = "Number of meals during\n30 min periods\n") +  
  labs (x = "\nDevelopment Weeks", y = "Number of meals/30 min\n", fill = NULL) + 
  geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
  geom_line (size=1)  + 
  geom_point () #+

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
  name="",
  values = colors) + # , labels=labs_plot) + 
  theme (legend.key.height = unit (2, "line")) + #distance between lines in legend 
  theme(plot.title = element_text(hjust = 0.5))

# gAllByWeek_grid <- gAllByWeek + facet_grid(genotype ~ diet)
gAllByWeek_grid <- gAllByWeek + facet_grid(diet ~ genotype)

gAllByWeek_grid_simple <- gAllByWeek + 
  geom_point (aes(shape=groupPhase), fill="white",  size=4) +
  scale_shape_manual(values= rep(c(17, 15),10)) +
  #     facet_grid(genotype ~ diet) + ylim(c(0,1))
  facet_grid(diet ~ genotype) + ylim(c(0, 1)) +
  theme_update(strip.text.x = element_text (size=base_size * 1.3, face="bold")) +
  theme(plot.title = element_text(hjust = 0.5))

df_legend <- data.frame(c(0,1), c(2,4), c("SC","CM"))
colnames(df_legend) <- c("x", "y", "names")
df_legend$names <- factor(df_legend$names, levels = c("SC","CM"))

df_legend_shape <- data.frame(c(0,1), c(2,4), c("Day","Night"))
colnames(df_legend_shape) <- c("x", "y", "names_phase")

## Plot for extracting legend
gr_legend_p <- ggplot() + geom_point(data=df_legend, aes(x=x, y=y, colour = names), shape=15, size=5) +
  geom_point(data=df_legend_shape, aes(x=x, y=y, shape=names_phase), size=5) +
  scale_colour_manual (values=c("#E69F00","#999999","#0072B2")) + guides(color=guide_legend(title=NULL)) + 
  scale_shape_manual(values= c(17, 15)) +  guides(color=guide_legend(title=NULL)) +
  theme(legend.title=element_blank()) +
  theme(legend.position="bottom", legend.justification=c(1, 0)) +
  geom_blank() + guides(colour = guide_legend(order = 1), 
                        shape = guide_legend(order = 2))

## Extract legend
g_legend <- function(a.gplot){ 
  tmp <- ggplot_gtable(ggplot_build(a.gplot)) 
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box") 
  legend <- tmp$grobs[[leg]] 
  return(legend)} 

legend_simple <- g_legend(gr_legend_p)

png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_trisomics_and_dyrk_by_genotype_simple_counts_no_filtered.png", sep=""), width=1000, height=400 )
# png(paste(home, "/2017_phecomp_marta/figures/", "circadian_day_night_trisomics_and_dyrk_by_genotype_simple_counts_zscore.png", sep=""), width=1000, height=400 )

grid.newpage()
# grid.draw(legend_simple)
g <- grid.arrange(arrangeGrob(gAllByWeek_grid_simple + theme(legend.position="none"), nrow=1),
                  legend_simple, nrow=2,heights=c(10, 1))

dev.off()



########################
########################
### tbl for statistics
tbl_all_stats <- rbind(tbl_FC_sc_wt, tbl_FC_cd_wt, tbl_FC_sc_ts, tbl_FC_cd_ts, 
                       tbl_FC_sc_wt_dyrk, tbl_FC_cd_wt_dyrk, tbl_FC_sc_dyrk, tbl_FC_cd_dyrk)

tbl_all_stats$mouse <- as.numeric (gsub ("_dt_food_cd","" , (gsub (".bedGraph" , "", gsub ("_dt_food_sc", "", gsub("tr_", "", tbl_all_stats$Filename))))))

head (meanAll.byWeek_dev)
head (tbl_all_stats)

# stats_mean <- with (tbl_all_stats, aggregate (cbind (value), list (group=group, phase=phase, week=week, genotype=genotype, diet=diet, mouse=mouse), FUN=function (x) c (mean=mean(x))))
stats_mean <- with (tbl_all_stats, aggregate (cbind (value), list (group=group, phase=phase, week=week, mouse=mouse), FUN=function (x) c (mean=mean(x))))
stats_mean <- stats_mean [ stats_mean$week < 9, ]
head (stats_mean)
unique (stats_mean$group)
# data.frame (mouse, group, phase, mean)
library("reshape2")
library(xlsx)

# stats_mean_export <- dcast (stats_mean, mouse + group + diet ~ phase + week, value.var="value")
stats_mean_export <- dcast (stats_mean, mouse + group ~ phase + week, value.var="value")
head(stats_mean_export)
# write.xlsx(stats_mean_export, "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export.xlsx", row.names =FALSE) 

library(foreign)

## http://stackoverflow.com/questions/25420570/how-to-export-a-dataset-to-spss
# write.foreign(as.data.frame(stats_mean_export), "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export_FC_ts_vs_dyrk.txt", "/Users/jespinosa/sharedWin/2017_trisomics_spps_analysis/stats_mean_export_FC_ts_vs_dyrk.sps",   package="SPSS") 

stats_mean$phase_week <- paste(stats_mean$phase, stats_mean$week, sep="_")
head(stats_mean)

# The id of the free choice mice, should be considered as different animals, I treat each diet group as a different group  
stats_mean [stats_mean$group == "dyrk FC SC",]$mouse <- stats_mean [stats_mean$group == "dyrk FC SC",]$mouse + 100
stats_mean [stats_mean$group == "wt_dyrk FC SC",]$mouse <- stats_mean [stats_mean$group == "wt_dyrk FC SC",]$mouse + 100
stats_mean [stats_mean$group =="ts FC SC",]$mouse <- stats_mean [stats_mean$group == "ts FC SC",]$mouse + 100
stats_mean [stats_mean$group =="wt FC SC",]$mouse <- stats_mean [stats_mean$group == "wt FC SC",]$mouse + 100

stats_mean$mouse <- as.factor(stats_mean$mouse)
stats_mean$group <- as.factor(stats_mean$group)
stats_mean$week <- as.factor(stats_mean$week)
stats_mean$phase <- as.factor(stats_mean$phase)
stats_mean$phase_week <- as.factor(stats_mean$phase_week)

aov.weekIntakes = aov (value ~ group * phase * week + Error (mouse/ (phase * week)), data=stats_mean)
aov.weekIntakes = aov (value ~ group * phase_week + Error (mouse), data=stats_mean)
summary (aov.weekIntakes)

# este sale bien (es decir sale como en el spss)
aov.weekIntakes = aov (value ~ group * phase * week + Error (mouse/ (phase * week)), data=stats_mean)
summary (aov.weekIntakes)

install.packages("afex")
library("afex")

#ANOVA
## https://stats.stackexchange.com/questions/82387/how-to-specify-mixed-anova-with-multiple-repeated-measures-and-covariate-in-r
## este tb da lo mismos que el spss
aov_ez("mouse", "value", stats_mean, within=c("phase","week"), 
       between= c("group"))

# POST-hoc test
# for group
head (stats_mean)
stats_mean$group_phase <- paste(stats_mean$group, stats_mean$phase, sep="&")
unique(stats_mean$group_phase)

with (stats_mean, pairwise.t.test (value, group_phase,  p.adjust.method="bonf"))
with (meanAnimalByWeekAnova, pairwise.t.test (mean, week ,  p.adjust.method="bonf"))

with (stats_mean, pairwise.t.test (value, group_phase,  p.adjust.method="bonf"))
postHoc_group_phase <- as.data.frame(pairwise.t.test (stats_mean$value, stats_mean$group_phase,  p.adjust.method="bonf")$p.value)


write.xlsx(postHoc_group_phase, 
           "/Users/jespinosa/2017_phecomp_marta/results/anova_group_phase/posthoc_bonferroni_sign_trisomics_vs_dyrk1a.xlsx", 
           row.names =TRUE) 

## Check bonferroni
with (stats_mean, aggregate (cbind (value), list (group_phase=group_phase), FUN=function (x) c (mean=mean(x))))

