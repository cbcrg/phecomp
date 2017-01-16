############################################################
### Jose A Espinosa. CSN/CB-CRG Group. Feb 2015          ###
############################################################
### Getting the behavior of mice at the beginning of each###
### new recording period (30 min) and comparing it to    ###
### 30 minutes after 24 hours (same phase of the cycle)  ###
### Number of meals                                      ###
### Coverage                                             ###
############################################################
### Calling this script in iOS:                          ###
### Rscript starting_regions_file_vs_24h.R               ###
############################################################

##Loading libraries
library ("ggplot2")
library ("plotrix") #std.error

#####################
### VARIABLES
#Reading arguments
# args <- commandArgs (TRUE) #if not it doesn't start to count correctly
# 
# ## Default setting when no arguments passed
# if ( length(args) < 1) {
#   args <- c("--help")
# }
# 
# ## Help section
# if("--help" %in% args) {
#   cat("
#       starting_regions_file_vs_24h
#  
#       Arguments:
#       --tag=someValue        - character, stat to analyze (sum, mean, ...)
#       --path2files=someValue - character, path to read files
#       --path2plot=someValue  - character, path to dump plots
#       --help                 - print this text
#  
#       Example:
#       ./starting_regions_file_vs_24h.R --tag=\"sum\" --path2plot=\"/foo/plots\"\n")
#   
#   q (save="no")
# }
# 
# # Use to parse arguments beginning by --
# parseArgs <- function(x) 
# {
#   strsplit (sub ("^--", "", x), "=")
# }
# 
# #Parsing arguments
# argsDF <- as.data.frame (do.call("rbind", parseArgs(args)))
# argsL <- as.list (as.character(argsDF$V2))
# names (argsL) <- argsDF$V1
# # print (argsL)
# 
# # tag is mandatory
# {
#   if (is.null (argsL$tag)) 
#   {
#     stop ("[FATAL]: Tag parameter is mandatory")
#   }
#   else
#   {
#     tag <- argsL$tag
#   }
# }
# 
# {
#   if (is.null (argsL$path2files)) 
#   {
#     path2files <- "/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h"
#   }
#   else
#   {
#     path2files <- argsL$path2files
#   }
# }
# 
# {
#   if (is.null (argsL$path2plot)) 
#   {
#     print ("[Warning]: Plots will be dump in working directory as not path was provided")
#     path2plot <- getwd()  
#   }
#   else
#   {
#     path2plot <- argsL$path2plot
#   }
# }


# Loading functions:
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

load_tbl_measure <- function (pattern="30min_sum") {
  #print(files <- list.files(pattern=paste(pattern, ".bed$", sep="")))
  files <- list.files(pattern=paste(pattern, ".bed$", sep=""))
  group <- c()
  HF_lab <- paste ("HF", pattern,  sep="")
  ctrl_lab <- paste ("Ctrl", pattern,  sep="")
  
  pattern2grep <- paste ("_dt_food_fat_food_sc_", pattern, "\\.bed",sep="")
  group <- sapply (files, y <- function (x) {if (grepl(pattern2grep, x)) return (HF_lab) else {return (ctrl_lab)}})
  
  labs<-gsub("tr_", "", files, perl=TRUE)
  labs<-gsub(paste ("_dt_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE)
  labs<-gsub(paste ("_dt_food_fat_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE)
  
  # Create lists to hold coverage and cumulative coverage for each animal group and phase,
  # and read the data into these lists.
  cov <- list()
  
  for (i in 1:length(files)) {
    cov[[i]] <- read.table(files[i])
  }
      
  cov_all <- cov[[1]]
  cov_all$id <- labs[1]
  cov_all$group <- group[1]  
  cov_all$index <- c(1:length(cov_all[,1]))
  
  for (i in 2:length(cov)) {
    cov_gr <- cov[[i]] 
    cov_gr$id <- labs[i]
    cov_gr$group <- group[i]
    cov_gr$index <- c(1:length(cov[[i]][,1]))
    cov_all<-rbind (cov_all, cov_gr)    
  }
  
  return (cov_all)
}

## PATTERN ==> DEPENDING ON THE PATTERN A DIFFERENT TYPE OF MEASURE WILL BE LOAD: MEAN VALUE, ACCUMULATED VALUE...

# tag = "sum"
tag = "mean"
# tag = "cov"
# tag = "count"

# path2files <- "/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h"
# This is the last one used because in the previous one there was an error
# path2files <- "/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper"

# manual execution, uncomment
# setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h")

# Last data used 
setwd("/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper")

#The bash script to generate the results is:
# /Users/jespinosa/git/phecomp/lib/bash/bed_after_clean.sh

pattern = paste("30min_", tag, sep="")
#pattern = "30min_cov" 
#pattern = "30min_sum"

tbl_30min <- load_tbl_measure (pattern)

#pattern = "24h_sum"
pattern = paste("24h_", tag, sep="")
tbl_24h <- load_tbl_measure (pattern)

# In the last post 24 hours guy 18 is an outliers 
# tbl_24h[tbl_24h$index==9 & tbl_24h$group==paste("HF24h_", tag, sep=""), ]
tbl_24h <- tbl_24h [!(tbl_24h$index==9 & tbl_24h$group=="HF24h_mean" & tbl_24h$id == "18"),]

pattern = paste("24h_less_", tag, sep="")
#pattern = "24h_less_sum"
tbl_24h_less <- load_tbl_measure (pattern)

# First period can not be calculated because there is no 24 hours before frist file,
# thus I have to add +1 to the index
# tbl_24h_less$index <- tbl_24h_less$index + 1
# in this case yes because I am using the development data

# I include a fake values for 24hours before in the first file, otherwise only 4 bars are plot and the width of the bars
# differ from the rest
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, NA, 1000, "+", 1609221, 1616855, 0, 19, paste("Ctrl24h_less_", tag, sep=""), 1))
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, NA, 1000, "+", 1609221, 1616855, 0, 19, paste("HF24h_less_", tag, sep=""), 1))

