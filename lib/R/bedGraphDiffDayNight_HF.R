#!/usr/bin/env Rscript

#############################################################
### Jose A Espinosa. CSN/CB-CRG Group. March 2014         ###
#############################################################
### A script to read genome browser files in order to     ###
### statistically compare the night periods of the control###
### with respect to the case                              ###
### Cage 6 out Problems in signal, deleted from folder    ###
#############################################################

##Loading libraries
library (ggplot2)
library (plyr)
#install.packages("reshape")
library (reshape) #melt
library (gtools) #foldchange
library (plotrix) 
library (grid) #unit function

##Getting HOME directory
home <- Sys.getenv("HOME")

## Functions
## Functions for GB files reading
# source ("/Users/jespinosa/phecomp/lib/R/f_readGBFiles.R")
source ("/Users/jespinosa/git/phecomp/lib/R/f_readGBFiles.R")
# source ("/Users/jespinosa/phecomp/lib/R/plotParamPublication.R")
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")
#Path to folder with intervals files for each cage
path2Tbls <- paste (home, "/phecomp/processedData/201205_FDF_CRG/GBfilesSync8AM/20140310_habDev/combCh/", sep = "")

colors <- RColorBrewer::brewer.pal (8, "Paired")[3:6]

### HF
# Animal 6 tbl file has been eliminated from the folder
# rm combChcage06chfood_fatfood_fat34.tbl

## HF group declaration of variables
patternHF <- "combChcage[0-1][0,2,4,6,8]chfood(.*)\\.tbl"
labelHF <- "HF"

pattern <- patternHF
label <- labelHF

tblHF <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=1800)
head (tblHF)

### CTRLs
patternCtrl <- "combChcage[0-1][1,3,5,7,9]chfood(.*)\\.tbl"
labelCtrl <- "Ctrl"

pattern <- patternCtrl
label <- labelCtrl

tblCtrl <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=1800)
head (tblCtrl,49)
tail (tblCtrl,50)

tblAll <- rbind (tblCtrl,tblHF)
str (tblAll)
tblAll$week <- as.factor (tblAll$week)
tblAll$group <- as.factor (tblAll$group)

## BOXPLOT SHOWING THE AVERAGE INTAKE OF 30 MINUTES PERIOD ALONG THE WEEKS AND SEPARATED BY DAY AND NIGHT
boxPlots <- ggplot(tblAll, aes (week, value, fill = group)) + 
            geom_boxplot() +          
#           scale_fill_manual(name = "Group", values = c("green", "brown"), labels = c ("Control", "High-fat")) +
            scale_fill_manual (name = "", values = colors [c(2,4)], labels = c ("Control", "High-fat")) +
            #scale_fill_manual (name = "Group", values = c ("green", "brown")) +
            labs (title = "Average intake during 30 min periods\n") +
            scale_y_continuous (limits=c(0, 1)) 
          
#legend
boxPlots + theme (legend.key.height = unit (1,"line")) + facet_wrap (~phase) 

head (tblAll,50)

## BOXPLOT SHOWING THE AVERAGE INTAKE OF 30 MINUTES PERIOD ALONG THE WEEKS AND SEPARATED BY DAY AND NIGHT
tblAll$indexPh <- as.factor (tblAll$indexPh)
boxPlots <- ggplot (tblAll, aes (indexPh, value, fill = group)) + 
                    geom_boxplot() +
                    scale_fill_manual(name = "", values = colors [c(2,4)], labels = c ("Control", "High-fat")) +
                    labs (title = "Average intake during 30 min periods\n")+  
                    labs (x = "\nDay phases", y = "intake (g)\n", fill = NULL) +
                    scale_y_continuous(limits=c(0, 1)) +
                    facet_wrap (~phase)

#legend
boxPlots + theme (legend.key.height = unit (1,"line")) + 
           scale_x_discrete(labels = tblAll$timeDay)

