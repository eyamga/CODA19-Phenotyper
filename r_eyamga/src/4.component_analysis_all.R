# Same process but we will be using a reduced set of the data with only observations and columns with no missing variables
# NB this is arguable as most information is contained from continuous variable
# Loading data ------------------------------------------------------------

#### Loading libraries

source("./library_load.R")
library(cluster)
library(Rtsne)
library(cowplot) 
library(svglite)
library(FactoMineR)
library(factoextra)
library(fpc)
library(NbClust)
library(explor)
library("GGally")

# Loading Datasets --------------------------------------------------------

# Recalculate # of filtered patients
# coda <- read_csv("./data/processed/covid24h_notimputed.csv")
# coda <- coda%>%distinct(patient_site_uid, .keep_all = TRUE) # f <- coda[!duplicated(coda), ] 
# coda <- coda %>%  
#   purrr::discard(~sum(is.na(.x))/length(.x)*100 >=25)%>% 
#   filter(rowSums(is.na(.)) < ncol(.)*0.25)                 
# Comments on the 24h dataset : 36 duplicates, 179 observations with missing data

# Loading imputed dataset
coda19 <- read_csv("./data/imputed/covid24h_imputed.csv")

# Removing a few duplicated patients
coda19 <- coda19%>%distinct(patient_site_uid, .keep_all = TRUE)
coda19 <- coda19%>%select(-patient_site_uid) # Removing ID from the clustering algorithm

# Reminder of categorical variables (mv, icu, levelofcare, wave)

# Separating categorical from numerical variables
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) >= 13)}, function(x){as.numeric(x)})

coda19_continuous <- coda19%>%select_if(is.numeric)
coda19_categorical <- coda19%>%select_if(is.factor)


# Selecting continuous variables of interest
coda19_continuous_labs <- coda19%>%select(c("hemoglobin_min", "plt_max", "wbc_max", "neutrophil_max", 
                                       "lymph_min", "mono_max", "eos_min", "baso_mean", "sodium_mean",
                                       "creatinine_max")) #pvco2 does not exist

coda19_continuous_vitals <- coda19%>%select(c("sbp_max", "sbp_min", "dbp_min", "temp_max", "so2_min", "rr_mean", "fio2_mean", "patient_age"))


# Modifying categorical variables
# coda19_categorical <- coda19_categorical%>%select(-c("icu", "death")) 


# KMO testing
# library(psych)
# data_matrix = cor(coda19_continuous, use = 'complete.obs')
# KMO(data_matrix)
# cortest.bartlett(coda19_continuous)


# PCA  all cotinuous variables--------------------------------------------------------

# Adding two categorical variables to better observe PCA results
coda19_continuous$death <- coda19$death
coda19_continuous$mv <- coda19$mv
coda19_continuous$wave <- coda19$wave
coda19_continuous$levelofcare <- coda19$levelofcare
coda19_continuous$icu <- coda19$icu


pca.coda19 <- PCA(coda19_continuous,
                  quali.sup = c(52:56),
                  graph = FALSE)

# pca.coda19_labs <- PCA(coda19_continuous_labs,
#                   graph = FALSE)
# 
# pca.coda19_vitals <- PCA(coda19_continuous_vitals,
#                   graph = FALSE)
# 

# print(pca.coda19)


# # PCA results - Tabular data --------------------------------------------

# A - PC evaluation
# 1)  Eigenvalue
kable(pca.coda19$eig)
write_csv(as_tibble(pca.coda19$eig, rownames='PCA comp')%>%head(10), "./output/pca/pca_all_eigenvalues.csv")

#pca.coda19_labs$eig
#pca.coda19_vitals$eig

# B - Variables evaluation

# 2) Variable Contributions
write_csv(as_tibble(pca.coda19$var$contri, rownames='Variables')%>%head(10), "./output/pca/pca_all_correlations.csv")

# Contributions
#as_tibble(pca.coda19$var$contrib, rownames='variables')%>%arrange(desc(Dim.1))
#as_tibble(pca.coda19$var$contrib, rownames='variables')%>%arrange(desc(Dim.2))

# Cos2 
#head(pca.coda19$var$cos2, 5)

