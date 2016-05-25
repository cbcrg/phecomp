#!/usr/bin/env Rscript

#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Feb 2016                         ###
#############################################################################
### PCA reinstatement experiment from Rafael's lab                        ###
### Phases of the experiment labeled following discussion on 11th Feb     ### 
### meting                                                                ###
###                                                                       ###
#############################################################################

library (plyr)
library(FactoMineR)
library(ggplot2)
library(Hmisc) # arrow function
library("cowplot")

##Getting HOME directory 
home <- Sys.getenv("HOME")

## Dumping figures folder
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session_20160518/"
dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session_20160525/"

# Loading functions:
source (paste (home, "/git/phecomp/lib/R/plot_param_public_reinst.R", sep=""))

# Parameter to set plot qualities
dpi_q <- 50
img_format = ".tiff"

data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_06_04_16.csv", sep=""), dec=",", sep=";")
reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/annot_descriptors_18_05_16.csv", sep=""), 
                               dec=",", sep=";", stringsAsFactors=FALSE)

color_v <- c("orange", "red", "lightblue", "blue")

####
## All columns but mouse id and group
# data_reinst_filt <- subset (data_reinst, select=-c(1,2))
## Mara proposed to separate the data by the different experimental phases
data_reinst_filt <- subset (data_reinst, select=-c(1,2))
tag_file <- "all_var"
# Color for all variables, I want to mantain always the same colors for the variables
# The palette with grey:
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# Adapted
cb_palette_adapt <- c("#999999", "#CC79A7", "#009E73", "#E69F00", "#0072B2", "#D55E00")


# deprivation
# dep <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", "Acquisition_day")
dep <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", "Acquisition_day", "Learning_Inactive")
# tag_file = "_acq_operant_cond"
# cb_palette_adapt <- c("#999999", "#009E73", "#E69F00", "#0072B2", "#D55E00", "#CC79A7")
# filter_v <- dep

# ad_libitum
ad_lib <- c("Primary_Reinf", "Habituation_Primary_Reinf", "Prim_R_discrim", "Impulsivity_adlib", "Imp_comp_adlib", "Compulsivity_adlib", "Prim_R_Inactive")
tag_file = "_maint_operant_cond"
cb_palette_adapt <- c("#999999", "#009E73", "#0072B2", "#E69F00", "#D55E00", "#CC79A7")
filter_v <- ad_lib

# progressive ratio
# PR <- c("PR2_break_point")
# tag_file <- "_progressive_ratio"
# filter_v <- PR

# Extinction operant conditioning
ext <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day", "Ext_Inflex_Inactive")
tag_file <- "_extinction"
cb_palette_adapt <- c("#CC79A7", "#009E73", "#E69F00", "#0072B2", "#D55E00","#999999")
filter_v <- ext

# relapse
relapse <- c("Relapse_Fold_Change", "Relapse_Inflex", "Relapse_Inactive_Inflex")
tag_file <- "_cue_reinst"
cb_palette_adapt <- c("#CC79A7","#D55E00", "#009E73", "#E69F00", "#0072B2", "#999999")
filter_v <- relapse

# deprivation + ad libitum
dep_ad_lib <- c(dep, ad_lib)
tag_file = "_whole_operant_cond"
cb_palette_adapt <- c("#999999", "#009E73", "#0072B2","#E69F00", "#0072B2", "#D55E00", "#CC79A7")
filter_v <- dep_ad_lib

# Filtering by session
data_reinst_filt <- subset (data_reinst, select=c(filter_v))

data_reinst_means <- subset(data_reinst, select = c("subject"))

# HF_lab <- "High fat"
# choc_lab <- "Choc"
# ctrl_HF_lab <- "Ctrl high fat" 
# ctrl_choc_lab <- "Ctrl choc"

HF_lab <- "HF diet"
choc_lab <- "CM diet"
ctrl_HF_lab <- "Ctrl HF" 
ctrl_choc_lab <- "Ctrl CM"

