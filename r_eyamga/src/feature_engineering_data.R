# Same process but we will be using a reduced set of the data with only observations and columns with no missing variables
# NB this is arguable as most information is contained from continuous variable
# Loading data ------------------------------------------------------------

#### Loading libraries
setwd("/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/r_eyamga")


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

# Loading Datasets --------------------------------------------------------

# Loading imputed dataset
# Original dataset

coda19 <- read_csv("./imputedset/covid24h_imputed_missing_removed.csv")
# Removing a few duplicated patients
coda19 <- coda19%>%distinct(patient_site_uid, .keep_all = TRUE)
coda19 <- coda19%>%select(-patient_site_uid) # Removing ID from the clustering algorithm


# Separating categorical from numerical variables
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) >= 13)}, function(x){as.numeric(x)})

coda19_continuous <- coda19%>%select_if(is.numeric)
coda19_categorical <- coda19%>%select_if(is.factor)


# Selecting continuous variables of interest
coda19_continuous_labs <- coda19%>%select(c("hemoglobin_min", "plt_max", "wbc_max", "neutrophil_max", 
                                       "lymph_min", "mono_max", "eos_min", "baso_mean", "sodium_min",
                                       "creatinine_max")) #pvco2 does not exist

coda19_continuous_vitals <- coda19%>%select(c("sbp_max", "sbp_min", "dbp_min", "temp_max", "so2_min", "rr_mean",
                                          ))

coda19_continuous <- coda19_continuous_labs%>%cbind(coda19_continuous_vitals)
# coda19 <- coda19%>%select(-death)


# Modifying categorical variables
coda19_categorical <- coda19_categorical%>%select("female", "male", "vasopressors", "glucocorticoids", "anti_bacterial_agents", "antifungal_agents",
                                                  "immunosuppressive_agents", "diuretics", "platelet_aggregation_inhibitors", "sedation",
                                                  "neuromuscular_blocking_agents", "bronchodilator_agents", "hiv_medication", "mv", "death") 

# adding bronchodilator

# Simplifying the number of variables 
coda19_categorical <- coda19_categorical%>%
  mutate_if(is.factor, ~as.numeric(as.character(.)))

coda19_categorical <- coda19_categorical%>% replace(. >= 1, 1) 

coda19_categorical <- coda19_categorical%>%
  mutate_if(is.numeric, ~as.factor(.))

# coda19_categorical2$score <- coda19_categorical$score


# complete dataset

coda19_complete <- coda19_continuous%>%cbind(coda19_categorical) 

# KMO testing
library(psych)
data_matrix = cor(coda19_continuous, use = 'complete.obs')
KMO(data_matrix)
cortest.bartlett(coda19_continuous)


# PCA --------------------------------------------------------

# All cotinuous variables
# Adding two categorical variables to better observe PCA results
coda19_continuous$death <- coda19$death
coda19_continuous$mv <- coda19$mv
coda19_continuous$baso_mean <- as.numeric(coda19_continuous$baso_mean)
coda19_continuous_labs$baso_mean <- as.numeric(coda19_continuous_labs$baso_mean)

pca.coda19 <- PCA(coda19_continuous,
                  quali.sup = c(17,18),
                  graph = FALSE)

pca.coda19_labs <- PCA(coda19_continuous_labs,
                  graph = FALSE)

pca.coda19_vitals <- PCA(coda19_continuous_vitals,
                  graph = FALSE)


print(pca.coda19)

# PCA results - Tabular data

# A - PC evaluation
# Eigenvalue
pca.coda19$eig

pca.coda19_labs$eig

pca.coda19_vitals$eig

# B - Variables evaluation

# Correlations
pca.coda19$var$contri

# Contributions
as_tibble(pca.coda19$var$contrib, rownames='variables')%>%arrange(desc(Dim.1))
as_tibble(pca.coda19$var$contrib, rownames='variables')%>%arrange(desc(Dim.2))

# Cos2 
head(pca.coda19$var$cos2, 5)

# C - Observations projections = PCs scores # Not that helpful here
pca.coda19$ind$coord

# PCA results - Visualization

# Scree plot
fviz_eig(pca.coda19)

# Variables contributions
library("corrplot")

# Correlation plot of variables and cos2
corrplot(pca.coda19$var$contrib, is.corr=FALSE)
corrplot(pca.coda19$var$cos2, is.corr=FALSE)

# VARIABLES bar plot
# Contributions of variables to PC1
fviz_contrib(pca.coda19, choice = "var", axes = 1, top = 10)
# Contributions of variables to PC2
fviz_contrib(pca.coda19, choice = "var", axes = 2, top = 10)

# Contributions of variables to PC1-2
# This is not simply the contribution of PC1 and PC2
# When calculated, this reflects the total contribution of variable on the 2 PCs 
# contrib = [(C1 * Eig1) + (C2 * Eig2)]/(Eig1 + Eig2)

fviz_contrib(pca.coda19, choice = "var", axes = 1:2, top = 10) + coord_flip()


# COS2 bar plot
fviz_cos2(pca.coda19, choice = "var", axes = 1:5, top=20) # Seeing mots important cos2 variables on PC1 and PC2

# Variables plot
fviz_pca_var(pca.coda19,
             col.var = "contrib", # Color by contributions to the PC alternatives, color by cos2
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
             )


# Clustering of the variables
# Create 3 groups of variables (centers = 3)
set.seed(123)
coda19.kmeans.onvar <- kmeans(pca.coda19$var$coord, centers = 3, nstart = 25)
coda19.var.clusters <- as.factor(coda19.kmeans.onvar$cluster)

