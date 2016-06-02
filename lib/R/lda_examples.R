
#######################################
# LDA biplot EXAMPLE with iris data from stackoverflow
## http://stackoverflow.com/questions/17232251/how-can-i-plot-a-biplot-for-lda-in-r/17240647#17240647

lda.arrows <- function(x, myscale = 1, tex = 0.75, choices = c(1,2), ...){
  ## adds `biplot` arrows to an lda using the discriminant function values
  heads <- coef(x)
  arrows(x0 = 0, y0 = 0, 
         x1 = myscale * heads[,choices[1]], 
         y1 = myscale * heads[,choices[2]], ...)
  text(myscale * heads[,choices], labels = row.names(heads), 
       cex = tex)
}

dis2 <- lda(as.matrix(iris[, 1:4]), iris$Species)
plot(dis2, asp = 1)
lda.arrows(dis2, col = 2, myscale = 2)

###########################
### Code from stackexchange
## http://stats.stackexchange.com/questions/82497/can-the-scaling-values-in-a-linear-discriminant-analysis-lda-be-used-to-plot-e

#Perform LDA analysis
iris.lda <- lda(as.factor(Species)~.,
                data=iris)

#Project data on linear discriminants
iris.lda.values <- predict(iris.lda, iris[,-5])

#Extract scaling for each predictor and
data.lda <- data.frame(varnames=rownames(coef(iris.lda)), coef(iris.lda))

#coef(iris.lda) is equivalent to iris.lda$scaling

data.lda$length <- with(data.lda, sqrt(LD1^2+LD2^2))
scale.para <- 0.75

#Plot the results
p <- qplot(data=data.frame(iris.lda.values$x),
           main="LDA",
           x=LD1,
           y=LD2,
           shape=iris$Species)#+stat_ellipse()
p <- p + geom_hline(aes(yintercept=0), size=.2) + geom_vline(aes(xintercept=0), size=.2)
p <- p + theme(legend.position="none")
p <- p + geom_text(data=data.lda,
                   aes(x=LD1*scale.para, y=LD2*scale.para,
                       label=varnames, 
                       shape=NULL, linetype=NULL,
                       alpha=length),
                   size = 3, vjust=0.5,
                   hjust=0, color="red")
p <- p + geom_segment(data=data.lda,
                      aes(x=0, y=0,
                          xend=LD1*scale.para, yend=LD2*scale.para,
                          shape=NULL, linetype=NULL,
                          alpha=length),
                      arrow=arrow(length=unit(0.2,"cm")),
                      color="red")
p <- p + coord_flip()

print(p)

#######################################
# LDA biplot from github
# https://github.com/vqv/ggbiplot/tree/experimental
library(MASS)
data(iris)

# Standardize numeric variables and apply LDA
# library(devtools)
# install_github("vqv/ggbiplot", ref = "experimental")

fortify.lda <- function(model, data = NULL, scale = 0, equalize = scale != 0, ...) {
  
  # Predict
  fit <- if (is.null(data)) {
    predict(model, ...)
  } else {
    predict(model, data, ...)
  }
  
  # Rescale
  scores <- sweep(fit$x, 2, model$svd^(-scale), FUN = "*")
  loadings <- sweep(model$scaling, 2, model$svd^scale, FUN = "*")
  
  if(equalize) {
    r <- sqrt( median(rowSums(scores^2)) / max(colSums(loadings^2)) )
    loadings <- loadings * r
  }
  
  scores <- data.frame(scores, .class = fit$class)
  loadings <- data.frame(loadings)
  
  if (!is.null(data)) scores <- cbind(data, scores)
  if (!is.null(rownames(loadings))) {
    loadings$.name <- rownames(loadings)
    rownames(loadings) <- NULL
  }
  
  structure(scores, basis = loadings)
}

iris_z <- lapply(iris, function(x) if (is.numeric(x)) scale(x) else x)
m <- lda(Species ~ ., data = iris_z)
df <- fortify.lda(m, iris_z)

g <- ggplot(df, aes(x = LD1, y = LD2)) +
  geom_point(aes(color = Species)) + 
  stat_ellipse(aes(group = Species, color = Species)) +
  ylim(-4, 4) + coord_equal() +
#   geom_segment(data=data.lda,
#                aes(x=0, y=0,
#                    xend=LD1*scale.para, yend=LD2*scale.para,
#                    shape=NULL, linetype=NULL,
#                    alpha=length),
#                arrow=arrow(length=unit(0.2,"cm")),
#                color="red")

  
  
  geom_segment(data=df_att,
                 aes(x=0, y=0, 
                     xend=LD1*scale.para, yend=LD2*scale.para,
                     shape=NULL, linetype=NULL,
                     alpha=length),
                 arrow=arrow(length=unit(0.2,"cm")),
                 color="red") + 
  geom_text (data=df_att,aes (x=LD1, y=LD2, label=.name))
#  geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 

print(g)


#### my data set

data_reinst_filt

iris_z <- lapply(data_reinst_filt, function(x) if (is.numeric(x)) scale(x) else x)
m <- lda(group ~ ., data = iris_z, normalize=TRUE)
df <- fortify.lda(m, iris_z)


df_att <- attr(df, "basis")
df_att$length <- 1
g <- ggplot(df, aes(x = LD1, y = LD2)) +
  geom_point(aes(color = group)) + 
  stat_ellipse(aes(group = group, color = group)) +
  ylim(-20, 20) + coord_equal() +
#   ylim(-1, 1) + coord_equal() +
  #   geom_segment(data=data.lda,
  #                aes(x=0, y=0,
  #                    xend=LD1*scale.para, yend=LD2*scale.para,
  #                    shape=NULL, linetype=NULL,
  #                    alpha=length),
  #                arrow=arrow(length=unit(0.2,"cm")),
  #                color="red")
  
  
  
  geom_segment(data=df_att,
               aes(x=0, y=0, 
                   xend=LD1*scale.para, yend=LD2*scale.para,
                   shape=NULL, linetype=NULL,
                   alpha=length),
               arrow=arrow(length=unit(0.2,"cm")),
               color="red") + 
  geom_text (data=df_att,aes (x=LD1, y=LD2, label=.name))
#  geom_text (data=neg_positions_plot, aes (x=LD1, y=LD2, label=neg_labels, hjust=1.2), show.legend = FALSE, size=size_text_circle) + 

print(g)

######################

## https://beckmw.wordpress.com/2015/05/14/reinventing-the-wheel-for-ordination-biplots-with-ggplot2/
library(devtools)
install_github('fawda123/ggord')
library(ggord)

ord <- lda(Species ~ ., iris, prior = rep(1, 3)/3)
ggord(ord, iris$Species)

res_lda = lda(group  ~ . , data_reinst_filt)
ggord(res_lda, data_reinst_filt$group)
