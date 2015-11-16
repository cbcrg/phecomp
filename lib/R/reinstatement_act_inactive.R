#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Nov 2015                         ###
#############################################################################
### Active inactive plots reinstatement experiment from Rafael's lab      ###
###                                                                       ### 
###                                                                       ###
###                                                                       ###
#############################################################################

# Calling libraries
library(ggplot2)

##Getting HOME directory 
home <- Sys.getenv("HOME") 

# Loading functions:
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

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
# tail (data_reinst_filt_no_summary_var)

#############################################
# Plot of active vs inactive press levers (c'est a dire correct vs incorrect)

###
# Extinction
###
###################
# Plotting all groups in the same plot

# tag
tag = "ex_"
title_phase = "extincition"
data_reinst_filt_act_extinction <- data_reinst_filt_no_summary_var[ , grepl(paste (tag, "act", sep="") , names( data_reinst_filt_no_summary_var ) ) ]
data_reinst_filt_inact_extinction <- data_reinst_filt_no_summary_var[ , grepl(paste (tag, "inact", sep=""), names( data_reinst_filt_no_summary_var ) ) ]

# Adding a column with labels of the group as we want them in the plots
data_reinst$group_lab_n  <- gsub ("F1", "High_fat", data_reinst$Group)
data_reinst$group_lab_n <- gsub ("SC", "Ctrl_choc", data_reinst$group_lab_n)
data_reinst$group_lab_n  <- gsub ("Cafeteria diet", "Choc", data_reinst$group_lab_n)
data_reinst$group_lab_n  <- gsub ("C1", "Ctrl_high_fat", data_reinst$group_lab_n)

data_reinst$group_lab_n <- factor(data_reinst$group_lab_n, levels=c("Ctrl_choc", "Choc", "Ctrl_high_fat", "High_fat"), 
                                  labels=c("Ctrl_choc", "Choc", "Ctrl_high_fat", "High_fat"))

data_reins_actInactive <- cbind (data_reinst_filt_act_extinction, data_reinst_filt_inact_extinction )

data_reins_actInactive$group <- data_reinst$group_lab
mean_cor_inc_ex <- rbind (colMeans(data_reinst_filt_act_extinction), colMeans(data_reinst_filt_inact_extinction))

row.names (mean_cor_inc_ex) <- c ("active", "inactive")
mean_cor_inc_ex_days <- as.data.frame (t(mean_cor_inc_ex))
class (mean_cor_inc_ex_days)

mean_cor_inc_ex_days$days <- gsub ("^ex_active_day", "", row.names(mean_cor_inc_ex_days))

plot_act_inact_all <- ggplot (data=mean_cor_inc_ex_days, aes(x=active, y=inactive)) + 
  geom_point (size=3) + labs (title = paste("Active vs inactive ", title_phase, "\n", sep=""), 
                        x = "\nactive", y = "inactive\n") +
  scale_x_continuous (limits=c(0, 60)) +
  scale_y_continuous (limits=c(0, 60))

plot_act_inact_all
# ggsave (plot_act_inact_all, , file=paste(home, "/old_data/figures/", 
#                                          "active_inact_",  title_phase, "Phase.tiff", sep=""), width = 15, height = 10, dpi=300)

###################
# Plotting by group

data_reinst_filt_act_extinction$group <- data_reinst$group_lab_n
data_reinst_filt_inact_extinction$group <- data_reinst$group_lab_n

length_col <- dim (data_reinst_filt_act_extinction)[2]
length_col <- dim (data_reinst_filt_inact_extinction)[2]

means_by_group_act <- as.data.frame (do.call (cbind, lapply(split(data_reinst_filt_act_extinction[,-length_col], data_reinst_filt_act_extinction[,length_col]), colMeans)))
means_by_group_inact <- as.data.frame (do.call (cbind, lapply(split(data_reinst_filt_inact_extinction[,-length_col], data_reinst_filt_inact_extinction[,length_col]), colMeans)))

means_by_group_act$days <- gsub("^ex_active_day", "", row.names(means_by_group_act))
means_by_group_inact$days <- gsub("^ex_inactive_day", "", row.names(means_by_group_inact))

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

plot_act_inact_grp <- ggplot (data=tbl, aes(x=active, y=inactive, colour=group)) + 
  geom_point (size=3) +
  labs (title = paste("Active vs inactive ", title_phase, sep=""), x = "\nactive", y = "inactive\n") +
  scale_color_manual (values = c("orange", "red", "lightblue", "blue")) +
  scale_x_continuous(limits=c(0, 60)) +
  scale_y_continuous(limits=c(0, 60)) +
  facet_wrap(~group)

plot_act_inact_grp
# ggsave (plot_act_inact_grp, , file=paste(home, "/old_data/figures/", 
#                                          "active_inact_by_gr_",  title_phase, "Phase.tiff", sep=""), width = 15, height = 10, dpi=300)