data_reinst_means$group_lab  <- gsub ("F1", HF_lab, data_reinst$Group)
data_reinst_means$group_lab  <- gsub ("SC", ctrl_choc_lab, data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("Cafeteria diet", choc_lab, data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("C1", ctrl_HF_lab, data_reinst_means$group_lab)

# cbind (data_reinst_means, ext_by_annotation)
# merging the annotation tbl and the data in order to change the annotation used to show the variables

res = PCA(data_reinst_filt, scale.unit=TRUE, graph=FALSE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])
var_PC3 <- round (res$eig [3,2])

# Coordinates are store here
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id <- data_reinst_means$subject
pca2plot$group <- as.factor(data_reinst_means$group_lab)
pca2plot$group <- factor(pca2plot$group, levels=c(ctrl_choc_lab, choc_lab, ctrl_HF_lab, HF_lab), 
                         labels=c(ctrl_choc_lab, choc_lab, ctrl_HF_lab, HF_lab))
color_v

x_lim <- ceiling(min(pca2plot$Dim.1))
x_max_1 <-max(pca2plot$Dim.1)

# Font sizes
# size_text_circle <- 6.5
size_text_circle <- 5.5

title_PCA_individuals <- "\nMice PCA by annotated variables\n" #"Distribution of mice by sessions PCA\n"
title_var_loadings =  "\nVariables factor map\n" #"PCA of the variables\n"\ #"Sessions loadings"

#############
# PC1 PC2
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc2  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
#   geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  # the limits are mixed to get all pca plots of the same size
  scale_x_continuous (limits=c(floor(min(pca2plot$Dim.1)), ceiling(max(pca2plot$Dim.1))), breaks=floor(min(pca2plot$Dim.1)):ceiling(max(pca2plot$Dim.1))) + 
  scale_y_continuous (limits=c(floor(min(pca2plot$Dim.3)), ceiling(max(pca2plot$Dim.2))), breaks=floor(min(pca2plot$Dim.3)):ceiling(max(pca2plot$Dim.2))) +
  #   labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
  #        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc2

# keeping aspect ratio
pca_reinstatement.pc1.pc2_aspect_ratio <- pca_reinstatement.pc1.pc2 + coord_fixed() + 
#   theme(plot.title = element_text(size=size_titles)) + 
#   theme(axis.title.x = element_text(size = size_axis)) +
#   theme(axis.title.y = element_text(size = size_axis)) +
  guides(color=guide_legend(guide_legend(title = ""))) +
  theme (legend.key = element_blank(), legend.title = element_blank())

pca_reinstatement.pc1.pc2_aspect_ratio_title <- pca_reinstatement.pc1.pc2_aspect_ratio + labs (title = title_PCA_individuals)

# ggsave (pca_reinstatement.pc1.pc2_aspect_ratio_title, file=paste(home, dir_plots, 
#                                                     "PCA_pc1_pc2_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC1 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc3  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
#   geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  #   scale_x_continuous (limits=c(-4, 6.1), breaks=-4:6) +
  # the limits are mixed to get all pca plots of the same size
  scale_x_continuous (limits=c(floor(min(pca2plot$Dim.1)), ceiling(max(pca2plot$Dim.1))), breaks=floor(min(pca2plot$Dim.1)):ceiling(max(pca2plot$Dim.1))) + 
  scale_y_continuous (limits=c(floor(min(pca2plot$Dim.3)), ceiling(max(pca2plot$Dim.2))), breaks=floor(min(pca2plot$Dim.3)):ceiling(max(pca2plot$Dim.2))) +  
  #   labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
  #        y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc3

# keeping aspect ratio
pca_reinstatement.pc1.pc3_aspect_ratio <- pca_reinstatement.pc1.pc3 + coord_fixed() +
  guides(color=guide_legend(guide_legend(title = ""))) +
  theme (legend.key = element_blank(), legend.title = element_blank())
#   theme(plot.title = element_text(size=size_titles)) + 
#   theme(axis.title.x = element_text(size = size_axis)) +
#   theme(axis.title.y = element_text(size = size_axis)) +
#   guides(color=guide_legend(guide_legend(title = "Group"))) 
#+
#   theme (legend.text=element_text(size=size_leg_keys), legend.key = element_blank(), legend.title = element_blank(),
#          legend.title=element_text(size=size_leg_title))  

pca_reinstatement.pc1.pc3_aspect_ratio
pca_reinstatement.pc1.pc3_aspect_ratio_title <- pca_reinstatement.pc1.pc3_aspect_ratio + labs (title = title_PCA_individuals)
# ggsave (pca_reinstatement.pc1.pc3_aspect_title, file=paste(home, dir_plots, 
#                                                    "PCA_pc1_pc3_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC2 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc2.pc3  <- ggplot (pca2plot, aes(x=Dim.2, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
#   geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  # the limit is comming from PC1
  # the limits are mixed to get all pca plots of the same size
  scale_x_continuous (limits=c(floor(min(pca2plot$Dim.1)), ceiling(max(pca2plot$Dim.1))), breaks=floor(min(pca2plot$Dim.1)):ceiling(max(pca2plot$Dim.1))) + 
  scale_y_continuous (limits=c(floor(min(pca2plot$Dim.3)), ceiling(max(pca2plot$Dim.2))), breaks=floor(min(pca2plot$Dim.3)):ceiling(max(pca2plot$Dim.2))) +  
  #   labs(title = title_p, x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
  #        y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc2.pc3

# keeping aspect ratio
pca_reinstatement.pc2.pc3_aspect_ratio <- pca_reinstatement.pc2.pc3 + coord_fixed() + 
  guides(color=guide_legend(guide_legend(title = ""))) +
  theme (legend.key = element_blank(), legend.title = element_blank())
#   theme(plot.title = element_text(size=size_titles)) + 
#   theme(axis.title.x = element_text(size = size_axis)) +
#   theme(axis.title.y = element_text(size = size_axis)) +
#   guides(color=guide_legend(guide_legend(title = "Group"))) #+
#   theme (legend.text=element_text(size=size_leg_keys), legend.key = element_blank(), legend.title = element_blank(),
#          legend.title=element_text(size=size_leg_title))  


pca_reinstatement.pc2.pc3_aspect_ratio
pca_reinstatement.pc2.pc3_aspect_ratio_title <- pca_reinstatement.pc2.pc3_aspect_ratio + labs (title = title_PCA_individuals)

# ggsave (pca_reinstatement.pc2.pc3_aspect_ratio_title, file=paste(home, dir_plots, 
#                                                            "PCA_pc2_pc3_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

###############
### Circle Plot
circle_plot <- as.data.frame (res$var$coord)
circle_plot$var <- rownames (circle_plot)

# merging with annotation tbl
circle_plot_annotation_merged <- merge (circle_plot, reinst_annotation, by.x= "var", by.y = "tbl_name")
labels_v <- circle_plot_annotation_merged$Variable
neg_labels <- labels_v [which (circle_plot_annotation_merged$Dim.1 < 0)]
neg_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$Dim.1 < 0), c("Dim.1", "Dim.2")]

