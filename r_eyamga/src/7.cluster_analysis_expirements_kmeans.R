### In this iteration, we will use K Proto clustering


### - This iteration is similar as the first one BUT differs from by the removal of the different collinear variables
setwd("/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/r_eyamga")

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



# Loading Datasets --------------------------------------------------------

# Loading imputed dataset
coda19 <- read_csv("./data/imputed/covid24h_imputed.csv")


# # Removing colinear variables
# 
# # Method 1 blindly using means only
# coda19 <- coda19%>%select(-contains("min"))
# coda19 <- coda19%>%select(-contains("max"))
# 
# Method 2


# coda19 <- coda19%>%filter(wave==1)

coda19 <- coda19%>%mutate(
  neuromuscular_blocking_agents = ifelse(neuromuscular_blocking_agents_2 == 1, 1, neuromuscular_blocking_agents))
# coda19 <- coda19%>%mutate(
# antidepressive_agents = ifelse(serotonin_uptake_inhibitors == 1, 1, antidepressive_agents))

# # All candidates
# 
# coda19 <- coda19%>%select(c("patient_site_uid","patient_age", "hemoglobin_min", "plt_max", "wbc_mean", "neutrophil_mean", 
#                             "lymph_min", "mono_max", "baso_min", "eos_min", "sodium_mean", "potassium_mean", "creatinine_mean",
#                             "fio2_mean", "so2_min", "temp_mean", "sbp_mean", "dbp_mean", "rr_mean", "patient_age",
#                             "anti_bacterial_agents", "bicarbonate", "neuromuscular_blocking_agents", "anticoagulants", "factor_xa_inhibitors", "anticholesteremic_agents",
#                             "male", "bronchodilator_agents", "antihypertensive_agents", "antipsychotic_agents", "antidepressive_agents", "analgesics_opioid",
#                             "diuretics", "glucocorticoids", "hypoglycemic_agents", "platelet_aggregation_inhibitors", "sedation", "benzodiazepines", "vasopressors",
#                             'mv', "levelofcare", "wave", "icu", "death"))

coda19 <- coda19%>%select(c("patient_site_uid","patient_age", "hemoglobin_min", "plt_max", "wbc_mean", "neutrophil_mean", 
                            "lymph_min", "mono_max", "baso_min", "eos_min", "sodium_mean", "potassium_mean", "creatinine_mean",
                            "fio2_mean", "so2_min", "temp_mean", "sbp_mean", "dbp_mean", "rr_mean", "patient_age",
                            "factor_xa_inhibitors", "anticholesteremic_agents",
                            "male", "bronchodilator_agents", "antihypertensive_agents", "diuretics", "hypoglycemic_agents", 
                            "platelet_aggregation_inhibitors", "vasopressors",
                            'mv', "levelofcare", "wave", "icu", "death"))

# Separating categorical from numerical variables
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) >= 13)}, function(x){as.numeric(x)})




# Preparing the dataset for clustering  --------------------------------------------------------


# No data transformation for Kproto, handled by factoextraR

#Clustering algorithms --------------------------------------------------------

## Method one : using factoextra package and eclust method

# K-means clustering
# Main advantage of the eclust function, is that multiple clustering algorithms can be run
# # Can specify distance measure but only for continuous variables
# km.res <- eclust(coda19, "kmeans", k = 3, nstart = 25, stand=TRUE, graph = FALSE)
# 
# # Visualize k-means clusters
# fviz_cluster(km.res, geom = "point", ellipse.type = "norm",
#              palette = "jco", ggtheme = theme_minimal())


# #  Evaluating optimal Number of clusters - this plot will not work as the dataset is not standardized
# fviz_nbclust(coda19, FUNcluster = kmeans, method = "wss", stand=TRUE) 
# 
# ## Method 2 using the cluster package and the PAM algorithm


# Evaluation of optimal Lambda parameter ----------------------------------
library(clustMixType)
coda19_subset <- coda19%>%select(-c("patient_site_uid", "wave", "death", "levelofcare", "icu"))

Es <- numeric(10)
for(i in 1:10){
  kpres <- kproto(coda19_subset, k = i)
  Es[i] <- kpres$tot.withinss
}

Essil <- numeric(10)
for(i in 2:10){
  kpres <- kproto(coda19_subset, k = i)
  Essil[i] <- validation_kproto(method = "silhouette", object = kpres)
}

Esmcclain <- numeric(10)
for(i in 2:10){
  kpres <- kproto(coda19_subset, k = i)
  Esmcclain[i] <- validation_kproto(method = "mcclain", object = kpres)
}

plot(1:10, Es, type = "b", ylab = "Total Within Sum Of Squares", xlab = "Number of clusters")

plot(1:10, Essil, type = "b", ylab = "Silhouette", xlab = "Number of clusters")

plot(1:10, Esmcclain, type = "b", ylab = "McClain-Rao index", xlab = "Number of clusters")



# Final k value = 4
k=3
kpres <- kproto(coda19_subset, k = 3)



# Final clustering algorithm ----------------------------------------------

results <- coda19 %>%
  mutate(cluster = kpres$cluster) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

# Results - Variables per cluster
# This is also done later through EDA
#print(pam_results$the_summary)




# Plotting the results : TSNE  -------------------------------------

# 1 ) Plotting the clustering results on TSNE 
gower_distance <- cluster::daisy(coda19%>%select
                                 (-c("patient_site_uid", "wave", "death", "levelofcare", "icu")),  #keeping MV
                                 metric = "gower") #Removing all cat variables from clustering except MV
tsne_obj <- Rtsne(gower_distance, is_distance = TRUE, perplexity = 10)
tsne_data <- tsne_obj$Y %>%
  data.frame() %>%
  setNames(c("X", "Y")) %>%
  mutate(Clusters = factor(kpres$cluster))


p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
    geom_point(aes(color = Clusters))+
    ggtitle("3 K-PAM clustering") 
show(p)

dev.print(pdf, file="./output/clustering/finalclustering_TSNE.pdf")

fviz_cluster(kpres$data, geom = "point", ellipse.type = "norm")


# EDA of the clustering results -------------------------------------------

# Methods 2, Descriptive statistics
result <- coda19 %>%
  mutate(cluster = kpres$cluster) # dataframe with clusters added 
alllist <- names(result)
catlist <- names(result[sapply(result, is.factor)])

tableOne_compared <- tableone::CreateTableOne(vars = alllist, data = coda19, strata = "cluster", factorVars = catlist, test=TRUE, addOverall = TRUE)
pt <- print(tableOne_compared, missing = TRUE, quote = FALSE, noSpaces = FALSE)
write.csv(pt, file = "./output/clustering/clusters_stats_tableone.csv")



