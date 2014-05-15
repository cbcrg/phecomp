##################################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2014                ###
##################################################################
### This script plots the probability of each cage along time  ###
### I use data to estimate a model for example habituation     ###
### then I calculate the probability of the sequence of events ###
### produced by each animal during a given a time lapse (for   ###
### example habituation and first two weeks of development)    ###
##################################################################

library (ggplot2)

home <- Sys.getenv("HOME")

path2Tbl <- "/phecomp/20140512_probOfIncreasingInt/20120502_FDF_habDevW1_W2/prob/tableResults.tbl"

df.probSeq <- read.table (paste (home, path2Tbl, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=T)
head (df.probSeq)
df.probSeq <- labelGroups (df.probSeq)
df.probSeq$cage <- as.factor (df.probSeq$cage)
df.probSeq$diet <- as.factor (df.probSeq$diet)
probLinesPlot <- ggplot(df.probSeq, aes(x=step, y=evalScore, group=cage)) + geom_line(aes(colour=diet), size = 1.5)

# Adding cage number
df.probSeqLastPoint <- df.probSeq [which (df.probSeq$step == max(df.probSeq$step)),]
df.probSeqLastPoint
probLinesPlot + geom_text (data = df.probSeqLastPoint, aes (x =step+200, y =evalScore, label = cage), size=6, face="bold")
