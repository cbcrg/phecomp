#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. April 2013                       ###
#############################################################################
### Phecomp                                                               ###
### Plot weights of mice in boxplot by week                               ### 
#############################################################################

##Loading libraries
library (ggplot2)
library (plyr)
library(reshape)
library (grid) #viewport
library (plotrix) # std.error ()

##Getting HOME directory
home <- Sys.getenv("HOME")

source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

# setwd ("/Users/jespinosa/phecomp/data/CRG/20130130_FCSC_CRG/")


# High fat group 20120502
path2WeightTbl<- paste (home, "/phecomp/data/CRG/20120502_FDF_CRG/weightData/20120502to0711rawWeightsHabDevOneWeightPerWeek.tbl", sep="")
rawWeight <- read.table (path2WeightTbl, sep=" ", dec=".", header=T, stringsAsFactors=T)
head (rawWeight)

## Calculation of delta weight to respect last weight of the habituation phase
iniW <- rawWeight$Hab
deltaWeight <-sapply (rawWeight [,c (-1,-2)], y <- function (x, iniW) { return ((x - iniW) / x * 100) }, iniW <- rawWeight$Hab )
deltaWeight <- as.data.frame (deltaWeight)
deltaWeight$cage <- rawWeight$cage
warnings()
## HIGH-FAT group
#Label by experimental group (control, free choice, force diet...)
#Hard code
caseGroupLabel <- "HF diet"
controlGroupLabel <- "SC diet"

nAnimals <- 18
cage <- c (1 : nAnimals)
group <- c (rep (controlGroupLabel, nAnimals/2), rep (caseGroupLabel, nAnimals/2))
df.miceGroup <- data.frame (cage, group)
df.miceGroup$group [which (cage %% 2 != 0)] <- controlGroupLabel
df.miceGroup$group [which (cage %% 2 == 0)] <- caseGroupLabel

#Adding group labels to the table
deltaWeight <- merge (deltaWeight, df.miceGroup, by.x= "cage", by.y = "cage")
head (deltaWeight)

#The data is melted maintaining cage and group columns
m.deltaWeight <- melt (deltaWeight, id = c("cage", "group"))
colnames (m.deltaWeight) [3] <- "DWeek"
colnames (m.deltaWeight) [4] <- "deltaWeight"

head (m.deltaWeight)

## PLOTTING
## Boxplots of delta weight
boxPlots <- ggplot(m.deltaWeight, aes (DWeek, deltaWeight, fill = group)) + 
  geom_boxplot() +
  scale_fill_manual(name = "Group", values = c("red", "darkgreen")) +
  #scale_fill_manual (name = "Group", values = c ("green", "brown")) +
  labs (title = "Boxplots % of delta weight by development week") 
#+
#facet_wrap (~group)
boxPlots

## Get summary table with min, max, mean, median, 1Q and 3Q, and standard error
pDayMeanIntake <- ddply (m.deltaWeight, ~group, summarize, pDayMean = getPDayMean (pDayStart, pDayEnd, dataFrame=tbl), std.error = getPDayStd.err (pDayStart, pDayEnd, dataFrame=tbl))