# Color variables by groups
fviz_pca_var(pca.coda19, col.var = coda19.var.clusters, 
             palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
             legend.title = "Cluster")


# Observations and PCA


# Labeling observation using outcome variable
# Observations classified
fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$death, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "Groups"
)

fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             habillage = 114, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             #ellipse.type = "confidence",
             legend.title = "Groups"
)


fviz_pca_ind(pca.coda19,
             geom.ind = "point", # show points only (nbut not "text")
             col.ind = coda19_continuous$mv, # color by death
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             addEllipses = TRUE, # Concentration ellipses
             legend.title = "Groups"
)

# Labeling observations using clustering 
# Create 3 groups of variables (centers = 3)
set.seed(123)
coda19.kmeans.onobs <- kmeans(pca.coda19$ind$coord, centers = 3, nstart = 25)
coda19.obs.clusters <- as.factor(coda19.kmeans.onobs$cluster)

# Color variables by groups
fviz_pca_ind(pca.coda19, 
             geom.ind = "point",
             col.ind = coda19.obs.clusters, 
             palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
             addEllipses = TRUE, 
             legend.title = "Cluster")




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
                  quali.sup = c(15), # Removing death from observation but MV kept
                  graph = FALSE)

print(mca.coda19)

print(mca.coda19$eig)

# Possible to view the variables as we did above
# For the sake of time, simply use explor! 



# FAMD -------------------------------

famd.coda19_cut <- FAMD(coda19_complete,
                    sup.var = c(31), # Removing death from observation but MV kept
                    graph = FALSE)


## Variables 

fviz_cos2(famd.coda19_cut, choice = "var", axes = 1:5, top=20) # Seeing mots important cos2 variables on PC1 and PC2

fviz_cos2(famd.coda19_cut, choice = "ind", axes = 1:5, top=20) # Seeing mots important cos2 observations on PC1 and PC2

# Using clustering to draw some patterns

set.seed(123)
fmadcoda19.kmeans.onvar <- kmeans(famd.coda19_cut$var$coord, centers = 3, nstart = 25)
fmadcoda19.var.clusters <- as.factor(fmadcoda19.kmeans.onvar$cluster)

# Color variables by groups
fviz_famd_var(famd.coda19_cut, col.var = fmadcoda19.var.clusters, 
             palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
             legend.title = "Cluster",
             addEllipses = TRUE, 
             repel = TRUE)

## Observations pattern

fmadcoda19.kmeans.onobs <- kmeans(famd.coda19_cut$ind$coord, centers = 3, nstart = 50)
fmadcoda19.obs.clusters <- as.factor(fmadcoda19.kmeans.onobs$cluster)

# Color observations by groups
fviz_famd_ind(famd.coda19_cut, 
              axes = c(1,2),
             geom.ind = "point",
             col.ind = fmadcoda19.obs.clusters, 
             palette = c("#0073C2FF", "#EFC000FF", "#868686FF"),
             addEllipses = TRUE, 
             legend.title = "Cluster")

# Shiny Interactive Vizualization using exploR ------------------------------------------------------
library(explor)
# PCA exploration
explor(pca.coda19)
explor(pca.coda19_labs)

# MCA exploration
explor(mca.coda19)



# Clustering preview on the data (vs on PCA result as done above) ------------------------------------------------------

coda19_gower <- cluster::daisy(coda19_complete, metric = "gower")

set.seed(13130)
k=4
pam_fit <- pam(coda19_complete, diss = TRUE, k)
pam_results <- coda19_complete %>%
  mutate(cluster = pam_fit$clustering) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

table(pam_fit$clustering)


# Optimal cluster viz #Nb
# fviz_nbclust -> does not work with gower distance and PAM

# This is also done later through EDA
print(pam_results$the_summary)

tsne_obj <- Rtsne(coda19_gower, is_distance = TRUE)
tsne_data <- tsne_obj$Y %>%
  data.frame() %>%
  setNames(c("X", "Y")) %>%
  mutate(cluster = factor(pam_fit$clustering))


# Plotting the results : TSNE + PCA  -------------------------------------

# 1) Plotting the clustering results on TSNE 
p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
  geom_point(aes(color = cluster))+
  ggtitle("3 K-means clustering")

show(p)

# 2)  Plotting the clustering results on PCA
# Difficult to interpret as data not scaled in this iteration and categorical data

pam_fit$data <- coda19_complete%>%
  mutate_if(is.factor, ~as.numeric(as.character(.)))
fviz_cluster(pam_fit, geom = "point", ellipse.type = "norm")

## 3) Plotting on FAMD
coda19_complete_famd <- coda19_complete # copying the data on a new variable
coda19_complete_famd$clusters <- pam_fit$clustering #adding the clustering results on the dataset

famd.coda19_cut_clust <- FAMD(coda19_complete_famd, # FAMD on this data
                        sup.var = c(31,32), # Removing death from observation and clusters from component analysis
                        graph = FALSE)

fviz_famd_ind(famd.coda19_cut_clust, 
              axes = c(1,2),
              geom.ind = "point",
              repel = TRUE,
              label = "none", 
              col.ind = as.factor(coda19_complete_famd$clusters), 
              palette = c("#0073C2FF", "#EFC000FF", "#868686FF", "#4A6990FF"),
              addEllipses = TRUE, 
              legend.title = "Cluster")