# Mean Calculation by different grouping factors
# with (df.weekStats [which (df.weekStats$group == controlGroupLabel),] , aggregate (cbind (Number, Avg_Duration, Avg_Intake, Rate), list(channel=channel, group=group, period=period), mean))
head (with (tblCtrl , aggregate (cbind (phase, group), list (value=value), mean)))

# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), mean, std.error))
with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, week=week), mean))
meanCtrl.byWeek <- with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group), mean))
with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# Cleaning problematic files
tblCtrl <- tblCtrl [-(which (tblCtrl$week==5 & tblCtrl$Filename=="combChcage07chfood_scfood_sc34.tbl")),]
tblCtrl <- tblCtrl [-(which (tblCtrl$week==5 & tblCtrl$Filename=="combChcage17chfood_scfood_sc34.tbl")),]
tblCtrl <- tblCtrl [-(which (tblCtrl$week==7 & tblCtrl$Filename=="combChcage03chfood_scfood_sc34.tbl")),]
meanCtrl.byWeek <- with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))


# with (tblHF , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), mean))
with (tblHF , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblHF , aggregate (cbind (value), list (phase=phase, group=group, week=week), mean))
meanHF.byWeek<- with (tblHF , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblHF , aggregate (cbind (value), list (phase=phase, group=group), mean))
with (tblHF , aggregate (cbind (value), list (phase=phase, group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# Join the two tables 
meanAll.byWeek <- rbind (meanCtrl.byWeek, meanHF.byWeek)
meanAll.byWeek$mean <- meanAll.byWeek$value [,1]
meanAll.byWeek$std.error <- meanAll.byWeek$value [,2]

# Plotting all
str (meanAll.byWeek)
# Weeks should be numeric to plot lines
meanAll.byWeek$week <- as.numeric (meanAll.byWeek$week)

meanAll.byWeek$mean - meanAll.byWeek$std.error
meanAll.byWeek$groupPhase <- paste (meanAll.byWeek$group, meanAll.byWeek$phase)
meanAll.byWeek$ymax <- meanAll.byWeek$mean + meanAll.byWeek$std.error
meanAll.byWeek$ymin <- meanAll.byWeek$mean - meanAll.byWeek$std.error

# I filter only 9 weeks of the experiment, hab + 7 weeks as in the heatmap
# meanAll.byWeek8Weeks <- meanAll.byWeek [meanAll.byWeek$week < 9 , ]

# In the new version no hab and 8 weeks
meanAll.byWeek8Weeks <- meanAll.byWeek [meanAll.byWeek$week < 10 & meanAll.byWeek$week != 1 , ]

meanAll.byWeek8Weeks$week <- meanAll.byWeek8Weeks$week -1 

pd <- position_dodge(.1)
colors <- RColorBrewer::brewer.pal (8, "Paired")[3:6]
meanAll.byWeek

gAllByWeek <- ggplot (meanAll.byWeek8Weeks, aes(x = week, y = mean, colour = groupPhase)) + 
  #   scale_x_continuous (breaks=fractHour) + 
                      labs (title = "Average intake during\n30 min periods\n") +  
                      labs (x = "\nDevelopment phase (weeks)", y = "g/30 min\n", fill = NULL) + 
                      geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
                      #   geom_line (position=pd, size=1)  + 
                      #   geom_point (position=pd) +
                      geom_line (size=1)  + 
                      geom_point () +
                      scale_y_continuous (limits = c(0, 0.6005)) +
#                       scale_x_continuous (breaks = c(0:7)) 
                      scale_x_continuous (breaks = c(1:9)) 

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
                                   name="",
                                   values = colors) + 
                                   theme (legend.key.height = unit (1, "line")) #distance between lines in legend
gAllByWeek

setwd("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/submissionEuNeuroPsycho")
ggsave (gAllByWeek, file=paste(home, "/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/submissionEuNeuroPsycho/", "figS3A.tiff", sep=""), 
        width=12, height=7, dpi=400)

## Ratio between day and night
mean (meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "Ctrl day"] /meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "Ctrl night"])
mean (meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "HF day"] /meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "HF night"])