summaryDeltaWeight_SE <- with (m.deltaWeight, aggregate (cbind (deltaWeight), list (group=group, DWeek=DWeek),   FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# Set as a column for plot mean and std.error
# summaryDeltaWeight_SE$mean <- rbind (meanCtrl.byWeek, meanFC_Choc.byWeek, meanFC_SC.byWeek)
summaryDeltaWeight_SE$mean <- summaryDeltaWeight_SE$deltaWeight [,1]
summaryDeltaWeight_SE$std.error <- summaryDeltaWeight_SE$deltaWeight [,2]

## Line plot with error bars
weightLinesSError <- ggplot (summaryDeltaWeight_SE, aes (DWeek, mean, group = group)) + 
  geom_errorbar (aes (ymin=mean-std.error , ymax=mean+std.error), colour = "black", width=.1) +
  geom_line(size =1.5, aes (colour=group)) +
  geom_point (aes(colour=group), size = 3) +
  scale_color_manual (values=c("red", "darkgreen")) +
  theme (legend.position = "none") +
  labs (y = "Weight Increase (%)\n") + labs (x = "\nTime (Weeks)")
  
weightLinesSError












#   scale_fill_manual(name = "Group", values = c("red", "darkgreen")) +
#   scale_fill_manual (name = "Group", values = c ("green", "brown")) +
  labs (title = "Boxplots % of delta weight by development week") 
geom_line (size =1.5, aes (colour=dietPhase) ) +
  scale_color_manual (values=c("red", "deeppink1", "darkgreen" , "chartreuse")) +

geom_point(aes(colour=diet), size = 4)
labs (y = "score log(p)\n") + labs (x = "\ntime (days)") + labs (title = title)
probBoxPlots <- ggplot(df.probWinStep12h, aes (x=time, y=evalScore, group = dietPhase)) + 
  geom_line (size =1.5, aes (colour=dietPhase) ) 


subplot <- ggplot (data = summaryDeltaWeight, aes (x=DWeek, y = Mean, colour = group, group=group), linetype = "dashed", size=2) + 
  scale_color_manual("group", values = c("darkgreen", "brown")) +
  labs (panel.border = element_blank()) +
  labs (y = NULL, x=NULL) + #scale_x_continuous (breaks = NA) +
  scale_y_continuous(breaks = NULL) +
  scale_x_discrete (breaks = NULL)+
  theme (legend.position = "none") +
  labs (title = "Means") +
  geom_line (size=1) 

theme_subPlot <- function() 
{
  theme_update(panel.background =theme_rect (fill='grey90'),
               plot.background = theme_blank ())        
}

subplot

## Combining the 2 plots in the same figure
# Placing and setting the size of the subplot
vp <- viewport (width = 0.3, height = 0.30, x = 0.07,
                y = unit (24, "lines"), just = c ("left",
                                                  "top"))

# Creating the function to plot the whole plot
full <- function() 
{
  print(boxPlots)
  theme_white()
  print(subplot, vp = vp)           
}

full ()

#Gray background and big titles
base_size<-12
dailyInt_theme <- theme_update (
  axis.text.x = theme_text (angle = 90, hjust = 1, size = base_size * 1.5),                   
  axis.text.y = theme_text (size = base_size * 1.3),
  axis.title.x = theme_text (size=base_size * 1.5, face="bold"),
  axis.title.y = theme_text (size=base_size * 1.5, angle = 90, face="bold"),
  strip.text.x = theme_text (size=base_size * 1.3, face="bold"),#facet titles size 
  strip.text.y = theme_text (size=base_size * 1.3, face="bold"),
  plot.title = theme_text (size=base_size * 1.5, face="bold"), 
  legend.text = theme_text (size=base_size * 1.2),
  legend.title = theme_text (size=base_size * 1.2),
  panel.grid.major = theme_line (colour = "grey90"),
  panel.grid.minor = theme_blank(), 
  axis.ticks = theme_blank())

# Each animal as a line of its delta weight
# Lines of percentage of weight of each animal by weeks
p <- ggplot (m.deltaWeight, aes (x=DWeek, y = deltaWeight, colour = group, group=cage)) + 
  #scale_fill_manual (name = "group", values = c("green", "brown")) +
  scale_color_manual("group", values = c("darkgreen", "brown")) +
  opts (title = "Evolution of % of delta weight increased by animal")+
  geom_line (size=1)   
p

#adding a line with mean values of each group
pMeans <- p + geom_line (data = summaryDeltaWeight, aes (x=DWeek, y = Mean, colour = group, group=group), linetype = "dashed", size=2) 
pMeans <- p + geom_line (data = summaryDeltaWeight, aes (x=DWeek, y = Mean, colour = group, group=group), linetype = "dashed", size=2)
pMeans 

#adding the name of each cage to the lines
# m.deltaWeightLastWeek <- m.deltaWeight [which (m.deltaWeight$DWeek == "DPW9_1"),] 
m.deltaWeightLastWeek <- m.deltaWeight [which (m.deltaWeight$DWeek == "DP_9"),] 

pMeans + geom_text (data = m.deltaWeightLastWeek, aes (x =DWeek, y =deltaWeight, label = cage), size=6, face="bold") 

m.deltaWeightLastWeek <- m.deltaWeight [which (m.deltaWeight$DWeek == "DPW9_1"),] 
pMeans + geom_text (data = m.deltaWeightLastWeek, aes (x = DWeek, y =deltaWeight, label = cage), size=6, face="bold") +
  xlab ("weeks") + ylab ("Delta Weight (%)")

###############################
#The two plots in the same plot
pMeans <- p + geom_text (data = m.deltaWeightLastWeek, aes (x = DWeek, y =deltaWeight, label = cage), size=6, face="bold")

vp <- viewport (width = 0.4, height = 0.4, x = 0.45,
                y = unit (15, "lines"), just = c ("right",
                                                  "bottom"))       
full ()

theme_white <- function() {
  theme_update(#panel.background = theme_blank(),
    panel.grid.major = theme_blank())
}

theme_set(theme_bw())
full <- function() {
  print(pMeans)
  theme_set(theme_bw(base_size = 8))
  theme_white()
  print(subplot, vp = vp)
  theme_set(theme_bw())
}

full ()

?viewport
ggplot(ChickWeight, aes(x=Time, y=weight, colour=Diet, group=Chick)) +
  geom_line()

a_plot <- ggplot(cars, aes(speed, dist)) + geom_line()

#A viewport taking up a fraction of the plot area
vp <- viewport(width = 0.4, height = 0.4, x = 0.8, y = 0.2)
print(a_plot)
print(a_plot, vp = vp)

## Identifying outliers of boxplot
#Control group 
#Week DPW9_1:
m.deltaWeight
min (m.deltaWeight$deltaWeight [m.deltaWeight$DWeek == "DPW9_1" & m.deltaWeight$group == "control" ])
# --> Cage 10 with -2.167 % DW

#Week DPW8_2:
min (m.deltaWeight$deltaWeight [m.deltaWeight$DWeek == "DPW8_2" & m.deltaWeight$group == "control" ])
# --> Cage 10 with -4.93653
max (m.deltaWeight$deltaWeight [m.deltaWeight$DWeek == "DPW8_2" & m.deltaWeight$group == "control" ])
# --> Cage 12 with 15.8371 

#Week DPW7_2:
min (m.deltaWeight$deltaWeight [m.deltaWeight$DWeek == "DPW7_2" & m.deltaWeight$group == "control" ])
# --> Cage 10 with -1.917808

#Week DPW6_1:
min (m.deltaWeight$deltaWeight [m.deltaWeight$DWeek == "DPW6_1" & m.deltaWeight$group == "control" ])
# --> Cage 10 with -11.586052

# Significancy ttest
? t.test
apply (m.deltaWeight [,c('x','z')], 1, function(x) sum(x) )

# T.test of weights between groups (control and free choice)
# With by I subset the dataframe by weeks
# Then I apply the t.test to each of the groups with "with"
ttestRes <- by (m.deltaWeight, m.deltaWeight [,"DWeek"],
                function(x) 
                {
                  with (x, t.test (deltaWeight[group =="freeChoice"], deltaWeight[group == "control"]))$p.value
                } 
)

ttestRes [1]
as.vector (ttestRes)    

## Filter animals 9 and 15 of free choice group
m.deltaWeight9i15Filt <- m.deltaWeight [ - which (m.deltaWeight$cage == 9 | m.deltaWeight$cage == 15 ),]

ttestRes9i15Filt <- by (m.deltaWeight9i15Filt, m.deltaWeight9i15Filt [,"DWeek"],
                        function(x) 
                        {
                          with (x, t.test (deltaWeight[group =="freeChoice"], deltaWeight[group == "control"], alternative = "two.sided", var.equal = TRUE))$p.value
                        } 
)
as.vector (ttestRes9i15Filt)

m.deltaWeight1i9Filt <- m.deltaWeight [ - which (m.deltaWeight$cage == 9 | m.deltaWeight$cage == 1 ),]
rm (ttestRes1i9Filt)
ttestRes1i9Filt <- by (m.deltaWeight1i9Filt, m.deltaWeight1i9Filt [,"DWeek"],
                       function(x) 
                       {
                         with (x, t.test (deltaWeight[group =="freeChoice"], deltaWeight[group == "control"], alternative = "two.sided", var.equal = TRUE))$p.value
                       } 
)


## ASSESSMENT OF THE VALUES OF T.TEST
?t.test
ttestRes1i9Filt
as.vector (ttestRes1i9Filt)
t.test (m.deltaWeight1i9Filt$deltaWeight [which (m.deltaWeight1i9Filt$group == "control" & m.deltaWeight1i9Filt$DWeek == "DPW9_1")],
        m.deltaWeight1i9Filt$deltaWeight [which (m.deltaWeight1i9Filt$group == "freeChoice" & m.deltaWeight1i9Filt$DWeek == "DPW9_1")],
        #alternative = "two.sided",
        #var.equal = TRUE                
)



x<-summary (m.deltaWeight)
x<-"3"
y<-"1"
c (x,y)
rm(x)
ddply (m.deltaWeight, .(DWeek, group), function (x) 
{
  #qnt <- quantile(x$Weight, probs=c(.25, .75))
  H <- 1.5 * IQR (x$Weight)
  meanV <- mean (x$Weight)
  return ( c (H, meanV))
  #return (H)
  #         with (x, t.test (Weight[group =="freeChoice"], Weight[group == "control"]))$p.value
})
ddply (df.logOddTblSlidWin, .(odd_ratio, iteration, group), y <- function (x) { sum <- summary (lm(odd_ratio_value ~ delta_w, data = x))
                                                                                r_sqr <- sum$r.squared
                                                                                return (r_sqr)})
by (m.deltaWeight, m.deltaWeight [,"DWeek" & "freeChoice"], 
    function(x) 
    {
      print (x)
    } 
)

#Printar pesos por grupos
by (m.deltaWeight, m.deltaWeight [,"DWeek"],
    function(x) 
    {
      with (x, print (Weight[group =="freeChoice"]))
    } 
)


xm <- melt(x, id = c('site', 'status')) 
m.deltaWeight 
with (dd, wilcox.test(y[as.numeric(g)==idx[1,i]], 
                      y[as.numeric(g)==idx[2,i]]))$p.value

#kk <- sapply (df, function (x) { x -  (as.numeric(x)) } )
ddply (df, function (x) { x -  (as.numeric(x)) } )
class (as.data.frame (kk))

m.rawWeight <- melt (rawWeight)


# Some toy data
df <- data.frame(Year = rep(c(1:30), each=20), Value = rnorm(600))
str(df)

Note that Year is an integer variable

ggplot(df, aes(Year, Value)) + geom_boxplot()   # One boxplot
df

head (df)

nba <- read.csv("http://datasets.flowingdata.com/ppg2008.csv")
nba$Name <- with(nba, reorder(Name, PTS))
nba
nba.m <- melt(nba)

/Users/jespinosa/phecomp/data/CRG/20130130_FCSC_CRG/20130130to0411rawWeights.tbl