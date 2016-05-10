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

##Getting HOME directory 
home <- Sys.getenv("HOME")

## Dumping figures folder
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session/HF/"
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session/all_animals/"
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session_20160211/"
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session_20160217/"
dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/dividedPhases_20160330/"

# Loading functions:
source (paste (home, "/git/mwm/lib/R/plot_param_public.R", sep=""))

# Parameter to set plot qualities
dpi_q <- 50
img_format = ".tiff"

# data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_11_02_16.csv", sep=""), dec=",", sep=";")
# reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/annot_descriptors_11_02_16.csv", sep=""), dec=",", sep=";")
# data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_17_02_16.csv", sep=""), dec=",", sep=";")
# reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/annot_descriptors_17_02_16.csv", sep=""), dec=",", sep=";")
data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_06_04_16.csv", sep=""), dec=",", sep=";")
reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/annot_descriptors_06_04_16.csv", sep=""), dec=",", sep=";")


reinst_annotation$tbl_name
# head (data_reinst)
#head (reinst_annotation)

color_v <- c("orange", "red", "lightblue", "blue")

####
## All columns but mouse id and group
# data_reinst_filt <- subset (data_reinst, select=-c(1,2))
## Mara proposed to separate the data by the different experimental phases
data_reinst_filt <- subset (data_reinst, select=-c(1,2))

# deprivation
## filter_phases <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", 
##                      "Acquisition_day")
# filter_phases <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", 
#                    "Acquisition_day", "Learning_Inactive")

# tag <- "deprivation"
# bar_ylim <- 55

# deprivation + PR
# filter_phases <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", 
#                    "Acquisition_day", "PR2_break_point")
filter_phases <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", 
                   "Acquisition_day", "Learning_Inactive", "PR2_break_point")
tag <- "deprivation_PR"
bar_ylim <- 45

## ad_libitum
## filter_phases <- c("Primary_Reinf", "Habituation_Primary_Reinf", "Prim_R_discrim", "Impulsivity_adlib", "Imp_comp_adlib", "Compulsivity_adlib")
# filter_phases <- c("Primary_Reinf", "Habituation_Primary_Reinf", "Prim_R_discrim", "Impulsivity_adlib", "Imp_comp_adlib", "Compulsivity_adlib", "Prim_R_Inactive")

# tag <- "ad_lib"
# bar_ylim <- 50

# ## progressive ratio
# filter_phases <- c("PR2_break_point")
# tag <- "PR"
# 
# ## extinction operant conditioning
## filter_phases <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day")
# filter_phases <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day", "Ext_Inflex_Inactive")
# tag <- "ext"
# bar_ylim <- 75
# 
# ## relapse
# filter_phases <- c("Relapse_Fold_Change", "Relapse_Inflex")
# tag <- "relapse"

# ## extinction operant conditioning with relapse
## filter_phases <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day", "Relapse_Fold_Change", "Relapse_Inflex")
# filter_phases <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day", "Ext_Inflex_Inactive", 
#                    "Relapse_Fold_Change", "Relapse_Inflex")
# 
# tag <- "ext_relapse"
# bar_ylim <- 45

## Filtering by session
## matrix
data_reinst_filt <- subset (data_reinst, select=c(filter_phases))

#annotations
reinst_annotation <- reinst_annotation[reinst_annotation$tbl_name %in% filter_phases, ]

data_reinst_means <- subset(data_reinst, select = c("subject"))

data_reinst_means$group_lab  <- gsub ("F1", "High fat", data_reinst$Group)
data_reinst_means$group_lab  <- gsub ("SC", "Ctrl choc", data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("Cafeteria diet", "Choc", data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("C1", "Ctrl high fat", data_reinst_means$group_lab)

# cbind (data_reinst_means, ext_by_annotation)

res = PCA(data_reinst_filt, scale.unit=TRUE, graph=FALSE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])
var_PC3 <- round (res$eig [3,2])

# Coordinates are store here
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id <- data_reinst_means$subject
pca2plot$group <- as.factor(data_reinst_means$group_lab)
pca2plot$group <- factor(pca2plot$group, levels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"), 
                         labels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"))
color_v

#############
# PC1 PC2
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc2  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-4, 6.1), breaks=-4:6) + 
  scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
  #   labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
  #        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc2

