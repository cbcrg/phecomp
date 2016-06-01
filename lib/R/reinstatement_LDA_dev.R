#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. MAY 2016                         ###
#############################################################################
### LDA reinstatement experiment from Rafael's lab                        ###
### Phases of the experiment labeled following discussion on 11th Feb     ### 
### meting                                                                ###
### Development dirty script                                              ###
#############################################################################

library (plyr)
library(FactoMineR)
library(ggplot2)
library(Hmisc) # arrow function
library("cowplot")
require(scales)
library ("MASS")

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

# color_v <- c("orange", "red", "lightblue", "blue")
# For lda
color_v <- c("orange", "red", "blue")

####
## All columns but mouse id and group
# data_reinst_filt <- subset (data_reinst, select=-c(1,2))
## Mara proposed to separate the data by the different experimental phases
data_reinst_filt <- subset (data_reinst, select=-c(1))
tag_file <- "all_var"
# Color for all variables, I want to mantain always the same colors for the variables
# The palette with grey:
# cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# Adapted
cb_palette_adapt <- c("#999999", "#CC79A7", "#009E73", "#E69F00", "#0072B2", "#D55E00")


# deprivation
# dep <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", "Acquisition_day")
# dep <- c("Learning_AUC", "Learning_delta", "Learning_discrim", "Impulsivity_dep", "Imp_comp_dep", "Compulsivity_dep", "Acquisition_day", "Learning_Inactive")
# tag_file = "_acq_operant_cond"
# cb_palette_adapt <- c("#999999", "#009E73", "#E69F00", "#0072B2", "#D55E00", "#CC79A7")
# filter_v <- dep

# ad_libitum
# ad_lib <- c("Primary_Reinf", "Habituation_Primary_Reinf", "Prim_R_discrim", "Impulsivity_adlib", "Imp_comp_adlib", "Compulsivity_adlib", "Prim_R_Inactive")
# tag_file = "_maint_operant_cond"
# cb_palette_adapt <- c("#999999", "#009E73", "#0072B2", "#E69F00", "#D55E00", "#CC79A7")
# filter_v <- ad_lib

# progressive ratio
# PR <- c("PR2_break_point")
# tag_file <- "_progressive_ratio"
# filter_v <- PR

# Extinction operant conditioning
# ext <- c("Ext_Learning_AUC", "Ext_Learning_delta", "Ext_Inflex", "Extinction_day", "Ext_Inflex_Inactive")
# tag_file <- "_ext_operant_cond"
# cb_palette_adapt <- c("#CC79A7", "#009E73", "#E69F00", "#0072B2", "#D55E00","#999999")
# filter_v <- ext

# relapse
# relapse <- c("Relapse_Fold_Change", "Relapse_Inflex", "Relapse_Inactive_Inflex")
# tag_file <- "_cue_reinst"
# cb_palette_adapt <- c("#CC79A7","#D55E00", "#009E73", "#E69F00", "#0072B2", "#999999")
# filter_v <- relapse

# deprivation + ad libitum
# dep_ad_lib <- c(dep, ad_lib)
# tag_file = "_whole_operant_cond"
# cb_palette_adapt <- c("#999999", "#009E73", "#E69F00", "#0072B2", "#D55E00", "#CC79A7")
# filter_v <- dep_ad_lib

data_reinst_means <- subset(data_reinst, select = c("subject"))

# HF_lab <- "High fat"
# choc_lab <- "Choc"
# ctrl_HF_lab <- "Ctrl high fat" 
# ctrl_choc_lab <- "Ctrl choc"

