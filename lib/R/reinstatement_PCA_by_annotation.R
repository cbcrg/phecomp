#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Jan 2016                         ###
#############################################################################
### PCA reinstatement experiment from Rafael's lab                        ###
### Phases of the experiment labeled following discussion on 27th Jan     ### 
### meting                                                                ###
###                                                                       ###
#############################################################################

library (plyr)
library(FactoMineR)
library(ggplot2)
library(Hmisc) # arrow function

# Loading functions:
source (paste (home, "/git/mwm/lib/R/plot_param_public.R", sep=""))

##Getting HOME directory 
home <- Sys.getenv("HOME")
# Dropbox (CRG)/2015_reinstatement_rafa/data/tbl_phases_coloured2R.csv
data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/tbl_phases_coloured2R.csv", sep=""), dec=",", sep=";")
reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_annotation.csv", sep=""), dec=",", sep=";")

head (data_reinst)
head (reinst_annotation)

# Shaping data for PCA
# I keep id and groups and
# filter out all the columns that are not in the annotation tbl
col <- as.character(reinst_annotation$Session)
data_reinst_filt <- subset (data_reinst, select=col)

# data_reinst_filt <- cbind (data_reinst_means, subset (data_reinst, select=col))

# Mejor asi porque tengo la anotacion
ext_by_annotation_t <- ddply(reinst_annotation, c("Annotation"), function(x) { 
  rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
})

ext_by_annotation_t

class(ext_by_annotation_t[,28])

# Drop first column with labels:
ext_by_annotation_t_no_lab <- ext_by_annotation_t [,-1]
ext_by_annotation <- as.data.frame(t(ext_by_annotation_t_no_lab), stringsAsFactors=FALSE)
class(ext_by_annotation[,1])
colnames(ext_by_annotation) <- ext_by_annotation_t$Annotation

# Adding a column with labels of the group as we want them in the plots
data_reinst_means <- subset(data_reinst, select = c("subject"))

data_reinst_means$group_lab  <- gsub ("F1", "High fat", data_reinst$Group)
data_reinst_means$group_lab  <- gsub ("SC", "Ctrl choc", data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("Cafeteria diet", "Choc", data_reinst_means$group_lab)
data_reinst_means$group_lab  <- gsub ("C1", "Ctrl high fat", data_reinst_means$group_lab)

cbind (data_reinst_means, ext_by_annotation)

res = PCA(ext_by_annotation, scale.unit=TRUE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])
var_PC3 <- round (res$eig [3,2])

# Coordinates are store here
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id <- data_reinst_means$subject
pca2plot$group <- data_reinst_means$group_lab

title_p <- paste ("PCA reinstatement - ", "annotated\n", sep="")
pca_reinstatement <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
                             geom_point (size = 3.5, show_guide = T) + 
                             scale_color_manual(values=c("orange", "red", "lightblue", "blue")) +
                             geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
                             theme(legend.key=element_rect(fill=NA)) +
                             scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
                             scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
                             labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                                  y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                             guides(colour = guide_legend(override.aes = list(size = 3)))+
                             theme(legend.key=element_rect(fill=NA))

pca_reinstatement

# keeping aspect ratio
pca_reinstatement_aspect_ratio <- pca_reinstatement + coord_fixed()

pca_reinstatement_aspect_ratio

# ggsave (pca_reinstatement_bin_aspect_ratio, file=paste(home, "/old_data/figures/", 
#                                                        "PCA_",  tag, "Phase.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

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

#aes(x=PC1, y=PC2, colour=gentreat )) 
p_circle_plot <- ggplot(circle_plot) + 
                 geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
                 arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, color="red") +
                 xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
                 geom_text (data=neg_positions, aes (x=Dim.1 + 0.1, y=Dim.2 + 0.1, label=neg_labels, hjust=1.2), show_guide = FALSE, size=5) + 
                 geom_text (data=pos_positions, aes (x=Dim.1-0.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=5) +
                 geom_vline (xintercept = 0, linetype="dotted") +
                 geom_hline (yintercept=0, linetype="dotted") +
                 labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                 y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                 geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)

base_size <- 10
p_circle_plot

dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
                                axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
                                plot.title = element_text (size=base_size * 2, face="bold"))

p_circle_plot

# ggsave (p_circle_plot, , file=paste(home, "/old_data/figures/","circle_",  tag, "Phase.tiff", sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

# Plotting the variables by experimental phase

############
# Doing a circle plot with arrows coloured by experimental phase