# keeping aspect ratio
pca_reinstatement.pc1.pc2_aspect_ratio <- pca_reinstatement.pc1.pc2 + coord_fixed() + 
  theme(plot.title = element_text(size=22)) + 
  theme(axis.title.x = element_text(size =22)) +
  theme(axis.title.y = element_text(size =22)) +
  guides(color=guide_legend(guide_legend(title = "Group"))) +
  theme (legend.text=element_text(size=18), legend.key = element_blank(), 
         legend.title=element_text(size=20))  

# ggsave (pca_reinstatement.pc1.pc2_aspect_ratio, file=paste(home, dir_plots, 
#                                                            "PCA_pc1_pc2_annotated_sessions_", tag, ".tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC1 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc3  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-4, 6.1), breaks=-4:6) + 
  scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
  #   labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
  #        y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc3

# keeping aspect ratio
pca_reinstatement.pc1.pc3_aspect_ratio <- pca_reinstatement.pc1.pc3 + coord_fixed() +
  theme(plot.title = element_text(size=22)) + 
  theme(axis.title.x = element_text(size =22)) +
  theme(axis.title.y = element_text(size =22)) +
  guides(color=guide_legend(guide_legend(title = "Group"))) +
  theme (legend.text=element_text(size=18), legend.key = element_blank(), 
         legend.title=element_text(size=20))  

pca_reinstatement.pc1.pc3_aspect_ratio

# ggsave (pca_reinstatement.pc1.pc3_aspect_ratio, file=paste(home, dir_plots, 
#                                                    "PCA_pc1_pc3_annotated_sessions_", tag, ".tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC2 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc2.pc3  <- ggplot (pca2plot, aes(x=Dim.2, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
  scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
  #   labs(title = title_p, x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
  #        y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  labs(x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc2.pc3

# keeping aspect ratio
pca_reinstatement.pc2.pc3_aspect_ratio <- pca_reinstatement.pc2.pc3 + coord_fixed() +
  theme(plot.title = element_text(size=22)) + 
  theme(axis.title.x = element_text(size =22)) +
  theme(axis.title.y = element_text(size =22)) +
  guides(color=guide_legend(guide_legend(title = "Group"))) +
  theme (legend.text=element_text(size=18), legend.key = element_blank(), 
         legend.title=element_text(size=20))  

pca_reinstatement.pc2.pc3_aspect_ratio

# ggsave (pca_reinstatement.pc2.pc3_aspect_ratio, file=paste(home, dir_plots, 
#                                                            "PCA_pc2_pc3_annotated_sessions_", tag, ".tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

###############
### Circle Plot
circle_plot <- as.data.frame (res$var$coord)
labels_v <- row.names(res$var$coord)
which (circle_plot$Dim.1 < 0)

neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2)]

pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2)]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

pos_positions_plot <- pos_positions
pos_positions_plot$Dim.1 <- pos_positions$Dim.1 - 0.1
pos_positions_plot$Dim.2 <- pos_positions$Dim.2 + 0.02

neg_positions_plot <- neg_positions
neg_positions_plot$Dim.1 <- neg_positions$Dim.1 + 0.1
neg_positions_plot$Dim.2 <- neg_positions$Dim.2 + 0.05

circle_plot$var <- rownames (circle_plot)

## Are all var in circle_plot equal to annotations in the table to set behavioral annotation
### HERE I HAVE TO FILTER THE VARIABLES THAT DO NOT CORRESPOND TO DEPRIVATION
all.equal(circle_plot$var, as.vector(reinst_annotation$tbl_name))
circle_plot$annot_gr <- reinst_annotation$Group_color

p_circle_plot <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, colour="red") +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  ## extinction has only positive values on PC1 Comment
  geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=6.5) + 
  geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=6.5) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)

p_circle_plot

# base_size <- 12
# p_circle_plot
# 
# dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
#                                 axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
#                                 plot.title = element_text (size=base_size * 2, face="bold"))

p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed() + 
  theme(plot.title = element_text(size=22)) + 
  theme(axis.title.x = element_text(size =22)) +
  theme(axis.title.y = element_text(size =22))