tbl_24h_less$V9 <- as.numeric(tbl_24h_less$V9)
tbl_24h_less$index <- as.numeric(tbl_24h_less$index)

tbl_stat <- c()
tbl_stat <- rbind (tbl_30min, tbl_24h, tbl_24h_less)

#Calculate mean and stderror of the mean by file and group
tbl_stat_mean <-with (tbl_stat, aggregate (cbind (V9), list (group=group, index=index), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# tbl_stat_mean

tbl_stat_mean$mean <- tbl_stat_mean$V9 [,1]
tbl_stat_mean$std.error <- tbl_stat_mean$V9 [,2]

### Plots
# Prettier colors:
# Reordering colors for showing dark periods as dark colors
col_redish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Reds"))(10)
col_greenish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Greens"))(10)
col_blueish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Blues"))(10)
cols <- c(col_greenish[c(4,7,10)], col_redish[c(4,7,10)])

# Get title and file name according with stat
var_labels<-switch(tag, 
           sum={
                 
            c("Accumulated intake ","accu_intake", "(g)\n")
           },
           mean={
           
             c("Mean intake ", "mean_intake", "(g)\n")    
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

# Save file with prefix new_ not to overwrite old plots
#file_name <- paste ("new_", var_labels[2], sep="")

unit <- var_labels[3]
title_plot = paste (title_beg[1], "during first 30 min after cleaning,\n24h before and 24h after\n\n", sep="")
y_lab = paste (title_beg, unit)

# Order for plotting
tbl_stat_mean$group2 <- factor(tbl_stat_mean$group, levels=c(paste("Ctrl24h_less_", tag, sep=""),paste("Ctrl24h_", tag, sep=""),
                                                             paste("Ctrl30min_", tag, sep=""), paste("HF24h_less_", tag, sep=""), 
                                                             paste("HF30min_", tag, sep=""), paste("HF24h_", tag, sep="")))

# Only 8 weeks of development
tbl_stat_mean <- tbl_stat_mean [which(tbl_stat_mean$index < 25),]

# scale_x_continuous(breaks=seq(2,28,3), labels=c(1:9), limits=c(0.6,28.5))+
ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group2)) + 
#        geom_bar(stat="identity", position=position_dodge()) +
       geom_bar(stat="identity", position=position_dodge(), show_guide = FALSE) +
       geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
              width=.2,                    # Width of the error bars
              position=position_dodge(.9)) +
#               scale_x_continuous(breaks=1:9, limits=c(0.6,9.5))+
#               scale_x_continuous(breaks=1:28, limits=c(0.6,28.5))+
              scale_x_continuous(breaks=seq(2,24,3), labels=c(1:8), limits=c(0,24.5))+
              scale_y_continuous(limits=c(0, max(tbl_stat_mean$mean, na.rm=TRUE) + max(tbl_stat_mean$std.error, na.rm=TRUE))) +                
              labs (title = title_plot) +  
              labs (x = "\nDevelopment week\n", y=y_lab, fill = NULL) +
              scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                       "HF 24h before", "HF after cleaning", "HF 24h after"))

