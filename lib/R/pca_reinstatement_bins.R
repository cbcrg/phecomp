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
# res_withPR = PCA (bin_tbl_withPR, scale.unit=TRUE)
# res <- res_withPR
# v_colours <- c("red", "magenta", "darkgreen", "black", "blue", "orange", "lightblue", "gray", "pink", "darkblue", "lightgreen")
# bin_tbl<-bin_tbl_withPR

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

# ggsave (p_circle_plot, , file=paste(home, "/old_data/figures/","circle_",  tag, "Phase.tiff", sep=""), 
#         width = 15, height = 15, dpi=dpi_q)

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

n_v_colours <- c("red", "magenta", "darkgreen", "black", "blue", "orange", "lightblue", "gray", "pink", "darkblue", "lightgreen")

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

####################################
## Same thing but without arrows
circle_plot$hj <- rep(c(0, 1), length.out=dim(circle_plot)[1])
p_circle_points_by_group_bin <- ggplot(circle_plot) + 
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

#####################
## ACTIVE vs INACTIVE
bin_tbl

bin_tbl_act <- bin_tbl[ , grepl("_act", colnames(bin_tbl)) ]
bin_tbl_inact <- bin_tbl[ , grepl("inact", colnames(bin_tbl)) ]
bin_tbl_act <- as.data.frame (bin_tbl_act)
bin_tbl_inact <- as.data.frame (bin_tbl_inact)

bin_tbl_actInactive <- cbind (bin_tbl_act, bin_tbl_inact)
mean_bin_act_inact <- rbind (colMeans(bin_tbl_act), colMeans(bin_tbl_inact))

row.names (mean_bin_act_inact) <- c ("active", "inactive")
mean_bin_act_inact_sessions <- as.data.frame (t(mean_bin_act_inact))

mean_bin_act_inact_sessions$session <- row.names(mean_bin_act_inact_sessions)

tag = "all_bin"
lim_axis_x = c(0,110)
lim_axis_y = c(0,100)
plot_act_inact_bin <- ggplot (data=mean_bin_act_inact_sessions, aes(x=active, y=inactive)) + 
                      geom_text (aes (label=session), size=6, vjust=0, hjust=-0.5, show_guide = F) +
                      geom_point (size=3) +
                      scale_x_continuous (limits=lim_axis_x) +
                      scale_y_continuous (limits=lim_axis_y) +
                      labs (title = paste("Active vs inactive ", gsub("_", " ", tag), sep=""), x = "\nactive", y = "inactive\n")

plot_act_inact_bin

# ggsave (plot_act_inact_bin, , file=paste(home, "/old_data/figures/", "active_inact_bin",  tag, "Phase.tiff", sep=""), 
#         width = 15, height = 10, dpi=dpi_q)
# 
# ggsave (plot_act_inact_bin, , file=paste(home, "/old_data/figures/", "active_inact_bin",  tag, "Phase_zoom.tiff", sep=""), 
#         width = 15, height = 10, dpi=dpi_q)

###################
# Plotting by group

bin_tbl_act$group <- data_reinst$group_lab
bin_tbl_inact$group <- data_reinst$group_lab


# data_reinst_filt_act_extinction$group <- data_reinst$group_lab_n
# data_reinst_filt_inact_extinction$group <- data_reinst$group_lab_n

length_col <- dim (bin_tbl_act)[2]
length_col <- dim (bin_tbl_inact)[2]

means_by_group_act_bin <- as.data.frame (do.call (cbind, lapply(split(bin_tbl_act[,-length_col], bin_tbl_act[,length_col]), colMeans)))
means_by_group_inact_bin <- as.data.frame (do.call (cbind, lapply(split(bin_tbl_inact[,-length_col], bin_tbl_inact[,length_col]), colMeans)))