pos_labels <- labels_v [which (circle_plot_annotation_merged$Dim.1 >= 0)]
pos_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$Dim.1 >= 0), c("Dim.1", "Dim.2")]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

pos_positions_plot <- pos_positions
pos_positions_plot$Dim.1 <- pos_positions$Dim.1 - 0.025
pos_positions_plot$Dim.2 <- pos_positions$Dim.2 + 0.02

neg_positions_plot <- neg_positions
neg_positions_plot$Dim.1 <- neg_positions$Dim.1 #- 0.01
neg_positions_plot$Dim.2 <- neg_positions$Dim.2 + 0.05

p_circle_plot <- ggplot(circle_plot_annotation_merged) + 
  geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, colour="red") +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
  geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) #+
#   theme(axis.title.x = element_text(size = size_axis)) +
#   theme(axis.title.y = element_text(size = size_axis))

p_circle_plot

# base_size <- 12
# p_circle_plot
# 
# dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
#                                 axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
#                                 plot.title = element_text (size=base_size * 2, face="bold"))

p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed() #+ 
#   theme(plot.title = element_text(size=22)) + 
#   theme(axis.title.x = element_text(size =22)) +
#   theme(axis.title.y = element_text(size =22))
p_circle_plot_coord_fixed

# ggsave (p_circle_plot_coord_fixed, file=paste(home, dir_plots, "circle_annotated_behavior", img_format, sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

