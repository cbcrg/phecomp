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

##Getting HOME directory
home <- Sys.getenv("HOME")

##Loading libraries
library ("ggplot2")
library ("plotrix") #std.error

#####################
### VARIABLES
#Reading arguments
args <- commandArgs (TRUE) #if not it doesn't start to count correctly

## Default setting when no arguments passed
if ( length(args) < 1) {
  args <- c("--help")
}

## Help section
if("--help" %in% args) {
  cat("
      starting_regions_file_vs_24h
 
      Arguments:
      --tag=someValue        - character, stat to analyze (sum, mean, ...)
      --path2files=someValue - character, path to read files
      --path2plot=someValue  - character, path to dump plots
      --help                 - print this text
 
      Example:
      ./starting_regions_file_vs_24h.R --tag=\"sum\" --path2plot=\"/foo/plots\"\n")
  
  q (save="no")
}

# Use to parse arguments beginning by --
parseArgs <- function(x) 
{
  strsplit (sub ("^--", "", x), "=")
}

#Parsing arguments
argsDF <- as.data.frame (do.call("rbind", parseArgs(args)))
argsL <- as.list (as.character(argsDF$V2))
names (argsL) <- argsDF$V1
# print (argsL)

# tag is mandatory
{
  if (is.null (argsL$tag)) 
  {
    stop ("[FATAL]: Tag parameter is mandatory")
  }
  else
  {
    tag <- argsL$tag
  }
}

{
  if (is.null (argsL$path2files)) 
  {
    path2files <- "/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h"
  }
  else
  {
    path2files <- argsL$path2files
  }
}

{
  if (is.null (argsL$path2plot)) 
  {
    print ("[Warning]: Plots will be dump in working directory as not path was provided")
    path2plot <- getwd()  
  }
  else
  {
    path2plot <- argsL$path2plot
  }
}


# Loading functions:
source (paste (home, "/git/phecomp/lib/R/plotParamPublication.R", sep=""))

# manual execution, uncomment
#setwd("/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/mean/")
#path2files <- "/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/mean/"
#path2plot <- "/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/mean/"
#path2plot <- "/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/count/"
#path2files <- "/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/count/"
#path2files <- "/users/cn/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/count/"
setwd(path2files)
write(paste("Path to files: ", path2files, sep=""), stderr())

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
# tag = "mean"
# tag = "cov"
# tag = "count"

# path2files <- "~/phecomp/data/CRG/20120502_FDF_CRG/results/mean/"
pattern = paste("30min_", tag, sep="")
#pattern = "30min_cov" 
#pattern = "30min_sum"

tbl_30min <- load_tbl_measure (pattern)

#pattern = "24h_sum"
pattern = paste("24h_", tag, sep="")
tbl_24h <- load_tbl_measure (pattern)

# In the last post 24 hours guy 18 is an outliers 
# tbl_24h[tbl_24h$index==9 & tbl_24h$group==paste("HF24h_", tag, sep=""), ]
# tbl_24h <- tbl_24h [!(tbl_24h$index==9 & tbl_24h$group=="HF24h_mean" & tbl_24h$id == "18"),]

pattern = paste("24h_less_", tag, sep="")
#pattern = "24h_less_sum"
tbl_24h_less <- load_tbl_measure (pattern)

# First period can not be calculated because there is no 24 hours before frist file,
# thus I have to add +1 to the index
tbl_24h_less$index <- tbl_24h_less$index + 1

# I include a fake values for 24hours before in the first file, otherwise only 4 bars are plot and the width of the bars
# differ from the rest, fake intervals and track
# chr1 1085008 1086808 1000    + 1171384 1171409     0.056  8   HF24h_less_mean                 6
# Two values to get a std.error of the mean value of each group
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, 1000, "+", 1609221, 1616855, 0, 19, paste("Ctrl24h_less_", tag, sep=""), 1))
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, 1000, "+", 1609221, 1616855, 0, 21, paste("Ctrl24h_less_", tag, sep=""), 1))
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, 1000, "+", 1609221, 1616855, 0, 20, paste("HF24h_less_", tag, sep=""), 1))
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, 1000, "+", 1609221, 1616855, 0, 22, paste("HF24h_less_", tag, sep=""), 1))

tbl_24h_less$V8 <- as.numeric(tbl_24h_less$V8)
tbl_24h_less$index <- as.numeric(tbl_24h_less$index)

tbl_stat <- c()
tbl_stat <- rbind (tbl_30min, tbl_24h, tbl_24h_less)
# head (tbl_stat)
tail (tbl_stat,20) 