# C - Observations projections = PCs scores # Not that helpful here
#pca.coda19$ind$coord

# PCA results - Visualization

# 1) Scree plot
pca.scree <- fviz_eig(pca.coda19, addlabels=TRUE) + theme_minimal() + labs(title = "PCA Scree Plot", x = "Principal Components", y = "% of variances")
pca.scree
dev.print(pdf, file="./output/pca/pca_all_screeplot.pdf");


# Variables contributions
library("corrplot")
# Correlation plot of variables and cos2
#corrplot(pca.coda19$var$contrib, is.corr=FALSE)
#corrplot(pca.coda19$var$cos2, is.corr=FALSE)

# 2) COS2 correlation plot

cos2plot <- ggcorrplot::ggcorrplot(t(pca.coda19$var$cos2),
                       outline.col = "white",
                       legend.title = "cos2 values",
                       ggtheme = ggplot2::theme_gray,
                       colors = c("#6D9EC1", "white", "#E46726")) + 
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  labs(title = "Cos 2 of variables",x = "Principal Components", y = "Variables",  xfill = "Cos2 values") + 
  scale_fill_gradient2(breaks=c(0, 0.5), limit = c(0,0.6), low = "white", mid ="#89efc7",  high =  "#1e6076", midpoint = 0.25)

cos2plot
dev.print(pdf, file="./output/pca/pca_all_cos2plot.pdf")

# VARIABLES bar plot
# Contributions of variables to PC1
#fviz_contrib(pca.coda19, choice = "var", axes = 1, top = 10)
# Contributions of variables to PC2
#fviz_contrib(pca.coda19, choice = "var", axes = 2, top = 10)

# Contributions of variables to PC1-2
# This is not simply the contribution of PC1 and PC2
# When calculated, this reflects the total contribution of variable on the 2 PCs 
# contrib = [(C1 * Eig1) + (C2 * Eig2)]/(Eig1 + Eig2)

# fviz_contrib(pca.coda19, choice = "var", axes = 1:2, top = 10) + coord_flip()


# COS2 bar plot
# fviz_cos2(pca.coda19, choice = "var", axes = 1:5, top=20) # Seeing mots important cos2 variables on PC1 and PC2

# 3) PCA Variables plot
pca_varplot <- fviz_pca_var(pca.coda19,
             col.var = "contrib", # Color by contributions to the PC alternatives, color by cos2
             gradient.cols = c(low ="#89efc7",  high =  "#1e6076"),
             ggtheme = theme_minimal(),
             #gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
             ) +
  labs(title = "PCA Variables Plot", x = "PC1", y = "PC2", color = "Contribution %")

pca_varplot
dev.print(pdf, file="./output/pca/pca_all_pcavarplot.pdf")


# Clustering of the variables
# Create 3 groups of variables (centers = 3)
# set.seed(123)
# coda19.kmeans.onvar <- kmeans(pca.coda19$var$coord, centers = 3, nstart = 25)
# coda19.var.clusters <- as.factor(coda19.kmeans.onvar$cluster)
# 
# # Color variables by groups
# fviz_pca_var(pca.coda19, col.var = coda19.var.clusters, 
#              palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
#              legend.title = "Cluster")


# Observations and PCA

# 4) PCA Individual plot

# Labeling observation using outcome variable

# Observations classified
# By death
pca_indplot_bydeath <- fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$death, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "Death"
) +
  labs(title = "PCA Individuals Plot", x = "PC1", y = "PC2")

pca_indplot_bydeath
dev.print(pdf, file="./output/pca/pca_all_pcaindplot_death.pdf")




#By icu (NB does not represent current ICU admission but all ICU admissions)
pca_indplot_byicu <- fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$icu, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "ICU"
) +
  labs(title = "PCA Individuals Plot", x = "PC1", y = "PC2")

pca_indplot_byicu
dev.print(pdf, file="./output/pca/pca_all_pcaindplot_icu.pdf")

#By MV
pca_indplot_bymv <- fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$mv, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "Mechanical Ventilation"
)

pca_indplot_bymv
dev.print(pdf, file="./output/pca/pca_all_pcaindplot_mv.pdf")


#By Level Of Care