HF_lab <- "HF diet"
choc_lab <- "CM diet"
ctrl_HF_lab <- "Ctrl HF" 
ctrl_choc_lab <- "Ctrl CM"
ctrl_lda <- "Ctrl"
data_reinst_means$group_lab  <- gsub ("F1", HF_lab, data_reinst$Group)
data_reinst_means$group_lab  <- gsub ("SC", ctrl_choc_lab, data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("Cafeteria diet", choc_lab, data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("C1", ctrl_HF_lab, data_reinst_means$group_lab)

# Filtering by session
# data_reinst_filt <- subset (data_reinst, select=c(filter_v))
# no filtering
data_reinst_filt <- subset (data_reinst, select=-c(1,2))
data_reinst_filt$group <- data_reinst$Group
# cbind (data_reinst_means, ext_by_annotation)
# merging the annotation tbl and the data in order to change the annotation used to show the variables

# res = PCA(data_reinst_filt, scale.unit=TRUE, graph=FALSE)

data_reinst_filt$group <- gsub ("C1", ctrl_lda, data_reinst_filt$group)
data_reinst_filt$group <- gsub ("SC", ctrl_lda, data_reinst_filt$group)
data_reinst_filt$group <- gsub ("F1", HF_lab, data_reinst_filt$group)
data_reinst_filt$group <- gsub ("Cafeteria diet", choc_lab, data_reinst_filt$group)

res_lda = lda(group  ~ . , data_reinst_filt)


prop.lda = res_lda$svd^2/sum(res_lda$svd^2) * 100

plda <- predict(object = res_lda,
                newdata = data_reinst_filt)

lda2plot = data.frame(group = data_reinst_filt$group,
                      lda = plda$x)

p1 <- ggplot(lda2plot) + geom_point(aes(lda.LD1, lda.LD2, colour = group, shape = group), size = 2.5) + 
  labs(x = paste("LD1 (", percent(prop.lda[1]), ")", sep=""),
       y = paste("LD2 (", percent(prop.lda[2]), ")", sep=""))

p1
# str(res)
# plot(res)
# points(res$scaling*2)
# text(res$scaling*2, rownames(res$scaling))

# Variance of LD1 and LD2
var_PC1 <- round(prop.lda[1])
var_PC2 <- round(prop.lda[2])

# Coordinates are store here
# pca2plot <- as.data.frame (res$ind$coord)
# pca2plot$id <- data_reinst_means$subject
# pca2plot$group <- as.factor(data_reinst_means$group_lab)
lda2plot$group <- factor(lda2plot$group, levels=c(ctrl_lda, choc_lab, HF_lab), 
                         labels=c(ctrl_lda, choc_lab, HF_lab))
color_v

x_lim <- ceiling(min(lda2plot$lda.LD1))
x_max_1 <-max(lda2plot$lda.LD2)

# Font sizes
# size_text_circle <- 6.5
size_text_circle <- 5.5

title_PCA_individuals <- "\nMice LDA by annotated variables\n" #"Distribution of mice by sessions PCA\n"
title_var_loadings =  "\nVariable contribution\n" #"PCA of the variables\n"\ #"Sessions loadings"

#############
# LD1 LD2
title_p <- paste ("LCA annotated sessions reinstatement\n", sep="")
lda_reinstatement.pc1.pc2  <- ggplot (lda2plot, aes(lda.LD1, lda.LD2, colour=group)) + 
  geom_point (size = 3.5, show.legend = T) + 
  scale_color_manual(values=color_v) +
  #   geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show.legend = F)+
  theme(legend.key=element_rect(fill=NA)) +
  # the limits are mixed to get all pca plots of the same size
  #   scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=seq (floor(min(lda2plot$lda.LD1)),ceiling(max(lda2plot$lda.LD1)),by=5)) + 
  #   scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=seq (floor(min(lda2plot$lda.LD1)),ceiling(max(lda2plot$lda.LD1)),by=5)) +
  scale_x_continuous (limits=c(-25,20), breaks=seq(-25,20, by=5)) + 
  scale_y_continuous (limits=c(-10,5), breaks=seq(-10,5, by=5)) +
  labs(x = paste("\nLD1 (", var_PC1, "% of between group variance)", sep=""), 
       y=paste("LD2 (", var_PC2, "% of between group variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

lda_reinstatement.pc1.pc2

# keeping aspect ratio
lda_reinstatement.ld1.ld2_aspect_ratio <- lda_reinstatement.pc1.pc2 + coord_fixed() + 
  #   theme(plot.title = element_text(size=size_titles)) + 
  #   theme(axis.title.x = element_text(size = size_axis)) +
  #   theme(axis.title.y = element_text(size = size_axis)) +
  guides(color=guide_legend(guide_legend(title = ""))) +
  theme (legend.key = element_blank(), legend.title = element_blank())

lda_reinstatement.pc1.pc2_aspect_ratio_title <- lda_reinstatement.ld1.ld2_aspect_ratio + labs (title = title_PCA_individuals)

###############
### Circle Plot
# circle_plot <- as.data.frame (res_lda$scaling)
# sqrt(circle_plot$LD1^2 + circle_plot$LD2^2)
# circle_plot$var <- rownames (circle_plot)
# res
# # merging with annotation tbl
# circle_plot_annotation_merged <- merge (circle_plot, reinst_annotation, by.x= "var", by.y = "tbl_name")
# labels_v <- circle_plot_annotation_merged$Variable
# neg_labels <- labels_v [which (circle_plot_annotation_merged$LD1 < 0)]
# neg_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 < 0), c("LD1", "LD2")]
# 
# pos_labels <- labels_v [which (circle_plot_annotation_merged$LD1 >= 0)]
# pos_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 >= 0), c("LD1", "LD2")]
# 
# angle <- seq(-pi, pi, length = 50)
# df.circle <- data.frame(x = sin(angle), y = cos(angle))
# 
# pos_positions_plot <- pos_positions
# pos_positions_plot$LD1 <- pos_positions$LD1 - 0.025
# pos_positions_plot$LD2 <- pos_positions$LD2 + 0.02
# 
# neg_positions_plot <- neg_positions
# neg_positions_plot$LD1 <- neg_positions$LD1 #- 0.01
# neg_positions_plot$LD2 <- neg_positions$LD2 + 0.05
# 
# p_circle_plot <- ggplot(circle_plot_annotation_merged) + 
#   geom_segment (data=circle_plot, aes(x=0, y=0, xend=LD1, yend=LD2), 
#                 arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, colour="red") +
#   xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
#   geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
#   geom_text (data=pos_positions_plot, aes (x=LD1, y=LD2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
#   geom_vline (xintercept = 0, linetype="dotted") +
#   geom_hline (yintercept=0, linetype="dotted") +
#   labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
#         y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
#   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) #+
# #   theme(axis.title.x = element_text(size = size_axis)) +
# #   theme(axis.title.y = element_text(size = size_axis))
# 
# p_circle_plot

p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed() #+ 
p_circle_plot_coord_fixed

# ggsave (p_circle_plot_coord_fixed, file=paste(home, dir_plots, "circle_annotated_behavior", img_format, sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

## Plotting by type of behavioral annotation
circle_plot_annotation_merged$Annotation
p_circle_plot_by_gr <- ggplot(circle_plot_annotation_merged) + 
  geom_segment (data=circle_plot_annotation_merged, aes(colour=Annotation, x=0, y=0, xend=LD1, yend=LD2), 
                arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
  scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=floor(min(lda2plot$lda.LD1)):ceiling(max(lda2plot$lda.LD1))) + 
  scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=floor(min(lda2plot$lda.LD2)):ceiling(max(lda2plot$lda.LD2))) +
  #   scale_x_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  #   scale_y_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
  #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  scale_color_manual(values = cb_palette_adapt) +
  geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
  geom_text (data=pos_positions_plot, aes (x=LD1, y=LD2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
  #   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
  guides(color=guide_legend(guide_legend(title = "Annotation"))) +
  theme (legend.key = element_blank())

#   theme (legend.text=element_text(size=18), legend.key = element_blank(), 
#          legend.title=element_text(size=20))                       

p_circle_plot_by_gr

p_circle_plot_by_gr_coord_fixed <- p_circle_plot_by_gr + coord_fixed() + theme(legend.key = element_blank(), 
                                                                               legend.title = element_blank())

# lda_reinstatement.pc1.pc2_aspect_ratio_title
# p_circle_plot_by_gr_coord_fixed
# 
# LD2 is specfic of chocolate, separates from ctrl and HF
# Between group variance


##### 
## BARPLOT 
res_lda$scaling
df.bars <- cbind (as.numeric(sort(res_lda$scaling[,1]^2/sum(res_lda$scaling[,1]^2)*100,decreasing=TRUE)), names(res_lda$scaling[,1])[order(res_lda$scaling[,1]^2,decreasing=TRUE)])
df.bars_to_plot <- as.data.frame(df.bars, stringsAsFactors = FALSE)
df.bars_to_plot$index <- as.factor (df.bars_to_plot$V2)


# LD1
title_b <- paste ("Variable contribution to LD1\n", sep="")
df.bars_to_plot$value <- as.numeric(sort(res_lda$scaling[,1]^2/sum(res_lda$scaling[,1]^2)*100,decreasing=TRUE))
df.bars_to_plot$index <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value, decreasing=TRUE)])

df.bars_to_plot$value_for_sign <- as.numeric(sort(res_lda$scaling[,1]/sum(res_lda$scaling[,1])*100,decreasing=TRUE))
df.bars_to_plot$index_for_sign <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value_for_sign, decreasing=TRUE)])

