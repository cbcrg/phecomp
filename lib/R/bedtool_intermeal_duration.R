#!/usr/bin/env Rscript

############################################################
### Jose A Espinosa. CSN/CB-CRG Group. March 2015        ###
############################################################
### Getting the behavior of mice at the beginning of each###
### new recording period (30 min) and comparing it to    ###
### 30 minutes after 24 hours (same phase of the cycle)  ###
### Number of meals                                      ###
### Coverage                                             ###
############################################################
### Calling this script in iOS:                          ###
### Rscript ./bedtool_intermeal_duration.R               ###
############################################################

##Loading libraries
library ("ggplot2")
library ("plotrix") #std.error

# Loading functions:
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

# setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h")

setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/intermeal_duration")

load_tbl_comp <- function (pattern="30min_sum") {
  print(files <- list.files(pattern=paste(pattern, ".bed$", sep="")))
  files <- list.files(pattern=paste(pattern, ".bed$", sep=""))
  group <- c()
  HF_lab <- paste ("HF", pattern,  sep="")
  ctrl_lab <- paste ("Ctrl", pattern,  sep="")
  
  pattern2grep <- paste ("_dt_food_fat_food_sc_", pattern, "\\.bed",sep="")
  group <- sapply (files, y <- function (x) {if (grepl(pattern2grep, x)) return (HF_lab) else {return (ctrl_lab)}})
  
  group_mice <- c()
  HF_lab <- "HF"
  ctrl_lab <- "Ctrl"
  group_mice <- sapply (files, y <- function (x) {if (grepl(pattern2grep, x)) return (HF_lab) else {return (ctrl_lab)}})
  
  labs<-gsub("tr_", "", files, perl=TRUE)
  labs<-gsub(paste ("_dt_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE)
  labs<-gsub(paste ("_dt_food_fat_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE)
  
  # Create lists to hold coverage and cumulative coverage for each animal group and phase,
  # and read the data into these lists.
  comp <- list()
  
  for (i in 1:length(files)) {
    comp[[i]] <- read.table(files[i])
  }
  
  comp_all <- comp[[1]]
  comp_all$id <- labs[1]
  comp_all$group <- group[1]
  comp_all$group_mice <- group_mice[1]
  comp_all$index <- c(1:length(comp_all[,1]))
  
  for (i in 2:length(comp)) {
    comp_gr <- comp[[i]] 
    comp_gr$id <- labs[i]
    comp_gr$group <- group[i]
    comp_gr$group_mice <- group_mice[i]
    comp_gr$index <- c(1:length(comp[[i]][,1]))
    comp_all<-rbind (comp_all, comp_gr)    
  }
  
  return (comp_all)
}

tag = "mean"

pattern="compl_hab_dark"

tbl_hab_dark <- load_tbl_comp(pattern)
tbl_hab_dark$phase <- "Habituation"
tbl_hab_dark$gr_dayphase <- gsub("compl_hab_","",tbl_hab_dark$group) 

pattern="compl_hab_light"
tbl_hab_light <- load_tbl_comp(pattern)
tbl_hab_light$phase <- "Habituation"
tbl_hab_light$gr_dayphase <- gsub("compl_hab_","",tbl_hab_light$group) 

pattern="compl_dev_dark"
tbl_dev_dark <- load_tbl_comp(pattern)
tbl_dev_dark$phase <- "Development"
tbl_dev_dark$gr_dayphase <- gsub("compl_dev_","",tbl_dev_dark$group) 

pattern="compl_dev_light"
tbl_dev_light <- load_tbl_comp(pattern)
tbl_dev_light$phase <- "Development"
tbl_dev_light$gr_dayphase <- gsub("compl_dev_","",tbl_dev_light$group) 

tbl_hab_dev <- rbind (tbl_hab_dark, tbl_hab_light, tbl_dev_light, tbl_dev_dark)

head (tbl_hab_dev,100)

# Calculate mean and stderror of the mean
tbl_stat_mean <-with (tbl_hab_dev, aggregate (cbind (V5), list (group=group, gr_dayphase=gr_dayphase, phase=phase), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
tbl_stat_mean

tbl_stat_mean$mean <- tbl_stat_mean$V5 [,1]
tbl_stat_mean$std.error <- tbl_stat_mean$V5 [,2]

### Plots
# Prettier colors:
# Reordering colors for showing dark periods as dark colors
col_redish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Reds"))(10)
col_greenish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Greens"))(10)
cols <- c(col_greenish[4], col_redish[4], col_greenish[10], col_redish[10], 
          col_greenish[4], col_redish[4], col_greenish[10], col_redish[10])
#cols <- c(col_greenish[c(4,7,10)], col_redish[c(4,7,10)])

# Get title and file name according with stat
var_labels<-switch(tag, 
                   sum={
                     
                     c("Accumulated intake ","accu_intake")
                   },
                   mean={
                     
#                      c("Mean intermeal length ", "mean_intermeal", "(s)\n") 
                     c("Intermeal length ", "mean_intermeal", "(s)\n") 
                   },
                   cov={
                     
                     c("Coverage ", "coverage", "(g)\n")
                   },
                   count={
                     
                     c("Number of meals ", "count", "\n")
                   },
                   max={
                     
                     c("Biggest meal ", "max", "(g)\n")
                   },
                   {
                     c("Not defined ", "not_defined", "NA")
                   }
)

title_beg <- var_labels[1]
file_name <- var_labels[2]
unit <- var_labels[3]
title_plot = paste (title_beg[1], "\n", sep="")
y_lab = paste (title_beg, unit)

# Order for plotting
#tbl_stat_mean$group2 <- factor(tbl_stat_mean$group, levels=c(paste("Ctrlcompl_hab", tag, sep=""),paste("HFcompl_hab", tag, sep=""),
#                                                             paste("Ctrlcompl_dev", tag, sep=""), paste("HFcompl_dev", tag, sep="")))

tbl_stat_mean$group2 <- factor(tbl_stat_mean$group, levels=c("Ctrlcompl_hab_light", "HFcompl_hab_light", 
                                                             "Ctrlcompl_hab_dark", "HFcompl_hab_dark", 
                                                             "Ctrlcompl_dev_light", "HFcompl_dev_light", 
                                                             "Ctrlcompl_dev_dark", "HFcompl_dev_dark"))

tbl_stat_mean$gr_dayphase <- factor(tbl_stat_mean$gr_dayphase, levels=c("Ctrllight", "HFlight", 
                                                                  "Ctrldark", "HFdark"))
                                                                  
tbl_stat_mean$phase <- factor(tbl_stat_mean$phase, levels=c("Habituation", "Development"))

# color blind friendly plots
cols_cb <- c("#FB6A4A", "#56B4E9", "#CB181D", "#0072B2")
ggplot(data=tbl_stat_mean, aes(x=phase, y=mean, fill=gr_dayphase)) + 
  geom_bar(stat="identity", position=position_dodge())+
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  #scale_x_discrete (labels=c("","")) +
  scale_y_continuous(limits=c(0, max(tbl_stat_mean$V5)+max(tbl_stat_mean$V5)/10)) +                
  labs (title = title_plot) +  
#   labs (x = "\nPhase of the experiment\n", y=y_lab, fill = NULL) +
  labs (x = "\nFeeding phase\n", y=y_lab, fill = NULL) +
  scale_fill_manual(values=cols_cb, labels=c("Ctrl light", "HF light", "Ctrl dark", "HF dark"))
                    #labels=c("Ctrl habituation light", "HF habituation light", "Ctrl habituation dark", "HF habituation dark", 
                             #"Ctrl development light", "HF development light", "Ctrl development dark", "HF development dark"))

ggsave(file=paste(file_name, "_error_bar", ".pdf", sep=""), width=10, height=8)

# Checking mean of the group of mice
tbl_stat_gr_mean <-with (tbl_hab_dev, aggregate (cbind (V5), list (group_mice=group_mice), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
tbl_stat_gr_mean

tbl_stat_gr_mean$mean <- tbl_stat_gr_mean$V5 [,1]
tbl_stat_gr_mean$std.error <- tbl_stat_gr_mean$V5 [,2]

# Prettier colors:
# Reordering colors for showing dark periods as dark colors
cols <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
cols <- c(cols[2],cols[4])
cols

ggplot(data=tbl_stat_gr_mean, aes(x=group_mice, y=mean, fill=group_mice)) + 
  geom_bar(stat="identity", position=position_dodge()) +
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  scale_y_continuous(limits=c(0,1650))+
  labs (title = "Intermeal Duration\n") +  
  labs (x = "\nGroup\n", y="Intermeal Duration (s)\n") +
  scale_fill_manual(values=cols) +
  theme(legend.title=element_blank())

ggsave(file=paste(file_name, "2groups_error_bar", ".pdf", sep=""), width=10, height=8)

stop("Execution finished correctly")

###
# Stats
## TTest

pairwise.t.test(tbl_hab_dev$V5, tbl_hab_dev$group_mice, , p.adj="bonferroni", paired=F)

# ANOVA for the 4 groups NOT FINISHED
head (tbl_hab_dev)
class(tbl_hab_dev$group)

df.anova <- within(tbl_hab_dev, {
  group <- factor(group)
  id <- factor(id)
})

demo1.aov <- aov(value ~ group * time + Error(id), data = df.anova)

demo1 <- read.csv("http://www.ats.ucla.edu/stat/data/demo1.csv")
class(demo1$time)
# df.plot$time <- as.integer(df.plot$variable)
# 
# df.plot [with(df.plot, order(id)), ]
## Convert variables to factor
df.anova <- within(df.anova, {
  group <- factor(group)
  time <- factor(variable)
  id <- factor(id)
})

df.anova
head(df.anova)
# demo1.aov <- aov(value ~ group * time + Error(id), data = df.anova)
demo1.aov <- aov(V5 ~ gr_dayphase * phase + Error(id), data = df.anova)

summary(demo1.aov)

# demo1.aov <- aov(pulse ~ group * time + Error(id), data = demo1)
# I set the interaction to perform the ttest
df.anova$interaction <- paste(df.anova$group, df.anova$time, sep="_")
pairwise.t.test(df.anova$value, df.anova$interaction, , p.adj="hochberg", paired=F)

# POST-hoc test
# for group
with (df.anova, pairwise.t.test (V5, group,  p.adjust.method="bonf"))

############################
# Original developing of the script
setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/intermeal_duration/data")

print(files_ctrl <- list.files(pattern="Ctrl.compl$"))

intermeal_ctrl <- data.frame()

for (i in 1:length(files_ctrl)) {
  tbl<-read.table(files_ctrl[i])
  #   tbl$id <- files_ctrl[i]
  tbl$id <- gsub("tr_|_dt_food_sc\\.bed\\.Ctrl\\.compl", "", files_ctrl[i], perl=TRUE)
  intermeal_ctrl <- rbind(intermeal_ctrl, tbl)
}

intermeal_ctrl$group <- "Ctrl"

print(files_HF <- list.files(pattern="HF.compl$"))

intermeal_HF <- data.frame()

for (i in 1:length(files_HF)) {
  tbl<-read.table(files_HF[i])
  #   tbl$id <- files_HF[i]
  tbl$id <- gsub("tr_|_dt_food_fat_food_sc\\.bed\\.HF\\.compl", "", files_HF[i], perl=TRUE)
  intermeal_HF <- rbind(intermeal_HF, tbl)
}

intermeal_HF$group <- "HF"

intermeal <- rbind(intermeal_ctrl, intermeal_HF)
tail (intermeal[intermeal$id==11,],100)


# with (intermeal , aggregate (cbind (V4), list (id=id, group=group), FUN=function (x) c (mean=mean(x))))
intermeal_mean <-with (intermeal , aggregate (cbind (V4), list (group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
intermeal_mean$mean <- intermeal_mean$V4 [,1]
intermeal_mean$std.error <- intermeal_mean$V4 [,2]

# Prettier colors:
# Reordering colors for showing dark periods as dark colors
cols <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
cols <- c(cols[2],cols[4])
cols

ggplot(data=intermeal_mean, aes(x=group, y=mean, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  scale_y_continuous(limits=c(0,1500))+
  labs (title = "Intermeal Duration\n") +  
  labs (x = "\nGroup (s)\n", y="Intermeal Duration (s)\n") +
  scale_fill_manual(values=cols) +
  theme(legend.title=element_blank())

ggsave(file="intermeal_duration.png",width=14, height=14, dpi=300, units ="cm")

