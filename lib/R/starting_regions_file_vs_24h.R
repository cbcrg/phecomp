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
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

# setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file_vs_24h")

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
tbl_24h_less$index <- tbl_24h_less$index + 1

# I include a fake values for 24hours before in the first file, otherwise only 4 bars are plot and the width of the bars
# differ from the rest
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, NA, 1000, "+", 1609221, 1616855, 0, 19, paste("Ctrl24h_less_", tag, sep=""), 1))
tbl_24h_less <- rbind(tbl_24h_less, c("chr1", 1530455, 1532255, NA, 1000, "+", 1609221, 1616855, 0, 19, paste("HF24h_less_", tag, sep=""), 1))

tbl_24h_less$V9 <- as.numeric(tbl_24h_less$V9)
tbl_24h_less$index <- as.numeric(tbl_24h_less$index)

tbl_stat <- c()
tbl_stat <- rbind (tbl_30min, tbl_24h, tbl_24h_less)
# head (tbl_stat)

#Calculate mean and stderror of the mean
tbl_stat_mean <-with (tbl_stat, aggregate (cbind (V9), list (group=group, index=index), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# tbl_stat_mean

tbl_stat_mean$mean <- tbl_stat_mean$V9 [,1]
tbl_stat_mean$std.error <- tbl_stat_mean$V9 [,2]

### Plots
# Prettier colors:
# Reordering colors for showing dark periods as dark colors
col_redish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Reds"))(10)
col_greenish <- colorRampPalette(RColorBrewer::brewer.pal(4,"Greens"))(10)
cols <- c(col_greenish[c(4,7,10)], col_redish[c(4,7,10)])

# Get title and file name according with stat
var_labels<-switch(tag, 
           sum={
                 
            c("Accumulated intake ","accu_intake")
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
unit <- var_labels[3]
title_plot = paste (title_beg[1], "during first 30 min after clean,\n24h before and 24h after\n", sep="")
y_lab = paste (title_beg, unit)

# Order for plotting
tbl_stat_mean$group2 <- factor(tbl_stat_mean$group, levels=c(paste("Ctrl24h_less_", tag, sep=""),paste("Ctrl24h_", tag, sep=""),
                                                             paste("Ctrl30min_", tag, sep=""), paste("HF24h_less_", tag, sep=""), 
                                                             paste("HF30min_", tag, sep=""), paste("HF24h_", tag, sep="")))

ggplot(data=tbl_stat_mean, aes(x=index, y=mean, fill=group2)) + 
geom_bar(stat="identity", position=position_dodge()) +
geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
              width=.2,                    # Width of the error bars
              position=position_dodge(.9)) +
              scale_x_continuous(breaks=1:9, limits=c(0,10))+
              scale_y_continuous(limits=c(0, max(tbl_stat_mean$V9)+max(tbl_stat_mean$V9)/5)) +                
              labs (title = title_plot) +  
              labs (x = "\nFile number\n", y=y_lab, fill = NULL) +
              scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
                       "HF 24h before", "HF after cleaning", "HF 24h after"))

ggsave(file=paste(file_name, "_error_bar", ".pdf", sep=""), width=10, height=8)

# Order for plotting
tbl_stat$group2 <- factor(tbl_stat$group, levels=c(paste("Ctrl24h_less_", tag, sep=""),paste("Ctrl24h_", tag, sep=""),
                                                   paste("Ctrl30min_", tag, sep=""), paste("HF24h_less_", tag, sep=""), 
                                                   paste("HF30min_", tag, sep=""), paste("HF24h_", tag, sep="")))

ggplot(data=tbl_stat, aes(x=index, y=V9, fill=group2)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  scale_y_continuous(limits=c(0, max(tbl_stat$V9) + max(tbl_stat$V9)/10)) +
  labs (title = title_plot) +
  labs (x = "\nFile number\n", y=y_lab, fill = NULL) +
  scale_fill_manual(values=cols, labels=c("Ctrl 24h before", "Ctrl after cleaning", "Ctrl 24h after", 
           "HF 24h before", "HF after cleaning", "HF 24h after"))

# ggsave(file=paste(file_name, ".png", sep=""),width=26, height=14, dpi=300, units ="cm")
#ggsave(file=paste(file_name, ".png", sep=""), width=26, height=14, dpi=300, units ="cm")
ggsave(file=paste(file_name, ".pdf", sep=""), width=10, height=8)

stop("Execution finished correctly")




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
  labs (x = "\nFile number\n", y="Percentage of time\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="first_30_min_coverage.png",width=26, height=14, dpi=300, units ="cm")




ggplot(data=cov_all, aes(x=index, y=V9, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "Number of meals during first 30 min of file\n") +  
  labs (x = "\nFile number\n", y="Number of meals\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="first_30_min_meal.png",width=26, height=14, dpi=300, units ="cm")



