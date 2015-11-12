#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Oct 2015                         ###
#############################################################################
### PCA reinstatement experiment from Rafael's lab                        ###
###                                                                       ### 
###                                                                       ###
###                                                                       ###
#############################################################################

#####################
#####################
## PCA of reinstatement matrix

# Calling libraries
# library(Hmisc)
# library(calibrate)
# library(multcomp)
library(ggplot2)
library(FactoMineR)

##Getting HOME directory 
home <- Sys.getenv("HOME") 

# Loading functions:
data_reinst <- read.csv (paste (home, "/old_data/data/Matrix 16_10_15 for CPA Reinstatement.csv", sep=""), dec=",", sep=";")
head (data_reinst)

# Adding a column with labels of the group as we want them in the plots
data_reinst$group_lab  <- gsub ("F1", "High fat", data_reinst$Group)
data_reinst$group_lab  <- gsub ("SC", "Ctrl choc", data_reinst$group_lab)
data_reinst$group_lab  <- gsub ("Cafeteria diet", "Choc", data_reinst$group_lab)
data_reinst$group_lab  <- gsub ("C1", "Ctrl high fat", data_reinst$group_lab)

data_reinst$group_lab <- factor(data_reinst$group_lab, levels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"), 
                         labels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"))

# data_reinst$X
data_reinst_filt <- subset (data_reinst, select = -c(X, group_lab))
head (data_reinst_filt)
length_tbl <- dim(data_reinst_filt) [2]
data_reinst_filt$dep_active_day1
data_reinst_filt_onlyVar <- data_reinst_filt [ , (7:length_tbl)]
res = PCA (data_reinst_filt [ , (7:length_tbl)], scale.unit=TRUE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])

# Coordinates are store here
# res$ind$coord --- rownames(res$ind$coord)
pca2plot <- as.data.frame (res$ind$coord)
pca2plot$id <- row.names(pca2plot)

# Changes labels of the groups
pca2plot$group <- data_reinst$group_lab

# # Changing labels of the group
# pca2plot$group  <- gsub ("F1", "High fat", pca2plot$group)
# pca2plot$group  <- gsub ("SC", "SC choc", pca2plot$group)
# pca2plot$group  <- gsub ("Cafeteria diet", "Choc", pca2plot$group)
# pca2plot$group  <- gsub ("C1", "SC fat", pca2plot$group)

# pca2plot$group <- factor(pca2plot$group, levels=c("SC choc", "SC fat", "Choc", "High fat"), 
                                                  labels=c("SC choc", "SC fat", "Choc", "High fat"))

pca2plot$id <- data_reinst$subject

pca_reinstatement <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
                           geom_point (size = 3.5, show_guide = T) + 
                           scale_color_manual(values=c("orange", "red", "magenta", "blue")) +
                          #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
                           geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
                           theme(legend.key=element_rect(fill=NA)) +
                           labs(title = "PCA reinstatement raw data\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                                y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                          #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
                           guides(colour = guide_legend(override.aes = list(size = 3)))+
                           theme(legend.key=element_rect(fill=NA))

pca_reinstatement

# keeping aspect ratio
pca_reinstatement_aspect_ratio <- pca_reinstatement + coord_fixed()
+ 
  scale_x_continuous (limits=c(-4, 5), breaks=-4:5) + 
  scale_y_continuous (limits=c(-2, 3), breaks=-2:3)

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

# # Plotting the variables by experimental phase
# circle_plot$var <- rownames (circle_plot)
# 
# circle_plot$var <- gsub ("day", "", circle_plot$var)
# circle_plot$var <- gsub ("inactive", "inact", circle_plot$var)
# circle_plot$var <- gsub ("active", "act", circle_plot$var)
# circle_plot$var <- gsub ("Prog_ratio", "PR", circle_plot$var)
# 
# circle_plot$varGroup <- circle_plot$var
# circle_plot$varGroup [grep("^dep_act", circle_plot$var)] <- "dep_act"
# circle_plot$varGroup [grep("^dep_inact", circle_plot$var)] <- "dep_in"
# circle_plot$varGroup [grep("^adlib_act", circle_plot$var)] <- "adlib_act"
# circle_plot$varGroup [grep("^adlib_inact", circle_plot$var)] <- "adlib_in"
# circle_plot$varGroup [grep("^ex_act", circle_plot$var)] <- "ex_act"
# circle_plot$varGroup [grep("^ex_inact", circle_plot$var)] <- "ex_inact"
# circle_plot$varGroup [c(81:length(circle_plot$varGroup))] <- "others"
as.factor(circle_plot$varGroup)
colnames (circle_plot) <- c("Dim.1", "Dim.2", "Dim.3", "Dim.4", "Dim.5", "var", "varGroup")

# I only need the nummber of session for each of them
circle_plot$session <- gsub("^dep_act_", "", circle_plot$var) 
circle_plot$session <- gsub("^dep_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_act_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_act_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_inact_", "", circle_plot$session)



p_var_by_group <- ggplot(circle_plot) + 
                         xlim (c(-0.6, 1)) + ylim (c(-0.5, 1)) +
#                          geom_point (aes (x=Dim.1, y=Dim.2), show_guide = FALSE, size=2) +
                         geom_text (aes (x=Dim.1, y=Dim.2, label=session), show_guide = FALSE, size=5) +
                         facet_wrap(~varGroup)
p_var_by_group

# Poner solo los numeros de la sesion

+ 
  geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=5) +
  geom_vline (xintercept = 0, linetype="dotted") +
  geom_hline (yintercept=0, linetype="dotted") +
  labs (title = "PCA of the variables\n", x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  #        geom_polygon(aes(x, y), data = df, inherit.aes = F, Fill=NA)
  #                         scale_x_continuous(breaks=1:10)  
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)



