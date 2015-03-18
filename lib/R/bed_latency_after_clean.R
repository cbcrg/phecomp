#!/usr/bin/env Rscript

############################################################
### Jose A Espinosa. CSN/CB-CRG Group. March 2015        ###
############################################################
### Using bedtools to get the latency to the first meal  ###
### after a stop of each animal                          ###
############################################################
### Calling this script in iOS:                          ###
### ~/git/phecomp/lib/R/bed_latency_after_clean.R        ###
############################################################

##Loading libraries
library ("ggplot2")
library ("plotrix") #std.error

# Loading functions:
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file/results/")

load_tbl_latency <- function (pattern="latency") {
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
  latency <- list()
  
  for (i in 1:length(files)) {
    latency[[i]] <- read.table(files[i])
  }
  
  latency_all <- latency[[1]]
  latency_all$id <- labs[1]
  latency_all$group <- group[1]
  latency_all$group_mice <- group_mice[1]
  latency_all$index <- c(1:length(latency_all[,1]))
  
  for (i in 2:length(latency)) {
    latency_gr <- latency[[i]] 
    latency_gr$id <- labs[i]
    latency_gr$group <- group[i]
    latency_gr$group_mice <- group_mice[i]
    latency_gr$index <- c(1:length(latency[[i]][,1]))
    latency_all<-rbind (latency_all, latency_gr)    
  }
  
  return (latency_all)
}

tag = "mean"

pattern="latency"
tbl_latency <- load_tbl_comp(pattern)
head (tbl_latency)
tail (tbl_latency)

#Calculate mean and stderror of the mean
# remove this row because is a whole file empty
# chr1 996879 1007108 NA 1000  + 996879 1007108 chr1 1187875 1187911  NA 0.02   + 1187875 1187911 254,153,162 180768 10   HFlatency

tbl_latency <- tbl_latency [!(tbl_latency$id ==10 & tbl_latency$V2 == 996879),]

# I filter everything bigger than an hour 
tbl_latency <- tbl_latency [which(tbl_latency$V18 < 3600),]
tbl_latency
tbl_stat_mean <-with (tbl_latency, aggregate (cbind (V18), list (group=group, index=index), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
tbl_stat_mean

tbl_stat_mean$mean <- tbl_stat_mean$V18 [,1]
tbl_stat_mean$std.error <- tbl_stat_mean$V18 [,2]

ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "Latency First Meal\n") +  
  labs (x = "\nFile Number\n", y="Latency (s)\n",fill = NULL) +
  scale_fill_manual(values=cols, labels=c("Ctrl", "HF"))

ggsave(file="bed_latency_after_clean.pdf",width=10, height=8)