# ggsave(file=paste(path2plot, file_name, "_error_bar", ".pdf", sep=""), width=10, height=8)
# ggsave(file=paste(path2plot, file_name, "_error_bar", ".pdf", sep=""), width=16, height=8)

# Order for plotting
tbl_stat$group2 <- factor(tbl_stat$group, levels=c(paste("Ctrl24h_less_", tag, sep=""),paste("Ctrl24h_", tag, sep=""),
                                                   paste("Ctrl30min_", tag, sep=""), paste("HF24h_less_", tag, sep=""), 
                                                   paste("HF30min_", tag, sep=""), paste("HF24h_", tag, sep="")))

ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group2)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
#   scale_x_continuous(breaks=1:9, limits=c(0.6,9.5))+
#   scale_x_continuous(breaks=1:28, limits=c(0.6,28.5))+
  scale_x_continuous(breaks=seq(2,24,3), labels=c(1:8), limits=c(0.6,24.5)) +
#   scale_y_continuous(limits=c(0, max(tbl_stat$V9) + max(tbl_stat$V9)/10)) +
  scale_y_continuous(limits=c(0, max(tbl_stat_mean$mean, na.rm=TRUE) + max(tbl_stat_mean$mean, na.rm=TRUE)/10)) +
  labs (title = title_plot) +
  labs (x = "\nDevelopment week\n", y=y_lab, fill = NULL) +
  scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
           "HF 24h before", "HF after cleaning", "HF 24h after"))

# ggsave(file=paste(path2plot, file_name, ".png", sep=""),width=26, height=14, dpi=300, units ="cm")
#ggsave(file=paste(path2plot, file_name, ".png", sep=""), width=26, height=14, dpi=300, units ="cm")
# ggsave(file=paste(path2plot, file_name, ".pdf", sep=""), width=10, height=8)

stop("Execution finished correctly")

###########################
# How to write a table to perform the mixed anova
# head (tbl_stat)

# Writing the table for spss ANOVA analysis
# tbl_stat <- tbl_stat [which(tbl_stat$index < 25),]
tbl_stat$group_n <- gsub("Ctrl24h_less_mean", 1, tbl_stat$group)
tbl_stat$group_n <- gsub("Ctrl30min_mean", 2, tbl_stat$group_n)
tbl_stat$group_n <- gsub("Ctrl24h_mean", 3, tbl_stat$group_n)
tbl_stat$group_n <- gsub("HF24h_less_mean", 1, tbl_stat$group_n)
tbl_stat$group_n <- gsub("HF30min_mean", 2, tbl_stat$group_n)
tbl_stat$group_n <- gsub("HF24h_mean", 3, tbl_stat$group_n)

tbl_stat$group_id <- gsub("Ctrl24h_less_mean", "ctrl", tbl_stat$group)
tbl_stat$group_id <- gsub("Ctrl30min_mean", "ctrl", tbl_stat$group_id)
tbl_stat$group_id <- gsub("Ctrl24h_mean", "ctrl", tbl_stat$group_id)
tbl_stat$group_id <- gsub("HF24h_less_mean", "HF", tbl_stat$group_id)
tbl_stat$group_id <- gsub("HF30min_mean", "HF", tbl_stat$group_id)
tbl_stat$group_id <- gsub("HF24h_mean", "HF", tbl_stat$group_id)
tbl_stat <- tbl_stat [tbl_stat$id != 6, ]

# Tbl with all the cleaning starvation periods
# write.table (tbl_stat, file = "/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/20151103_result/tbl_intake_cleanPeaks.csv", row.names=FALSE, sep="\t")

#Calculate mean and stderror of the mean by file and group
head (tbl_stat)
tbl_stat_aggregate_mean <-with (tbl_stat, aggregate (cbind (V9), list (id=id, group_n=group_n, group_id=group_id), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
tbl_stat_aggregate_mean$mean <- tbl_stat_aggregate_mean$V9 [,1]
tbl_stat_aggregate_mean$std.error <- tbl_stat_aggregate_mean$V9 [,2]
tbl_stat_aggregate_mean <- subset(tbl_stat_aggregate_mean, select = -c(V9))
tbl_stat_HF_1 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "HF" & tbl_stat_aggregate_mean$group_n == 1, c(1,2,4)]
tbl_stat_HF_2 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "HF" & tbl_stat_aggregate_mean$group_n == 2, c(1,2,4)]
tbl_stat_HF_3 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "HF" & tbl_stat_aggregate_mean$group_n == 3, c(1,2,4)]

