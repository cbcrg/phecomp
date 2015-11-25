#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Oct 2015                         ###
#############################################################################
### PCA of the feeding behavior of reinstatement mice                     ###
###                                                                       ### 
###                                                                       ###
###                                                                       ###
#############################################################################

# TODO
# I have to analyzed the data form int2combo --> /Users/jespinosa/old_data/lib/HF_reinstatement.sh

#/Users/jespinosa/old_data/lib/HF_reinstatement.sh

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