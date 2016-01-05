############################################################
### Jose A Espinosa. CSN/CB-CRG Group. Nov 2015          ###
############################################################
### Obtain min and max value of each file inside a csv   ###
### file created from an int file                        ###
### The output of this script can be then use for the    ###
### generation of a bed track file with files info       ###
### intersecting of the file with files with behavioral  ###
### info a so on                                         ###
############################################################
###                                                      ###
###                                                      ###
############################################################
library("plyr")

# Getting HOME directory
home <- Sys.getenv("HOME") 
path2data <- "/phecomp/20140807_pergola/20150411_validationPaper/20120502_FDF_CRG_habDev_filt_6fields.csv"

# read table
tbl_int <- read.csv (paste (home, path2data, sep=""), header=FALSE, sep="\t")
head (tbl_int)
tbl_int$file <- gsub ("/users/cn/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/", "", tbl_int$V6) 

# I name with the same factor files belonging to c6 batch and to c12 file this way I will get the absolute min and max:
tbl_int$NameFile <- gsub ("_c12|_c6", "_c18", tbl_int$file) 
tbl_min_max_file <- ddply(tbl_int, c("NameFile"), summarise, StartT= min(V2), EndT=max(V2))
tbl_min_max_file$Value <- 1000
tbl_min_max_file$File <- 1:nrow(tbl_min_max_file)

# Structure of the ontology and the header of the other files I have use to generate file separation
# behavioural_file:File > genome_file:track
# behavioural_file:NameFile > genome_file:dataTypes
# behavioural_file:StartT > genome_file:chromStart
# behavioural_file:EndT > genome_file:chromEnd
# behavioural_file:Value > genome_file:dataValue
# 
# File  NameFile	StartT	EndT	Value

# write.table (tbl_min_max_file, "/Users/jespinosa/phecomp/20140807_pergola/20150411_validationPaper/data_bed_format/files_val_peaks.csv", sep="\t", row.names = F)
