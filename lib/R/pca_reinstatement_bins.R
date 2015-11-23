#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Nov 2015                         ###
#############################################################################
### PCA reinstatement experiment from Rafael's lab                        ###
### Binning by number of sessions, mean within this bins                  ### 
###                                                                       ###
###                                                                       ###
#############################################################################

#####################
#####################
## PCA of reinstatement matrix

# Calling libraries
library(Hmisc) # arrow function
# library(calibrate)
# library(multcomp)
library(ggplot2)
library(FactoMineR)

##Getting HOME directory 
home <- Sys.getenv("HOME") 

# Loading functions:
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

# Parameter to set plot qualities
dpi_q <- 50
data_reinst <- read.csv (paste (home, "/old_data/data/Matrix 16_10_15 for CPA Reinstatement.csv", sep=""), dec=",", sep=";")
head (data_reinst)

# I set as vector with colors for all the plots I just have to set the number of colours that I need for the plots
v_colours <- c("red", "gray", "blue", "lightblue", "magenta", "orange", "darkgreen")

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

##### Different tables depending if I want to analyze all the sessions or only one
# I get rid of the variables that are in the table that are a summary of other phases of the experiment
data_reinst_filt_no_summary_var <- subset (data_reinst_filt, select = -c(mean_last_three_days_ext, acq_3_days_active, 
                                                                         ext_3_days_active, mean.ext, X30.acq, acq_3_days_inactive,
                                                                         ext_3_days_inactive))
tail (data_reinst_filt_no_summary_var)

# Tbl with all the variables and without the columns that are factors
length_tbl <- dim(data_reinst_filt_no_summary_var) [2]
data_reinst_filt_onlyVar <-data_reinst_filt_no_summary_var [ , (7:length_tbl)]

# Choosing the table that will be use
# all phases
phase <- "bin by"
tag <- "bin_by"
data_reinst_filt <- data_reinst_filt_onlyVar

dep_act_1_5 = rowMeans(data_reinst_filt[,c(1:5)])
dep_act_6_10 = rowMeans(data_reinst_filt[,c(6:10)])
dep_inact_1_5 = rowMeans(data_reinst_filt[,c(11:15)])
dep_inact_6_10 = rowMeans(data_reinst_filt[,c(16:20)])
ad_act_1_5 = rowMeans(data_reinst_filt[,c(21:25)])
ad_act_6_10 = rowMeans(data_reinst_filt[,c(26:30)])
ad_inact_1_5 = rowMeans(data_reinst_filt[,c(31:35)])
ad_inact_6_10 = rowMeans(data_reinst_filt[,c(36:40)])
ex_act_1_5 = rowMeans(data_reinst_filt[,c(41:45)])
ex_act_6_10 = rowMeans(data_reinst_filt[,c(46:50)])
ex_act_11_15 = rowMeans(data_reinst_filt[,c(51:55)])
ex_act_16_20 = rowMeans(data_reinst_filt[,c(56:60)])
ex_inact_1_5 = rowMeans(data_reinst_filt[,c(61:65)])
ex_inact_6_10 = rowMeans(data_reinst_filt[,c(66:70)])
ex_inact_11_15 = rowMeans(data_reinst_filt[,c(71:75)])
ex_inact_16_20 = rowMeans(data_reinst_filt[,c(76:80)])

bin_tbl <- cbind (dep_act_1_5, dep_act_6_10,dep_inact_1_5 , dep_inact_6_10 , ad_act_1_5, ad_act_6_10, ad_inact_1_5, ad_inact_6_10, 
                  ex_act_1_5, ex_act_6_10, ex_act_11_15, ex_act_16_20, ex_inact_1_5, ex_inact_6_10, ex_inact_11_15, ex_inact_16_20)
       
bin_tbl_withPR <- cbind (dep_act_1_5, dep_act_6_10,dep_inact_1_5 , dep_inact_6_10 , ad_act_1_5, ad_act_6_10, ad_inact_1_5, 
                         ad_inact_6_10, ex_act_1_5, ex_act_6_10, ex_act_11_15, ex_act_16_20, ex_inact_1_5, ex_inact_6_10, ex_inact_11_15, 
                         ex_inact_16_20, data_reinst_filt[,c(81:85)])