facet_wrap(~Q) + 














###########################
###########################
# CA of reinstatement data

library(FactoMineR)
ca_res <- CA (data_reinst_filt_onlyVar, graph=F)
plot (ca_res)

# Individuals
ca2plot_row <- as.data.frame (ca_res$row$coord)
ca2plot_row$id <-  rownames (ca_res$row$coord)
ca2plot_row$group <- data_reinst$group_lab
colnames (ca2plot_row) <- c("Dim.1", "Dim.2", "Dim.3", "Dim.4", "Dim.5", "id", "group")

# Variables
ca2plot_col <- as.data.frame (ca_res$col$coord)
ca2plot_col$var <-  rownames (ca_res$col$coord)
ca2plot_col$var <- gsub ("day", "", ca2plot_col$var)
ca2plot_col$var <- gsub ("inactive", "inact", ca2plot_col$var)
ca2plot_col$var <- gsub ("active", "act", ca2plot_col$var)
ca2plot_col$var <- gsub ("Prog_ratio", "PR", ca2plot_col$var)

ca2plot_col$varGroup <- ca2plot_col$var
ca2plot_col$varGroup [grep("^dep_act", ca2plot_col$var)] <- "dep_act"
ca2plot_col$varGroup [grep("^dep_inact", ca2plot_col$var)] <- "dep_in"
ca2plot_col$varGroup [grep("^adlib_act", ca2plot_col$var)] <- "adlib_act"
ca2plot_col$varGroup [grep("^adlib_inact", ca2plot_col$var)] <- "adlib_in"
ca2plot_col$varGroup [grep("^ex_act", ca2plot_col$var)] <- "ex_act"
ca2plot_col$varGroup [grep("^ex_inact", ca2plot_col$var)] <- "ex_inact"
ca2plot_col$varGroup [c(81:length(ca2plot_col$varGroup))] <- "others"
as.factor(ca2plot_col$varGroup)
colnames (ca2plot_col) <- c("Dim.1", "Dim.2", "Dim.3", "Dim.4", "Dim.5", "var", "varGroup")

# Variance of Dim,1 and Dim.2
var_dim1 <- round (ca_res$eig [1,2])
var_dim2 <- round (ca_res$eig [2,2])

# Only the individuals
ca_reinstatement <- ggplot (ca2plot_row, aes(x=Dim.1, y=Dim.2, colour=group)) + 
  geom_point (size = 3.5, show_guide = T) + 
#   scale_color_manual(values=c("red", "orange","blue" , "magenta")) +
  #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F) +
  theme(legend.key=element_rect(fill=NA)) +
  labs(title = "CA reinstatement raw data:\nIndividuals and variables\n", x = paste("\nDim 1 (", var_dim1, "% of variance)", sep=""), 
       y=paste("Dim 2 (", var_dim2, "% of variance)\n", sep = "")) +
  #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
  guides(colour = guide_legend(override.aes = list(size = 3), title="Group"))+
  theme(legend.key=element_rect(fill=NA)) 

ca_reinstatement_ind <- ca_reinstatement + scale_color_manual(values=c("orange", "red", "magenta", "blue")) 
ca_reinstatement_ind 

# The individuals and the variables at the same time
ca_reinstatement_ind_var <- ca_reinstatement + geom_point (data=ca2plot_col, aes(x=Dim.1, y=Dim.2), colour="black", shape=17) +
  geom_text (data=ca2plot_col, aes(x=Dim.1, y=Dim.2, label=var, colour=varGroup)) +
  scale_color_manual(values=c("orange", "red", "magenta", "blue", "black", "green", "yellow", "gray", "pink", "brown", "cyan")) 

ca_reinstatement_ind_var

# Plot of only the variables
ca_reinstatement_var <- ggplot (ca2plot_col, aes(x=Dim.1, y=Dim.2, colour=varGroup)) + 
  geom_point (size = 3.5, show_guide = T) + 
  scale_color_manual(values=c("red", "orange", "darkblue" , "magenta", "black", "darkgreen", "cyan")) +
  geom_text (aes(label=var), vjust=-0.5, hjust=1, size=5, show_guide = F) +
  theme(legend.key=element_rect(fill=NA)) +
  labs(title = "CA reinstatement raw data:\nVariables\n", x = paste("\nDim 1 (", var_dim1, "% of variance)", sep=""), 
       y=paste("Dim 2 (", var_dim2, "% of variance)\n", sep = "")) +
  #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
  guides(colour = guide_legend(override.aes = list(size = 3), title="Group"))+
  theme(legend.key=element_rect(fill=NA)) 

ca_reinstatement_var

# Agrupar las sessiones de cada tipo y entonces ponerles el color por sesion

# ca_reinstatement
