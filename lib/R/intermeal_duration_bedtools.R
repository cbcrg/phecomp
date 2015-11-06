############################################################
### Jose A Espinosa. CSN/CB-CRG Group. Feb 2015          ###
############################################################
### Analysis of intermeal intervals using bedtools       ###
############################################################

library (plotrix) #std.error
library (ggplot2)

source ("/Users/jespinosa/phecomp/lib/R/plotParamPublication.R")

setwd("/Users/jespinosa/phecomp/20140807_pergola/bedtools_ex/intermeal_duration")

print(files_ctrl <- list.files(pattern="Ctrl.compl$"))

intermeal_ctrl <- data.frame()

for (i in 1:length(files_ctrl)) {
  tbl<-read.table(files_ctrl[i])
  #   tbl$id <- files_ctrl[i]
  tbl$id <- gsub("tr_|_dt_food_sc\\.bed\\.Ctrl\\.compl", "", files_ctrl[i], perl=TRUE)
  intermeal_ctrl <- rbind(intermeal_ctrl, tbl)
}

intermeal_ctrl$group <- "Ctrl"

print(files_HF <- list.files(pattern="HF.compl$"))

intermeal_HF <- data.frame()

for (i in 1:length(files_HF)) {
  tbl<-read.table(files_HF[i])
  #   tbl$id <- files_HF[i]
  tbl$id <- gsub("tr_|_dt_food_fat_food_sc\\.bed\\.HF\\.compl", "", files_HF[i], perl=TRUE)
  intermeal_HF <- rbind(intermeal_HF, tbl)
}

intermeal_HF$group <- "HF"

intermeal <- rbind(intermeal_ctrl, intermeal_HF)
head (intermeal)


# with (intermeal , aggregate (cbind (V4), list (id=id, group=group), FUN=function (x) c (mean=mean(x))))
intermeal_mean <-with (intermeal , aggregate (cbind (V4), list (group=group), FUN=function (x) c (mean=mean(x), std.error=std.error(x))))
intermeal_mean$mean <- intermeal_mean$V4 [,1]
intermeal_mean$std.error <- intermeal_mean$V4 [,2]

# Prettier colors:
# Reordering colors for showing dark periods as dark colors
cols <- RColorBrewer::brewer.pal (8, "Paired")[3:8]
cols <- c(cols[2],cols[4])
cols

ggplot(data=intermeal_mean, aes(x=group, y=mean, fill=group)) + 
  geom_bar(stat="identity", position=position_dodge()) +
  geom_errorbar(aes(ymin=mean-std.error, ymax=mean+std.error),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  scale_y_continuous(limits=c(0,1500))+
  labs (title = "Intermeal Duration\n") +  
  labs (x = "\nGroup (s)\n", y="Intermeal Duration (s)\n") +
  scale_fill_manual(values=cols) +
  theme(legend.title=element_blank())

ggsave(file="intermeal_duration.png",width=14, height=14, dpi=300, units ="cm")
