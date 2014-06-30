##################################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2014                ###
##################################################################
### This script plots the probability of each cage along time  ###
### I use data to estimate a model for example habituation     ###
### then I calculate the probability of the sequence of events ###
### produced by each animal during a given a time lapse (for   ###
### example habituation and first two weeks of development)    ###
##################################################################

##### MIRAR LOS DATOS PORQUE SON DIFERENTES EL 10 Y EL 2??
library (ggplot2)
library (grid) #viewport

source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

home <- Sys.getenv("HOME")

path2Tbl <- "/phecomp/20140512_probOfIncreasingInt/20120502_FDF_habDevW1_W2/prob/tableResults.tbl"
# path2Tbl <- "/phecomp/20140512_probOfIncreasingInt/20130130_FCSC_habDevW1_W2/prob/tableResults.tbl"
df.probSeq <- read.table (paste (home, path2Tbl, sep = ""), sep="\t", dec=".", header=T, stringsAsFactors=T)
head (df.probSeq)
df.probSeq$time <- df.probSeq$step * 300 / (3600*24) 

# For high-fat food
df.probSeq <- labelGroups (df.probSeq)

# For free-choice
# df.probSeq <- labelGroups (df.probSeq, ctrlGroup = "even", labelCase = "FC diet")

df.probSeq$cage <- as.factor (df.probSeq$cage)
df.probSeq$diet <- as.factor (df.probSeq$diet)
probLinesPlot <- ggplot(df.probSeq, aes(x=time, y=evalScore, group=cage)) + geom_line(aes(colour=diet), size = 1.5) +
                 scale_color_manual (values=c("red", "darkgreen")) +
                 labs (y = "score log(p)") + labs (x = "time (days)")

probLinesPlot
# Adding cage number
df.probSeqLastPoint <- df.probSeq [which (df.probSeq$time == max(df.probSeq$time)),]
df.probSeqLastPoint
# bigPlot <- probLinesPlot + geom_text (data = df.probSeqLastPoint, aes (x =time+1, y =evalScore, label = cage), size=6, face="bold")
bigPlot <- probLinesPlot                           

# For free choice
# df.probSeqSmall <- df.probSeq [which (df.probSeq$step > 6000), ]

# For high-fat
df.probSeqSmall <- df.probSeq [which (df.probSeq$step > 4500), ]

smallPlot <- ggplot(df.probSeqSmall, aes(x=time, y=evalScore, group=cage)) + 
             geom_line(aes(colour=diet), size = 1.5) +
             scale_color_manual (values=c("red", "darkgreen"))
smallPlot
smallPlot <- smallPlot + theme (panel.border = element_blank()) +
  labs (y = NULL, x=NULL) +
  scale_y_continuous(breaks = NULL) +
#   scale_x_continuous (breaks = NULL)+
  theme (legend.position = "none", axis.text.x = element_text (size=12), plot.title = element_text (size=12)) +
  labs(title = "Last period") 
  
smallPlotBlack <- smallPlot  + theme (plot.background = element_rect(fill = 'black', colour = 'black'),
                                       axis.title.x = element_text (color='white'),
                                       axis.title.y = element_text (color='white'),
                                       plot.title = element_text (color='white', size=base_size * 2),
                                       axis.text.x = element_text (color='white'),
                                       axis.text.y = element_text (color='white'),                       
                                       legend.title = element_text (color='white'),
                                       legend.text = element_text (color='white'),
                                       legend.background = element_rect(fill = 'black'),
                                       legend.key = element_rect(fill = 'black') 
) 
# smallPlotLines <- smallPlotLines + geom_text (data = df.probSeqLastPoint, aes (x =step+200, y =evalScore, label = cage), size=6, face="bold")
# smallPlotLines

bigPlotBlack <- bigPlot + theme (plot.background = element_rect(fill = 'black', colour = 'black'),
                 axis.title.x = element_text (color='white'),
                 axis.title.y = element_text (color='white'),
                 plot.title = element_text (color='white', size=base_size * 2),
                 axis.text.x = element_text (color='white'),
                 axis.text.y = element_text (color='white'),                       
                 legend.title = element_text (color='white'),
                 legend.text = element_text (color='white'),
                 legend.background = element_rect(fill = 'black'),
                 legend.key = element_rect(fill = 'black') 
) 

## Combining the 2 plots in the same figure
# Placing and setting the size of the subplot
vp <- viewport (width = 0.45, #height = 0.30, x = 0.50,
                height = 0.4, x = 0.55,
                y = unit (27, "lines"), just = c ("left",
                                                  "top"))

full <- function() 
{
  print(bigPlot)
  element_blank()
  print(smallPlot, vp = vp)           
}
full ()

fullBlack <- function() 
{
  print(bigPlotBlack)
  element_blank()
  print(smallPlotBlack, vp = vp)           
}
fullBlack ()
chr1:820,000-1,508,013