## Plotting by type of behavioral annotation
circle_plot_annotation_merged$Annotation
p_circle_plot_by_gr <- ggplot(circle_plot_annotation_merged) + 
  geom_segment (data=circle_plot_annotation_merged, aes(colour=Annotation, x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
  scale_x_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  scale_y_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  scale_color_manual(values = cb_palette_adapt) +
  geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
  geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
  guides(color=guide_legend(guide_legend(title = "Annotation"))) +
  theme (legend.key = element_blank())
  
#   theme (legend.text=element_text(size=18), legend.key = element_blank(), 
#          legend.title=element_text(size=20))                       

p_circle_plot_by_gr

p_circle_plot_by_gr_coord_fixed <- p_circle_plot_by_gr + coord_fixed() + theme(legend.key = element_blank(), 
                                                                               legend.title = element_blank())
  
#   guides(color=guide_legend(guide_legend(title = "Annotation"))) +
#   theme(legend.key = element_blank()) +
#   theme(plot.title = element_text(size=30)) + 
#   theme(axis.title.y = element_text(size=30))
p_circle_plot_by_gr_coord_fixed

# ggsave (p_circle_plot_by_gr_coord_fixed, file=paste(home, dir_plots, "circle_annotated_beh_coloured_by_gr", img_format, sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

####################################
## Same thing but without arrows
# aes(colour=annot_gr,
p_circle_points <- ggplot(circle_plot_annotation_merged,) + 
  geom_text (aes(colour=Annotation, x=Dim.1, y=Dim.2,label=labels_v), show.legend = FALSE, size=size_text_circle, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=annot_gr, x=Dim.1, y=Dim.2,label=labels_v), colour="white",show.legend = FALSE, size=size_text_circle, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
  geom_point(aes(colour=Annotation, x=Dim.1, y=Dim.2), size=0) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = title_var_loadings) +
  labs (x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (0.8, "line"), legend.title=element_blank()) +
  guides (colour = guide_legend (override.aes = list(size = 3)))
  
# p_circle_points_leg <- p_circle_points + theme(legend.text = element_text(size = 20))

p_circle_points_coord_fixed <-p_circle_points + coord_fixed()
p_circle_points_coord_fixed

# ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_behavior_text",  img_format, sep=""),
#         width = 15, height = 15, dpi=dpi_q)
# ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_behavior_labels",  img_format, sep=""),
#         width = 15, height = 15, dpi=dpi_q)

############
## BARPLOT

###########
## Barplot showing the contribution of all principal components
## Plot showing the percentage of variance explained by each principal component
bar_ylim <- 30

eigenvalues <- res$eig
head(eigenvalues[, 1:2])
barplot(eigenvalues[, 2], names.arg=1:nrow(eigenvalues), 
        main = "Variances",
        xlab = "Principal Components",
        ylab = "Percentage of variances",
        col ="steelblue")
# Add connected line segments to the plot
lines(x = 1:nrow(eigenvalues), eigenvalues[, 2], 
      type="b", pch=19, col = "red")

df.bars <- cbind (as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE)), names(res$var$coord[,1])[order(res$var$coord[,1]^2,decreasing=TRUE)])
df.bars_to_plot <- as.data.frame(df.bars)
df.bars_to_plot$index <- as.factor (df.bars_to_plot$V2)


# PC1
# title_b <- paste ("Variable contribution to PC1\n", "Variance explained: ", var_PC1, "%\n", sep="")
title_b <- paste ("Variable contribution to PC1\n", sep="")
df.bars_to_plot$value <- as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE))
df.bars_to_plot$index <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value, decreasing=TRUE)])

# merge with annotation tbl
df.bars_to_plot <- merge (df.bars_to_plot, reinst_annotation, by.x= "V2", by.y = "tbl_name")
df.bars_to_plot <- df.bars_to_plot[with(df.bars_to_plot, order(-value)), ]
df.bars_to_plot$Variable <- factor(df.bars_to_plot$Variable, levels = df.bars_to_plot$Variable[order(df.bars_to_plot$value, decreasing=TRUE)])