tbl_HF_1_2 <- merge(tbl_stat_HF_1,tbl_stat_HF_2,by=c("id")) 
tbl_HF_1_2_3 <- merge(tbl_HF_1_2 ,tbl_stat_HF_3,by=c("id")) 
tbl_HF <- tbl_HF_1_2_3 [,c(1,3,5,7)]
tbl_HF$group <- "HF"
tbl_stat_Ctrl_1 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "ctrl" & tbl_stat_aggregate_mean$group_n == 1, c(1,2,4)]
tbl_stat_Ctrl_2 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "ctrl" & tbl_stat_aggregate_mean$group_n == 2, c(1,2,4)]
tbl_stat_Ctrl_3 <- tbl_stat_aggregate_mean [tbl_stat_aggregate_mean$group_id == "ctrl" & tbl_stat_aggregate_mean$group_n == 3, c(1,2,4)]

tbl_Ctrl_1_2 <- merge(tbl_stat_Ctrl_1,tbl_stat_Ctrl_2,by=c("id")) 
tbl_Ctrl_1_2_3 <- merge(tbl_Ctrl_1_2 ,tbl_stat_Ctrl_3,by=c("id")) 
tbl_Ctrl <- tbl_Ctrl_1_2_3 [,c(1,3,5,7)]
tbl_Ctrl$group <- "Ctrl"


tbl2anova <- rbind (tbl_HF, tbl_Ctrl)

# write.table (tbl2anova, file = "/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/20151103_result/tbl_peaks_3timePoints.csv", row.names=FALSE, sep="\t")

require(nlme)
require(multcomp)
tbl_stat_aggregate_mean
tbl_anova<-tbl_stat_aggregate_mean

tbl_anova <- within(tbl_anova, {
  id <- factor(id)
  time <- factor(group_n)
  group <- factor(group_id)
})

anova<-aov(mean ~ group*time + Error (id), data=tbl_anova)
summary (anova)

lme_clean = lme(mean ~ group*time, data=tbl_anova, random = ~1|id)
anova(lme_clean)

summary(glht(lme_clean,  test = adjusted(type = "bonferroni"))

tbl_anova$interaction <- paste (tbl_anova$group, tbl_anova$time, sep="")

with(tbl_anova, pairwise.t.test(mean, interaction, p.adjust.method="bonf"))

# Plot of the new barplot with just the three timepoints and the groups
head (tbl_stat)
tbl_mean_group_day <-with (tbl_stat, aggregate (cbind (V9), list (group=group_id, group_time=group, time=group_n), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
tbl_mean_group_day$mean <- tbl_mean_group_day$V9 [,1]
tbl_mean_group_day$std.error <- tbl_mean_group_day$V9 [,2]
# tbl_mean_group_day$time <-as.numeric(tbl_mean_group_day$time)

# pca2plot$gentreat <- factor(pca2plot$gentreat , levels=c("WT", "TS", "WTEE", "TSEE", "WTEGCG", "TSEGCG", "WTEEEGCG", "TSEEEGCG"), 
#                             labels=c("WT", "TS", "WTEE", "TSEE", "WTEGCG", "TSEGCG", "WTEEEGCG", "TSEEEGCG"))

tbl_mean_group_day$group_time <- factor(tbl_mean_group_day$group_time, levels=c("Ctrl24h_less_mean", "Ctrl30min_mean", "Ctrl24h_mean", 
                                                                                "HF24h_less_mean", "HF30min_mean", "HF24h_mean"), 
                                        labels=c("Ctrl24h_less_mean", "Ctrl30min_mean", "Ctrl24h_mean", 
                                                 "HF24h_less_mean", "HF30min_mean", "HF24h_mean"))
tbl_mean_group_day$group <- factor(tbl_mean_group_day$group, levels=c("ctrl", "HF"), 
                                        labels=c("ctrl", "HF"))

ggplot(data=tbl_mean_group_day, aes(x=time, y=mean, fill=group)) + 
       geom_bar(stat="identity", colour="black", position=position_dodge(), show_guide = T) +
#        geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
       geom_errorbar(aes(ymin=mean, ymax=mean+std.error),
                     width=.2,                    # Width of the error bars 
                     position=position_dodge(.9)) +
       scale_x_discrete (labels = c("24h before", "After cleaning", "24h after")) +
       scale_y_continuous(limits=c(0, max(tbl_mean_group_day$mean, na.rm=TRUE) + max(tbl_mean_group_day$std.error, na.rm=TRUE))) +                
       labs (title = title_plot) +  
       labs (x = "\nTime respect cleaning starvation\n", y=y_lab, fill = NULL) +
       scale_fill_manual(values=c( "white", "black"), labels=c("Ctrl", "HF")) +
#        scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
#                                           "HF 24h before", "HF after cleaning", "HF 24h after"))
       guides(fill = guide_legend(override.aes = list(colour = NULL))) + 
       theme (legend.key = element_rect(colour = "black"))

# path2plot <- "/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/20151103_result/"
# path2plot <- "/Users/jespinosa/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures_20151110/figS2/"
# ggsave(file=paste(path2plot, "Clean_dietXtimeGreenRed_noDodge",".pdf", sep=""), width=16, height=8)
# ggsave(file=paste(path2plot, "Clean_dietXtimeGreenRed_noDodge",".tiff", sep=""), width=16, height=8, dpi=400)


### PLOT with the bars grouped by diet
ggplot(data=tbl_mean_group_day, aes(x=group_time, y=mean, fill=group_time)) + 
  geom_bar(stat="identity", position=position_dodge(), show_guide = F) +
  #        geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars 
                position=position_dodge(.9)) +
#   scale_x_discrete (labels = c("24h before", "After cleaning", "24h after")) +
  scale_x_discrete (labels = c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                               "HF 24h before", "HF after cleaning", "HF 24h after")) +
  scale_y_continuous(limits=c(0, max(tbl_mean_group_day$mean, na.rm=TRUE) + max(tbl_mean_group_day$std.error, na.rm=TRUE))) +                
  labs (title = title_plot) +  
  labs (x = "\nDiet and time respect\ncleaning starvation", y=y_lab, fill = NULL) +

         scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                                            "HF 24h before", "HF after cleaning", "HF 24h after"))

