##############################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2014            ###
##############################################################
### This script construct a pca using the probabilities of ###
### the models estimated by HMM                            ###
##############################################################

library (ggplot2)
# library(lattice)
# install.packages("e1071")
# library("e1071")
# install.packages("plyr")
# library("plyr")
# install.packages("grid.extra")

source ("/Users/jespinosa/git/phecomp/lib/R/plotParamPublication.R")

home <- Sys.getenv("HOME")
#habituation
path2Tbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsSingleCage/20120502_FDF_hab/modelsSingleCage/"
#development
# path2Tbl <- "/Users/jespinosa/phecomp/20140301_oneOutValidation/resultsSingleCage/20120502_FDF_dev/modelsSingleCage/"
setwd(path2Tbl)
pattern <- "trainedModelR_cage[[:digit:]]"

listFiles <- list.files (path = path2Tbl, pattern = pattern)
listFiles[1]

df <- do.call ("rbind", lapply (listFiles, dfTranspose))
warnings ()
df

pcaObject <- prcomp (df) 
summary (pcaObject)

PCbiplot(pcaObject)

pcaObject$rotation
df.loadings <- as.data.frame(pcaObject$rotation, row.names = FALSE)
# df.loadingsVarNames <- as.data.frame(pcaObject$rotation)
# df.loadings$NameVar <- rownames (df.loadingsVarNames)

#reordering the dataframe by PCA1 values and converting variables field into a factor
# head(df.loadings)
# df.loadings$PC1 <- with(df.loadings, reorder (NameVar, PC1))


# PCAResult <- table2plotpca (dataTable)

#Proportion of variance explained by PCA1, PCA2 and PCA3
percent <- round((((pcaObject$sdev)^2 / sum(pcaObject$sdev^2))*100)[1:5])

#Getting 3 first PC to make the plot
PCA2plot <- as.data.frame (pcaObject$x[,c (1:3)])
plotmatrix(PCA2plot)

# Adding cages as column
animals <- row.names(df)
colors <- PCA2plot
colors$cage <- as.numeric(animals)

colors <- labelGroups (colors)
PCA2plot$diet <- as.factor(colors$diet)

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
#                   df.temp
                  
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

PCbiplot <- function(PC, x="PC1", y="PC2") {
  # PC being a prcomp object
  data <- data.frame(obsnames=row.names(PC$x), PC$x)
  plot <- ggplot(data, aes_string(x=x, y=y)) + geom_text(alpha=.4, size=5, aes(label=obsnames))
  plot <- plot + geom_hline(aes(0), size=.2) + geom_vline(aes(0), size=.2)
  datapc <- data.frame(varnames=rownames(PC$rotation), PC$rotation)
  mult <- min(
    (max(data[,y]) - min(data[,y])/(max(datapc[,y])-min(datapc[,y]))),
    (max(data[,x]) - min(data[,x])/(max(datapc[,x])-min(datapc[,x])))
  )
  datapc <- transform(datapc,
                      v1 = .7 * mult * (get(x)),
                      v2 = .7 * mult * (get(y))
  )
  plot <- plot + coord_equal() + geom_text(data=datapc, aes(x=v1, y=v2, label=varnames), size = 5, vjust=1, color="red")
  plot <- plot + geom_segment(data=datapc, aes(x=0, y=0, xend=v1, yend=v2), alpha=0.75, color="red")
  plot
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