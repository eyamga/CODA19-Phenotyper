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


coda19 <- coda19%>%filter(wave==1)

coda19 <- coda19%>%mutate(
  neuromuscular_blocking_agents = ifelse(neuromuscular_blocking_agents_2 == 1, 1, neuromuscular_blocking_agents))
# coda19 <- coda19%>%mutate(
#   # antidepressive_agents = ifelse(serotonin_uptake_inhibitors == 1, 1, antidepressive_agents))
coda19 <- coda19%>%select(c("patient_site_uid","patient_age", "hemoglobin_min", "plt_max", "wbc_mean", "neutrophil_mean", 
                            "lymph_min", "mono_max", "baso_min", "eos_min", "sodium_mean", "potassium_mean", "creatinine_mean",
                            "fio2_mean", "so2_min", "temp_mean", "sbp_mean", "dbp_mean", "rr_mean", "patient_age",
                            "anti_bacterial_agents", "bicarbonate", "neuromuscular_blocking_agents", "anticoagulants", "factor_xa_inhibitors", "anticholesteremic_agents",
                            "male", "bronchodilator_agents", "antihypertensive_agents", "antipsychotic_agents", "antidepressive_agents", "analgesics_opioid",
                            "diuretics", "glucocorticoids", "hypoglycemic_agents", "platelet_aggregation_inhibitors", "sedation", "benzodiazepines", "vasopressors",
                            'mv', "levelofcare", "wave", "icu", "death"))


# Separating categorical from numerical variables
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) >= 13)}, function(x){as.numeric(x)})


# Observing the data quickly FAMD ------------------------------------------
# 
# coltypes <- str(coda19)
# sapply(coda19, class) #alternatively typeof
# 
# 
# # FAMD analysis - pre clustering, simply looking at variance of the mixed dataset
# res.coda19 <- FAMD(coda19, 
#                    sup.var = c(40:42), #DEATH is not included for now 
#                    graph = FALSE, 
#                    ncp=25)
# 
# 
# ## Inspect principal components
# kable(get_eigenvalue(res.coda19))%>%
#   kableExtra::kable_styling(bootstrap_options = c("striped", "hover"))
# 
# fviz_famd_ind(res.coda19, 
#               col.ind = "#2eb135", 
#               label = "none", 
#               repel = TRUE) + 
#   xlim(-5, 5) + ylim (-4.5, 4.5)
# 
# # get_famd_ind(res.coda19)
# 


# Preparing the dataset for clustering  --------------------------------------------------------

# Compute Gower Distances
# gower_distance <- cluster::daisy(coda19, metric = "gower")
gower_distance <- cluster::daisy(coda19%>%select
                                  (-c("patient_site_uid","levelofcare", "wave", "icu", "death")), 
                                  metric = "gower") #Removing all cat variables from clustering except MV

gower_mat <- as.matrix(gower_distance)

# Print most similar patients
# demo <- coda19[which(gower_mat == min(gower_mat[gower_mat != min(gower_mat)]), arr.ind = TRUE)[1, ], ]
# # Print most dissimilar clients
# demo2 <- coda19[which(gower_mat == max(gower_mat[gower_mat != max(gower_mat)]), arr.ind = TRUE)[1, ], ]


# NB this step is only needed for PAM algorithm as the euclidean distance is directly computed in the K means method

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




# Evaluation of optimal K -------------------------------------------------

# Visualization method

# 1) Different TSNE visuals according to K 
# Trying different values of k from 2 to 8
tsne_obj <- Rtsne(gower_distance, is_distance = TRUE)
plotslist = list()
for(i in 2:8){  
  pam_fit <- pam(gower_distance, diss = TRUE, k = i)  
  pam_results <- coda19 %>%
    mutate(cluster = pam_fit$clustering) %>%
    group_by(cluster) %>%
    do(the_summary = summary(.))
  tsne_data <- tsne_obj$Y %>%
    data.frame() %>%
    setNames(c("X", "Y")) %>%
    mutate(cluster = factor(pam_fit$clustering))
  p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
    geom_point(aes(color = cluster))+
    ggtitle(paste0(as.character(i), " K-means clustering"))
  plotslist[[i]] <- p
}