# PC2
# title_b <- paste ("Variable contribution to PC2\n", "Variance explained: ", var_PC2, "%\n", sep="")
title_b <- paste ("Variable contribution to PC2\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE)), names(res$var$coord[,2])[order(res$var$coord[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)
df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))

df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

# merge with annotation tbl
df.bars_to_plot_PC2 <- merge (df.bars_to_plot_PC2, reinst_annotation, by.x= "V2", by.y = "tbl_name")
df.bars_to_plot_PC2 <- df.bars_to_plot_PC2[with(df.bars_to_plot_PC2, order(-value)), ]
df.bars_to_plot_PC2$Variable <- factor(df.bars_to_plot_PC2$Variable, levels = df.bars_to_plot_PC2$Variable[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

# PC3
# title_b <- paste ("Variable contribution to PC3\n", "Variance explained: ", var_PC3, "%\n", sep="")
title_b <- paste ("Variable contribution to PC3\n", sep="")

df.bars_PC3 <- cbind (as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE)), names(res$var$coord[,3])[order(res$var$coord[,3]^2,decreasing=TRUE)])
df.bars_to_plot_PC3 <- as.data.frame(df.bars_PC3)
df.bars_to_plot_PC3$index <- as.factor (df.bars_to_plot_PC3$V2)
df.bars_to_plot_PC3$value <- as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE))

df.bars_to_plot_PC3$index
df.bars_to_plot_PC3$index <- factor(df.bars_to_plot_PC3$index, levels = df.bars_to_plot_PC3$index[order(df.bars_to_plot_PC3$value, decreasing=TRUE)])

# merge with annotation tbl
df.bars_to_plot_PC3 <- merge (df.bars_to_plot_PC3, reinst_annotation, by.x= "V2", by.y = "tbl_name")
df.bars_to_plot_PC3 <- df.bars_to_plot_PC2[with(df.bars_to_plot_PC3, order(-value)), ]
df.bars_to_plot_PC3$Variable <- factor(df.bars_to_plot_PC3$Variable, levels = df.bars_to_plot_PC3$Variable[order(df.bars_to_plot_PC3$value, decreasing=TRUE)])

# BARPLOTS ALL TOGETHER
bar_ylim = ceiling (max (df.bars_to_plot$value, df.bars_to_plot_PC2$value, df.bars_to_plot_PC3$value))

bars_plot_PC1 <- ggplot (data=df.bars_to_plot, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  #   scale_y_continuous (limits=c(0, 14), breaks=seq(0, 14, by=2)) + 
  scale_y_continuous (limits=c(0, 18), breaks=seq(0, 18, by=2)) +
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1))
bars_plot_PC1

# ggsave (bars_plot_PC1, file=paste(home, dir_plots, "bars_PC1", img_format, sep=""),
#         width = 15, height = 12, dpi=dpi_q)

bars_plot_PC1 <- ggplot (data=df.bars_to_plot, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_b, x = "", y="Contribution in %\n") +
  #   theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1)) 
  theme (axis.text.x=element_blank())    
bars_plot_PC1

#####
bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  #   scale_y_continuous (limits=c(0, 14), breaks=seq(0, 14, by=2)) + 
  scale_y_continuous (limits=c(0, 18), breaks=seq(0, 18, by=2)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC2
# ggsave (bars_plot_PC2, file=paste(home, dir_plots, "bars_PC2", img_format,
#         sep=""), width = 15, height = 12, dpi=dpi_q)

bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_b, x = "", y="Contribution in %\n") +
  #   theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1)) 
  theme (axis.text.x=element_blank())    
bars_plot_PC2

# Variability explained by PC3
var_PC3