pca_indplot_byloc <- fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$levelofcare, # color by death
             #habillage = c(53), alternative script valid for factoextrar pca objects
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "Level Of Care"
)

pca_indplot_byloc
dev.print(pdf, file="./output/pca/pca_indplot_byloc.pdf")


#By Wave

pca_indplot_bywave <- fviz_pca_ind(pca.coda19,
                                  geom.ind = "point", # show points only (nbut not "text")
                                  col.ind = coda19_continuous$wave, # color by death
                                  #habillage = c(53), alternative script valid for factoextrar pca objects
                                  palette = c("#00AFBB", "#E7B800", "#FC4E07"),
                                  addEllipses = TRUE, # Concentration ellipses
                                  legend.title = "Wave"
)

pca_indplot_bywave
dev.print(pdf, file="./output/pca/pca_indplot_bywave.pdf")

# Labeling observations using clustering 

# Create 3 groups of variables (centers = 3)
# set.seed(123)
# coda19.kmeans.onobs <- kmeans(pca.coda19$ind$coord, centers = 3, nstart = 25)
# coda19.obs.clusters <- as.factor(coda19.kmeans.onobs$cluster)
# 
# # Color variables by groups
# fviz_pca_ind(pca.coda19, 
#              geom.ind = "point",
#              col.ind = coda19.obs.clusters, 
#              palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
#              addEllipses = TRUE, 
#              legend.title = "Cluster")
# 


# Biplot (observations plot)
fviz_pca_biplot(pca.coda19, repel = TRUE,
                col.var = "#2E9FDF", # Variables color
                col.ind = "#696969")  # Individuals color


# Other stuff prediction on unobserved variables
# Remember ind.sup : a numeric vector specifying the indexes of the supplementary individuals in the PCA function
# This allows to see the prediction by simply adding the col.ind.sup in the fviz_pca_ind function
# p <- fviz_pca_ind(res.pca, col.ind.sup = "blue", repel = TRUE)


# MCA --------------------------------------------------------

mca.coda19 <- MCA(coda19_categorical,
                  quali.sup = c(3), # Removing death from observation but MV, ICU, WAVE, LOC
                  graph = FALSE)

# Tabular info only
# 1) Eigen values
write_csv(as_tibble(mca.coda19$eig, rownames='MCA comp')%>%head(10), "./output/mca/mca_all_eigenvalues.csv")

print(mca.coda19$eig)

# 2) MCA all contributions
write_csv(as_tibble(mca.coda19$var$contri, rownames='Variables')%>%head(100)%>%arrange(desc(.[[2]], .[[3]], .[[4]], .[[5]])), "./output/mca/mca_all_contributions.csv")


# Possible to view the variables as we did above
# For the sake of time, simply use explor! 
#  write_csv(as_tibble(pca.coda19$var$contri, rownames='Variables')%>%head(10), "./output/pca/pca_all_correlationscsv")

### MCA viz 
# 1) MCA variables correlation plot

# mca_cos2plot <- ggcorrplot::ggcorrplot(t(mca.coda19$var$cos2),
#                                    outline.col = "white",
#                                    legend.title = "cos2 values",
#                                    ggtheme = ggplot2::theme_gray,
#                                    colors = c("#6D9EC1", "white", "#E46726")) + 
#   theme_minimal() + 
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
#   labs(title = "Cos 2 of variables",x = "Principal Components", y = "Variables",  xfill = "Cos2 values") + 
#   scale_fill_gradient2(breaks=c(0, 0.5), limit = c(0,0.6), low = "white", mid ="#89efc7",  high =  "#1e6076", midpoint = 0.25)
# 
# mca_cos2plot
# dev.print(pdf, file="./output/mca/mca_all_cos2plot.pdf")

# explor(mca.coda19)
# Not much information, too many variables, no plotting deemed useful


# FAMD -------------------------------

famd.coda19 <- FAMD(coda19,
                    sup.var = c(3), # Removing death from observation but MV, ICU, WAVE, LOC
                    graph = FALSE)


# Tabular info only
# 1) Eigen values
write_csv(as_tibble(famd.coda19$eig, rownames='FAMD comp')%>%head(10), "./output/famd/famd_all_eigenvalues.csv")

