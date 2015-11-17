#!/usr/bin/env Rscript

#############################################################
### Jose A Espinosa. CSN/CB-CRG Group. January 2015       ###
#############################################################
### A script to read genome browser files in order to     ###
### statistically compare the night periods of the control###
### with respect to the case                              ###
### DATA FROM 20130130                                    ###
#############################################################

##Loading libraries
library (ggplot2)
library (plyr)
#install.packages("reshape")
library (reshape) #melt
library (gtools) #foldchange
library (plotrix) #std.error
library (grid) #unit function

## In this case I treat the channels chocolate and SC separated

##Getting HOME directory
home <- Sys.getenv("HOME")

colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]

## Functions
## Functions for GB files reading
source ("/Users/jespinosa/git/phecomp/lib/R/f_readGBFiles.R")
source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

#Path to folder with intervals files for each cage
# path2Tbls <- paste (home, "/phecomp/processedData/20120509_FCSC_UPF/GBfilesSync8AM/20140310_dev2/splitCh", sep = "")
# path2Tbls <- paste (home, "/phecomp/processedData/20120509_FCSC_UPF/GBfilesSync8AM/20140310_realDev/splitCh", sep = "")
# path2Tbls <- paste (home, "/phecomp/processedData/20120509_FCSC_UPF/GBfilesSync8AM/20140310_dev2/splitCh", sep = "")
# path2Tbls <- paste (home, "/phecomp/processedData/20130130_FCSC_CRG/GBfiles/20150112_hab_Dev_NoDeadMouse_w300s/splitCh", sep = "")
path2Tbls <- paste (home,   "/phecomp/processedData/20130130_FCSC_CRG/GBfiles/20150112_hab_Dev_NoDeadMouse/splitCh", sep = "")

## Free Choice Choc group declaration of variables 
patternFC_Choc <- "splitChcage[0-1][1,3,5,7,9]chfood_cd(.*)\\.tbl"
labelFC_Choc <- "FC_Choc"

pattern <- patternFC_Choc
label <- labelFC_Choc

# Window size
tblFC_Choc <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=1800)
# tblFC_Choc <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=300)


head (tblFC_Choc)
tail (tblFC_Choc)

## Free Choice SC group declaration of variables 
patternFC_SC <- "splitChcage[0-1][1,3,5,7,9]chfood_sc(.*)\\.tbl"
labelFC_SC <- "FC_SC"

pattern <- patternFC_SC
label <- labelFC_SC

tblFC_SC <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=1800)
# tblFC_SC <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=300)

head (tblFC_SC)
tail (tblFC_SC)

### CTRLs (We take the combined SC channels and not the separated ones that is why we change the folder)
# path2Tbls <- paste (home, "/phecomp/processedData/20120509_FCSC_UPF/GBfilesSync8AM/20140310_dev2/combCh", sep = "")
# path2Tbls <- paste (home, "/phecomp/processedData/20120509_FCSC_UPF/GBfilesSync8AM/20140310_realDev/combCh", sep = "")
path2Tbls <- paste (home, "/phecomp/processedData/20130130_FCSC_CRG/GBfiles/20150112_hab_Dev_NoDeadMouse/combCh", sep = "")
patternCtrl <- "combChcage[0-1][0,2,4,6,8]chfood(.*)\\.tbl"
labelCtrl <- "Ctrl"

pattern <- patternCtrl
label <- labelCtrl

tblCtrl <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=1800)
# tblCtrl <- readGBTbl (path2Tbl=path2Tbls, pattern, label=label, ws=300)

head (tblCtrl,49)
tail (tblCtrl,50)

tblAll <- rbind (tblCtrl, tblFC_Choc, tblFC_SC)
tail (tblAll)
str (tblAll)
tblAll$week <- as.factor (tblAll$week)
tblAll$group <- as.factor (tblAll$group)

## BOXPLOT SHOWING THE AVERAGE INTAKE OF 30 MINUTES PERIOD ALONG THE WEEKS AND SEPARATED BY DAY AND NIGHT
boxPlots <- ggplot(tblAll, aes (week, value, fill = group)) + 
  geom_boxplot() +          
  #           scale_fill_manual(name = "Group", values = c("green", "brown"), labels = c ("Control", "Free Choice")) +
  scale_fill_manual (name = "", values = colors [c(2:4)], labels = c ("Control", "FC Choc", "FC SC")) +
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
  scale_fill_manual(name = "", values = colors [c(2:4)], labels = c ("Control", "FC Choc", "FC SC")) +
  labs (title = "Average intake during 30 min periods\n")+  
  labs (x = "\nDay phases", y = "intake (g)\n", fill = NULL) +
  scale_y_continuous(limits=c(0, 1)) +
  facet_wrap (~phase)

