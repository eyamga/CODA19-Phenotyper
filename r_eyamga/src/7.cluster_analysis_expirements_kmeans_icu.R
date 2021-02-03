### In this iteration, we will use K Mesan clustering using continuous data only


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
coda19 <- read_csv("./data/icudata/imputed/covidicu24h_imputed.csv")


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
                            "fio2_mean", "so2_min", "temp_mean", "sbp_mean", "dbp_mean", "rr_mean",'mv', 
                            "levelofcare", "wave", "icu", "death"))

# Separating categorical from numerical variables
# And scaling the data
coda19pid <- coda19%>%select(patient_site_uid)
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 15)}, 
                             function(x){as.factor(x)})
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) >= 15)}, 
                             function(x){scale(as.numeric(x))})
coda19$mv <- scale(as.numeric(coda19$mv))
coda19$baso_min <- scale(as.numeric(coda19$baso_min))
coda19$patient_site_uid <- coda19pid



# Keeping original dataframe for post clustering analysis
coda19_original <- read_csv("./data/imputed/covid24h_imputed.csv")
coda19_original <- coda19_original%>%mutate_if(function(x){(length(unique(x)) <= 15)}, 
                             function(x){as.factor(x)})
coda19_original <- coda19_original%>%mutate_if(function(x){(length(unique(x)) >= 15)}, 
                             function(x){as.numeric(x)})
coda19_original <- coda19_original%>%select(c("patient_site_uid","patient_age", "hemoglobin_min", "plt_max", "wbc_mean", "neutrophil_mean", 
                            "lymph_min", "mono_max", "baso_min", "eos_min", "sodium_mean", "potassium_mean", "creatinine_mean",
                            "fio2_mean", "so2_min", "temp_mean", "sbp_mean", "dbp_mean", "rr_mean",'mv', 
                            "levelofcare", "wave", "icu", "death"))
# Preparing the dataset for clustering  --------------------------------------------------------


# No data transformation for Kproto, handled by factoextraR

#Clustering algorithms --------------------------------------------------------

## Method one : using factoextra package and eclust method

# K-means clustering
# Main advantage of the eclust function, is that multiple clustering algorithms can be run
# Can specify distance measure but only for continuous variables




# Evaluation of optimal K numberr ----------------------------------


#  Evaluating optimal Number of clusters - this plot will not work as the dataset is not standardized
fviz_nbclust(coda19%>%select(-c("patient_site_uid","levelofcare", "wave", "icu", "death")), kmeans, palette = "jco", method = "silhouette")

dev.print(pdf, file="./output/clustering/silhouetteKMeans.pdf")

# Using Gap Statistic
# fviz_nbclust(coda19%>%select(-c("patient_site_uid","levelofcare", "wave", "icu", "death")), kmeans, palette = "jco", nstart = 25, method = "gap_stat", nboot = 500) + 
#   labs(subtitle = "Gap Statistic Method") #nboot is # of bootstrap sample - must be included
#   


# Final clustering algorithm ----------------------------------------------

km.res <- eclust(coda19%>%select(-c("patient_site_uid","levelofcare", "wave", "icu", "death")), "kmeans", k = 2, nstart = 25, stand=TRUE, graph = FALSE)


# Visualize k-means clusters
fviz_cluster(km.res, geom = "point", ellipse.type = "norm",
             palette = "jco", ggtheme = theme_minimal())


dev.print(pdf, file="./output/clustering/clusteringKMeans.pdf")

results <- coda19 %>%
  mutate(cluster = km.res$cluster) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

# Results - Variables per cluster
# This is also done later through EDA
#print(pam_results$the_summary)




# Plotting the results : TSNE  -------------------------------------

# 1 ) Plotting the clustering results on TSNE 
gower_distance <- cluster::daisy(coda19_original%>%select
                                 (-c("patient_site_uid", "wave", "death", "levelofcare", "icu")),  #keeping MV
                                 metric = "gower") #Removing all cat variables from clustering except MV
tsne_obj <- Rtsne(gower_distance, is_distance = TRUE, perplexity = 10)
tsne_data <- tsne_obj$Y %>%
  data.frame() %>%
  setNames(c("X", "Y")) %>%
  mutate(Clusters = factor(km.res$cluster))


p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
    geom_point(aes(color = Clusters))+
    ggtitle("3 K-PAM clustering") 
show(p)

dev.print(pdf, file="./output/clustering/finalKMEANSclustering_TSNE.pdf")


# EDA of the clustering results -------------------------------------------

# Methods 2, Descriptive statistics
result <- coda19_original %>%
  mutate(cluster = km.res$cluster) # dataframe with clusters added 
alllist <- names(result)
catlist <- names(result[sapply(result, is.factor)])

tableOne_compared <- tableone::CreateTableOne(vars = alllist, data = result, strata = "cluster", factorVars = catlist, test=TRUE, addOverall = TRUE)
pt <- print(tableOne_compared, missing = TRUE, quote = FALSE, noSpaces = FALSE)
write.csv(pt, file = "./output/clustering/clusters_stats_tableone.csv")



