#####################################################
### Jose A Espinosa. NPMMD/CB-CRG Group. Feb 2014 ###
#####################################################
### SCRIPT WITH GENERIC FUNCTIONS FOR HEATMAPS    ###
#####################################################

# Function to capitalize each word beginning of a string
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

#water and food out of the label
#this function was aimed to label the y axis of the heatmap only with the variable name instead of channel+variable name
foodWaterOut <- function (string)
{
  mString <- gsub ("Water|Food", "", string, ignore.case = TRUE)
  
  return (mString)
}

#Generates a table with the values for each unique combination of period and channel (where channel is only water or food)
#then for each table it table it performs the statistical comparison between groups (control vs case) and returns these results
#in a dataframe
pValueCalc <- function (df.weekStatsTbl)
{
  sigResults <- c()
  for (p in unique (df.weekStatsTbl$period))
  {
    for (ch in unique (df.weekStatsTbl$channel))
    {
      print (p)
      
#       df.subset <- subset (df.weekStatsTbl, period == p & channel == ch, 
#                            select = c(period, channel, group, cage, Rate, Number, Avg_Intake, Avg_Duration))
      #with avg intermeal duration
      df.subset <- subset (df.weekStatsTbl, period == p & channel == ch, 
                           select = c(period, channel, group, cage, Avg_Intermeal_Duration, Rate, Number, Avg_Intake, Avg_Duration))
      
      #The first columns with categorical data do not need to be include in signif calculation
      signWater <- t (sapply (df.subset [c(-1, -2, -3, -4)], 
                              function (x)
                              {
                                #wilcox test
                                unlist (wilcox.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                                #t test
                                #unlist (t.test (x~df.subset$group) [c ("estimate", "p.value", "statistic", "conf.int")])
                              }))
      
      rNmeals <- c (ch, caseGroupLabel , p, "Number", as.numeric(signWater ["Number","p.value"]))
      rAvgDuration <- c (ch, caseGroupLabel, p, "Avg_Duration",as.numeric (signWater ["Avg_Duration","p.value"]))
      rAvgIntake <- c (ch, caseGroupLabel, p, "Avg_Intake", as.numeric (signWater ["Avg_Intake","p.value"]))
      rRate <- c (ch, caseGroupLabel, p, "Rate", as.numeric(signWater ["Rate","p.value"]))
      rAvgIntermeal <- c (ch, caseGroupLabel, p, "Avg_Intermeal_Duration", as.numeric(signWater ["Avg_Intermeal_Duration","p.value"]))
#       sigResults <- rbind (sigResults, rRate, rNmeals, rAvgIntake, rAvgDuration)
      sigResults <- rbind (sigResults, rAvgIntermeal, rRate, rNmeals, rAvgIntake, rAvgDuration)
    }
  }
  return (sigResults)
}

#Function for significancy heatmap generation
# weekNotation == T -> In this case the notation is change so that each natural period changes development phase + p-1, has the first
# period correspond to habituation hab (period 1), dev_1 (period 2)...
# legPos == "right" place the legend on the right, "none" --> do not place the legend in any place
# mode == "default" --> color scale for fold change values || mode == "pvalues" --> color scale for pvalues
heatMapPlotter <- function (table, main="", weekNotation=F, legPos="right", mode="default", xlab="", ylab="")
{
  #Change weeks by Development and habituation notation
  if (weekNotation == T)
  {           
    table$week <- paste ("Dev Phase", table$period-1, sep = " ") 
    #table$week <- paste ("Dev Phase", table$period, sep = " ") 
    
    levels(table$week) <- c (levels(table$week), "Dev Phase")          
    #table$week  [table$week == "Dev Phase 0"] <- 'Habituation'
    angleY = 330
  }
  else
  {
    #only numbers on the y axis of the plot
    if (weekNotation == "N")
    {
      table$week <- table$period-1 
      levels(table$week) <- c (levels(table$week))
      angleY = 0
    }
    else
    {
      table$week <- paste ("week", table$period, sep = "_")
      angleY = 330
    }
  }
  
  #Checking mode for setting suitable color scale
  if (mode == "pvalues")
  {           
    colorsSc = c ('black', 'black', 'black', 'yellow', 'cyan', 'black','black',  'black')
    #           valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
    valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
    limitsSc= c (-0.06,0.06)
    breaksSc   = c (-0.05, -0.01, 0.01, 0.05)
    labelsSc = c (">0.05", "0.01", "0.01", ">0.05")
    legName = "p-value"          
  }
  else
  {
    colorsSc = c ('green', 'green', 'green', 'black', 'black', 'red', 'red', 'red')
    valuesSc   = c (-10,  -3, -3, 0, 0, 3, 3, 10)
    limitsSc= c (-3,3)
    breaksSc = c (-3, -2, -1, 0, 1, 2, 3)
    labelsSc = c ("<-3","-2","-1","0", "1", "2", ">3")
    legName = "Fold change"
  }
  
  #table$week <-table$period
  table$period <- as.numeric (table$period)
  table$week <- with (table, reorder (week, period,))
  
  #Merging channel and variable
  #table$chVar <- paste (table$channel, table$variable, sep = " ")
  
  #Capitalizing channel name
  #       table$chVar <- paste (sapply (table$channel, simpleCap), table$variable, sep = " ")
  
  ### CHVAR is controlling order in ggplot function!!!
  table$chVar <- paste (sapply (table$channel, simpleCap), table$varOrder, table$variable, sep = " ")
  
  #Capitalizing variable for labels      
  table$variable <-sapply (table$variable, simpleCap)
  
  #lo que hacemos asignar el orden como nosotros lo queremos en este caso como aparece en la tabla
  #ahora ya no hace falta porque el orden viene de fuera
  #       table$variable <- factor (table$variable, labels=unique (paste (sapply (table$variable, simpleCap))),ordered=T)
  
  (p <- ggplot (table, aes (week, chVar)) + geom_tile (aes (fill = foldChange),
                                                       colour = "white") + #scale_y_discrete (labels = foodWaterOut(table$chVar)) +
     geom_text(aes(label=stars), color="white", size=7) +
     scale_fill_gradientn (guide = "colorbar",
                           colours = colorsSc,
                           values = valuesSc,
                           limits = limitsSc,
                           breaks   = breaksSc,
                           labels = labelsSc,
                           name = legName,
                           rescaler = function(x,...) x,
                           #                                   oob = identity)+ ggtitle(main))#with legend                          
                           oob = identity) + ggtitle(main) + theme (legend.position = "none"))#no legend
  base_size <- 9
  
  p + theme_grey (base_size = base_size) + labs (x = xlab,
                                                 y = ylab) + scale_x_discrete (expand = c(0, 0)) +
    scale_y_discrete (expand = c(0, 0), labels = table$variable) + 
    theme (axis.ticks = element_blank(),
          legend.position = legPos,
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.title.x =  element_text (size = base_size * 1.4, face = "bold"),
          axis.title.y =  element_text (size = base_size * 1.4, face = "bold", angle = 90),
          axis.text.x = element_text(size = base_size * 1.4, angle = angleY,
                                   #1.2, angle = 330,                     
                                   #hjust = 0, colour = "grey50", face = "bold"), #labels=c("Control", "Treat 1", "Treat 2")),
                                   hjust = 0, face = "bold", colour = "black"),                           
          #axis.text.y = element_text (size = base_size * 1.2,hjust = 0, colour = "grey50"))
          legend.text = element_text (size = base_size * 1.2),      
          legend.title = element_text (size = base_size *1.2, face = "bold"),      
          #legend.hjust = element_text (hjust=c(0, 0.5, 1)),
          legend.text = element_text (hjust=c(0, 0.5, 1)),
          plot.title = element_text (size=base_size * 1.5, face="bold"),
          #axis.text.y = element_text (size = base_size * 1.4,hjust = 0, colour = "grey50", face = "bold"))
          axis.text.y = element_text (size = base_size * 1.4,hjust = 0, face = "bold", colour = "black"))                          
}

#Function for significancy heatmap generation only for HABITUATION PHASE
# weekNotation == T -> In this case the notation is change so that each natural period changes development phase + p-1, has the first
# period correspond to habituation hab (period 1), dev_1 (period 2)...
# legPos == "right" place the legend on the right, "none" --> do not place the legend in any place
# mode == "default" --> color scale for fold change values || mode == "pvalues" --> color scale for pvalues
heatMapPlotterHab <- function (table, main="", weekNotation=F, legPos="right", mode="default", xlab="", ylab="", widthCol = "")
{
  #Change weeks by Development and habituation notation
  if (weekNotation == T)
  {           
    table$week <- paste ("Dev Phase", table$period-1, sep = " ") 
    #table$week <- paste ("Dev Phase", table$period, sep = " ") 
    
    levels(table$week) <- c (levels(table$week), "Dev Phase")          
    #table$week  [table$week == "Dev Phase 0"] <- 'Habituation'
    angleY = 330
  }
  else
  {
    #only numbers on the y axis of the plot
    if (weekNotation == "N")
    {
      table$week <- table$period
      levels(table$week) <- c (levels(table$week))
      angleY = 0
    }
    else
    {
      table$week <- paste ("week", table$period, sep = "_")
      angleY = 330
    }
  }
  
  #Checking mode for setting suitable color scale
  if (mode == "pvalues")
  {           
    colorsSc = c ('black', 'black', 'black', 'yellow', 'cyan', 'black','black',  'black')
    #           valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
    valuesSc   = c (-100,    -0.08,   -1.08,     -1,         0.00000000000000000001,         0.08,   0.08,    100)
    limitsSc= c (-0.06,0.06)
    breaksSc   = c (-0.05, -0.01, 0.01, 0.05)
    labelsSc = c (">0.05", "0.01", "0.01", ">0.05")
    legName = "p-value"          
  }
  else
  {
    colorsSc = c ('green', 'green', 'green', 'black', 'black', 'red', 'red', 'red')
    valuesSc   = c (-10,  -3, -3, 0, 0, 3, 3, 10)
    limitsSc= c (-3,3)
    breaksSc = c (-3, -2, -1, 0, 1, 2, 3)
    labelsSc = c ("<-3","-2","-1","0", "1", "2", ">3")
    legName = "Fold Change"
  }
  
  #table$week <-table$period
  table$period <- as.numeric (table$period)
  table$week <- with (table, reorder (week, period,))
  
  #Merging channel and variable
  #table$chVar <- paste (table$channel, table$variable, sep = " ")
  
  ### CHVAR is controlling order in ggplot function!!!
  #Capitalizing channel name
  #       table$chVar <- paste (sapply (table$channel, simpleCap), table$variable, sep = " ")
  table$chVar <- paste (sapply (table$channel, simpleCap), table$varOrder, table$variable, sep = " ")
  
  #Capitalizing variable for labels      
  table$variable <-sapply (table$variable, simpleCap)
  
  #lo que hacemos asignar el orden como nosotros lo queremos en este caso como aparece en la tabla
  #ahora ya no hace falta porque el orden viene de fuera
  #       table$variable<- factor (table$variable, labels=unique (paste (sapply (table$variable, simpleCap))),ordered=T)
  #print (factor (table$variable, labels=unique (paste (sapply (table$variable, simpleCap))),ordered=T) )
  print (table$variable)      
  print (rep (0.5,length (unique (table$week))))
#   (p <- ggplot(table, aes(week, chVar)) + geom_tile(aes(fill = foldChange, width=widthCol),
  (p <- ggplot(table, aes(week, chVar)) + geom_tile(aes(fill = foldChange, width=0.09),
                                                    colour = "white") + #scale_y_discrete (labels = foodWaterOut(table$chVar)) +
     geom_text(aes(label=stars), color="white", size=5) +
     scale_fill_gradientn (guide = "colorbar",
                           colours = colorsSc,
                           values = valuesSc,
                           limits = limitsSc,
                           breaks   = breaksSc,
                           labels = labelsSc,
                           name= legName,
                           rescaler = function(x,...) x,
                           #                                   oob = identity) + ggtitle(main)#with legend
                           oob = identity) + ggtitle(main) + theme (legend.position = "none"))#no legend
  
  base_size <- 9
  p + theme_grey (base_size = base_size) + labs (x = xlab,
                                                 y = ylab) + scale_x_discrete (expand = c(0, 0)) +
    scale_y_discrete (expand = c(0, 0), labels = table$variable) + 
    theme (axis.ticks = element_blank(),
          legend.position = legPos,
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.title.x =  element_text (size = base_size * 1.4, face = "bold"),
          axis.title.y =  element_text (size = base_size * 1.4, face = "bold", angle = 90),
          axis.text.x = element_text(size = base_size * 1.4, angle = angleY,
                                   #1.2, angle = 330,                     
                                   #hjust = 0, colour = "grey50", face = "bold"), #labels=c("Control", "Treat 1", "Treat 2")),
                                   hjust = 0, face = "bold", colour="black"),
          #                           axis.text.x = element_text,
          #axis.text.y = element_text (size = base_size * 1.2,hjust = 0, colour = "grey50"))
          legend.text = element_text (size=base_size * 1.2),      
          legend.title = element_text (size = base_size *1.2, face = "bold"),      
          legend.text = element_text (hjust=c(0, 0.5, 1)),
          plot.title = element_text (size=base_size * 1.5, face="bold"),
          #axis.text.y = element_text (size = base_size * 1.4,hjust = 0, colour = "grey50", face = "bold"))
          axis.text.y = element_text (size = base_size * 1.4,hjust = 0, face = "bold", colour = "black"))                          
}

##############################