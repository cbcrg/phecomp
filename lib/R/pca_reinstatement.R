#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Oct 2015                         ###
#############################################################################
### PCA reinstatement                                                     ###
###     ### 
###                  ###
###                                                                       ###
#############################################################################

# Calling libraries
library(Hmisc)
library(calibrate)
library(multcomp)
library(ggplot2)
library(FactoMineR)

##Getting HOME directory
home <- Sys.getenv("HOME") 

# Loading functions:
source (paste (home, "/git/mwm/lib/R/plot_param_public.R", sep=""))

data_reinst <- read.csv(paste (home, "/old_data/compulse_analysis/MealPattern_HFD_Choc_CMchannel.csv", sep=""),  dec=",", sep=";")
head (data_reinst)

length_data <-dim(data_reinst)[2]
reinst2PCA <- data_reinst [4: length_data]
reinst2PCA <- subset(reinst2PCA, select=-c(Reliability....))
head (reinst2PCA)

rownames (reinst2PCA) <- paste (data_reinst[,1], data_reinst[,3], sep="_")
class(reinst2PCA$Meal.Number)
res = PCA(reinst2PCA, scale.unit=TRUE) 

# summary_resPCA<- summary(res)

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

#####################
#####################
## PCA of reinstatement matrix

##Getting HOME directory
home <- Sys.getenv("HOME") 

# Loading functions:
data_reinst <- read.csv (paste (home, "/old_data/data/Matrix 16_10_15 for CPA Reinstatement.csv", sep=""), dec=",", sep=";")
head (data_reinst)

# data_reinst$X
data_reinst_filt <- subset (data_reinst, select = -c(X))
head (data_reinst_filt)
length_tbl <- dim(data_reinst_filt) [2]
data_reinst_filt$dep_active_day1
res = PCA (data_reinst_filt [ , (7:length_tbl)], scale.unit=TRUE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])

# Coordinates are store here
# res$ind$coord --- rownames(res$ind$coord)
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id <- row.names(pca2plot)

# Changes labels of the groups
pca2plot$group <- data_reinst_filt$Group

# Changing labels of the group
pca2plot$group  <- gsub ("F1", "High fat", pca2plot$group)
pca2plot$group  <- gsub ("SC", "SC choc", pca2plot$group)
pca2plot$group  <- gsub ("Cafeteria diet", "Choc", pca2plot$group)
pca2plot$group  <- gsub ("C1", "SC fat", pca2plot$group)

pca2plot$group <- factor(pca2plot$group, levels=c("SC choc", "SC fat", "Choc", "High fat"), 
                                                  labels=c("SC choc", "SC fat", "Choc", "High fat"))

pca_medians_rev <- ggplot (pca2plot, aes(x=-Dim.1, y=-Dim.2, colour=group)) + 
                           geom_point (size = 3.5, show_guide = T) + 
                           scale_color_manual(values=c("red", "orange","blue" , "magenta")) +
                          #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
                        #   geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = F)+
                           theme(legend.key=element_rect(fill=NA)) +
                           labs(title = "PCA of group medians\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                                y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                          #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
                           guides(colour = guide_legend(override.aes = list(size = 3)))+
                           theme(legend.key=element_rect(fill=NA))

pca_medians_rev

###############
### Circle Plot
circle_plot <- as.data.frame (res$var$coord)
labels_v <- row.names(res$var$coord)
which (circle_plot$Dim.1 < 0)

neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2)]

# change positions for labels
# neg_positions [2,2] <- neg_positions [2,2] - 0.03 
# neg_positions [3,2] <- neg_positions [3,2] + 0
# neg_positions [4,2] <- neg_positions [4,2] - 0.02

pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2)]

angle <- seq(-pi, pi, length = 50)
df.circle <- data.frame(x = sin(angle), y = cos(angle))

#aes(x=PC1, y=PC2, colour=gentreat )) 
p_circle_plot <- ggplot(circle_plot) + 
                 geom_segment (data=circle_plot, aes(x=0, y=0, xend=Dim.1, yend=Dim.2), arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1, color="red") +
                 xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
#                  geom_text (data=circle_plot, aes (x=Dim.1, y=Dim.2, label=labels_v, hjust=1.2), show_guide = FALSE, size=5) + 
                 geom_text (data=neg_positions, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show_guide = FALSE, size=5) + 
                 geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=5) +
                 geom_vline (xintercept = 0, linetype="dotted") +
                 geom_hline (yintercept=0, linetype="dotted") +
                 labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                       y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                 #        geom_polygon(aes(x, y), data = df, inherit.aes = F, Fill=NA)
                 #                         scale_x_continuous(breaks=1:10)  
                 geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)

base_size <- 10
p_circle_plot
dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
                                axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
                                plot.title = element_text (size=base_size * 2, face="bold"))

p_circle_plot