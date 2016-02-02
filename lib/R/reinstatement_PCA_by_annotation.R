#!/usr/bin/env Rscript

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

##Getting HOME directory 
home <- Sys.getenv("HOME")

## Dumping figures folder
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session/all_animals/"
# dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session/free_choice/"
dir_plots <- "/Dropbox (CRG)/2015_reinstatement_rafa/figures/annotated_session/HF/"

# Loading functions:
source (paste (home, "/git/mwm/lib/R/plot_param_public.R", sep=""))

# Parameter to set plot qualities
dpi_q <- 50

data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/tbl_phases_coloured2R.csv", sep=""), dec=",", sep=";")
reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_annotation.csv", sep=""), dec=",", sep=";")

# head (data_reinst)
# head (reinst_annotation)

color_v <- c("orange", "red", "lightblue", "blue")

# Shaping data for PCA
# I keep id and groups and
# filter out all the columns that are not in the annotation tbl
col <- as.character(reinst_annotation$Session)

## FREE CHOICE ONLY
## Filtering data to use only free choice and control animals
# data_reinst <- data_reinst [ data_reinst$Group=="SC" | data_reinst$Group=="Cafeteria diet", ]
## HIGH-FAT ONLY
data_reinst <- data_reinst [ data_reinst$Group=="C1" | data_reinst$Group=="F1", ]
color_v <- c("lightblue", "blue", "orange", "red")
####

data_reinst_filt <- subset (data_reinst, select=col)

# data_reinst_filt <- cbind (data_reinst_means, subset (data_reinst, select=col))

# Mejor asi porque tengo la anotacion
ext_by_annotation_t <- ddply(reinst_annotation, c("Annotation"), function(x) { 
  rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
})

ext_by_annotation_t

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

# cbind (data_reinst_means, ext_by_annotation)

res = PCA(ext_by_annotation, scale.unit=TRUE)

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

#############
# PC1 PC2
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc2  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
                              geom_point (size = 3.5, show_guide = T) + 
                              scale_color_manual(values=color_v) +
                              geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
                              theme(legend.key=element_rect(fill=NA)) +
                              scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
                              scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
                              labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                                   y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                              guides(colour = guide_legend(override.aes = list(size = 3)))+
                              theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc2

# keeping aspect ratio
pca_reinstatement.pc1.pc2_aspect_ratio <- pca_reinstatement.pc1.pc2 + coord_fixed()

pca_reinstatement.pc1.pc2_aspect_ratio

ggsave (pca_reinstatement.pc1.pc2_aspect_ratio, file=paste(home, dir_plots, 
                                                       "PCA_pc1_pc2_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC1 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc1.pc3  <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show_guide = T) + 
  scale_color_manual(values=color_v) +
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
  scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
  labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc1.pc3

# keeping aspect ratio
pca_reinstatement.pc1.pc3_aspect_ratio <- pca_reinstatement.pc1.pc3 + coord_fixed()

pca_reinstatement.pc1.pc3_aspect_ratio

ggsave (pca_reinstatement.pc1.pc3_aspect_ratio, file=paste(home, dir_plots, 
                                                   "PCA_pc1_pc3_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

#############
# PC2 PC3
title_p <- paste ("PCA annotated sessions reinstatement\n", sep="")
pca_reinstatement.pc2.pc3  <- ggplot (pca2plot, aes(x=Dim.2, y=Dim.3, colour=group)) + 
  geom_point (size = 3.5, show_guide = T) + 
  scale_color_manual(values=color_v) +
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
  scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
  labs(title = title_p, x = paste("\nPC2 (", var_PC2, "% of variance)", sep=""), 
       y=paste("PC3 (", var_PC3, "% of variance)\n", sep = "")) +
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement.pc2.pc3

# keeping aspect ratio
pca_reinstatement.pc2.pc3_aspect_ratio <- pca_reinstatement.pc2.pc3 + coord_fixed()

pca_reinstatement.pc2.pc3_aspect_ratio

ggsave (pca_reinstatement.pc2.pc3_aspect_ratio, file=paste(home, dir_plots, 
                                                           "PCA_pc2_pc3_annotated_sessions.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)




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

p_circle_plot <- ggplot(circle_plot) + 
                 geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
                 arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, color="red") +
                 xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
                 geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show_guide = FALSE, size=6.5) + 
                 geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=6.5) +
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

p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed()
p_circle_plot_coord_fixed

ggsave (p_circle_plot_coord_fixed, , file=paste(home, dir_plots, "circle_annotated_behavior", ".tiff", sep=""), 
        width = 15, height = 15, dpi=dpi_q)

####################################
## Same thing but without arrows
p_circle_points <- ggplot(circle_plot) + 
                   geom_text (aes(x=Dim.1, y=Dim.2,label=labels_v), show_guide = FALSE, size=7, vjust=-0.4) +
                   geom_point(aes(x=Dim.1, y=Dim.2), size=3) +
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

ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_behavior",  ".tiff", sep=""),
        width = 15, height = 15, dpi=dpi_q)

############
## BARPLOT
df.bars <- cbind (as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE)), names(res$var$coord[,1])[order(res$var$coord[,1]^2,decreasing=TRUE)])
df.bars_to_plot <- as.data.frame(df.bars)
df.bars_to_plot$index <- as.factor (df.bars_to_plot$V2)
df.bars_to_plot$value <- as.numeric(sort(res$var$coord[,1]^2/sum(res$var$coord[,1]^2)*100,decreasing=TRUE))
df.bars_to_plot$index <- factor(df.bars_to_plot$index, levels = df.bars_to_plot$index[order(df.bars_to_plot$value, decreasing=TRUE)])