res = PCA (bin_tbl, scale.unit=TRUE)

# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])
var_PC3 <- round (res$eig [3,2])

# Coordinates are store here
# res$ind$coord --- rownames(res$ind$coord)
pca2plot <- as.data.frame (res$ind$coord)
# pca2plot$id <- row.names(pca2plot)
pca2plot$id <- data_reinst$subject

# Changes labels of the groups
pca2plot$group <- data_reinst$group_lab


title_p <- paste ("PCA reinstatement - ", phase, " sessions\n", sep="")
pca_reinstatement_bin <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
                                 geom_point (size = 3.5, show_guide = T) + 
                                 scale_color_manual(values=c("orange", "red", "lightblue", "blue")) +
                                 #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
                                 geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
                                 theme(legend.key=element_rect(fill=NA)) +
                                 scale_x_continuous (limits=c(-4, 6), breaks=-4:6) + 
                                 scale_y_continuous (limits=c(-4, 4), breaks=-4:4) +
                                 labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
                                      y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
                                 guides(colour = guide_legend(override.aes = list(size = 3)))+
                                 theme(legend.key=element_rect(fill=NA))

pca_reinstatement_bin

# keeping aspect ratio
pca_reinstatement_bin_aspect_ratio <- pca_reinstatement_bin + coord_fixed()

pca_reinstatement_bin_aspect_ratio

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
                 geom_text (data=neg_positions, aes (x=Dim.1, y=Dim.2, label=neg_labels, hjust=1.2), show_guide = FALSE, size=5) + 
                 geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=pos_labels, hjust=-0.3), show_guide = FALSE, size=5) +
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

# ggsave (p_circle_plot, , file=paste(home, "/old_data/figures/", 
#                                     "circle_",  tag, "Phase.tiff", sep=""), width = 15, height = 15, dpi=dpi_q)

# Plotting the variables by experimental phase
circle_plot$var <- rownames (circle_plot)
circle_plot$session <- circle_plot$var

circle_plot$session [grep ("ad_act", circle_plot$session)] <- "adlib_act"
circle_plot$session [grep ("ad_in", circle_plot$session)] <- "adlib_in"
circle_plot$session [grep ("dep_act", circle_plot$session)] <- "dep_act"
circle_plot$session [grep ("dep_inact", circle_plot$session)] <- "dep_inact"
circle_plot$session [grep ("ex_act", circle_plot$session)] <- "ex_act"
circle_plot$session [grep ("ex_inact", circle_plot$session)] <- "ex_inact"

############
# Doing a circle plot with arrows coloured by experimental phase

n_v_colours <- c("red", "magenta", "darkgreen", "gray", "blue", "orange", "lightblue")

# Adding session to the circle_plot df to plot them
labels_v <- row.names(res$var$coord)
neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2,6,7)]

pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2,6,7)]

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
                                       show_guide = FALSE, size=5) + 
                            geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=var, hjust=-0.2), 
                                       show_guide = FALSE, size=5) +
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

ggsave (p_circle_plot_colors_bin_coord, file=paste(home, "/old_data/figures/", "circle_color_act_", tag, "Phase.tiff", sep=""),          
        width = 15, height = 15, dpi=dpi_q)























########@@@@@@@@@@@@@@@@@@@@@@@@@





# Binning by sessions
circle_plot$varGroup <- circle_plot$var
circle_plot$varGroup [grep("^dep_act", circle_plot$var)] <- "dep_act"
circle_plot$varGroup [grep("^dep_inact", circle_plot$var)] <- "dep_in"
circle_plot$varGroup [grep("^adlib_act", circle_plot$var)] <- "adlib_act"
circle_plot$varGroup [grep("^adlib_inact", circle_plot$var)] <- "adlib_in"
circle_plot$varGroup [grep("^ex_act", circle_plot$var)] <- "ex_act"
circle_plot$varGroup [grep("^ex_inact", circle_plot$var)] <- "ex_inact"
circle_plot$varGroup [c(81:length(circle_plot$varGroup))] <- "others"
as.factor(circle_plot$varGroup)
colnames (circle_plot) <- c("Dim.1", "Dim.2", "Dim.3", "Dim.4", "Dim.5", "var", "varGroup")