# ggsave(file=paste(path2plot, "Clean_timeGreenRed_DietDodge",".pdf", sep=""), width=16, height=8)
# ggsave(file=paste(path2plot, "Clean_timeGreenRed_DietDodge",".tiff", sep=""), width=16, height=8, dpi=400)

cols <- c(col_redish[c(4,7,10)], col_blueish[c(4,7,10)])
title_plot = paste (title_beg[1], "during first 30 min after cleaning,\n24h before and 24h after", sep="")

### PLOT with the bars grouped by diet
## gray cols

# ggplot(data=tbl_mean_group_day, aes(x=group, y=mean, fill=group_time)) + 
ggplot(data=tbl_mean_group_day, aes(x=group, y=mean, fill=time)) +
  geom_bar(stat="identity", position=position_dodge(), show.legend = T) +
  #        geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars 
                position=position_dodge(.9)) +
  scale_x_discrete (labels = c("Ctrl", "HF")) +
#   scale_y_continuous(limits=c(0, max(tbl_mean_group_day$mean, na.rm=TRUE) + max(tbl_mean_group_day$std.error, na.rm=TRUE))) +
  scale_y_continuous(limits=c(0, 0.63)) +
  labs (title = title_plot) +  
  labs (x = "\nDiet and time respect cleaning starvation", y=y_lab, fill = NULL) +
  
#   scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
#                                           "HF 24h before", "HF after cleaning", "HF 24h after")) + 
  scale_fill_grey(labels=c("24h before", "After cleaning", "24h after")) + 
#   scale_fill_grey(start = 0, end = .9)) +
  theme(plot.title = element_text(size=20)) + 
  theme(axis.title.x = element_text(size = 20)) +
  theme(axis.title.y = element_text(size = 20)) +
  theme(legend.text=element_text(size=17)) +
  annotate("text", x=2, y=0.57,label="***", size=10) +
  annotate("text", x=2, y=0.615,label="###", size=6) +
  theme(axis.line.x = element_line(colour = "black")) + 
  theme(axis.line.y = element_line(colour = "black"))


# path2plot <- "/Users/jespinosa/Dropbox (CRG)/thesis_presentation/figures/obesity_paper/"
path2plot <- "/Users/jespinosa/Dropbox (CRG)/2013phecomp2shareFinal/drafts_paper/figures_20151110/figS3/"
# ggsave(file=paste(path2plot, "Clean_timeGreenRed_TimeDodge",".pdf", sep=""), width=16, height=8)
# ggsave(file=paste(path2plot, "Clean_timeGreenRed_TimeDodge",".tiff", sep=""), , width=16, height=8, dpi=400)
ggsave(file=paste(path2plot, "peaks_clean",".tiff", sep=""), width=16, height=8, dpi=300)

