##############################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2014            ###
##############################################################
### This script construct a pca using the probabilities of ###
### the models estimated by HMM                            ###
##############################################################

home <- Sys.getenv("HOME")
path2Tbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsSingleCage/20120502_FDF_hab/modelsSingleCage/"

pattern <- "trainedModelR_cage[[:digit:]]"

listFiles <- list.files (path = path2Tbl, pattern = pattern)
listFiles[1]
setwd (path2Tbl)

path <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsSingleCage/20120502_FDF_hab/modelsSingleCage/trainedModelR_cage01"
dfSingleTbl <- read.table (path, header=F, stringsAsFactors=F, dec=".", sep="\t")

df <- do.call ("rbind", lapply (listFiles, dfTranspose))
df

# Functions
dfTranspose <- function (tbl2read) 
                {
                  df.temp <- data.frame (read.csv (tbl2read, sep="\t", dec=".", stringsAsFactors=F, header = F))
                  df.temp <- df.temp [,-4]
                  df.temp$trEm <-paste (df.temp$V1, df.temp$V2, sep="_")
                  df.temp <- df.temp [,c(-1,-2)]
                  colnames(df.temp)  <- c("proba", "trEm")
#                   return (df.temp)
                  #State 1 day, it means that bin 0 should have high value
                  if(df.temp [which (df.temp$trEm == "ST_1_0"),"proba"] < 0.6) 
                    {                      
                      df.temp <- transform(df.temp, trEm = gsub("ST_1", "ST_3", trEm)) 
                      df.temp <- transform(df.temp, trEm = gsub("ST_2", "ST_1", trEm))
                      df.temp <- transform(df.temp, trEm = gsub("ST_3", "ST_2", trEm))
                    }
                                    
                  colNames <- df.temp$trEm
                  
                  #t() changes values to string matrix that is way we need to change the mode 
                  transpDf <- t(df.temp)
                  mode (transpDf) <- "numeric"
                  df.temp <- as.data.frame(transpDf, stringAsFactor=F)
                  df.temp <- df.temp[-2,]
                  colnames(df.temp) <- colNames                
                  rownames (df.temp) <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
#                   df.temp$cage <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
                  # begin (B) and end (E) bins are not informative, removed
                  drops = c("ST_1_E","ST_1_B","ST_2_E","ST_2_B")
                  df.temp <- df.temp [,!(names(df.temp) %in% drops)]

                  return (df.temp)
                }



# Code development
# tblOriginal<- dfTranspose (listFiles[1])
tblOriginal
subset (df,select="ST_1_E")
drops = c("ST_1_E","ST_1_B","ST_2_E","ST_2_B")
df[,!(names(df) %in% drops)]
if(df [which (df$trEm == "ST_1_0"),"proba"] < 0.6)
  
tblChange
tbl <- dfTranspose (listFiles[1])
tbl
getwd()
dput (df, "dfModels.txt")
dput(df)
culo <- 

  which (tbl$trEm == "ST_1_0") 
tbl [which (tbl$trEm == "ST_1_0"),"V3"] 

df.temp <- data.frame (Filename=fn, read.csv (fn, sep="\t", dec=".", header = F))
df.temp <- df.temp [,-4]
df.temp$trEm <-paste (df.temp$V1, df.temp$V2, sep="_")
df.temp <- df.temp [,c(-1,-2)]
colNames <- df.temp$trEm
df <- as.data.frame(t(df.temp))
colnames(df.temp) <- colNames

df <- df [,-4]
df$trEm <-paste (df$V1, df$V2, sep="_")
df <- df [,c(-1,-2)]
colNames <- df$trEm

df <- as.data.frame(t(df))
head (df)
colnames(df) <- colNames
df
rownames(df) <- 
  class (c("i_j", "j_i"))
df

df <- df[-3, ]
df
df.aree$myfactor <- factor(row.names(df.aree))





tblHab <- do.call("rbind", lapply(tblHabFiles, function (fn)
  
data <- do.call("rbind", lapply(c("file1", "file2"), function(fn) 
  data.frame(Filename=fn, read.csv(fn)
  ))