options(repr.plot.width = 20, repr.plot.height = 20)
p <- plot_grid(plotlist = plotslist, ncol = 3)
ggsave2("./output/clustering/pamcluster_tsneformultipleK.svg", plot =p, width=20,height=20, limitsize = FALSE)


# 2) Silhouette  analysis

# 3 methods of validation of clustering 1) Elbow 2) Silhouette 3) Statistical i.e. gap statistic
# Determines how well each object lies within its cluster. 
# Measures how well an observation is clustered and it estimates the average distance between clusters
# A high average silhouette width indicates a good clustering.
# Negative value means that the the observation is place in the wrong cluster.  


# Silhouette analysis for values of K between 2 and 10
set.seed(123)
sil_width <- c(NA)
for(i in 2:10){
  pam_fit <- pam(gower_distance,
                 diss = TRUE,
                 k = i)
  sil_width[i] <- pam_fit$silinfo$avg.width
  
}

sil <-tibble(axis = seq(1:10), silhouette = sil_width)
ggplot(data=sil, aes(x=axis, y=silhouette, color = "black")) +
  geom_line() + geom_point()+
  labs(title="Silhouette Analysis",x="Number of Clusters", y = "Average Silhouette Width")+
  theme_minimal() +
  scale_color_brewer(palette="Set2", guide = "none") + 
  scale_x_continuous(limits=c(2, 10), breaks=seq(2:11))
  
dev.print(pdf, file="./output/clustering/silhouette_analysis.pdf")



# 3) Silhouette plot
pam_fit <- pam(gower_distance, diss = TRUE, k = 2)  
fviz_silhouette(pam_fit, palette = "jco", ggtheme = theme_minimal())#%>%
  #scale_y_continuous(limits=c(-0.5, 0.5), breaks=c(-0.5,0, 0.25,0.50))
  
dev.print(pdf, file="./output/clustering/silhouette_plot.pdf")
# 
# # Silhouette details bad observations
# silinfo <- pam_fit$silinfo
# 
# # Average cluster silinfo$clus.avg.widths
# head(pam_fit$silinfo$widths)
# 
# # Seeing bad observations
# sil <- pam_fit$silinfo$widths
# neg_sil_index <- which(sil[, 'sil_width'] < 0)
# sil[neg_sil_index, , drop = FALSE] 



# Final clustering algorithm ----------------------------------------------

# Final k value = 2
k=2
pam_fit <- pam(gower_distance, diss = TRUE, k)
pam_results <- coda19 %>%
  mutate(cluster = pam_fit$clustering) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

# Results - Variables per cluster
# This is also done later through EDA
#print(pam_results$the_summary)




# Plotting the results : TSNE  -------------------------------------

# 1 ) Plotting the clustering results on TSNE 

tsne_obj <- Rtsne(coda19_gower, is_distance = TRUE)
tsne_data <- tsne_obj$Y %>%
  data.frame() %>%
  setNames(c("X", "Y")) %>%
  mutate(Clusters = factor(pam_fit$clustering))


p <- ggplot(aes(x = X, y = Y,), data = tsne_data) +
    geom_point(aes(color = Clusters))+
    ggtitle("3 K-PAM clustering") 
show(p)

dev.print(pdf, file="./output/clustering/finalclustering_TSNE.pdf")

# Plotting the results : PCA  -------------------------------------

# 2) Plotting the clustering results on PCA
# Difficult to interpret as data not scaled in this iteration and categorical data
pam_fit$data <- coda19
fviz_cluster(pam_fit, geom = "point", ellipse.type = "norm")

# Plotting the results on FAMD 
library(FactoMineR, quietly=T)
library(factoextra, quietly=T)
library(plotly, quietly=T)

### Plot relationship between levels of categorical variables obtained from MCA
# Transforming categorical variables appropriately

# Must return indices
# https://nextjournal.com/pc-methods/hierarchical-clustering-pcs
# https://cran.r-project.org/web/packages/invctr/vignettes/insiders.html
#coda19 <- coda19%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})