#Calculate mean and stderror of the mean
tbl_stat_mean <-with (tbl_stat, aggregate (cbind (V8), list (group=group, index=index), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# For the validation of std.error I have created my own function
# result is actually the same
# my_std_error <- function(x) {
#     return (sd(x)/sqrt(length(x)))   
# }
# 
# tbl_stat_mean <-with (tbl_stat, aggregate (cbind (V8), list (group=group, index=index), FUN=function (x) c (mean=mean(x), std.error=my_std_error(x))))

#tbl_stat_mean

tbl_stat_mean$mean <- tbl_stat_mean$V8 [,1]
tbl_stat_mean$std.error <- tbl_stat_mean$V8 [,2]

### Plots
# Prettier colors:
# Reordering colors for showing dark periods as dark colors
col_redish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Reds"))(10)
col_greenish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Greens"))(10)
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
title_plot = paste (title_beg[1], "during first 30 min after clean,\n24h before and 24h after\n", sep="")
y_lab = paste (title_beg, unit)

# Order for plotting
tbl_stat_mean$group2 <- factor(tbl_stat_mean$group, levels=c(paste("Ctrl24h_less_", tag, sep=""),paste("Ctrl24h_", tag, sep=""),
                                                             paste("Ctrl30min_", tag, sep=""), paste("HF24h_less_", tag, sep=""), 
                                                             paste("HF30min_", tag, sep=""), paste("HF24h_", tag, sep="")))

# Setting folder to dump plot
setwd (path2plot)

# Removing last item because there neither first 30 minutes after cleaning nor 24 hours
# tail(tbl_stat_mean, 10)
tbl_stat_mean <- tbl_stat_mean [!(tbl_stat_mean$index==max (tbl_stat_mean$index)),]

# Removing habituation week
# three first files
tbl_stat_mean <- tbl_stat_mean [!(tbl_stat_mean$index==1 | tbl_stat_mean$index==2 | tbl_stat_mean$index==3),]
tbl_stat_mean$index <- tbl_stat_mean$index - 3

max_file = max(tbl_stat_mean$index)

# Filtering over 3 weeks intervals
filter_over <- as.integer(max_file/3) * 3
tbl_stat_mean <- tbl_stat_mean [tbl_stat_mean$index <= filter_over, ] 

max_file = max(tbl_stat_mean$index)
lim_max_file = max_file + 0.5

ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group2)) + 
geom_bar(stat="identity", position=position_dodge()) +
geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
              width=.2,                    # Width of the error bars
              position=position_dodge(.9)) +
              scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                       "HF 24h before", "HF after cleaning", "HF 24h after")) +
#               scale_x_continuous(breaks=1:max_file, limits=c(0.6, lim_max_file)) +
              scale_x_continuous(breaks = c(seq(from = 2, to = lim_max_file, by = 3)), limits=c(0.4, lim_max_file), 
                                 labels = c(seq(from = 1, to = lim_max_file/3, by = 1))) +
              
              #scale_y_continuous(limits=c(0, max(tbl_stat_mean$V8) + max(tbl_stat_mean$V8)/5)) +
              #scale_y_continuous(limits=c(0, 1.8)) +  
              scale_y_continuous(limits=c(0, max(tbl_stat_mean$mean + tbl_stat_mean$std.error)+0.2)) +    
              labs (title = title_plot) +  
              labs (x = "\nDevelopment phase (weeks)\n", y=y_lab, fill = NULL)

# ggsave(file=paste(file_name, "_error_bar", ".pdf", sep=""), width=10, height=8)
ggsave(file=paste(file_name, "_error_bar", ".pdf", sep=""), width=18, height=10)


ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
#   scale_x_continuous(breaks=1:max_file, limits=c(0.6,9.5))+
#   scale_x_continuous(breaks=1:max_file, limits=c(0.6, max_file))+
  scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                                          "HF 24h before", "HF after cleaning", "HF 24h after")) +
#   scale_x_continuous(breaks = c(seq(from = 1, to = lim_max_file, by = 3)), limits=c(0.4, lim_max_file),
  scale_x_continuous(breaks = c(seq(from = 2, to = lim_max_file, by = 3)), limits=c(0.4, lim_max_file),
                     labels = c(seq(from = 1, to = lim_max_file/3, by = 1))) +
  #scale_y_continuous(limits=c(0, max(tbl_stat$V8) + max(tbl_stat$V8)/10)) +
  #scale_y_continuous(limits=c(0, 1.8)) +  
  scale_y_continuous(limits=c(0, max(tbl_stat_mean$mean + tbl_stat_mean$std.error)+0.2)) + 
  labs (title = title_plot) +
  labs (x = "\nDevelopment phase (weeks)\n", y=y_lab, fill = NULL)
  

# ggsave(file=paste(file_name, ".png", sep=""),width=26, height=14, dpi=300, units ="cm")
#ggsave(file=paste(file_name, ".png", sep=""), width=26, height=14, dpi=300, units ="cm")
ggsave(file=paste(file_name, ".pdf", sep=""), width=18, height=10)

warning ("Execution finished correctly")


# # Writing table for excel
# library(xlsx)
# require(plyr)
# 
# # Remove duplicated columns 
# head (tbl_stat)
# tbl_short <- tbl_stat_mean [,c(-1,-3,-5,-6)]
# tbl_by_index <- dlply(tbl_short, .(index))
# df.by_index <- do.call (cbind.data.frame, tbl_by_index)
# df.by.index_only_mean <-df.by_index [,-seq(1, ncol(df.by_index), by=2)]
# 
# tbl_group <- tbl_stat_mean [ which (tbl_stat_mean$index== 1),]$group
# df.by_index$group <- tbl_group
# 
# tbl_short <- tbl_stat [,c(-1,-2,-3,-4,-5,-6,-7)]
# head(tbl_short)
# tbl_short <- tbl_short [tbl_short$index <= 24, ] 
# tbl_short <- tbl_short [tbl_short$index > 1, ] 
# tbl_by_index <- dlply(tbl_short, .(index))
# df.by_index <- do.call (cbind.data.frame, tbl_by_index)
# head (df.by_index)
# df.by.index_only_mean_gr <- df.by_index [,-seq(2, ncol(df.by_index), by=2)]
# means <- df.by.index_only_mean_gr [,-seq(2, ncol(df.by.index_only_mean_gr), by=2)]
# means$group <- df.by.index_only_mean_gr[,2]
# means$id <- df.by_index[,2]
# means
# means$time <- gsub ("Ctrl", "", gsub ("HF", "" ,gsub ("_mean", "", means$group)))
# means$N_group <- sapply (means$group, y <- function (x) {if (grepl("HF", x)) return (2) else {return (1)}})
# values_by_time <- dlply(means, .(time))
# df.values_by_time <- do.call (cbind.data.frame, values_by_time)
# write.xlsx(df.values_by_time, "/Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/results/mean/tbl_stat_mean.xlsx") 
# 
