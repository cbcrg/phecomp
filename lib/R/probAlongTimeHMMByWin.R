##################################################################
### Jose A Espinosa. CSN/CB-CRG Group. Jun 2014                ###
##################################################################
### This script plots the probability of each cage along time  ###
### in window of time.                                         ###
### I use data to estimate a model for example habituation     ###
### then I calculate the probability of a sequence of events   ###
### produced by each animal during a given window time (for    ###
### example 2 hours, 12 hours or 24 hours                      ###
##################################################################

##Getting HOME directory
home <- Sys.getenv ("HOME")
wd<-getwd()

setwd ("/Users/jespinosa/phecomp/20140627_probOfWindowInt")

##Libraries
library (ggplot2)
library (plyr)
library(reshape)

##Loading functions
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPoster.R")

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

## HIGH FAT
#Table window of 2 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20120502_FDF_habDevW1_W2_step2h/prob/tableResults.tbl"
windowSize <- "2"
#Table window of 12 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20120502_FDF_habDevW1_W2_step12h/prob/tableResults.tbl"
windowSize <- "12"
#Table window of 24 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20120502_FDF_habDevW1_W2_step24h/prob/tableResults.tbl"
windowSize <- "24"

## FREE-CHOICE
#Table window of 2 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step2h/prob/tableResults.tbl"
windowSize <- "2"
#Table window of 12 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step12h/prob/tableResults.tbl"
windowSize <- "12"
#Table window of 24 hours
path2Tbl <- "/phecomp/20140627_probOfWindowInt/20130130_FCSC_habDevW1_W2_step24h/prob/tableResults.tbl"
windowSize <- "24"