n_v_colours <- c("red", "magenta", "darkgreen", "black", "blue", "orange", "lightblue", "gray", "pink", "darkblue", "lightgreen")

# # Adding session to the circle_plot df to plot them
# labels_v <- row.names(res$var$coord)
# neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
# neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2,6,7)]
# 
# pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
# pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2,6,7)]

# -0.003580923   ad_inact_1_5
# -0.036285400  ad_inact_6_10
# 0.015524024   ex_inact_1_5
# 0.019560799 ex_inact_16_20
# ex_inact_11_15

# change label position for labels
pos_positions [11,2] <- pos_positions [11,2] + 0.05
pos_positions [12,2] <- pos_positions [12,2] + 0.05 
pos_positions [9,2] <- pos_positions [9,2] + 0.01 
# neg_positions [3,2] <- neg_positions [3,2] + 0
# neg_positions [4,2] <- neg_positions [4,2] - 0.02


title_c <- paste ("PCA of the variables - ",phase, " phases\n", sep="")
p_circle_plot_colors_bin <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(colour=session, x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1) +
  scale_color_manual (values = n_v_colours ) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (data=neg_positions, aes (x=Dim.1, y=Dim.2, label=var, hjust=0.9, vjust=-0.4), 
             show_guide = FALSE, size=5.5) + 
  geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=var, hjust=-0.2), 
             show_guide = FALSE, size=5.5) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = title_c, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1) +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), 
         legend.title=element_blank()) 
base_size <- 10

dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
                                axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
                                plot.title = element_text (size=base_size * 2, face="bold"))
p_circle_plot_colors_bin_coord <- p_circle_plot_colors_bin + coord_fixed()
p_circle_plot_colors_bin_coord

# ggsave (p_circle_plot_colors_bin_coord, file=paste(home, "/old_data/figures/", "circle_color_act_", tag, "Phase.tiff", sep=""),          
#         width = 15, height = 15, dpi=dpi_q)

###############
##############
#############
####################################
## Same thing but without arrows
# circle_plot$hj <- rep(c(0, 1), length.out=dim(circle_plot)[1])
p_circle_points_by_group_bin <- ggplot(circle_plot) + 
#   geom_text (aes(colour=session, x=Dim.1, y=Dim.2, label=var, hjust=hj), show_guide = FALSE, size=8, vjust=-0.4) +
#   geom_point(aes(colour=session, x=Dim.1, y=Dim.2), size=4)
  geom_text (aes(x=Dim.1, y=Dim.2,label=labels_v), show_guide = FALSE, size=8, vjust=-0.4) +
  geom_point(aes(x=Dim.1, y=Dim.2), size=4)

  
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (aes(colour=session, x=Dim.1, y=Dim.2, label=var, hjust=hj), show_guide = FALSE, size=8, vjust=-0.4) +
  geom_point(aes(colour=session, x=Dim.1, y=Dim.2), size=4)+
  scale_color_manual (values = n_v_colours) +
  labs (title = title_c) +
  labs (x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of ddvariance)\n", sep = "")) +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), 
         legend.title=element_blank()) 
p_circle_points_by_group_bin
p_circle_points_by_group_bin_coord <- p_circle_points_by_group_bin + coord_fixed ()
p_circle_points_by_group_bin_coord

dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 3, face="bold"),
                                axis.title.y = element_text (size=base_size * 3, angle = 90, face="bold"),
                                plot.title = element_text (size=base_size * 3, face="bold"))

p_circle_points_by_group_bin_coord <- p_circle_points_by_group_bin_coord + theme(legend.text = element_text(size = 20))

# ggsave (p_circle_points_by_group_bin_coord , file=paste(home, "/old_data/figures/", "points_circle_",  tag, "Phase.tiff", sep=""),
#         width = 15, height = 15, dpi=dpi_q)

############
## BARPLOT
df.bars <- cbind (as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE)), names(res$var$coord[,1])[order(res$var$coord[,1]^2,decreasing=TRUE)])
df.bars_to_plot <- as.data.frame(df.bars)
df.bars_to_plot$index <- as.factor (df.bars_to_plot$V2)
# class (df.bars_to_plot$V1)
df.bars_to_plot$value <- as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE))
df.bars_to_plot$index <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value, decreasing=TRUE)])

# PC1
# Filtering only the top contributors more than 2 %
# threshold <- 2
# df.bars_to_plot <- df.bars_to_plot [df.bars_to_plot$value > threshold, ]
title_b <- paste ("Variable contribution to PC1 - ", phase, " phases\n", sep="")

bars_plot <- ggplot (data=df.bars_to_plot, aes(x=index, y=value)) + 
  ylim (c(0, 12.5)) +
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1))
bars_plot

