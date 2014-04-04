#############################################################################
### Jose A Espinosa. CSN/CB-CRG Group. April 2013                         ###
#############################################################################
### Graphical parameters for ggplot                                       ###
### Publication quality plots                                             ### 
#############################################################################

base_size <- 12

dailyInt_theme <- theme_update (
#axis.text.x = theme_text (angle = 90, hjust = 1, size = base_size * 1.5),
  axis.text.x = theme_text (hjust = 1, size = base_size * 1.5),
  axis.text.y = theme_text (size = base_size * 1.5),
  axis.title.x = theme_text (size=base_size * 1.5, face="bold"),
  axis.title.y = theme_text (size=base_size * 1.5, angle = 90, face="bold"),
  strip.text.x = theme_text (size=base_size * 1.3, face="bold"),#facet titles size 
  strip.text.y = theme_text (size=base_size * 1.3, face="bold", angle=90),
  plot.title = theme_text (size=base_size * 1.5, face="bold"), 
  legend.text = theme_text (size=base_size * 1.2),             
  #   panel.grid.major = theme_line (colour = "grey90"),
  panel.grid.major = theme_blank(),
  #                   panel.grid.minor = element_blank(), 
  panel.grid.minor = theme_blank(),
  panel.border = theme_blank(),
  panel.background = theme_blank(),
  axis.line = theme_segment (colour = "black"),
  #                   axis.ticks = element_blank())
  axis.ticks = theme_blank())