df.probWin <- read.table (paste (home, path2Tbl, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=T)

head (df.probWin)
# time in days
df.probWin$time <- df.probWin$step * 300 / (3600*24)

## Labeling of the groups 
# HIGH FAT
df.probWin <- labelGroups (df.probWin)
group = "High-Fat Diet"
title = paste ("Model estimated on habituation,\nposterior probability on windows of", windowSize, "hours\n", group, "\n", sep =" " )
title = paste ("Sequence posterior probability windows of", windowSize, "hours\n", group, "\n", sep =" " )
df.probWin [which (df.probWin$evalScore > -30),]
# FREE-CHOICE
df.probWin <- labelGroups (df.probWin, ctrlGroup = "even", labelCase = "FC diet")
group = "Free-Choice Diet"
title = paste ("Model estimated on habituation,\nposterior probability on windows of", windowSize, "hours\n", group, "\n", sep =" " )


df.probWin$cage <- as.factor (df.probWin$cage)
df.probWin$diet <- as.factor (df.probWin$diet)

#source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublicationBlack.R")

probLinesPlot <- ggplot(df.probWin, aes(x=time, y=evalScore, group=cage)) + geom_line (size =1.5, aes (colour=cage)) +geom_point(aes(colour=diet), size = 4) +
  scale_color_manual (values=c("red", "green")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlot

## Plotting each animals as a different line 24 hours steps
# Color scale
colors10 <- RColorBrewer::brewer.pal (10,"Paired")
colors20 <- c(colors10, colors10)

#Filtering just HF animals
df.probWinHF<- df.probWin [df.probWin$diet == "HF diet",]

probLinesPlotByAnimal <- ggplot(df.probWinHF, aes(x=time, y=evalScore, group=cage)) + geom_line (size =1.5, aes (colour=cage)) +
#   geom_point(aes(colour=diet), size = 4) +
  scale_color_manual (values=colors10) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlotByAnimal

#Plotting each animal as a heatmap of their probability value
heatMapByAnimal <- ggplot(df.probWinHF, aes(time, cage)) + 
                   geom_tile(aes(fill = evalScore), colour = "white") +
                   scale_fill_gradient(low = "red", high = "yellow") +
                   scale_x_discrete (breaks = seq (1, 21, 5))

#                    scale_fill_gradientn (colours = c('green', 'green', 'green', 'black', 'red', 'red', 'red'),
#                       values   = c(0,  -50, -100, -150, -200, -250, -300, -350, -400), guide = "colorbar", limits=c(-400,-0),
# #                       labels = c("0","-50","-100","-150", "-200", "-250", "-300"), name ="Fold Change",                            
#                       rescaler = function(x,...) x, oob = identity)

heatMapByAnimal

# Jitter not all points in the same axis but moved a little bit so they are not on top of each other
df.probWin <- df.probWin [ df.probWin$time <= 20, ] 
probLinesPlotJitter <- ggplot (df.probWin, aes(x=time, y=evalScore, group=cage)) + 
  geom_jitter (position = position_jitter(width = .1), aes(colour=diet), size=4) +
  scale_color_manual (values=c("red", "green")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") 
# + theme (legend.position = "none") 
# + labs (title = title)  
# + geom_vline(xintercept = 1:25, color="lightgrey") 

probLinesPlotJitter

## Two plots one with light periods and one with night periods
# Only when we are working with step size = 12 h
df.probWinStep12h <- df.probWin       
            
df.probWinStep12h$phase <-  sapply (df.probWinStep12h$time, y <- function (x) { if (x - as.integer (x) == 0) return ("Dark phase") else {return ("Light phase")}})
df.probWinStep12h$dietPhase <- paste (df.probWinStep12h$diet, df.probWinStep12h$phase, sep="-")
probLinesPlot <- ggplot(df.probWinStep12h, aes(x=time, y=evalScore, group=cage)) + geom_point(aes(colour=dietPhase), size = 4) +
  scale_color_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)

probLinesPlot

probLinesPlotJitter <- ggplot(df.probWinStep12h, aes(x=time, y=evalScore, group=cage)) +
  geom_jitter (position = position_jitter(width = .1), aes(colour=dietPhase), size=4) +
  scale_color_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)")  
# + theme (legend.position = "none")
probLinesPlotJitter

## Plotting each animals as a different line 24 hours steps
# Color scale
colors10 <- RColorBrewer::brewer.pal (10,"Paired")
colors20 <- c(colors10, colors10)

#Filtering just HF animals
df.probWinHF<- df.probWin [df.probWin$diet == "HF diet",]

probLinesPlotByAnimal <- ggplot(df.probWinHF, aes(x=time, y=evalScore, group=cage)) + geom_line (size =1.5, aes (colour=cage)) +
  #   geom_point(aes(colour=diet), size = 4) +
  scale_color_manual (values=colors10) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlotByAnimal

#Plotting each animal as a heatmap of their probability value
heatMapByAnimal <- ggplot(df.probWinHF, aes(time, cage)) + 
  geom_tile(aes(fill = evalScore), colour = "white") +
  scale_fill_gradient(low = "red", high = "yellow") +
  scale_x_discrete (breaks = seq (1, 21, 5))

##############

## Plotting each animals as a different line 12 hours steps 
## LIGHT Phase
# Color scale
colors10 <- RColorBrewer::brewer.pal (10,"Paired")
colors20 <- c(colors10, colors10)

#Filtering just HF animals
df.probWinStep12h_HF <- df.probWinStep12h [df.probWinStep12h$diet == "HF diet",]

#Filtering dark periods
df.probWinStep12h_HF_light <- df.probWinStep12h_HF [df.probWinStep12h_HF$phase == "Light phase",]


probLinesPlotByAnimal <- ggplot(df.probWinStep12h_HF_light, aes(x=time, y=evalScore, group=cage)) + geom_line (size =1.5, aes (colour=cage))+ 
#                                   geom_point(aes(colour=diet), size = 4) +
   scale_color_manual (values=colors10) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlotByAnimal

#Plotting each animal as a heatmap of their probability value
heatMapByAnimal <- ggplot(df.probWinStep12h_HF_light, aes(time, cage)) + 
  geom_tile(aes(fill = evalScore), colour = "white") +
  scale_fill_gradient(low = "red", high = "yellow") +
  scale_x_discrete (breaks = seq (1, 21, 5))

heatMapByAnimal

## DARK Phase
# Color scale
colors10 <- RColorBrewer::brewer.pal (10,"Paired")
colors20 <- c(colors10, colors10)

#Filtering just HF animals
df.probWinStep12h_HF <- df.probWinStep12h [df.probWinStep12h$diet == "HF diet",]

#Filtering dark periods
df.probWinStep12h_HF_dark <- df.probWinStep12h_HF [df.probWinStep12h_HF$phase == "Dark phase",]


probLinesPlotByAnimal <- ggplot(df.probWinStep12h_HF_dark, aes(x=time, y=evalScore, group=cage)) + geom_line (size =1.5, aes (colour=cage))+ 
  #                                   geom_point(aes(colour=diet), size = 4) +
  scale_color_manual (values=colors10) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probLinesPlotByAnimal

#Plotting each animal as a heatmap of their probability value
heatMapByAnimal <- ggplot(df.probWinStep12h_HF_dark, aes(time, cage)) + 
  geom_tile(aes(fill = evalScore), colour = "white") +
  scale_fill_gradient(low = "red", high = "yellow") +
  scale_x_discrete (breaks = seq (1, 21, 5))

heatMapByAnimal



# Boxplots along time
df.probWinStep12h$time <-  sapply (df.probWinStep12h$time, y <- function (x) { if (x - as.integer (x) == 0) return (as.integer (x)) else {return (as.integer (x) + 1)}})
df.probWinStep12h$time <- as.factor (df.probWinStep12h$time)

probBoxPlots <- ggplot(df.probWinStep12h, aes (x=time, y=evalScore, fill = dietPhase)) + 
  geom_boxplot (size =0.5, colour='white') +
  scale_fill_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)

probBoxPlots 

## same plot but with lines
## First I have to calculate median
class (df.probWinStep12h$evalScore)
class (df.probWinStep12h$diet)
df.probWinStep12h$phase <- as.factor (df.probWinStep12h$phase)
df.probWinStep12h$time <- as.factor (df.probWinStep12h$time)

# Calculation of summary df (median)
summaryProbWinStep12 <- ddply (df.probWinStep12h, .(dietPhase, time), function(x) summary (x$evalScore))
lineMedianProbWinStep12 <- ggplot (data = summaryProbWinStep12, aes (x=time, y = Median, colour = dietPhase, group=dietPhase), linetype = "dashed", size=2) + 
  scale_color_manual("group", values = c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  geom_line (size=0.5) + 
  labs (y = "Median\n") + labs (x = "\ntime (days)")  + scale_x_discrete (breaks=seq(0, 20, 5)) 
# + labs (title = title)
lineMedianProbWinStep12 

class(df.probWinStep12h$time)
probBoxPlots <- ggplot(df.probWinStep12h, aes (x=time, y=evalScore, group = dietPhase)) + 
  geom_line (size =1.5, aes (colour=dietPhase) ) +
  scale_color_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
#   scale_fill_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +
  labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)

probBoxPlots 

colors()[117]
colors()[47]