# PC1
title_b <- paste ("Variable contribution to PC1\n", "Variance explained: ", var_PC1, "%\n", sep="")

bars_plot_PC1 <- ggplot (data=df.bars_to_plot, aes(x=index, y=value)) + 
  ylim (c(0, 18)) +
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1))
bars_plot_PC1

ggsave (bars_plot_PC1, file=paste(home, dir_plots, "bars_PC1", ".tiff", sep=""),
        width = 15, height = 12, dpi=dpi_q)

# PC2
title_b <- paste ("Variable contribution to PC2\n", "Variance explained: ", var_PC2, "%\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE)), names(res$var$coord[,2])[order(res$var$coord[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)
df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))

df.bars_to_plot_PC2$index
df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=index, y=value)) + 
  ylim (c(0, 30)) +
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC2
ggsave (bars_plot_PC2, file=paste(home, dir_plots, "bars_PC2", ".tiff",
        sep=""), width = 15, height = 12, dpi=dpi_q)

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
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC3
ggsave (bars_plot_PC3, file=paste(home, dir_plots, "bars_PC3", ".tiff", 
        sep=""), width = 15, height = 12, dpi=dpi_q)

#######################
#######################
#######################
# Plotting annotations by session name instead of annotation
#######################

reinst_annotation_1_1 <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinst_annotation_1to1.csv", sep=""), dec=",", sep=";")

ext_by_annotation
colnames(ext_by_annotation)

ext_by_annotation_t$Annotation
ext_by_sessions <- merge (ext_by_annotation_t, reinst_annotation_1_1 , by.x= "Annotation", by.y = "Annotation")

# Drop first column with labels:
ext_by_annotation_t_no_lab <- ext_by_annotation_t [,-1]
ext_by_annotation <- as.data.frame(t(ext_by_annotation_t_no_lab), stringsAsFactors=FALSE)
class(ext_by_annotation[,1])
ext_by_session <- ext_by_annotation
colnames(ext_by_session) <- ext_by_sessions$Session

res_session = PCA(ext_by_session, scale.unit=TRUE)

# Variance of PC1 and PC2
var_PC1 <- round (res_session$eig [1,2])
var_PC2 <- round (res_session$eig [2,2])
var_PC3 <- round (res_session$eig [3,2])

# Coordinates are store here
pca2plot_session <- as.data.frame (res_session$ind$coord)
length(pca2plot_session$Dim.1)
pca2plot_session$id <- data_reinst_means$subject
pca2plot_session$group <- data_reinst_means$group_lab

###############
### Circle Plot
circle_plot <- as.data.frame (res_session$var$coord)
labels_v <- row.names(res_session$var$coord)
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

p_circle_plot <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, color="red") +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (data=neg_positions_plot, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show_guide = FALSE, size=6.5) + 
  geom_text (data=pos_positions_plot, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=6.5) +
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

p_circle_plot_coord_fixed <- p_circle_plot + coord_fixed()
p_circle_plot_coord_fixed

ggsave (p_circle_plot_coord_fixed, , file=paste(home, dir_plots, "circle_annotated_sessions", ".tiff", sep=""), 
        width = 15, height = 15, dpi=dpi_q)

####################################
## Same thing but without arrows
p_circle_points <- ggplot(circle_plot) + 
  geom_text (aes(x=Dim.1, y=Dim.2,label=labels_v), show_guide = FALSE, size=7, vjust=-0.4) +
  geom_point(aes(x=Dim.1, y=Dim.2), size=3) +
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
ggsave (p_circle_points_leg_coord_fixed, file=paste(home, dir_plots, "points_circle_session",  ".tiff", sep=""),
        width = 15, height = 15, dpi=dpi_q)


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