# Add sessions
means_by_group_act_bin$session <- row.names (means_by_group_act_bin)
means_by_group_inact_bin$session  <- row.names (means_by_group_inact_bin)
means_by_group_act <- means_by_group_act_bin
means_by_group_inact <- means_by_group_inact_bin
means_by_group_act_ctrl_choc <- means_by_group_act [,c(1,5)]
means_by_group_act_ctrl_choc$group <- "Ctrl choc" 
colnames (means_by_group_act_ctrl_choc)[1] <- "mean"
means_by_group_act_choc <- means_by_group_act [,c(2,5)]
means_by_group_act_choc$group <- "Choc" 
colnames (means_by_group_act_choc)[1] <- "mean"
means_by_group_act_ctrl_high_fat <- means_by_group_act [,c(3,5)]
means_by_group_act_ctrl_high_fat$group <- "Ctrl high fat" 
colnames (means_by_group_act_ctrl_high_fat)[1] <- "mean"
means_by_group_act_high_fat <- means_by_group_act [,c(4,5)]
means_by_group_act_high_fat$group <- "High fat" 
colnames (means_by_group_act_high_fat)[1] <- "mean"
active_df <- rbind (means_by_group_act_ctrl_choc, means_by_group_act_choc, means_by_group_act_ctrl_high_fat, means_by_group_act_high_fat)

# inactiv
means_by_group_inact_ctrl_choc <- means_by_group_inact [,c(1,5)]
means_by_group_inact_ctrl_choc$group <- "Ctrl choc" 
colnames (means_by_group_inact_ctrl_choc)[1] <- "mean"
means_by_group_inact_choc <- means_by_group_inact [,c(2,5)]
means_by_group_inact_choc$group <- "Choc" 
colnames (means_by_group_inact_choc)[1] <- "mean"
means_by_group_inact_ctrl_high_fat <- means_by_group_inact [,c(3,5)]
means_by_group_inact_ctrl_high_fat$group <- "Ctrl high fat" 
colnames (means_by_group_inact_ctrl_high_fat)[1] <- "mean"
means_by_group_inact_high_fat <- means_by_group_inact [,c(4,5)]
means_by_group_inact_high_fat$group <- "High fat" 
colnames (means_by_group_inact_high_fat)[1] <- "mean"
inactive_df <- rbind (means_by_group_inact_ctrl_choc, means_by_group_inact_choc, means_by_group_inact_ctrl_high_fat, means_by_group_inact_high_fat)

tbl <- cbind (active_df, inactive_df$mean )
colnames (tbl)[1] <- "active"
colnames (tbl)[4] <- "inactive"

tbl$group <- factor(tbl$group, levels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"), 
                    labels=c("Ctrl choc", "Choc", "Ctrl high fat", "High fat"))
max (tbl$active)
max (tbl$inactive)
min (tbl$active)
min (tbl$inactive)

tag = "bin"
# lim_axis_x <- c(0,1200)
# lim_axis_y <- c(0,200)
lim_axis_x <- c(0,120)
lim_axis_y <- c(0,60)

plot_act_inact_grp <- ggplot (data=tbl, aes(x=active, y=inactive, colour=group)) + 
  geom_point (size=4) +
  geom_text (aes (label=session), size=5, vjust=0, hjust=-0.2, show_guide = F) +
#   geom_text (aes (label=session), size=5, vjust=0, hjust=0, show_guide = F) +
  labs (title = paste("Active vs inactive ", tag, sep=""), x = "\nactive", y = "inactive\n") +
  scale_color_manual (values = c("orange", "red", "lightblue", "blue")) +
  scale_x_continuous(limits = lim_axis_x) +
  scale_y_continuous(limits = lim_axis_y)  # + facet_wrap(~group)

plot_act_inact_grp <- plot_act_inact_grp + coord_fixed()

# ggsave (plot_act_inact_grp , file=paste(home, "/old_data/figures/", "active_inact_by_gr_",  title_phase, "Phase.tiff", sep=""), 
#         width = 15, height = 10, dpi=dpi_q)
# ggsave (plot_act_inact_grp , file=paste(home, "/old_data/figures/", "active_inact_by_gr_",  title_phase, "Phase_zoom.tiff", sep=""), 
#         width = 15, height = 10, dpi=dpi_q)
# ggsave (plot_act_inact_grp , file=paste(home, "/old_data/figures/", "active_inact_by_gr_",  title_phase, "Phase_labels.tiff", sep=""),
#         width = 15, height = 10, dpi=dpi_q)