p_circle_plot_coord_fixed

# ggsave (p_circle_plot_coord_fixed, file=paste(home, dir_plots, "circle_annotated_behavior_", tag, img_format, sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

# The palette with grey:
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# Adapted
cb_palette_adapt <- c("#999999", "#CC79A7", "#009E73", "#E69F00", "#0072B2", "#D55E00")

## Plotting by type of behavioral annotation
p_circle_plot_by_gr <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(colour=annot_gr, x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
  scale_x_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  scale_y_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  scale_color_manual(values = cb_palette_adapt) +
  ## extinction has only positive values on PC1 Comment
  geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=7.5) + 
  geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=7.5) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
  guides(color=guide_legend(guide_legend(title = "Annotation"))) +
  theme (legend.text=element_text(size=18), legend.key = element_blank(), 
         legend.title=element_text(size=20))                       

p_circle_plot_by_gr

p_circle_plot_by_gr_coord_fixed <- p_circle_plot_by_gr + coord_fixed() + 
  guides(color=guide_legend(guide_legend(title = "Annotation"))) +
  theme(legend.key = element_blank()) +
  theme(plot.title = element_text(size=30)) + 
  theme(axis.title.x = element_text(size=30)) +
  theme(axis.title.y = element_text(size=30))
p_circle_plot_by_gr_coord_fixed

# ggsave (p_circle_plot_by_gr_coord_fixed, file=paste(home, dir_plots, "circle_annotated_beh_coloured_by_gr_", tag, img_format, sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

####################################
## Same thing but without arrows
# aes(colour=annot_gr,
p_circle_points <- ggplot(circle_plot) + 
    geom_text (aes(colour=annot_gr, x=Dim.1, y=Dim.2,label=labels_v), show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
#   geom_label (aes(fill=annot_gr, x=Dim.1, y=Dim.2,label=labels_v), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
  geom_point(aes(colour=annot_gr, x=Dim.1, y=Dim.2), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = "Sessions loadings\n") +
  labs (x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_leg <- p_circle_points + theme(legend.text = element_text(size = 20))
p_circle_points_leg_coord_fixed <-p_circle_points_leg + coord_fixed()
p_circle_points_leg_coord_fixed

# ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_behavior_labels_", tag, img_format, sep=""),
#         width = 15, height = 15, dpi=dpi_q)

############
## BARPLOT

###########
## Barplot showing the contribution of all principal components
## Plot showing the percentage of variance explained by each principal component
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
df.bars_to_plot$value <- as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE))
df.bars_to_plot$index <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value, decreasing=TRUE)])

# PC1
title_b <- paste ("Variable contribution to PC1\n", "Variance explained: ", var_PC1, "%\n", sep="")

bars_plot_PC1 <- ggplot (data=df.bars_to_plot, aes(x=index, y=value)) + 
  #   ylim (c(0, 12)) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=index), hjust=-0.1, color="black", angle = 90, size=5) +
  annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 3, y = 2 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_b, x = "", y="Contribution in %\n") +
#   theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1)) 
  theme (axis.text.x=element_blank())
bars_plot_PC1

# ggsave (bars_plot_PC1, file=paste(home, dir_plots, "bars_PC1", tag, img_format, sep=""),
#         width = 15, height = 12, dpi=dpi_q)

# PC2
title_b <- paste ("Variable contribution to PC2\n", "Variance explained: ", var_PC2, "%\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE)), names(res$var$coord[,2])[order(res$var$coord[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)
df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))

df.bars_to_plot_PC2$index
df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=index, y=value)) + 
  #   ylim (c(0, 12)) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +  
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=index), hjust=-0.1, color="black", angle = 90, size=5) +
  labs (title = title_b, x = "", y="Contribution in %\n") +
  annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 3, y = 2 * bar_ylim/3, size = 6, colour = "black") +
#   theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))
  theme (axis.text.x=element_blank())

bars_plot_PC2
# ggsave (bars_plot_PC2, file=paste(home, dir_plots, "bars_PC2_", tag, img_format,
#         sep=""), width = 15, height = 12, dpi=dpi_q)

# PC3
title_b <- paste ("Variable contribution to PC3\n", "Variance explained: ", var_PC3, "%\n", sep="")

