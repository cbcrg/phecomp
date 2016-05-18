#############################################################################
### Jose A Espinosa. CSN/CB-CRG Group. May 2015                           ###
#############################################################################
### Graphical parameters for ggplot                                       ###
### Publication quality plots                                             ### 
#############################################################################

base_size <- 12
size_titles <- 22

size_axis_text <- 14 #22
size_axis_title <- 16
size_leg_title <- 14
size_leg_text <- 11

# size_text_circle
dailyInt_theme <- theme_update (
  axis.text.x = element_text (size = size_axis_text),
  axis.text.y = element_text (size = size_axis_text),
  axis.title.x = element_text (size = size_axis_title, face="bold"),
  axis.title.y = element_text (size = size_axis_title, angle = 90, face="bold"),
  plot.title = element_text (size = size_titles, face="bold"),
  legend.title = element_text (size = size_leg_title), 
  legend.text = element_text (size = size_leg_text), 
  #   panel.grid.major = theme_line (colour = "grey90"),
  panel.grid.major = element_blank(),
  #                   panel.grid.minor = element_blank(), 
  panel.grid.minor = element_blank(),
  #panel.border = element_blank(),
  panel.border = element_rect(colour = "black",fill=NA),
  panel.background = element_blank(),
  axis.line = element_line (colour = "black"),
  #                   axis.ticks = element_blank())
  axis.ticks = element_blank())