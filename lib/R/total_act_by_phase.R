#!/usr/bin/env Rscript

############################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2015          ###
############################################################
### Using bedtools I get the sumatory of the activity    ###
### during each light or dark phase                      ###
### This script is used to plot this values              ###
###                                                      ###
### Total distance                                       ###
############################################################
### Calling this script in iOS:                          ###
### Rscript total_act_by_phase.R                         ###
############################################################

##Getting HOME directory
home <- Sys.getenv("HOME")

##Loading libraries
library ("ggplot2")
library ("plotrix") #std.error

# Loading functions:
source (paste (home, "/phecomp/lib/R/plotParamPublication.R", sep=""))

setwd (paste(home, "/phecomp/processedData/201205_FDF_CRG/tac2activity/bed_from_cluster", sep=""))

#####################
##Loading functions
labelGroups <- function (df.data, ctrlGroup = "odd", labelCase = "HF diet", labelCtrl="SC diet")
{    
  df.data$diet <- labelCtrl
  
  if (ctrlGroup == "odd")
  {       
    df.data$diet [which (df.data$cage%% 2 == 0)] <- labelCase    
  }
  else 
  {        
    df.data$diet [which (df.data$cage%% 2 != 0)] <- labelCase
  }
  
  return (df.data)
}

load_activity <- function (pattern="sum") {
  print(files <- list.files(pattern=paste(pattern, ".bed$", sep="")))
  files <- list.files(pattern=paste(pattern, ".bed$", sep=""))
  group <- c()
  
  HF_lab <- paste ("HF", pattern,  sep="")
  ctrl_lab <- paste ("Ctrl", pattern,  sep="")
  
  # Implement a way of getting the number and calculating odds 
  #pattern2grep <- paste ("_dt_food_fat_food_sc_", pattern, "\\.bed",sep="")
  #print (pattern2grep)
  
  #group <- sapply (files, y <- function (x) {if (grepl(pattern2grep, x)) return (HF_lab) else {return (ctrl_lab)}})
 
  cage_n <- as.numeric(gsub ("_all_phases_sum.bed","", gsub("tr_", "", files)))
  print (cage_n)
  
  group_mice <- c()
  HF_lab <- "HF"
  ctrl_lab <- "Ctrl"
  group_mice <- sapply (files, y <- function (x) {if (cage_n%% 2 == 0) return (HF_lab) else {return (ctrl_lab)}})
  
  # Create lists to hold coverage and cumulative coverage for each animal group and phase,
  # and read the data into these lists.
  stats <- list()
  
  for (i in 1:length(files)) {
    stats[[i]] <- read.table(files[i])
  }
  
  stats_all <- stats[[1]]
  stats_all$id <- cage_n[1]
  stats_all$group <- group[1]
  stats_all$group_mice <- group_mice[1]
  #stats_all$index <- c(1:length(stats_all[,1]/2))
  stats_all$index <- rep(1: as.integer(length(stats_all[,1])/2), each=2)
  print (rep(1: as.integer(length(stats_all[,1])/2), each=2))

  #stats_all$index <- rep(1:length(stats_all[,1)/2, each=2))

  for (i in 2:length(stats)) {
    stats_gr <- stats[[i]] 
    stats_gr$id <- cage_n[i]
    stats_gr$group <- group[i]
    stats_gr$group_mice <- group_mice[i]
    # stats_gr$index <- c(1:length(stats[[i]][,1]))
    #stats_gr$index <- rep(1:length(stats[[i]][,1])/2, each=2)
    stats_gr$index <- rep(1: as.integer(length(stats[[i]][,1])/2), each=2)
    stats_all<-rbind (stats_all, stats_gr)    
  }
  
  return (stats_all)
}


df.act_sum <- load_activity("all_phases_sum")
print (rep (1: 18/2, each=2))
print (rep (1: 9, each=2))
stop ("lllll")  

















tag = "all_phases_sum"

pattern="latency"
tbl_latency <- load_tbl_latency(pattern)
head (tbl_latency)
tail (tbl_latency)