df.bars_PC3 <- cbind (as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE)), names(res$var$coord[,3])[order(res$var$coord[,3]^2,decreasing=TRUE)])
df.bars_to_plot_PC3 <- as.data.frame(df.bars_PC3)
df.bars_to_plot_PC3$index <- as.factor (df.bars_to_plot_PC3$V2)
df.bars_to_plot_PC3$value <- as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE))

df.bars_to_plot_PC3$index
df.bars_to_plot_PC3$index <- factor(df.bars_to_plot_PC3$index, levels = df.bars_to_plot_PC3$index[order(df.bars_to_plot_PC3$value, decreasing=TRUE)])

# Variability explained by PC3
var_PC3

bars_plot_PC3 <- ggplot (data=df.bars_to_plot_PC3, aes(x=index, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=index), hjust=-0.1, color="black", angle = 90, size=5) +
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  annotate("text", label = paste("PC3 (",var_PC3, "%)", sep=""), x = 3, y = 2 * bar_ylim/3, size = 6, colour = "black") + 
#   theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1)) +
  theme (axis.text.x=element_blank())

bars_plot_PC3
# ggsave (bars_plot_PC3, file=paste(home, dir_plots, "bars_PC3_", tag, img_format,
#         sep=""), width = 15, height = 12, dpi=dpi_q)

# #######################
# #######################
# #######################
# # Plotting annotations by session name instead of annotation
# #######################
# 
# reinst_annotation_1_1 <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinst_annotation_1to1.csv", sep=""), dec=",", sep=";")
# # write.table(as.data.frame(t(reinst_annotation_1_1)), "/Users/jespinosa/Dropbox (Personal)/presentations_2016/20160210_GM_Mara/t_annot.csv",
# #             sep=";", row.names=TRUE, col.names=FALSE)
# ext_by_annotation
# colnames(ext_by_annotation)
# 
# ext_by_annotation_t$Annotation
# ext_by_sessions <- merge (ext_by_annotation_t, reinst_annotation_1_1 , by.x= "Annotation", by.y = "Annotation")
# 
# # Drop first column with labels:
# ext_by_annotation_t_no_lab <- ext_by_annotation_t [,-1]
# ext_by_annotation <- as.data.frame(t(ext_by_annotation_t_no_lab), stringsAsFactors=FALSE)
# class(ext_by_annotation[,1])
# ext_by_session <- ext_by_annotation
# colnames(ext_by_session) <- ext_by_sessions$Session
# 
# res_session = PCA(ext_by_session, scale.unit=TRUE)
# 
# # Variance of PC1 and PC2
# var_PC1 <- round (res_session$eig [1,2])
# var_PC2 <- round (res_session$eig [2,2])
# var_PC3 <- round (res_session$eig [3,2])
# 
# # Coordinates are store here
# pca2plot_session <- as.data.frame (res_session$ind$coord)
# length(pca2plot_session$Dim.1)
# pca2plot_session$id <- data_reinst_means$subject
# pca2plot_session$group <- data_reinst_means$group_lab
# 
# ###############
# ### Circle Plot
# circle_plot <- as.data.frame (res_session$var$coord)
# labels_v <- row.names(res_session$var$coord)
# which (circle_plot$Dim.1 < 0)
# 
# neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
# neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2)]
# 
# pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
# pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2)]
# 
# angle <- seq(-pi, pi, length = 50)
# df.circle <- data.frame(x = sin(angle), y = cos(angle))
# 
# pos_positions_plot <- pos_positions
# pos_positions_plot$Dim.1 <- pos_positions$Dim.1 - 0.1
# pos_positions_plot$Dim.2 <- pos_positions$Dim.2 + 0.02
# 
# neg_positions_plot <- neg_positions
# neg_positions_plot$Dim.1 <- neg_positions$Dim.1 + 0.1
# neg_positions_plot$Dim.2 <- neg_positions$Dim.2 + 0.05
# 
# p_circle_plot <- ggplot(circle_plot) + 
#   geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
#                 arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, color="red") +
#   xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
#   geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=6.5) + 
#   geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=6.5) +
#   geom_vline (xintercept = 0, linetype="dotted") +
#   geom_hline (yintercept=0, linetype="dotted") +
#   labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
#         y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
#   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)
# 
# base_size <- 10
# p_circle_plot
# 
# dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
#                                 axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
#                                 plot.title = element_text (size=base_size * 2, face="bold"))
# 
# p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed()
# p_circle_plot_coord_fixed
# 
# # ggsave (p_circle_plot_coord_fixed, , file=paste(home, dir_plots, "circle_annotated_sessions_", tag, img_format, sep=""), 
# #         width = 15, height = 15, dpi=dpi_q)
# 
# ####################################
# ## Same thing but without arrows
# p_circle_points <- ggplot(circle_plot) + 
#   geom_text (aes(x=Dim.1, y=Dim.2,label=labels_v), show.legend = FALSE, size=7, vjust=-0.4) +
#   geom_point(aes(x=Dim.1, y=Dim.2), size=3) +
#   xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
#   labs (title = "Sessions loadings\n") +
#   labs (x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
#         y=paste("PC2 (", var_PC2, "% of ddvariance)\n", sep = "")) +
#   geom_vline(xintercept = 0, linetype = "longdash") +
#   geom_hline(yintercept = 0, linetype = "longdash") +
#   theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 
# 
# p_circle_points_leg <- p_circle_points + theme(legend.text = element_text(size = 20))
# p_circle_points_leg_coord_fixed <-p_circle_points_leg + coord_fixed()
# p_circle_points_leg_coord_fixed 
# # ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_session", tag, img_format, sep=""),
# #         width = 15, height = 15, dpi=dpi_q)

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
#         title="tips data", # title of the plot
#         colour = "sex") # aesthetics, ggplot2 style
## GGally example
# ggsave (pca_reinstatement.pc1.pc2_aspect_ratio, file=paste(home, dir_plots, 
#                                                        "PCA_pc1_pc2_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

