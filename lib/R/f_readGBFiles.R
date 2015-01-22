
# Functions

addPhases2dfSingleFile <- function (fn, ws = "", secDay = 3600 * 24) 
{
  secWeek <- secDay * 7
  df <- data.frame (Filename=fn, read.csv (fn, sep="\t", dec=".", header = F))
  
  # The file always starts at 8:00 AM, starting of the light phase
  phOfOneDay <- c (rep ("day", secDay / ws / 2), rep ("night", secDay / ws / 2))
  indexPhOfOneDay <- rep (seq (1: (secDay / ws / 2)), 2)
  
  #for axis ticks we want the hour of the day I have to comment it if I change the distro of the intervals
  #it is a hardcode
  path2TblFileDiv <- "/Users/jespinosa/phecomp/lib/R/dayHours30min.csv"
  path2DayHours <- read.table (path2TblFileDiv, sep="\t", dec=".", header=F, stringsAsFactors=F)
  path2TblFileDiv <- "/Users/jespinosa/phecomp/lib/R/nightHours30min.csv"
  path2NightHours <- read.table (path2TblFileDiv, sep="\t", dec=".", header=F, stringsAsFactors=F)
  timeDayAndNight <- rbind (path2DayHours, path2NightHours)
  timeDayAndNight <- as.vector (timeDayAndNight [,1])
  
  entireDays <-  length (df$Filename)  %/%   length (phOfOneDay) 
  remainderInt <- length (df$Filename)  %%   length (phOfOneDay)
  
  if (remainderInt != 0)
    {
      vPhases <- c (rep (phOfOneDay, entireDays), phOfOneDay [1:remainderInt])
      indexVPhases <- c (rep (indexPhOfOneDay, entireDays), indexPhOfOneDay [1:remainderInt])
      timeDay <- c (rep (timeDayAndNight, entireDays), timeDayAndNight [1:remainderInt])
    }
  else 
    {
      vPhases <- rep (phOfOneDay, entireDays)
      indexVPhases <- rep (indexPhOfOneDay, entireDays)
      timeDay <- rep (timeDayAndNight, entireDays) 
    }
  
  
  df$phase <-  vPhases 
  df$indexPh <- indexVPhases
  df$timeDay <- timeDay
  df$week <-(df [,3] %/% secWeek) + 1
  
  return (df)
}

readGBTbl <- function (path2Tbl, pattern, label = "", ws = 1800)
  {
    listFiles <- list.files (path = path2Tbl, pattern = pattern)
    setwd (path2Tbl)
    
    tbl <- do.call ("rbind", lapply (listFiles, addPhases2dfSingleFile, ws <- 1800))
    
    if (is.na (label))
    {    
      tbl$group <- "control"
    }
    else
    {
      tbl$group <- label
    }
    #   if (!is.na (labelCase))
    #   {
    #     tbl$group <- "control"
    #     tbl$group [which (tbl$cage%% 2 != 0)] <- labelCase    
    #   }  
    colnames (tbl) <- c ("Filename", "chr", "startInt", "endInt", "value", "phase", "indexPh", "timeDay", "week", "group")
#     colnames (tbl) <- c ("Filename", "chr", "startInt", "endInt", "value", "phase", "indexPh", "group")
    
    return (tbl)
  }

# readGBTblOld <- function (path2Tbl, pattern, label = "")
# {
#   listFiles <- list.files (path = path2Tbl, pattern = pattern)
#   setwd (path2Tbl)
#   
#   tbl <- do.call ("rbind", lapply (listFiles, function (fn) 
#     data.frame (Filename=fn, read.csv (fn, sep="\t", dec=".", header = F))))
#   
#   if (is.na (label))
#   {    
#     tbl$group <- "control"
#   }
#   else
#   {
#     tbl$group <- label
#   }
#   #   if (!is.na (labelCase))
#   #   {
#   #     tbl$group <- "control"
#   #     tbl$group [which (tbl$cage%% 2 != 0)] <- labelCase    
#   #   }  
#   colnames (tbl) <- c ("Filename", "chr", "startInt", "endInt", "value", "group")
#   return (tbl)
# }

getTableFirstOccurrence <- function (tbl)
{
  #diff is getting the consecutive values of the vector and given the difference
  #in this case we are comparing all the file names and when ever is different the name is returning it
  #as we only want values greater than 0 that is why we do it on tbl$value>0 subset
  df.firstOcc <- tbl [tbl$value > 0,] [ diff (c(0,tbl [tbl$value > 0,]$Filename)) != 0, ]
  #   return (mean (df.firstOcc$value))
  minStartInt <- min (df.firstOcc$startInt)
  pDay <-0
  pDayStart <- 1
  pDayEnd <- 43200
  
  if ((minStartInt / (3600*24)) > 1 ) 
  { 
    pDay <- round (minStartInt / (3600*24), 0) 
    pDayStart <- (pDay - 1) * (24*3600) + 1
    pDayEnd <- pDayStart + (12 * 3600) -1
  }
  
  return (df.firstOcc)
}

getMeanDf.ValueFirstOccurrence <- function (tbl)
{
  #diff is getting the consecutive values of the vector and given the difference
  #in this case we are comparing all the file names and when ever is different the name is returning it
  #as we only want values greater than 0 that is why we do it on tbl$value>0 subset
  df.firstOcc <- tbl [tbl$value > 0,] [ diff (c(0,tbl [tbl$value > 0,]$Filename)) != 0, ]
  #   return (mean (df.firstOcc$value))
  minStartInt <- min (df.firstOcc$startInt)
  pDay <-0
  pDayStart <- 1
  pDayEnd <- 43200
  
  if ((minStartInt / (3600*24)) > 1 ) 
  { 
    pDay <- round (minStartInt / (3600*24), 0) 
    pDayStart <- (pDay - 1) * (24*3600) + 1
    pDayEnd <- pDayStart + (12 * 3600) -1
  }
  
  return (c (avg=mean (df.firstOcc$value), std.error = std.error (df.firstOcc$value), minStartInt = minStartInt, pDayStart = pDayStart, pDayEnd = pDayEnd)  ) 
}

getPDayMean <- function (pDayStart, pDayEnd, dataFrame)
 {  
  meanPDay <- mean (dataFrame [dataFrame$startInt >= pDayStart & dataFrame$startInt <= pDayEnd, "value"])
  return (meanPDay)
 }

getPDayStd.err <- function (pDayStart, pDayEnd, dataFrame)
 {  
  std.error.PDay <- std.error (dataFrame [dataFrame$startInt >= pDayStart & dataFrame$startInt <= pDayEnd, "value"])
  return (std.error.PDay)
 }
 
getPDayDataFrame <- function (row, dataFrame)
 {  
#     print (row)
#   print (dataFrame)
    meanPDay <- dataFrame [dataFrame$startInt >= row$pDayStart & dataFrame$startInt <= row$pDayEnd,]
#     print (meanPDay)
    df.meanByCage<- with (meanPDay , aggregate (cbind (value), list (Filename=Filename, group=group, phase=phase, mtbFileName=mtbFileName), mean))
#     ddply (avgIntFirstIntFile, ~mtbFileName, summarize, pDayMean = getPDayMean (pDayStart, pDayEnd, dataFrame=tbl), std.error = getPDayStd.err (pDayStart, pDayEnd, dataFrame=tbl))
#     meanVal <- ddply (meanPDay, ~Filename, summarize, mean)
#     print (df.meanByCage)
    
    return (df.meanByCage)
 } 