############################################################
### Jose A Espinosa. CSN/CB-CRG Group. Feb 2015          ###
############################################################
### Getting first meal after cleanning and plotting:     ###
### Latency                                              ###
### Intake                                               ###
############################################################

source ("/Users/jespinosa/phecomp/lib/R/plotParamPublication.R")

setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/starting_regions_file")
# Get a list of the bedtools output files you'd like to read in
print(files <- list.files(pattern="meal_lat.bed$"))

# Optional, create short sample names from the filenames.
print(labs <-gsub("_first_meal_lat\\.bed", "", files, perl=TRUE))

# Create lists to hold latency and intake to the first meal for each animal group and phase,
# and read the data into these lists.
lat <- list()

for (i in 1:length(files)) {
  lat[[i]] <- read.table(files[i])
}

# Prettier colors:
# Reordering colors for showing dark periods as dark colors
cols <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
cols <- c(cols[2],cols[4])
cols

lat_all <- lat[[1]]
lat_all$group <- labs[1]  
lat_all$index <- c(1:length(lat_all[,1]))

for (i in 2:length(lat)) {
  lat_gr <- lat[[i]] 
  lat_gr$group <- labs[i]
  lat_gr$index <- c(1:length(lat[[i]][,1]))
  lat_all<-rbind (lat_all, lat_gr)    
}

lat_all 
ggplot(data=lat_all, aes(x=index, y=V18, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "Latency First Meal\n") +  
  labs (x = "\nFile Number\n", y="Latency (s)\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="latency_first_meal.png",width=26, height=14, dpi=300, units ="cm")

ggplot(data=lat_all, aes(x=index, y=V13, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +      
  scale_x_continuous(breaks=1:9, limits=c(0,10))+
  #        scale_y_continuous(limits=c(0,0.8))+
  labs (title = "First Meal Intake\n") +  
  labs (x = "\nFile number\n", y="Intake (g)\n",fill = NULL) +
  scale_fill_manual(values=cols)
ggsave(file="intake_first_meal.png",width=26, height=14, dpi=300, units ="cm")