# merge with annotation tbl
df.bars_to_plot <- merge (df.bars_to_plot, reinst_annotation, by.x= "V2", by.y = "tbl_name")
df.bars_to_plot <- df.bars_to_plot[with(df.bars_to_plot, order(-value)), ]
df.bars_to_plot$Variable <- factor(df.bars_to_plot$Variable, levels = df.bars_to_plot$Variable[order(df.bars_to_plot$value, decreasing=TRUE)])

# LD2
# title_b <- paste ("Variable contribution to LD2\n", "Variance explained: ", var_PC2, "%\n", sep="")
title_b <- paste ("Variable contribution to LD2\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res_lda$scaling[,2]^2/sum(res_lda$scaling[,1]^2)*100,decreasing=TRUE)), names(res_lda$scaling[,2])[order(res_lda$scaling[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2, stringsAsFactors = FALSE)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)

df.bars_to_plot_PC2$value <- as.numeric(sort(res_lda$scaling[,2]^2/sum(res_lda$scaling[,2]^2)*100,decreasing=TRUE))
df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

df.bars_to_plot_PC2$value_for_sign <- as.numeric(sort(res_lda$scaling[,2]/sum(res_lda$scaling[,2])*100,decreasing=TRUE))
df.bars_to_plot_PC2$index_for_sign <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value_for_sign, decreasing=TRUE)])