pca2plot_labPC <- pca2plot
colnames(pca2plot_labPC) <- c("PC1", "PC2", "PC3", "PC4", "PC5", "id", "group")
pm_empty = ggpairs(#data=tips,
  data = pca2plot_labPC,
  columns=1:3, 
  upper = "blank",
  lower = "blank",
  diag = "blank",
  title=paste("PCA ", tag, sep=""),
  colour = "sex")
pm_empty

PC1_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
  scale_x_continuous (limits=c(0, 4)) + 
  scale_y_continuous (limits=c(0, 4)) +
  geom_blank() +
  theme(axis.title = element_blank()) + 
  theme(axis.text = element_blank()) +
  annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 
PC2_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
  scale_x_continuous (limits=c(0, 4)) + 
  scale_y_continuous (limits=c(0, 4)) +
  geom_blank() +
  theme(axis.title = element_blank()) + 
  theme(axis.text = element_blank()) +
  annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 
PC3_lab <- ggplot(mtcars, aes(x = wt, y = mpg)) + 
  scale_x_continuous (limits=c(0, 4)) + 
  scale_y_continuous (limits=c(0, 4)) +
  geom_blank() +
  theme(axis.title = element_blank()) + 
  theme(axis.text = element_blank()) +
  annotate("text", label = paste("PC3 (",var_PC3, "%)", sep=""), x = 2, y = 2, size = 8, colour = "black") 

pm <- putPlot(pm_empty, pca_reinstatement.pc1.pc2_aspect_ratio, 2, 1)
pm <- putPlot(pm, pca_reinstatement.pc1.pc3_aspect_ratio, 3, 1)
pm <- putPlot(pm, pca_reinstatement.pc2.pc3_aspect_ratio, 3, 2)

pm <- putPlot(pm, bars_plot_PC1, 1,1)
pm <- putPlot(pm, bars_plot_PC2, 2,2)
pm <- putPlot(pm, bars_plot_PC3, 3,3)

# pm <- putPlot(pm, PC1_lab, 1, 1)
# pm <- putPlot(pm, PC2_lab, 2, 2)
# pm <- putPlot(pm, PC3_lab, 3, 3)

# pm