## Results
# Two-way repeated-measures ANOVA revealed a significant effect
# of diet (F(1,15) = 91.25; P < 0.001, Fig. S2B), time (F(2,30) = 62.512; P < 0.001, Fig. S2B)
# and interaction of diet and time

################################
###########################

# Get a list of the bedtools output files you'd like to read in
# 30 first minutes
print(files <- list.files(pattern=paste(pattern, ".bed$", sep="")))
group<-c()

# grepl("_dt_food_fat_food_sc_30min_cov\\.bed", files)

HF_lab<-"HF_30min"
ctrl_lab <- "Ctrl_30min"

print (pattern2grep <- paste ("_dt_food_fat_food_sc_", pattern, "\\.bed",sep=""))
print(group <- sapply (files, y <- function (x) {if (grepl(pattern2grep, x)) return (HF_lab) else {return (ctrl_lab)}}))
#group <- sapply (files, y <- function (x) {print (x)})
length (group)

# Optional, create short sample names from the filenames.
print (labs<-gsub("tr_", "", files, perl=TRUE))
print (labs<-gsub(paste ("_dt_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE))
print (labs<-gsub(paste ("_dt_food_fat_food_sc_", pattern,  "\\.bed", sep=""), "", labs, perl=TRUE))











# Create lists to hold coverage and cumulative coverage for each animal group and phase,
# and read the data into these lists.
cov <- list()

for (i in 1:length(files)) {
  cov[[i]] <- read.table(files[i])
}



cov_all <- cov[[1]]
cov_all$id <- labs[1]
cov_all$group <- group[1]  
cov_all$index <- c(1:length(cov_all[,1]))

for (i in 2:length(cov)) {
  cov_gr <- cov[[i]] 
  cov_gr$id <- labs[i]
  cov_gr$group <- group[i]
  cov_gr$index <- c(1:length(cov[[i]][,1]))
  cov_all<-rbind (cov_all, cov_gr)    
}

# 24hours + 30 first minutes
print(files <- list.files(pattern="24h_cov.bed$"))
group<-c()
grepl("_dt_food_fat_food_sc_24h_cov\\.bed", files)
HF_lab<-"HF_24h"
ctrl_lab <- "Ctrl_24h"

print(group <- sapply (files, y <- function (x) {if (grepl("_dt_food_fat_food_sc_24h_cov\\.bed", x)) return (HF_lab) else {return (ctrl_lab)}}))
#group <- sapply (files, y <- function (x) {print (x)})
length (group)

# Optional, create short sample names from the filenames.
print (labs<-gsub("tr_", "", files, perl=TRUE))
print (labs<-gsub("_dt_food_sc_24h_cov\\.bed", "", labs, perl=TRUE))
print (labs<-gsub("_dt_food_fat_food_sc_24h_cov\\.bed", "", labs, perl=TRUE))

# Create lists to hold coverage and cumulative coverage for each animal group and phase,
# and read the data into these lists.
cov_24h <- list()

for (i in 1:length(files)) {
  cov_24h[[i]] <- read.table(files[i])
}

for (i in 1:length(cov_24h)) {
  cov_gr <- cov_24h[[i]] 
  cov_gr$id <- labs[i]
  cov_gr$group <- group[i]
  cov_gr$index <- c(1:length(cov_24h[[i]][,1]))
  cov_all<-rbind (cov_all, cov_gr)    
}

cov_all

# Prettier colors:
# Reordering colors for showing dark periods as dark colors
cols <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
cols

# Order for plotting
cov_all$group2 <- factor(cov_all$group, levels=c("Ctrl_30min", "Ctrl_24h", "HF_30min", "HF_24h"))

ggplot(data=cov_all, aes(x=index, y=V9, fill=group2)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "Number of meals during \nfirst 30 min of file\n") +  
  labs (x = "\nDevelopment week\n", y="Percentage of time\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="first_30_min_coverage.png",width=26, height=14, dpi=300, units ="cm")




ggplot(data=cov_all, aes(x=index, y=V9, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "Number of meals during first 30 min of file\n") +  
  labs (x = "\nDevelopment week\n", y="Number of meals\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="first_30_min_meal.png",width=26, height=14, dpi=300, units ="cm")