# merge with annotation tbl
df.bars_to_plot_PC2 <- merge (df.bars_to_plot_PC2, reinst_annotation, by.x= "V2", by.y = "tbl_name")
df.bars_to_plot_PC2 <- df.bars_to_plot_PC2[with(df.bars_to_plot_PC2, order(-value)), ]
df.bars_to_plot_PC2$Variable <- factor(df.bars_to_plot_PC2$Variable, levels = df.bars_to_plot_PC2$Variable[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

# BARPLOTS ALL TOGETHER
bar_ylim = ceiling (max (df.bars_to_plot$value, df.bars_to_plot_PC2$value))

bars_plot_PC1 <- ggplot (data=df.bars_to_plot, aes(x=Variable, y=value)) + 
  #   ylim (c(0, 12)) +
  #   scale_y_continuous (limits=c(0, 14), breaks=seq(0, 14, by=2)) + 
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +
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
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) + 
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



##################################
########################
## Panel

# Placing the legend in the plot corner for pc1 pc2 plot
lda_reinstatement.pc1.pc2_leg_in <- lda_reinstatement.pc1.pc2 +
  theme(legend.title=element_blank()) +                                     
  #   theme(legend.position = c(0.1, 0.9)) +
  theme(legend.position = c(0.9, 0.1)) +
  labs (title = title_PCA_individuals)

lda_reinstatement.pc1.pc2_leg_in 

p_circle_points_leg_coord_fixed_leg_in <-  p_circle_plot_by_gr_coord_fixed +
  theme(legend.title=element_blank(),                                    
        legend.position = c(1.05, 0.185)) 


# p_circle_points_leg_coord_fixed_leg_in

###BARPLOTS panel
title_PC1_bar_plot = "\nVariable contribution to LD1"

bars_plot_PC1_panel <- ggplot (data=df.bars_to_plot, aes(x=Variable, y=value)) + 
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC1 (",var_PC1, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_PC1_bar_plot, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_blank())    

bars_plot_PC1_panel

title_PC2_bar_plot = "\nVariable contribution to LD2"

bars_plot_PC2_panel <- ggplot (data=df.bars_to_plot_PC2, aes(x=Variable, y=value)) + 
  scale_y_continuous (limits=c(0, bar_ylim), breaks=seq(0, bar_ylim, by=5)) +   
  geom_bar (stat="identity", fill="gray", width=0.8) +
  geom_text(aes(y=0, label=Variable), hjust=-0.1, color="black", angle = 90, size=size_text_circle) +  
  annotate("text", label = paste("PC2 (",var_PC2, "%)", sep=""), x = 5, y = 4 * bar_ylim/3, size = 6, colour = "black") +
  labs (title = title_PC2_bar_plot, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_blank())    

###############
### Circle Plot
# normalize to unit vector
# scalar1 <- function(x) {x / sqrt(sum(x^2))}
# 
circle_plot <- as.data.frame (res_lda$scaling)
# 
# sqrt(circle_plot$LD1^2 + circle_plot$LD2^2)
circle_plot$var <- rownames (circle_plot)
# df.bars_to_plot, df.bars_to_plot_PC2


df.bars_to_plot$LD1_sign <- df.bars_to_plot$value * (abs(df.bars_to_plot$value_for_sign) / df.bars_to_plot$value_for_sign)/100
df.bars_to_plot_PC2$LD2_sign <- df.bars_to_plot_PC2$value * (abs(df.bars_to_plot_PC2$value_for_sign) / df.bars_to_plot_PC2$value_for_sign)/100
circle_LD <- merge (df.bars_to_plot, df.bars_to_plot_PC2, by.x= "Variable", by.y = "Variable")

circle_LD <-  subset (circle_LD , select=c("Variable","Annotation.x", "LD1_sign", "LD2_sign"))

labels_v <- circle_LD$Variable
neg_labels <- labels_v [which (circle_LD$LD1_sign < 0)]
neg_positions <- circle_LD [which (circle_LD$LD1_sign < 0), c("LD1_sign", "LD2_sign")]

pos_labels <- labels_v [which (circle_LD$LD1_sign >= 0)]
pos_positions <- circle_LD [which (circle_LD$LD1_sign >= 0), c("LD1_sign", "LD2_sign")]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

pos_positions_plot <- pos_positions
pos_positions_plot$LD1 <- pos_positions$LD1_sign - 0.025
pos_positions_plot$LD2 <- pos_positions$LD2_sign + 0.02

neg_positions_plot <- neg_positions
neg_positions_plot$LD1 <- neg_positions$LD1_sign #- 0.01
neg_positions_plot$LD2 <- neg_positions$LD2_sign + 0.05

circle_LD$Annotation <- circle_LD$Annotation.x

## Plotting by type of behavioral annotation
circle_plot_annotation_merged$Annotation
p_circle_plot_by_gr <- ggplot(circle_LD) + 
  geom_segment (data=circle_LD, aes(colour=Annotation, x=0, y=0, xend=LD1_sign, yend=LD2_sign), 
                arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
#   scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=floor(min(lda2plot$lda.LD1)):ceiling(max(lda2plot$lda.LD1))) + 
#   scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=floor(min(lda2plot$lda.LD2)):ceiling(max(lda2plot$lda.LD2))) +
    scale_x_continuous(limits=c(-0.5, 0.5), breaks=(c(-1,0,1))) +
    scale_y_continuous(limits=c(-0, 0.5), breaks=(c(-1,0,1))) +
  #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  scale_color_manual(values = cb_palette_adapt) +
  geom_text (data=neg_positions_plot, aes (x=LD1_sign, y=LD2_sign, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
  geom_text (data=pos_positions_plot, aes (x=LD1_sign, y=LD2_sign, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
  #   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
  guides(color=guide_legend(guide_legend(title = "Annotation"))) +
  theme (legend.key = element_blank())

p_circle_plot_by_gr
# 
# # merging with annotation tbl
# circle_plot_annotation_merged <- merge (circle_plot, reinst_annotation, by.x= "var", by.y = "tbl_name")
# labels_v <- circle_plot_annotation_merged$Variable
# neg_labels <- labels_v [which (circle_plot_annotation_merged$LD1 < 0)]
# neg_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 < 0), c("LD1", "LD2")]
# 
# pos_labels <- labels_v [which (circle_plot_annotation_merged$LD1 >= 0)]
# pos_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 >= 0), c("LD1", "LD2")]
# 
# angle <- seq(-pi, pi, length = 50)
# df.circle <- data.frame(x = sin(angle), y = cos(angle))
# 
# pos_positions_plot <- pos_positions
# pos_positions_plot$LD1 <- pos_positions$LD1 - 0.025
# pos_positions_plot$LD2 <- pos_positions$LD2 + 0.02
# 
# neg_positions_plot <- neg_positions
# neg_positions_plot$LD1 <- neg_positions$LD1 #- 0.01
# neg_positions_plot$LD2 <- neg_positions$LD2 + 0.05
# 
# ## Plotting by type of behavioral annotation
# circle_plot_annotation_merged$Annotation
# p_circle_plot_by_gr <- ggplot(circle_plot_annotation_merged) + 
#   geom_segment (data=circle_plot_annotation_merged, aes(colour=Annotation, x=0, y=0, xend=LD1, yend=LD2), 
#                 arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
#   scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=floor(min(lda2plot$lda.LD1)):ceiling(max(lda2plot$lda.LD1))) + 
#   scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=floor(min(lda2plot$lda.LD2)):ceiling(max(lda2plot$lda.LD2))) +
#   #   scale_x_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
#   #   scale_y_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
#   #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
#   scale_color_manual(values = cb_palette_adapt) +
#   geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
#   geom_text (data=pos_positions_plot, aes (x=LD1, y=LD2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
#   geom_vline (xintercept = 0, linetype="dotted") +
#   geom_hline (yintercept=0, linetype="dotted") +
#   labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
#         y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
#   #   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
#   guides(color=guide_legend(guide_legend(title = "Annotation"))) +
#   theme (legend.key = element_blank())
# 
# #   theme (legend.text=element_text(size=18), legend.key = element_blank(), 
# #          legend.title=element_text(size=20))                       
# 
# p_circle_plot_by_gr
# 
# p_circle_plot_by_gr_coord_fixed <- p_circle_plot_by_gr + coord_fixed() + theme(legend.key = element_blank(), 
#                                                                                legend.title = element_blank())
# 
# panel_lda_reins <- ggdraw() + draw_plot (lda_reinstatement.pc1.pc2_leg_in, 0, .5, 0.5, .5) +
#   draw_plot (p_circle_points_leg_coord_fixed_leg_in, 0.5, 0.5, 0.5, 0.5) +
#   draw_plot (bars_plot_PC1_panel, 0, 0, 0.5, .5) +
#   draw_plot (bars_plot_PC2_panel, 0.5, 0, 0.5, .5) +
#   draw_plot_label(c("A", "B", "C", "D"), c(0, 0.5, 0, 0.5), c(1, 1, 0.5, 0.5), size = size_titles)
# 
# panel_lda_reins
# 
# 



# This way the figure is ok
# if i save it manually
# size 1100, 700
img_format=".tiff"
dpi_q = 300
ggsave (panel_pca_reins, file=paste(home, dir_plots, "panel_PCA_reinst", tag_file, img_format, sep=""), 
        dpi=dpi_q, width=16, height=12)

# stop("Execution finished correctly")


























# normalize to unit vector (scalar 1)
unit_vector <- function(x) {x / sqrt(sum(x^2))}

circle_plot <- as.data.frame (res_lda$scaling)
circle_plot$ori_LD1 <- circle_plot$LD1
circle_plot$ori_LD2 <- circle_plot$LD2
circle_plot$LD1 <- unit_vector(circle_plot$LD1)
circle_plot$LD2 <- unit_vector(circle_plot$LD2)

circle_plot$var <- rownames (circle_plot)
class(df.bars_to_plot_PC2$V1)
circle_LD <- merge (df.bars_to_plot, df.bars_to_plot_PC2, by.x= "Variable", by.y = "Variable")

circle_LD$sum_percentage <- as.numeric(circle_LD$V1.x) + as.numeric(circle_LD$V1.y)
perc_df <-  subset (circle_LD , select=c("Variable","sum_percentage", "V2.y"))

merged<-merge (perc_df, circle_plot, by.x="V2.y", by.y="var")
merged$scalar <- sqrt(merged$ori_LD1^2 + merged$ori_LD2^2)
plot (merged$scalar, sqrt(merged$sum_percentage))


sqrt(sum(x^2)
     
     
     
###     GOOD ABOVE
circle_LD

circle_LD$V1.y
circle_LD
V1.x V1.y

df.bars_to_plot$value

#### AQUI El Plot utilizando como coordenadas el porcentage
df.bars_to_plot, df.bars_to_plot_PC2

df.bars_to_plot$LD1_sign <- df.bars_to_plot$value * (abs(df.bars_to_plot$value_for_sign) / df.bars_to_plot$value_for_sign)/100
df.bars_to_plot_PC2$LD2_sign <- df.bars_to_plot_PC2$value * (abs(df.bars_to_plot_PC2$value_for_sign) / df.bars_to_plot_PC2$value_for_sign)/100
circle_LD <- merge (df.bars_to_plot, df.bars_to_plot_PC2, by.x= "Variable", by.y = "Variable")

circle_LD <-  subset (circle_LD , select=c("Variable","Annotation.x", "LD1_sign", "LD2_sign"))

labels_v <- circle_LD$Variable
neg_labels <- labels_v [which (circle_LD$LD1_sign < 0)]
neg_positions <- circle_LD [which (circle_LD$LD1_sign < 0), c("LD1_sign", "LD2_sign")]

pos_labels <- labels_v [which (circle_LD$LD1_sign >= 0)]
pos_positions <- circle_LD [which (circle_LD$LD1_sign >= 0), c("LD1_sign", "LD2_sign")]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

pos_positions_plot <- pos_positions
pos_positions_plot$LD1 <- pos_positions$LD1_sign - 0.025
pos_positions_plot$LD2 <- pos_positions$LD2_sign + 0.02

neg_positions_plot <- neg_positions
neg_positions_plot$LD1 <- neg_positions$LD1_sign #- 0.01
neg_positions_plot$LD2 <- neg_positions$LD2_sign + 0.05

circle_LD$Annotation <- circle_LD$Annotation.x

## Plotting by type of behavioral annotation
circle_plot_annotation_merged$Annotation
p_circle_plot_by_gr <- ggplot(circle_LD) + 
geom_segment (data=circle_LD, aes(colour=Annotation, x=0, y=0, xend=LD1_sign, yend=LD2_sign), 
           arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
#   scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=floor(min(lda2plot$lda.LD1)):ceiling(max(lda2plot$lda.LD1))) + 
#   scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=floor(min(lda2plot$lda.LD2)):ceiling(max(lda2plot$lda.LD2))) +
# scale_x_continuous(limits=c(-0.5, 0.5), breaks=(c(-1,0,1))) +
# scale_y_continuous(limits=c(-0, 0.5), breaks=(c(-1,0,1))) +
#                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
scale_color_manual(values = cb_palette_adapt) +
geom_text (data=neg_positions_plot, aes (x=LD1_sign, y=LD2_sign, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
geom_text (data=pos_positions_plot, aes (x=LD1_sign, y=LD2_sign, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
geom_vline (xintercept = 0, linetype="dotted") +
geom_hline (yintercept=0, linetype="dotted") +
labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
   y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
#   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
guides(color=guide_legend(guide_legend(title = "Annotation"))) +
theme (legend.key = element_blank())

p_circle_plot_by_gr

# merging with annotation tbl
circle_plot_annotation_merged <- merge (circle_plot, reinst_annotation, by.x= "var", by.y = "tbl_name")
labels_v <- circle_plot_annotation_merged$Variable
neg_labels <- labels_v [which (circle_plot_annotation_merged$LD1 < 0)]
neg_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 < 0), c("LD1", "LD2")]

pos_labels <- labels_v [which (circle_plot_annotation_merged$LD1 >= 0)]
pos_positions <- circle_plot_annotation_merged [which (circle_plot_annotation_merged$LD1 >= 0), c("LD1", "LD2")]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

pos_positions_plot <- pos_positions
pos_positions_plot$LD1 <- pos_positions$LD1 - 0.025
pos_positions_plot$LD2 <- pos_positions$LD2 + 0.02

neg_positions_plot <- neg_positions
neg_positions_plot$LD1 <- neg_positions$LD1 #- 0.01
neg_positions_plot$LD2 <- neg_positions$LD2 + 0.05

## Plotting by type of behavioral annotation
circle_plot_annotation_merged$Annotation
p_circle_plot_by_gr <- ggplot(circle_plot_annotation_merged) + 
 geom_segment (data=circle_plot_annotation_merged, aes(colour=Annotation, x=0, y=0, xend=LD1, yend=LD2), 
               arrow=arrow(length=unit(0.35,"cm")), alpha=1, size=2) +
 scale_x_continuous (limits=c(floor(min(lda2plot$lda.LD1)), ceiling(max(lda2plot$lda.LD1))), breaks=floor(min(lda2plot$lda.LD1)):ceiling(max(lda2plot$lda.LD1))) + 
 scale_y_continuous (limits=c(floor(min(lda2plot$lda.LD2)), ceiling(max(lda2plot$lda.LD2))), breaks=floor(min(lda2plot$lda.LD2)):ceiling(max(lda2plot$lda.LD2))) +
 #   scale_x_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
 #   scale_y_continuous(limits=c(-1.3, 1.3), breaks=(c(-1,0,1))) +
 #                        xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
 scale_color_manual(values = cb_palette_adapt) +
 geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 
 geom_text (data=pos_positions_plot, aes (x=LD1, y=LD2, label=pos_labels, hjust=-0.3), show.legend = FALSE, size=size_text_circle) +
 geom_vline (xintercept = 0, linetype="dotted") +
 geom_hline (yintercept=0, linetype="dotted") +
 labs (title = title_var_loadings, x = paste("\nPC1 (", var_PC1, "% of between group variance)", sep=""), 
       y=paste("PC2 (", var_PC2, "% of between group variance)\n", sep = "")) +
 #   geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
 guides(color=guide_legend(guide_legend(title = "Annotation"))) +
 theme (legend.key = element_blank())

#   theme (legend.text=element_text(size=18), legend.key = element_blank(), 
#          legend.title=element_text(size=20))                       

p_circle_plot_by_gr

p_circle_plot_by_gr_coord_fixed <- p_circle_plot_by_gr + coord_fixed() + theme(legend.key = element_blank(), 
                                                                              legend.title = element_blank())

     
