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
df <- read.table (path, header=F, stringsAsFactors=F, dec=".", sep="\t")

df <- do.call ("rbind", lapply (listFiles, 
                function (tbl2read) 
                  {
                  df.temp <- data.frame (read.csv (tbl2read, sep="\t", dec=".", header = F))
                  df.temp <- df.temp [,-4]
                  df.temp$trEm <-paste (df.temp$V1, df.temp$V2, sep="_")
                  df.temp <- df.temp [,c(-1,-2)]
                  colNames <- df.temp$trEm
                  df.temp <- as.data.frame(t(df.temp))
                  df.temp <- df.temp[-2,]
                  colnames(df.temp) <- colNames                
                  rownames (df.temp) <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
                  df.temp$cage <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
                  return (df.temp)}
                    )
               )
dfTranspose <- function (tbl2read) 
                {
                  df.temp <- data.frame (read.csv (tbl2read, sep="\t", dec=".", header = F))
                  df.temp <- df.temp [,-4]
                  df.temp$trEm <-paste (df.temp$V1, df.temp$V2, sep="_")
                  df.temp <- df.temp [,c(-1,-2)]
                  print (df.temp)
#                   if (df.temp [,df.trEm == "ST_1_0"] > 0.6) {print "culo"}
                  colNames <- df.temp$trEm
                  df.temp <- as.data.frame(t(df.temp))
                  df.temp <- df.temp[-2,]
                  colnames(df.temp) <- colNames                
                  rownames (df.temp) <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
                  df.temp$cage <- as.numeric (gsub ("trainedModelR_cage", "", tbl2read, ignore.case = TRUE))
                  return (df.temp)
                }
dfTranspose (listFiles[1])

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