####################################
## Same thing but without arrows
# aes(colour=annot_gr,
p_circle_points_PC2_PC1 <- ggplot(circle_plot) + 
  #   geom_text (aes(colour=annot_gr, x=Dim.1, y=Dim.2,label=labels_v), show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  geom_text (aes(colour=annot_gr, x=Dim.2, y=Dim.1, label=labels_v), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=annot_gr, x=Dim.2, y=Dim.1,label=labels_v), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
  geom_point(aes(colour=annot_gr, x=Dim.2, y=Dim.1), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = "Sessions loadings\n") +
  labs (x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
        y=paste("PC1 (", var_PC1, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC2_PC1_leg <- p_circle_points_PC2_PC1 + theme(legend.text = element_text(size = 20))
p_circle_points_PC2_PC1_leg_coord_fixed <-p_circle_points_PC2_PC1_leg + coord_fixed()

p_circle_points_PC3_PC1 <- ggplot(circle_plot) + 
  #   geom_text (aes(colour=annot_gr, x=Dim.1, y=Dim.2,label=labels_v), show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  geom_text (aes(colour=annot_gr, x=Dim.3, y=Dim.1, label=labels_v), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
  #   geom_label (aes(fill=annot_gr, x=Dim.3, y=Dim.1,label=labels_v), colour="white",show.legend = FALSE, size=7, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
  geom_point(aes(colour=annot_gr, x=Dim.3, y=Dim.1), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = "Sessions loadings\n") +
  labs (x = paste("\nPC3 (", var_PC3, "% of variance)", sep=""), 
        y=paste("PC1 (", var_PC1, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC3_PC1_leg <- p_circle_points_PC3_PC1 + theme(legend.text = element_text(size = 20))
p_circle_points_PC3_PC1_leg_coord_fixed <-p_circle_points_PC3_PC1_leg + coord_fixed()
p_circle_points_PC3_PC1_leg_coord_fixed

p_circle_points_PC3_PC2 <- ggplot(circle_plot) + 
  geom_text (aes(colour=annot_gr, x=Dim.3, y=Dim.2,label=labels_v), show.legend = FALSE, size=5, fontface="bold", vjust=-0.4) +
#   geom_label (aes(fill=annot_gr, x=Dim.3, y=Dim.2,label=labels_v), colour="white",show.legend = FALSE, size=3, fontface="bold", vjust=-0.4) +
  scale_fill_manual(values = cb_palette_adapt) +
  geom_point(aes(colour=annot_gr, x=Dim.3, y=Dim.2), size=3) +
  scale_color_manual(values = cb_palette_adapt) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) + 
  labs (title = "Sessions loadings\n") +
  labs (x = paste("\nPC3 (", var_PC3, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of ddvariance)\n", sep = "")) +
  geom_vline(xintercept = 0, linetype = "longdash") +
  geom_hline(yintercept = 0, linetype = "longdash") +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), legend.title=element_blank()) 

p_circle_points_PC3_PC2_leg <- p_circle_points_PC3_PC2 + theme(legend.text = element_text(size = 20))
p_circle_points_PC3_PC2_leg_coord_fixed <-p_circle_points_PC3_PC2_leg + coord_fixed()
p_circle_points_PC3_PC2_leg_coord_fixed

pm <- putPlot(pm, p_circle_points_PC2_PC1_leg_coord_fixed, 1, 2)
pm <- putPlot(pm, p_circle_points_PC3_PC1_leg_coord_fixed, 1, 3)
pm <- putPlot(pm, p_circle_points_PC3_PC2_leg_coord_fixed, 2, 3)
pm

tiff(file=paste(home, dir_plots, "matrix_pca_", tag,  ".tiff", sep=""), height = 800, width = 1200)
print(pm)
dev.off()


stop("Execution finished correctly")


##############
# Development
#############
install.packages("dplyr")
library(dplyr)


### WORKING
ddply(reinst_annotation, c("Annotation"), function(x) { print (as.character( x$Session)) })



### FUNCIONA!!!!!!!
# culo<-do.call("rbind",ddply(reinst_annotation, c("Annotation"), function(x) { 
# #                                                         print (as.character(x$Session))
#   rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
#                                                         }))

# Mejor asi porque tengo la anotacion
ext_by_annotation_t <- ddply(reinst_annotation, c("Annotation"), function(x) { 
  rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
})