bars_plot_PC3 <- ggplot (data=df.bars_to_plot_PC3, aes(x=Variable, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  #   scale_y_continuous (limits=c(0, 14), breaks=seq(0, 14, by=2)) +
  scale_y_continuous (limits=c(0, 18), breaks=seq(0, 18, by=2)) +
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC3
# ggsave (bars_plot_PC3, file=paste(home, dir_plots, "bars_PC3", img_format, 
#         sep=""), width = 15, height = 12, dpi=dpi_q)

bars_plot_PC3 <- ggplot (data=df.bars_to_plot_PC3, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC3 (",var_PC3, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_b, x = "", y="Contribution in %\n") +
  #   theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1)) 
  theme (axis.text.x=element_blank())    
bars_plot_PC3

#############################
## matrix PCA
#############################
# Sources
# http://ggobi.github.io/ggally/gh-pages/ggpairs.html
# http://www.r-bloggers.com/plot-matrix-with-the-r-package-ggally/
# https://tgmstat.wordpress.com/2013/11/13/plot-matrix-with-the-r-package-ggally/

require(GGally)
# data(tips, package="reshape")
# tips
# ggpairs(data=tips, # data.frame with variables
#         columns=1:3, # columns to plot, default to all.
#         title="", # title of the plot
#         colour = "sex") # aesthetics, ggplot2 style
# ## GGally example
# # ggsave (pca_reinstatement.pc1.pc2_aspect_ratio, file=paste(home, dir_plots, 
# #                                                        "PCA_pc1_pc2_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#### Matrix PLOT uncomment
# pca2plot_labPC <- pca2plot
# colnames(pca2plot_labPC) <- c("PC1", "PC2", "PC3", "PC4", "PC5", "id", "group")
# pm_empty = ggpairs(#data=tips,
#   data = pca2plot_labPC,
#   columns=1:3, 
#   #              upper = list(continuous = "density"),
#   upper = "blank",
#   lower = "blank",
#   diag = "blank",
#   #              lower = list(combo = "facetdensity"),
#   title="",
#   colour = "sex")
# pm_empty
# 
# PC1_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
#   scale_x_continuous (limits=c(0, 4)) + 
#   scale_y_continuous (limits=c(0, 4)) +
#   geom_blank() +
#   theme(axis.title = element_blank()) + 
#   theme(axis.text = element_blank()) +
#   annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 
# PC2_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
#   scale_x_continuous (limits=c(0, 4)) + 
#   scale_y_continuous (limits=c(0, 4)) +
#   geom_blank() +
#   theme(axis.title = element_blank()) + 
#   theme(axis.text = element_blank()) +
#   annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 
# PC3_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
#   scale_x_continuous (limits=c(0, 4)) + 
#   scale_y_continuous (limits=c(0, 4)) +
#   geom_blank() +
#   theme(axis.title = element_blank()) + 
#   theme(axis.text = element_blank()) +
#   annotate("text", label = paste("PC3 (",var_PC3, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 
# 
# pm <- putPlot(pm_empty, pca_reinstatement.pc1.pc2_aspect_ratio, 2, 1)
# pm <- putPlot(pm, pca_reinstatement.pc1.pc3_aspect_ratio, 3, 1)
# pm <- putPlot(pm, pca_reinstatement.pc2.pc3_aspect_ratio, 3, 2)
# 
# pm <- putPlot(pm, bars_plot_PC1, 1,1)
# pm <- putPlot(pm, bars_plot_PC2, 2,2)
# pm <- putPlot(pm, bars_plot_PC3, 3,3)


####################################
## Same thing but without arrows
p_circle_points_PC2_PC1 <- ggplot(circle_plot_annotation_merged) + 
  geom_text (aes(colour=Annotation, x=Dim.2, y=Dim.1,label=Variable), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=annot_gr, x=Dim.2, y=Dim.1,label=labels_v), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
#   geom_point(aes(colour=Annotation, x=Dim.2, y=Dim.1), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = title_var_loadings) +
  labs (x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
        y=paste("PC1 (", var_PC1, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC2_PC1_leg <- p_circle_points_PC2_PC1 + theme(legend.text = element_text(size = 20))
p_circle_points_PC2_PC1_leg_coord_fixed <-p_circle_points_PC2_PC1_leg + coord_fixed()

p_circle_points_PC3_PC1 <- ggplot(circle_plot_annotation_merged) + 
  geom_text (aes(colour=Annotation, x=Dim.3, y=Dim.1,label=Variable), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=Annotation, x=Dim.3, y=Dim.1,label=Variable), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
#   geom_point(aes(colour=Annotation, x=Dim.3, y=Dim.1), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = title_var_loadings) +
  labs (x = paste("\nPC3 (", var_PC3, "% of variance)", sep=""), 
        y=paste("PC1 (", var_PC1, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC3_PC1_leg <- p_circle_points_PC3_PC1 + theme(legend.text = element_text(size = 20))
p_circle_points_PC3_PC1_leg_coord_fixed <-p_circle_points_PC3_PC1_leg + coord_fixed()
p_circle_points_PC3_PC1_leg_coord_fixed

p_circle_points_PC3_PC2 <- ggplot(circle_plot_annotation_merged) + 
  geom_text (aes(colour=Annotation, x=Dim.3, y=Dim.2,label=Variable), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=Annotation, x=Dim.3, y=Dim.2,label=Variable), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
#   geom_point(aes(colour=Annotation, x=Dim.3, y=Dim.2), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = title_var_loadings) +
  labs (x = paste("\nPC3 (", var_PC3, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC3_PC2_leg <- p_circle_points_PC3_PC2 + theme(legend.text = element_text(size = 20))
p_circle_points_PC3_PC2_leg_coord_fixed <-p_circle_points_PC3_PC2_leg + coord_fixed()
p_circle_points_PC3_PC2_leg_coord_fixed

# pm <- putPlot(pm, p_circle_points_PC2_PC1_leg_coord_fixed, 1, 2)
# pm <- putPlot(pm, p_circle_points_PC3_PC1_leg_coord_fixed, 1, 3)
# pm <- putPlot(pm, p_circle_points_PC3_PC2_leg_coord_fixed, 2, 3)
# pm
#### Matrix PLOT uncomment

# tiff(file=paste(home, dir_plots, "matrix_pca", ".tiff", sep=""), height = 800, width = 1200)
# print(pm)
# dev.off()

#################
#######
## Panel

# Placing the legend in the plot corner for pc1 pc2 plot
pca_reinstatement.pc1.pc2_leg_in <- pca_reinstatement.pc1.pc2 +
                                 theme(legend.title=element_blank()) +                                     
#                                  theme(legend.text = element_text(size = 11)) +
                                 theme(legend.position = c(0.87, 0.15)) +
                                 labs (title = title_PCA_individuals)

pca_reinstatement.pc1.pc2_leg_in 

p_circle_points_leg_coord_fixed_leg_in <-  p_circle_points_coord_fixed +
                                       theme(legend.title=element_blank(),                                    
                                             legend.position = c(1.05, 0.185)) 


p_circle_points_leg_coord_fixed_leg_in

title_PC1_bar_plot = "\nVariable contribution to PC1"

bars_plot_PC1_panel <- ggplot (data=df.bars_to_plot, aes(x=Variable, y=value)) + 
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_PC1_bar_plot, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_blank())    

bars_plot_PC1_panel

title_PC2_bar_plot = "\nVariable contribution to PC2"

bars_plot_PC2_panel <- ggplot (data=df.bars_to_plot_PC2, aes(x=Variable, y=value)) + 
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) +
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_PC2_bar_plot, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_blank())    

bars_plot_PC2_panel

panel_pca_reins <- ggdraw() + draw_plot (pca_reinstatement.pc1.pc2_leg_in, 0, .5, 0.5, .5) +
  draw_plot (p_circle_points_leg_coord_fixed_leg_in, 0.5, 0.5, 0.5, 0.5) +
  draw_plot (bars_plot_PC1_panel, 0, 0, 0.5, .5) +
  draw_plot (bars_plot_PC2_panel, 0.5, 0, 0.5, .5) +
  draw_plot_label(c("A", "B", "C", "D"), c(0, 0.5, 0, 0.5), c(1, 1, 0.5, 0.5), size = size_titles)

panel_pca_reins

# This way the figure is ok
# if i save it manually
# size 1100, 700
img_format=".tiff"
dpi_q = 300
ggsave (panel_pca_reins, file=paste(home, dir_plots, "panel_PCA_reinst", tag_file, img_format, sep=""), 
        dpi=dpi_q, width=16, height=12)

# stop("Execution finished correctly")