# ggsave (bars_plot, file=paste(home, "/old_data/figures/", "bars_PC1_",  tag, "Phase.tiff", sep=""),
#         width = 15, height = 12, dpi=dpi_q)

# PC2
title_b <- paste ("Variable contribution to PC2 - ", tag, " phases\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE)), names(res$var$coord[,2])[order(res$var$coord[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)
# class (df.bars_to_plot_PC2$V1)
# df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))
df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))

# Filtering only the top contributors more than 2 %
# threshold_pc2 <- 0
# df.bars_to_plot_PC2 <- df.bars_to_plot_PC2 [df.bars_to_plot_PC2$value > threshold_pc2, ]
df.bars_to_plot_PC2$index
df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=index, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC2
# ggsave (bars_plot_PC2, file=paste(home, "/old_data/figures/", "bars_PC2_",  tag, "Phase.tiff", sep=""), 
#         width = 15, height = 12, dpi=dpi_q)

# PC3
title_b <- paste ("Variable contribution to PC3 - ", phase, " phases\n", sep="")
df.bars_PC3 <- cbind (as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE)), names(res$var$coord[,3])[order(res$var$coord[,3]^2,decreasing=TRUE)])
df.bars_to_plot_PC3 <- as.data.frame(df.bars_PC3)
df.bars_to_plot_PC3$index <- as.factor (df.bars_to_plot_PC3$V2)
df.bars_to_plot_PC3$value <- as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE))

# Filtering only the top contributors more than 2 %
# threshold_pc3 <- 2
# df.bars_to_plot_PC3 <- df.bars_to_plot_PC3 [df.bars_to_plot_PC3$value > threshold_pc3, ]
df.bars_to_plot_PC3$index
df.bars_to_plot_PC3$index <- factor(df.bars_to_plot_PC3$index, levels = df.bars_to_plot_PC3$index[order(df.bars_to_plot_PC3$value, decreasing=TRUE)])

# Variability explained by PC3
var_PC3

bars_plot_PC3 <- ggplot (data=df.bars_to_plot_PC3, aes(x=index, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC3

# ggsave (bars_plot_PC3, file=paste(home, "/old_data/figures/", "bars_PC3_",  tag, "Phase.tiff", sep=""), 
#         width = 15, height = 12, dpi=dpi_q)











#########################
##########################
#########################
# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])

# Coordinates are store here
# res$ind$coord --- rownames(res$ind$coord)
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id_group <- row.names(pca2plot)

library(stringr)
pca2plot$id <- as.factor(str_split_fixed(pca2plot$id_group, "_", 2)[,1])
pca2plot$group <- as.factor(str_split_fixed(pca2plot$id_group, "_", 2)[,2])
pca2plot$group_year <- as.factor(paste (data_reinst$Group, data_reinst$Experiment, sep="_"))
# pca2plot$days <-  as.factor(as.numeric (gsub(".*([0-9]+)$", "\\1", pca2plot$gen_day)))
# pca2plot$gentreat <-  as.factor(gsub("([A-Z]+).*$", "\\1", pca2plot$gen_day))

# pca2plot$gentreat <- factor(pca2plot$gentreat , levels=c("WT", "TS", "WTEE", "TSEE", "WTEGCG", "TSEGCG", "WTEEEGCG", "TSEEEGCG"), 
labels=c("WT", "TS", "WTEE", "TSEE", "WTEGCG", "TSEGCG", "WTEEEGCG", "TSEEEGCG"))

pca_medians_rev <- ggplot(pca2plot, aes(x=-Dim.1, y=-Dim.2, colour=group_year)) + geom_point(size=4) +
  scale_color_manual(values=c("red", "orange","blue" , "magenta")) +
  labs(title = "PCA of group medians\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC2 (", var_PC2, "% of variance)\n", sep = ""))
pca_medians_rev
+ 
  #                           geom_path (size = 1,show_guide = T) + 
  #   geom_path (size = 1,show_guide = F) + 
  #   scale_color_manual(values=c("red", "darkgreen", "blue", "lightblue", 
  #                               "magenta", "orange", "gray", "black")) +
  #   #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
  #   geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = F)+
  #   theme(legend.key=element_rect(fill=NA)) +
  #   labs(title = "PCA of group medians\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
  #        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  #   #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
  #   guides(colour = guide_legend(override.aes = list(size = 1)))+
#   theme(legend.key=element_rect(fill=NA))

#PLOT_paper
pca_medians_rev





############
# DRAFTS
############
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