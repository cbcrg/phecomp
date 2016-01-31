#############################################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Jan 2016                         ###
#############################################################################
### PCA reinstatement experiment from Rafael's lab                        ###
### Phases of the experiment labeled following discussion on 27th Jan     ### 
### meting                                                                ###
###                                                                       ###
#############################################################################

##Getting HOME directory 
home <- Sys.getenv("HOME")
# Dropbox (CRG)/2015_reinstatement_rafa/data/tbl_phases_coloured2R.csv
data_reinst <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/tbl_phases_coloured2R.csv", sep=""), dec=",", sep=";")
reinst_annotation <- read.csv (paste (home, "/Dropbox (CRG)/2015_reinstatement_rafa/data/reinstatement_annotation.csv", sep=""), dec=",", sep=";")

head (data_reinst)
head (reinst_annotation)

# Shaping data for PCA
# I keep id and groups and
# filter out all the columns that are not in the annotation tbl
col <- as.character(reinst_annotation$Session)

data_reinst_filt <- cbind (data_reinst_means, subset (data_reinst, select=col))

# Mejor asi porque tengo la anotacion
ext_by_annotation_t <- ddply(reinst_annotation, c("Annotation"), function(x) { 
  rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
})


ext_by_annotation <- as.data.frame(t(ext_by_annotation_t))
ext_by_annotation <- ext_by_annotation[-1,]
colnames(ext_by_annotation) <- ext_by_annotation_t$Annotation
ext_by_annotation

# Adding a column with labels of the group as we want them in the plots
# data_reinst_means <- subset(data_reinst, select = c("subject"))
# 
# data_reinst_means$group_lab  <- gsub ("F1", "High fat", data_reinst$Group)
# data_reinst_means$group_lab  <- gsub ("SC", "Ctrl choc", data_reinst_means$group_lab)
# data_reinst_means$group_lab  <- gsub ("Cafeteria diet", "Choc", data_reinst_means$group_lab)
# data_reinst_means$group_lab  <- gsub ("C1", "Ctrl high fat", data_reinst_means$group_lab)








############
# DRAFTS
############
install.packages("dplyr")
library(dplyr)
library (plyr)

### WORKING
ddply(reinst_annotation, c("Annotation"), function(x) { print (as.character( x$Session)) })



### FUNCIONA!!!!!!!
# culo<-do.call("rbind",ddply(reinst_annotation, c("Annotation"), function(x) { 
# #                                                         print (as.character(x$Session))
#   rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
#                                                         }))

# Mejor asi porque tengo la anotacion
ext_by_annotation_t <- ddply(reinst_annotation, c("Annotation"), function(x) { 
  rowMeans(subset(data_reinst_filt, select =as.character(x$Session)))
})