#STATS
# para hacer la anova de lo que sale en el grafico tendr??a que tener un valor para cada d??a de la semana por animal (cage)
# los animales si hago este dise??o no pueden estar repetidos entre dia y noche
meanAnimalByWeekHF <- with (tblHF , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanAnimalByWeekCtrl <- with (tblCtrl , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanAnimalByWeek <- rbind (meanAnimalByWeekHF, meanAnimalByWeekCtrl)
meanAnimalByWeek$animal <- gsub ("combChcage" , "",meanAnimalByWeek$animal)
meanAnimalByWeek$animal <- gsub ("chfood_scfood_sc34.tbl" , "",meanAnimalByWeek$animal)
meanAnimalByWeek$animal <- gsub ("chfood_fatfood_fat34.tbl" , "",meanAnimalByWeek$animal)
# ifelse (meanAnimalByWeek$phase == "night" ) {meanAnimalByWeek$animal <- meanAnimalByWeek$animal + 30, meanAnimalByWeek$animal <- meanAnimalByWeek$animal}
meanAnimalByWeek$animal <- paste (meanAnimalByWeek$animal, meanAnimalByWeek$phase, sep="")
meanAnimalByWeek$groupAndPhase <- paste (meanAnimalByWeek$group, meanAnimalByWeek$phase, sep="") 
meanAnimalByWeek$mean <- meanAnimalByWeek$value [,1]
meanAnimalByWeek$std.error <- meanAnimalByWeek$value [,2]
head (meanAnimalByWeek)

# I just take what I need for ANOVA is simple to deal with this new df
meanAnimalByWeekAnova <- meanAnimalByWeek [,c("animal", "groupAndPhase", "mean", "week")]

# I filter only 9 weeks of the experiment, hab + 7 weeks as in the heatmap
meanAnimalByWeekAnova <- meanAnimalByWeekAnova [meanAnimalByWeekAnova$week < 9 , ]

#As I am using a repeated measures design I have to replace the missing values with the mean of the others
# tblCtrl <- tblCtrl [-(which (tblCtrl$week==5 & tblCtrl$Filename=="combChcage07chfood_scfood_sc34.tbl")),]
# tblCtrl <- tblCtrl [-(which (tblCtrl$week==5 & tblCtrl$Filename=="combChcage17chfood_scfood_sc34.tbl")),]
# tblCtrl <- tblCtrl [-(which (tblCtrl$week==7 & tblCtrl$Filename=="combChcage03chfood_scfood_sc34.tbl")),]

# week 5 animal 7
head (meanAnimalByWeekAnova)
meanWeek5lightPhase <- meanCtrl.byWeek [which (meanCtrl.byWeek$phase == "day" & meanCtrl.byWeek$week == "5"),4][1]
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("07day", "Ctrlday",meanWeek5lightPhase, 5))
meanWeek5darkPhase <- meanCtrl.byWeek [which (meanCtrl.byWeek$phase == "night" & meanCtrl.byWeek$week == "5"),4][1]
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("07night", "Ctrlnight",meanWeek5darkPhase, 5))

# week 5 animal 17
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("17day", "Ctrlday",meanWeek5lightPhase, 5))
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("17night", "Ctrlnight",meanWeek5darkPhase, 5))

# week 7 animal 3
meanWeek7lightPhase <- meanCtrl.byWeek [which (meanCtrl.byWeek$phase == "day" & meanCtrl.byWeek$week == "7"),4][1]
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("03day", "Ctrlday",meanWeek7lightPhase, 7))
meanWeek7darkPhase <- meanCtrl.byWeek [which (meanCtrl.byWeek$phase == "night" & meanCtrl.byWeek$week == "7"),4][1]
meanAnimalByWeekAnova <- rbind (meanAnimalByWeekAnova, c("03night", "Ctrlnight",meanWeek7darkPhase, 7))