# Plotting the results : FAMD -------------------------------------

# By using FAMD plot above , trying reinjecting clusters results and color by cluster  # OR applying the FAMD algorithm on the clustered dataset with cluster variables already present
coda19$cluster <- pam_fit$clustering


# Plotting on FAMD 
# res.coda19.cluster <- FAMD(coda19, 
#                    sup.var = c(41:44), #Clusters, ICU, Death and Wave
#                    graph = FALSE, 
#                    ncp=25)
# 
# fviz_famd_ind(res.coda19.cluster, 
#               habillage = coda19$cluster, 
#               label = "none", 
#               repel = TRUE) + 
#   xlim(-5, 5) + ylim (-4.5, 4.5)



# EDA of the clustering results -------------------------------------------

# Method 1, Looking at medoids
medoids <- coda19[pam_fit$medoids, ]
write.csv(medoids, file = "./output/clustering/clusters_medoids.csv")


# Methods 2, Descriptive statistics
result <- coda19 # dataframe with clusters added 
alllist <- names(result)
catlist <- names(result[sapply(result, is.factor)])

tableOne_compared <- tableone::CreateTableOne(vars = alllist, data = coda19, strata = "cluster", factorVars = catlist, test=TRUE, addOverall = TRUE)
pt <- print(tableOne_compared, missing = TRUE, quote = FALSE, noSpaces = FALSE)
write.csv(pt, file = "./output/clustering/clusters_stats_tableone.csv")

# tableone::kableone(tableOne_compared)%>%
#   kable_classic(full_width = F, html_font = "Computer Modern")%>%
# 
# 
# Adding clusters back to the original dataset
# coda19$cluster <- pam_fit$clustering


# Looking at trends for different clusters
# library(autoEDA)  
# autoEDA_results <- autoEDA(coda19, 
#                            y = "cluster", returnPlotList = TRUE,
#                            outcomeType = "automatic", removeConstant = TRUE, 
#                            removeZeroSpread = TRUE, removeMajorityMissing = TRUE, 
#                            imputeMissing = TRUE, clipOutliers = FALSE, 
#                            minLevelPercentage = 0.025, predictivePower = TRUE, 
#                            outlierMethod = "tukey", lowPercentile = 0.01, 
#                            upPercentile = 0.99, plotCategorical = "groupedBar", 
#                            plotContinuous = "histogram", bins = 30, 
#                            rotateLabels = TRUE, color = "#26A69A", 
#                            verbose = FALSE) 
# 
# ## Plot figures in a grid
# p <- plot_grid(plotlist = autoEDA_results$plots, ncol = 3)
# show(p)
# ggsave("cluster_analysis.svg", width=20,height=84, limitsize = FALSE)
# 
# 
# ##  Most important features for our k Clustering
# res <- autoEDA_results$overview[autoEDA_results$overview$PredictivePower %in% c("High", "Medium"),]
# res[, c('Feature', 'PredictivePowerPercentage', 'PredictivePower')]





## Exploring TSNE Data
# tsne_data %>%
#   filter(X > 15 & X < 25,
#          Y > -15 & Y < -10) %>%
#   left_join(college_clean, by = "name") %>%
#   collect %>%
#   .[["name"]]


# # Not Done Hierarchical Clustering -------------------------------------------------
# 
# #  Alternative to compute silhouette for different k values, but does not work for mixed data type
# # fviz_nbclust(coda19_complete, cluster::pam, method = "silhouette") + theme_classic()
# 
# res.hc <- hclust(d = coda19_gower, method = "ward.D2") #Step Two - Linkage (Ward minimizes Within Cluster Variance)
# 
# fviz_dend(res.hc, cex = 0.6, k = 3, rect = TRUE)
# fviz_dend(res.hc, cex = 0.6, k = 4, type = "circular", rect = TRUE)
# 
# 
# # Validation of the algorithm
# # If cophrenetic Distance preserves pairwise distances between original and unmodeled data
# # Acceptable if > 0.75
# res.coph <- cophenetic(res.hc)
# cor(coda19_gower, res.coph)
# 
# 


