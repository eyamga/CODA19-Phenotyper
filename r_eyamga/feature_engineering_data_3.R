# Same process but removing min and max continuous variable arbitrarely

# Loading data ------------------------------------------------------------

#### Loading libraries

setwd("~/Documents/Médecine/Recherche/CODA19/code/r_eyamga")
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

coda19 <- read_csv("./imputedset/covid24h_precluster.csv")
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
                                       "lymph_min", "mono_max", "eos_min", "baso_mean", "albumin_min", "sodium_min", "chloride_min",
                                       "potassium_mean", "bicarbonate_min", "bun_max", "magnesium_mean",
                                       "phosphate_mean", "creatinine_max", "glucose_max",
                                       "anion_gap_mean", "ptt_max",
                                       "alt_max", "ast_max", "palc_max",
                                       "lipase_max", "bili_tot_max", "crp_max",
                                       "ldh_max", "tropot_max", "lactate_max", 
                                       "svo2sat_min", "svo2sat_max", "pvo2_mean", "paco2_max")) #pvco2 does not exist

coda19_continuous_vitals <- coda19%>%select(c("sbp_max", "sbp_min", "dbp_min", "temp_max", "so2_min", "rr_mean",
                                          "fio2_max"))

coda19_continuous <- coda19_continuous_labs%>%cbind(coda19_continuous_vitals)
# coda19 <- coda19%>%select(-death)


# Modifying categorical variables
coda19_categorical <- coda19_categorical%>%select("female", "male", "chf", "rend", "score", "vasopressors", "glucocorticoids", "anti_bacterial_agents", "antifungal_agents",
                                                  "immunosuppressive_agents", "diuretics", "platelet_aggregation_inhibitors", "hypnotics_and_sedatives", 
                                                  "neuromuscular_blocking_agents", "hiv_medication", "mv", "death") #sedation on the update



# Simplifying the number of variables 
coda19_categorical2 <- coda19_categorical%>%
  mutate_if(is.factor, ~as.numeric(as.character(.)))

coda19_categorical2 <- coda19_categorical2%>% replace(. >= 1, 1) 

coda19_categorical2 <- coda19_categorical2%>%
  mutate_if(is.numeric, ~as.factor(.))

coda19_categorical2$score <- coda19_categorical$score

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

pca.coda19 <- PCA(coda19_continuous,
                  quali.sup = c(43,44),
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
                  quali.sup = c(17), # Removing death from observation but MV kept
                  graph = FALSE)


mca.coda19v2 <- MCA(coda19_categorical2,
                  quali.sup = c(17), # Removing death from observation but MV kept
                  graph = FALSE)

print(mca.coda19)

print(mca.coda19$eig)

print(mca.coda192$eig)
# Possible to view the variables as we did above
# For the sake of time, simply use explor! 

# Shiny Interactive Vizualization using exploR ------------------------------------------------------
library(explor)
# PCA exploration
explor(pca.coda19)
explor(pca.coda19_vitals)

# MCA exploration
explor(mca.coda19)

# Remember v2 is the simplified version of the categorical codification of the meds
explor(mca.coda192)




# Feature Engineering Based On Observations -------------------------------




# Clustering preview ------------------------------------------------------

# Remove college name before clustering

gower_dist <- daisy(college_clean[, -1],
                    metric = "gower",
                    type = list(logratio = 3))

# Check attributes to ensure the correct methods are being used
# (I = interval, N = nominal)
# Note that despite logratio being called, 
# the type remains coded as "I"

summary(gower_dist)