# 2) FAMD all contributions
write_csv(as_tibble(famd.coda19$var$contri, rownames='Variables')%>%head(100)%>%arrange(desc(.[[2]], .[[3]], .[[4]], .[[5]])), "./output/famd/famd_all_contributions.csv")

# 
# ## Variables 
# 
# fviz_cos2(famd.coda19, choice = "var", axes = 1:5, top=20) # Seeing mots important cos2 variables on PC1 and PC2
# 
# # Using clustering to draw some patterns
# 
# set.seed(123)
# fmadcoda19.kmeans.onvar <- kmeans(famd.coda19_cut$var$coord, centers = 3, nstart = 25)
# fmadcoda19.var.clusters <- as.factor(fmadcoda19.kmeans.onvar$cluster)
# 
# # Color variables by groups
# fviz_famd_var(famd.coda19, col.var = fmadcoda19.var.clusters, 
#              palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
#              legend.title = "Cluster",
#              addEllipses = TRUE, 
#              repel = TRUE)
# 
# ## Observations pattern
# 
# fmadcoda19.kmeans.onobs <- kmeans(famd.coda19_cut$ind$coord, centers = 3, nstart = 50)
# fmadcoda19.obs.clusters <- as.factor(fmadcoda19.kmeans.onobs$cluster)
# 
# # Color observations by groups
# fviz_famd_ind(famd.coda19_cut, 
#               axes = c(1,2),
#              geom.ind = "point",
#              col.ind = fmadcoda19.obs.clusters, 
#              palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
#              addEllipses = TRUE, 
#              legend.title = "Cluster")



# Shiny Interactive Vizualization using exploR ------------------------------------------------------
library(explor)
# PCA exploration
explor(pca.coda19)
explor(pca.coda19_labs)

# MCA exploration
explor(mca.coda19)



# # Clustering preview on the data (vs on PCA result as done above) ------------------------------------------------------
# 
# coda19_gower <- cluster::daisy(coda19_complete, metric = "gower")
# 
# set.seed(13130)
# k=4
# pam_fit <- pam(coda19_complete, diss = TRUE, k)
# pam_results <- coda19_complete %>%
#   mutate(cluster = pam_fit$clustering) %>%
#   group_by(cluster) %>%
#   do(the_summary = summary(.))
# 
# table(pam_fit$clustering)
# 
# 
# # Optimal cluster viz #Nb
# # fviz_nbclust -> does not work with gower distance and PAM
# 
# # This is also done later through EDA
# print(pam_results$the_summary)
# 
# tsne_obj <- Rtsne(coda19_gower, is_distance = TRUE)
# tsne_data <- tsne_obj$Y %>%
#   data.frame() %>%
#   setNames(c("X", "Y")) %>%
#   mutate(cluster = factor(pam_fit$clustering))
# 
# 
# # Plotting the results : TSNE + PCA  -------------------------------------
# 
# # 1) Plotting the clustering results on TSNE 
# p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
#   geom_point(aes(color = cluster))+
#   ggtitle("3 K-means clustering")
# 
# show(p)
# 
# # 2)  Plotting the clustering results on PCA
# # Difficult to interpret as data not scaled in this iteration and categorical data
# 
# pam_fit$data <- coda19_complete%>%
#   mutate_if(is.factor, ~as.numeric(as.character(.)))
# fviz_cluster(pam_fit, geom = "point", ellipse.type = "norm")
# 
# ## 3) Plotting on FAMD
# coda19_complete_famd <- coda19_complete # copying the data on a new variable
# coda19_complete_famd$clusters <- pam_fit$clustering #adding the clustering results on the dataset
# 
# famd.coda19_cut_clust <- FAMD(coda19_complete_famd, # FAMD on this data
#                         sup.var = c(31,32), # Removing death from observation and clusters from component analysis
#                         graph = FALSE)
# 
# fviz_famd_ind(famd.coda19_cut_clust, 
#               axes = c(1,2),
#               geom.ind = "point",
#               repel = TRUE,
#               label = "none", 
#               col.ind = as.factor(coda19_complete_famd$clusters), 
#               palette = c("#0073C2FF", "#EFC000FF", "#868686FF", "#4A6990FF"),
#               addEllipses = TRUE, 
#               legend.title = "Cluster")