# I only need the nummber of session for each of them
circle_plot$session <- gsub("^dep_act_", "", circle_plot$var) 
circle_plot$session <- gsub("^dep_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_act_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_act_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_inact_", "", circle_plot$session)


res = PCA (data_reinst_filt, scale.unit=TRUE)

######################








# Variance of PC1 and PC2
var_PC1 <- round (res$eig [1,2])
var_PC2 <- round (res$eig [2,2])
var_PC3 <- round (res$eig [3,2])

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
#                                                   labels=c("SC choc", "SC fat", "Choc", "High fat"))

pca2plot$id <- data_reinst$subject
title_p <- paste ("PCA reinstatement - ", phase, " sessions\n", sep="")
pca_reinstatement <- ggplot (pca2plot, aes(x=Dim.1, y=Dim.2, colour=group)) + 
  geom_point (size = 3.5, show_guide = T) + 
  scale_color_manual(values=c("orange", "red", "lightblue", "blue")) +
  #                           geom_text (aes (label=days), vjust=-0.5, hjust=1, size=4, show_guide = T)+
  geom_text (aes(label=id), vjust=-0.5, hjust=1, size=4, show_guide = F)+
  theme(legend.key=element_rect(fill=NA)) +
  scale_x_continuous (limits=c(-10, 12), breaks=-10:12) + 
  scale_y_continuous (limits=c(-10, 12), breaks=-10:12) +
  labs(title = title_p, x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
       y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  #                           guides(colour = guide_legend(override.aes = list(size = 10)))+
  guides(colour = guide_legend(override.aes = list(size = 3)))+
  theme(legend.key=element_rect(fill=NA))

pca_reinstatement

# keeping aspect ratio
pca_reinstatement_aspect_ratio <- pca_reinstatement + coord_fixed()
# + 
#   scale_x_continuous (limits=c(-4, 5), breaks=-4:5) + 
#   scale_y_continuous (limits=c(-2, 3), breaks=-2:3)

pca_reinstatement_aspect_ratio

ggsave (pca_reinstatement_aspect_ratio, , file=paste(home, "/old_data/figures/", 
                                                     "PCA_",  phase, "Phase.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

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
  geom_polygon (data = df.circle, aes(x, y), alpha=1, colour="black", fill=NA, size=1)

base_size <- 10
p_circle_plot
dailyInt_theme <- theme_update (axis.title.x = element_text (size=base_size * 2, face="bold"),
                                axis.title.y = element_text (size=base_size * 2, angle = 90, face="bold"),
                                plot.title = element_text (size=base_size * 2, face="bold"))

p_circle_plot

# ggsave (p_circle_plot, , file=paste(home, "/old_data/figures/", 
#                                                      "circle_",  phase, "Phase.tiff", sep=""), width = 15, height = 10, dpi=dpi_q)

# Plotting the variables by experimental phase
circle_plot$var <- rownames (circle_plot)

circle_plot$var <- gsub ("day", "", circle_plot$var)
circle_plot$var <- gsub ("inactive", "inact", circle_plot$var)
circle_plot$var <- gsub ("active", "act", circle_plot$var)
circle_plot$var <- gsub ("Prog_ratio", "PR", circle_plot$var)

circle_plot$varGroup <- circle_plot$var
circle_plot$varGroup [grep("^dep_act", circle_plot$var)] <- "dep_act"
circle_plot$varGroup [grep("^dep_inact", circle_plot$var)] <- "dep_in"
circle_plot$varGroup [grep("^adlib_act", circle_plot$var)] <- "adlib_act"
circle_plot$varGroup [grep("^adlib_inact", circle_plot$var)] <- "adlib_in"
circle_plot$varGroup [grep("^ex_act", circle_plot$var)] <- "ex_act"
circle_plot$varGroup [grep("^ex_inact", circle_plot$var)] <- "ex_inact"
circle_plot$varGroup [c(81:length(circle_plot$varGroup))] <- "others"
as.factor(circle_plot$varGroup)
colnames (circle_plot) <- c("Dim.1", "Dim.2", "Dim.3", "Dim.4", "Dim.5", "var", "varGroup")

# I only need the nummber of session for each of them
circle_plot$session <- gsub("^dep_act_", "", circle_plot$var) 
circle_plot$session <- gsub("^dep_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_act_", "", circle_plot$session)
circle_plot$session <- gsub("^adlib_inact_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_act_", "", circle_plot$session)
circle_plot$session <- gsub("^ex_inact_", "", circle_plot$session)

############
# Doing a circle plot with arrows coloured by experimental phase

# Adding session to the circle_plot df to plot them
neg_labels <- labels_v [which (circle_plot$Dim.1 < 0)]
neg_positions <- circle_plot [which (circle_plot$Dim.1 < 0), c(1,2,8)]

pos_labels <- labels_v [which (circle_plot$Dim.1 >= 0)]
pos_positions <- circle_plot [which (circle_plot$Dim.1 >= 0), c(1,2,8)]

title_c <- paste ("PCA of the variables - ",phase, " phases\n", sep="")
p_circle_plot_colors <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(colour=varGroup, x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1) +
  scale_color_manual (values = v_colours) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (data=neg_positions, aes (x=Dim.1, y=Dim.2, label=session, hjust=0.9, vjust=-0.4), 
             show_guide = FALSE, size=5) + 
  geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=session, hjust=-0.2), 
             show_guide = FALSE, size=5) +
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
p_circle_plot_colors

ggsave (p_circle_plot_colors, 
        file=paste(home, "/old_data/figures/", 
                   "circle_color_act_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

# Colour circle plot by session 1-5 5-10 10-15 15-20
circle_plot 
circle_plot$session_bin <- "" 

circle_plot [which (as.numeric (circle_plot$session) < 6), "session_bin"] <- "1_5"
circle_plot [which (as.numeric (circle_plot$session) > 5 & as.numeric (circle_plot$session)< 11), "session_bin"] <- "6_10"
circle_plot [which (as.numeric (circle_plot$session) > 10 & as.numeric (circle_plot$session)< 16), "session_bin"] <- "11_15"
circle_plot [which (as.numeric (circle_plot$session) > 15), "session_bin"] <- "16_20"

# Plot with arrows coloured by session bin
p_circle_plot_colors_bin <- ggplot(circle_plot) + 
  geom_segment (data=circle_plot, aes(colour=session_bin, x=0, y=0, xend=Dim.1, yend=Dim.2), 
                arrow=arrow(length=unit(0.2,"cm")), alpha=1, size=1) +
  scale_color_manual (values = v_colours) +
  xlim (c(-1.2, 1.2)) + ylim (c(-1.2, 1.2)) +
  geom_text (data=neg_positions, aes (x=Dim.1, y=Dim.2, label=session, hjust=0.9, vjust=-0.4), 
             show_guide = FALSE, size=5) + 
  geom_text (data=pos_positions, aes (x=Dim.1, y=Dim.2, label=session, hjust=-0.2), 
             show_guide = FALSE, size=5) +
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
p_circle_plot_colors_bin

ggsave (p_circle_plot_colors_bin, file=paste(home, "/old_data/figures/", 
                                             "circle_color_bin_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

# Doing the same plot as above by colours but in this case facet
p_var_by_group_scale_free <- ggplot(circle_plot) + 
  labs (title = title_c, x = paste("PC1 (", var_PC1, "% of variance)", sep=""), 
        y=paste("PC2 (", var_PC2, "% of variance)", sep = "")) +
  geom_text (aes(colour=varGroup, x=Dim.1, y=Dim.2, label=session), show_guide = FALSE, size=5) +
  scale_color_manual (values = c("red", "gray", "blue", "lightblue", "magenta", "orange", "darkgreen")) +
  facet_wrap(~varGroup, scales="free")

p_var_by_group_scale_free
ggsave (p_var_by_group_scale_free, file=paste(home, "/old_data/figures/", 
                                              "points_act_facet_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

p_var_by_group <- ggplot(circle_plot) + 
  xlim (c(-1, 1)) + ylim (c(-1, 1)) +
  geom_text (aes(colour=varGroup, x=Dim.1, y=Dim.2, label=session), show_guide = FALSE, size=5, vjust=-0.4) +
  geom_point(aes(colour=varGroup, x=Dim.1, y=Dim.2), size=3)+
  scale_color_manual (values = v_colours) +
  labs (title = title_c)
labs (x = paste("\nPC1 (", var_PC1, "% of variance)", sep=""), 
      y=paste("PC2 (", var_PC2, "% of variance)\n", sep = "")) +
  theme (legend.key = element_blank(), legend.key.height = unit (1.5, "line"), 
         legend.title=element_blank()) 

p_var_by_group

ggsave (p_var_by_group, file=paste(home, "/old_data/figures/", 
                                   "points_act_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

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
threshold <- 2
df.bars_to_plot <- df.bars_to_plot [df.bars_to_plot$value > threshold, ]

title_b <- paste ("Variable contribution to PC1 - ", phase, " phases\n", sep="")

bars_plot <- ggplot (data=df.bars_to_plot, aes(x=index, y=value)) + 
  ylim (c(0, 10.5)) +
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = title_b, x = "", y="Contribution in %\n") +
  theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1) )
bars_plot

ggsave (bars_plot, file=paste(home, "/old_data/figures/", 
                              "bars_PC1_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

# PC2
title_b <- paste ("Variable contribution to PC2 - ", phase, " phases\n", sep="")
df.bars_PC2 <- cbind (as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE)), names(res$var$coord[,2])[order(res$var$coord[,2]^2,decreasing=TRUE)])
df.bars_to_plot_PC2 <- as.data.frame(df.bars_PC2)
df.bars_to_plot_PC2$index <- as.factor (df.bars_to_plot_PC2$V2)
# class (df.bars_to_plot_PC2$V1)
# df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))
df.bars_to_plot_PC2$value <- as.numeric(sort(res$var$coord[,2]^2/sum(res$var$coord[,2]^2)*100,decreasing=TRUE))

# Filtering only the top contributors more than 2 %
threshold_pc2 <- 2
df.bars_to_plot_PC2 <- df.bars_to_plot_PC2 [df.bars_to_plot_PC2$value > threshold_pc2, ]
df.bars_to_plot_PC2$index
df.bars_to_plot_PC2$index <- factor(df.bars_to_plot_PC2$index, levels = df.bars_to_plot_PC2$index[order(df.bars_to_plot_PC2$value, decreasing=TRUE)])

bars_plot_PC2 <- ggplot (data=df.bars_to_plot_PC2, aes(x=index, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = "Variable contribution to PC2\n", x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC2
ggsave (bars_plot_PC2, file=paste(home, "/old_data/figures/", 
                                  "bars_PC2_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

# PC3
title_b <- paste ("Variable contribution to PC3 - ", phase, " phases\n", sep="")
df.bars_PC3 <- cbind (as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE)), names(res$var$coord[,3])[order(res$var$coord[,3]^2,decreasing=TRUE)])
df.bars_to_plot_PC3 <- as.data.frame(df.bars_PC3)
df.bars_to_plot_PC3$index <- as.factor (df.bars_to_plot_PC3$V2)
df.bars_to_plot_PC3$value <- as.numeric(sort(res$var$coord[,3]^2/sum(res$var$coord[,3]^2)*100,decreasing=TRUE))

# Filtering only the top contributors more than 2 %
threshold_pc3 <- 2
df.bars_to_plot_PC3 <- df.bars_to_plot_PC3 [df.bars_to_plot_PC3$value > threshold_pc3, ]
df.bars_to_plot_PC3$index
df.bars_to_plot_PC3$index <- factor(df.bars_to_plot_PC3$index, levels = df.bars_to_plot_PC3$index[order(df.bars_to_plot_PC3$value, decreasing=TRUE)])

# Variability explained by PC3
var_PC3

bars_plot_PC3 <- ggplot (data=df.bars_to_plot_PC3, aes(x=index, y=value)) + 
  geom_bar (stat="identity", fill="gray", width=0.8) + 
  labs (title = "Variable contribution to PC3\n", x = "", y="Contribution in %\n") +
  theme (axis.text.x=element_text(angle=45, vjust=1, hjust=1))

bars_plot_PC3

ggsave (bars_plot_PC3, file=paste(home, "/old_data/figures/", 
                                  "bars_PC3_",  phase, "Phase.tiff", sep=""), width = 15, height = 12, dpi=dpi_q)

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

#################
# 



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