meanAnimalByWeekAnova <- within (meanAnimalByWeekAnova, {
                          groupAndPhase <- factor (groupAndPhase)
                          week <- factor(week)
                          animal <- factor(animal)
                        })
meanAnimalByWeekAnova$mean <- as.numeric (meanAnimalByWeekAnova$mean)
aov.weekIntakes = aov (mean ~ groupAndPhase * week + Error (animal), data=meanAnimalByWeekAnova)
summary (aov.weekIntakes)

# POST-hoc test
# for group
with (meanAnimalByWeekAnova, pairwise.t.test (mean, groupAndPhase,  p.adjust.method="bonf"))
with (meanAnimalByWeekAnova, pairwise.t.test (mean, week ,  p.adjust.method="bonf"))














meanAnimalByWeekAnova$groupAndPhase <- as.factor (meanAnimalByWeekAnova$groupAndPhase)
meanAnimalByWeek$week <- as.factor (meanAnimalByWeek$week)
meanAnimalByWeek$animal <- as.factor (meanAnimalByWeek$animal)



str(test)
str (demo1)

test$animal <- as.numeric (test$animal)
test$animal
test2$animal


head (meanAnimalByWeek)

head (test)
str (test)
demo1.aov <- aov(pulse ~ group * time + Error(id), data = demo1)
summary (demo1.aov)
str (meanAnimalByWeek)
meanAnimalByWeek$mean
meanAnimalByWeek$groupAndPhase
meanAnimalByWeek$animal
meanAnimalByWeek$week
test2 <- test [which (test$groupAndPhase == "HFday" | test$groupAndPhase == "HFnight"),] 
test2 <- test [which (test$groupAndPhase == "Ctrlnight" | test$groupAndPhase == "Ctrlday"),]

## El problema est?? en los controles

                      | test$groupAndPhase == "Ctrlnight"),]
test
demo1.aov <- aov       (pulse ~ group * time + Error(id), data = demo1)
summary(demo1.aov)
(subject/test)
aov.weekIntakes = aov (mean ~ groupAndPhase * week + Error (animal/week), data=test2)

summary (aov.weekIntakes)










str (demo1)


summary (demo1.aov)

m1.meanAnimalByWeek <- lmer (value ~ groupAndPhase * week + (1 + week |animal), meanAnimalByWeekForAnova)
summary (m1.meanAnimalByWeek)
anova (m1.meanAnimalByWeek)
?anova
str (meanAnimalByWeekForAnova)
test <- meanAnimalByWeekForAnova [which (as.numeric (meanAnimalByWeekForAnova$week) < 3),]
aov.weekIntakes = aov (value ~ groupAndPhase * week + Error (animal), data=test)
summary (aov.weekIntakes)
test2
demo1 <- read.csv("http://www.ats.ucla.edu/stat/data/demo1.csv")
demo1
demo1 <- rbind (demo1,c(9,3,20,1), c(9,3,20,2),c(9,3,20,3), c(10,3,20,1), c(10,3,20,2), c(10,3,20,3), c(11,3,20,1), c(11,3,20,2), c(11,3,20,3) )
## Convert variables to factor
demo1 <- within(demo1, {
  group <- factor(group)
  time <- factor(time)
  id <- factor(id)
})

str
tblAllColForAnova <- meanAnimalByWeek [, c ("Filename", "value", "week", "groupAndPhase")]
aov.weekIntakes = aov (value ~ groupAndPhase * week + Error (Filename), data=tblAllColForAnova)
summary (aov.weekIntakes)
str (tblAll)
demo1.aov <- aov(pulse ~ group * time + Error(id), data = demo1)
demo1.aov <- aov(pulse ~ group * time + Error(id), data = demo1)

summary(demo1.aov)

summary (aov.weekIntakes)
lmer(Obs ~ Treatment * Day + (1+Day|Subject), mydata)
lmer (value ~ groupAndPhase * week + (1 + week | Filename), tblAll)