#legend
# boxPlots + theme (legend.key.height = unit (1,"line")) + 
#    scale_x_discrete(labels = tblAll$timeDay)

# Cleaning controls abnormal values
# cage 3 semana 12 (file -> 20120725_FCSC_UPF)!!!
levels (tblCtrl$Filename)
# tblCtrl<- tblCtrl [-(which (tblCtrl$week==12 & tblCtrl$Filename=="combChcage03chfood_scfood_sc34.tbl")),]
# tblCtrl<- tblCtrl [-(which (tblCtrl$week==17 & tblCtrl$Filename=="combChcage09chfood_scfood_sc34.tbl")),]
# cage 9 week 6 -> was giving problems during the day
# tblCtrl <- tblCtrl [-(which (tblCtrl$week==6 & tblCtrl$Filename=="combChcage09chfood_scfood_sc34.tbl")),]

# To find possible problems
# levels (tblCtrl$Filename)
# tblCtrl_week6 <- tblCtrl [which (tblCtrl$week==6 & tblCtrl$Filename=="combChcage09chfood_scfood_sc34.tbl" & tblCtrl$phase == "day"),]
# mean (tblCtrl_week6$value)



## Mean calculation according to different factors combination
# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), mean, std.error))
with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, week=week), mean))
meanCtrl.byWeek <- with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
# with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group), mean))
with (tblCtrl , aggregate (cbind (value), list (phase=phase, group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## FC choc 
# Cleaning problematic files
# Checking of which files are contributing more to week 9 peak
# Cage10 > cage08 !!! 
# No contributing cage 6, cage 12
#No vale la pena filtrar nada porque todas son altas
# levels (tblFC_Choc$Filename)
# tblFC_Chocweek9 <- tblFC_Choc [which (tblFC_Choc$week==9 & tblFC_Choc$Filename=="splitChcage10chfood_cd4.tbl" & tblFC_Choc$phase == "night"),]
# mean (tblFC_Chocweek9$value)
# tblFC_Choc <- tblFC_Choc [-(which (tblFC_Choc$week==9 & tblFC_Choc$Filename=="splitChcage10chfood_cd4.tbl")),]

with (tblFC_Choc , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanFC_Choc.byWeek<- with (tblFC_Choc , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
with (tblFC_Choc , aggregate (cbind (value), list (phase=phase, group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

## FC SC
# Cleaning problematic files
# tblFC_SC <- tblFC_SC [-(which (tblFC_SC$week==9 & tblFC_SC$Filename=="splitChcage04chfood_sc4.tbl")),]
# tableWeek9<- tblFC_SC [which (tblFC_SC$week==9 & tblFC_SC$phase=="night") ,]

with (tblFC_SC , aggregate (cbind (value), list (phase=phase, group=group, indexPh=indexPh), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanFC_SC.byWeek<- with (tblFC_SC , aggregate (cbind (value), list (phase=phase, group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
with (tblFC_SC , aggregate (cbind (value), list (phase=phase, group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

# Join the three tables 
meanAll.byWeek <- rbind (meanCtrl.byWeek, meanFC_Choc.byWeek, meanFC_SC.byWeek)
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

# I filter only 9 weeks of the experiment, hab + 8 weeks as in the heatmap
meanAll.byWeek10Weeks <- meanAll.byWeek [meanAll.byWeek$week > 1 & meanAll.byWeek$week < 10, ]

pd <- position_dodge(.1)
colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
meanAll.byWeek


# gAllByWeek <- ggplot (meanAll.byWeek10Weeks, aes(x = week, y = mean, colour = groupPhase)) +
gAllByWeek <- ggplot (meanAll.byWeek10Weeks, aes(x = week-1, y = mean, colour = groupPhase)) + 
  #   scale_x_continuous (breaks=fractHour) + 
  scale_x_continuous (breaks=c(1:10)) + 
  labs (title = "Average intake during\n30 min periods\n") +  
  labs (x = "Development Weeks", y = "g/30 min\n", fill = NULL) + 
  geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
  #   geom_line (position=pd, size=1)  + 
  #   geom_point (position=pd) +
  geom_line (size=1)  + 
  geom_point () +
  #scale like in HF 0, 0.6
  #   scale_y_continuous (limits = c(0, 0.22)) 
  scale_y_continuous (limits = c(0, 0.6)) 

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
  name="",
  values = colors, labels=c("Control day", "Control Night", "CM day\n(CM channel)","CM Night\n(CM channel)", "CM day\n(SC channel)","CM Night\n(SC channel)")) + 
  theme (legend.key.height = unit (2, "line")) #distance between lines in legend
gAllByWeek
setwd("/Users/jespinosa/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/submissionEuNeuroPsycho")
# ggsave (gAllByWeek, file=paste(home, "/dropboxTCoffee/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/submissionEuNeuroPsycho/", "figS3B.tiff", sep=""), 
#           width=12, height=7, dpi=400)

# Labels can not be FC
meanAll.byWeek10Weeks$groupPhase_lab <- factor(meanAll.byWeek10Weeks$groupPhase, levels=c("Ctrl day", "Ctrl night", "FC_SC day", "FC_SC night", "FC_Choc day", "FC_Choc night"), 
                                           labels=c("Ctrl day", "Ctrl night", "FC SC day", "FC SC night", "FC CM day", "FC CM night"))
meanAll.byWeek10Weeks$groupPhase_lab <- revalue(meanAll.byWeek10Weeks$groupPhase_lab, c("FC SC day"="SC day", "FC SC night"="SC night", "FC CM day"="CM day", "FC CM night"="CM night"))

########################################
# New version of the plot (Rafael's way)
gAllByWeek_blackWhite <- ggplot (meanAll.byWeek10Weeks, aes(x = week-1, y = mean, group = groupPhase_lab)) +
                                 geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) + 
                                 geom_line (aes(linetype=groupPhase_lab), size=1.2)  +
                                 geom_point (aes(shape=groupPhase_lab), fill="white",  size=4) +
                                 scale_linetype_manual (values=rep("solid",6)) +                                 
                                 scale_shape_manual(values=c(24,17,21,19,22,15)) +
                                 scale_x_continuous (breaks=c(1:10)) + 
                                 scale_y_continuous (limits = c(0, 0.6)) +
                                 labs (title = "Average intake during\n30 min periods\n") +  
                                 labs (x = "\nDevelopment phase (weeks)", y = "g/30 min\n", fill = NULL) +                                  
                                 theme (legend.key = element_blank(), legend.key.height = unit (2, "line"), 
                                        legend.title=element_blank()) 

gAllByWeek_blackWhite

setwd("/Users/jespinosa/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/20150902_espinosa_EuNeuroPsycho")
# ggsave (gAllByWeek_blackWhite, file=paste(home, "/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/20150902_espinosa_EuNeuroPsycho/", "figS3B.tiff", sep=""), 
#           width=12, height=7, dpi=400)
ggsave (gAllByWeek_blackWhite, file=paste(home, "/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures_20151110/figS4/", "figS4.tiff", sep=""), 
        width=12, height=7, dpi=400)
ggsave (gAllByWeek_blackWhite, file=paste(home, "/dropboxTCoffee_new/Dropbox/jespinosa/2013phecomp2shareFinal/drafts_paper/figures_20151110/figS4/", "figS4.pdf", sep=""), 
        width=12, height=7)





## Ratio between day and night
mean (meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "Ctrl day"] /meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "Ctrl night"])
mean (meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "FC day"] /meanAll.byWeek$mean [meanAll.byWeek$groupPhase == "FC night"])

##########################
## ONLY FREE CHOICE TABLES
# Join only free choice files
meanFC.byWeek <- rbind (meanFC_Choc.byWeek, meanFC_SC.byWeek)
meanFC.byWeek$mean <- meanFC.byWeek$value [,1]
meanFC.byWeek$std.error <- meanFC.byWeek$value [,2]

# Plotting all
str (meanFC.byWeek)
# Weeks should be numeric to plot lines
meanFC.byWeek$week <- as.numeric (meanFC.byWeek$week)

meanFC.byWeek$mean - meanFC.byWeek$std.error
meanFC.byWeek$groupPhase <- paste (meanFC.byWeek$group, meanFC.byWeek$phase)
meanFC.byWeek$ymax <- meanFC.byWeek$mean + meanFC.byWeek$std.error
meanFC.byWeek$ymin <- meanFC.byWeek$mean - meanFC.byWeek$std.error

pd <- position_dodge(.1)
colors <- RColorBrewer::brewer.pal (8, "Paired")[5:10]
meanFC.byWeek

# I filter only 9 weeks of the experiment, hab + 7 weeks as in the heatmap
meanFC.byWeek8Weeks <- meanFC.byWeek [meanFC.byWeek$week < 9 , ]

gFCByWeek <- ggplot (meanFC.byWeek8Weeks, aes(x = week, y = mean, colour = groupPhase)) + 
  #scale_x_continuous (breaks=fractHour) +
  scale_x_continuous (breaks=c(1:8)) +
  labs (title = "Average intake during\n30 min periods\n") +  
  labs (x = "Weeks", y = "g/30 min\n", fill = NULL) + 
  geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
  #geom_line (position=pd, size=1)  + 
  # geom_point (position=pd) +
  geom_line (size=1)  + 
  geom_point () +
  #scale like in HF 0, 0.6
#   scale_y_continuous (limits = c(0, 0.22)) 
  scale_y_continuous (limits = c(0, 0.6)) 

gFCByWeek <- gFCByWeek + scale_colour_manual (#name="conditions",
  name="",
  values = colors) + 
  theme (legend.key.height = unit (1, "line")) #distance between lines in legend
gFCByWeek


##########################
## FREE CHOICE CHOC VS CONTROLS
# Join only free choice files
meanCtrlFC_choc.byWeek <- rbind (meanCtrl.byWeek,meanFC_Choc.byWeek)
meanCtrlFC_choc.byWeek$mean <- meanCtrlFC_choc.byWeek$value [,1]
meanCtrlFC_choc.byWeek$std.error <- meanCtrlFC_choc.byWeek$value [,2]

# Plotting SC vs FC choc
str (meanCtrlFC_choc.byWeek)
# Weeks should be numeric to plot lines
meanCtrlFC_choc.byWeek$week <- as.numeric (meanCtrlFC_choc.byWeek$week)

meanCtrlFC_choc.byWeek$mean - meanCtrlFC_choc.byWeek$std.error
meanCtrlFC_choc.byWeek$groupPhase <- paste (meanCtrlFC_choc.byWeek$group, meanCtrlFC_choc.byWeek$phase)
meanCtrlFC_choc.byWeek$ymax <- meanCtrlFC_choc.byWeek$mean + meanCtrlFC_choc.byWeek$std.error
meanCtrlFC_choc.byWeek$ymin <- meanCtrlFC_choc.byWeek$mean - meanCtrlFC_choc.byWeek$std.error

pd <- position_dodge(.1)
colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
meanCtrlFC_choc.byWeek

gCtrlFC_chocByWeek <- ggplot (meanCtrlFC_choc.byWeek, aes(x = week, y = mean, colour = groupPhase)) + 
  #   scale_x_continuous (breaks=fractHour) + 
  scale_x_continuous (breaks=c(1:9)) + 
  labs (title = "Average intake during\n30 min periods\n") +  
  labs (x = "Weeks", y = "g/30 min\n", fill = NULL) + 
  geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
  #   geom_line (position=pd, size=1)  + 
  #   geom_point (position=pd) +
  geom_line (size=1)  + 
  geom_point () +
  scale_y_continuous (limits = c(0, 0.22)) 

gCtrlFC_chocByWeek <- gCtrlFC_chocByWeek  + scale_colour_manual (#name="conditions",
  name="",
  values = colors) + 
  theme(legend.key.height = unit (1, "line")) #distance between lines in legend
gCtrlFC_chocByWeek

############
#STATS
# para hacer la anova de lo que sale en el grafico tendr??a que tener un valor para cada d??a de la semana por animal (cage)
# los animales si hago este dise??o no pueden estar repetidos entre dia y noche

###########
###########
# Tbl for spss analysis
# Writing table for performing anova in spss - We need the data by individual
tbl_all_FC <- rbind (tblFC_Choc, tblFC_SC, tblCtrl)
head (tbl_all_FC)
tail (tbl_all_FC)
cage <- gsub ("splitChcage", "", tbl_all_FC$Filename)
cage <- gsub ("combChcage", "", cage)
cage <- gsub ("chfood_scfood_sc34.tbl", "", cage)
cage <- gsub ("chfood_cd3.tbl", "", cage)
cage <- gsub ("chfood_cd4.tbl", "", cage)
cage <- gsub ("chfood_sc3.tbl", "", cage)
cage <- gsub ("chfood_sc4.tbl", "", cage)

tbl_all_FC$cageId <- as.numeric (cage)

# I have to summarize by week
meanAll_FC_byId_week <- with (tbl_all_FC , aggregate (cbind (value), list (phase=phase, group=group, week=week, cage=cageId), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
head (meanAll_FC_byId_week)

# write.table(meanAll_FC_byId_week, "/Users/jespinosa/sharedWin/20151109_dayNightDevelopment_FC.csv", sep="\t", row.names=FALSE ,dec=".")

##################
#################
# Same analysis in R
meanAnimalByWeekHF <- with (tblHF , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanAnimalByWeekCtrl <- with (tblCtrl , aggregate (cbind (value), list (week=week, group=group, phase=phase, animal=Filename), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanAnimalByWeek <- rbind (meanAnimalByWeekHF, meanAnimalByWeekCtrl)
meanAnimalByWeek$animal <- gsub ("combChcage" , "",meanAnimalByWeek$animal)
meanAnimalByWeek$animal <- gsub ("chfood_scfood_sc34.tbl" , "",meanAnimalByWeek$animal)
meanAnimalByWeek$animal <- gsub ("chfood_fatfood_fat34.tbl" , "",meanAnimalByWeek$animal)
meanAnimalByWeek$animal <- paste (meanAnimalByWeek$animal, meanAnimalByWeek$phase, sep="")

meanAnimalByWeek$mean <- meanAnimalByWeek$value [,1]
meanAnimalByWeek$std.error <- meanAnimalByWeek$value [,2]

meanAnimalByWeek$groupAndPhase <- paste (meanAnimalByWeek$group, meanAnimalByWeek$phase, sep="")  
meanAnimalByWeek$groupAndPhase <- as.factor (meanAnimalByWeek$groupAndPhase)
meanAnimalByWeek$week <- as.factor (meanAnimalByWeek$week)
meanAnimalByWeek$animal <- as.factor (meanAnimalByWeek$animal)

aov.weekIntakes = aov (mean ~ groupAndPhase * week + Error (animal), data=meanAnimalByWeek)
summary (aov.weekIntakes)


# POST-hoc test
# for group
with (meanAnimalByWeek, pairwise.t.test (mean, groupAndPhase,  p.adjust.method="bonf"))



meanCtrl.byWeekNoPhase <- with (tblCtrl , aggregate (cbind (value), list (group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanFC_Choc.byWeekNoPhase <- with (tblFC_Choc , aggregate (cbind (value), list (group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
meanFC_SC.byWeekNoPhase <- with (tblFC_SC , aggregate (cbind (value), list (group=group, week=week), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))

meanAll.byWeekNoPhase <- rbind (meanCtrl.byWeekNoPhase, meanFC_Choc.byWeekNoPhase, meanFC_SC.byWeekNoPhase)
meanAll.byWeekNoPhase$mean <- meanAll.byWeekNoPhase$value [,1]
meanAll.byWeekNoPhase$std.error <- meanAll.byWeekNoPhase$value [,2]

meanAll.byWeekNoPhase$week <- as.numeric (meanAll.byWeekNoPhase$week)
meanAll.byWeekNoPhase$groupPhase <- paste (meanAll.byWeekNoPhase$group, meanAll.byWeekNoPhase$phase)
meanAll.byWeekNoPhase$ymax <- meanAll.byWeekNoPhase$mean + meanAll.byWeekNoPhase$std.error
meanAll.byWeekNoPhase$ymin <- meanAll.byWeekNoPhase$mean - meanAll.byWeekNoPhase$std.error

# I filter only 9 weeks of the experiment, hab + 7 weeks as in the heatmap
meanAll.byWeek10Weeks <- meanAll.byWeek [meanAll.byWeek$week < 9 , ]

pd <- position_dodge(.1)
colors <- RColorBrewer::brewer.pal (8, "Paired")[3:8]

gAllByWeek <- ggplot (meanAll.byWeekNoPhase, aes(x = week, y = mean, colour = groupPhase)) + 
  #   scale_x_continuous (breaks=fractHour) + 
  opts (title = "Average intake during\n30 min periods\n") +  
  labs (x = "Weeks", y = "g/30 min\n", fill = NULL) + 
  geom_errorbar (aes (ymin=ymin, ymax=ymax), colour = "black", width=.1) +
  #   geom_line (position=pd, size=1)  + 
  #   geom_point (position=pd) +
  geom_line (size=1)  + 
  geom_point () +
  scale_y_continuous (limits = c(0, 0.251)) 

gAllByWeek <- gAllByWeek  + scale_colour_manual (#name="conditions",
  name="",
  values = colors) + 
  opts (legend.key.height = unit (1, "line")) #distance between lines in legend
gAllByWeek

