# Set Working Directory
setwd("~/Documents/Médecine/Recherche/CODA19/code/r_eyamga")

# Library load
source("./library_load.R")
library(comorbidity)
library(DBI)
library(RSQLite)
library("rjson")
library("rjson")

#devtools::install_github("vcastro/CCS")
#install.packages("remotes")
#remotes::install_github("mpancia/RxNormR")

### Loading db and querying the info and saving as CSV files
coda19 <- DBI::dbConnect(RSQLite::SQLite(), "../py_eyamga/covidb_version-1.0.0.db")
files_path <- list.files(path = "./sql", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./sql"), pattern =".sql", n=2))[[1]]
dflist = list()
for (i in seq_along(files_path)){
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <-  dbGetQuery(coda19, statement = read_file(files_path[i]))
  assign(files_names[i], tmp)
  dflist[[i]] = tmp
  write.csv(x = dflist[i], file = paste0(files_names[i], ".csv"))
  }



# # ### Reading the CSV script
files_path <- list.files(path = "./csv", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./csv"), pattern =".csv", n=2))[[1]]
for (i in seq_along(files_path)){
  print(paste0('Currently reading ...', files_names[i]))
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <- read_csv(files_path[i])
  if ("X1"%in%colnames(tmp)){
    tmp <- tmp%>%select(-X1)
  }
  assign(files_names[i], tmp)
}

# Data wrangling --------------------------------------------------------



# Transforming narrow dataframe to wide - only 3 : comorbidities, dx and drugs

# 1) Comorbidities 0 option 1 using raw CCS

# Reformatting ICD10 to map
#covid_comorbidities$diagnosis_icd_code <- str_remove(covid_comorbidities$diagnosis_icd_code, pattern = "\\.")

# Reformatting the CCS csv files before mapping
#map <- CCS::CCS_DX_mapping%>%filter(vocabulary_id == 'ICD10CM')%>%select(c('category_code', 'code'))
#map2 <- CCS::CCSR_DX_mapping%>%filter(vocabulary_id == 'ICD10CM')%>%select(c('CCSR_category_code', 'code'))
#cat <- CCS::CCS_DX_categories%>%select(c('category_code', 'category_desc'))%>%rename("dx_group" = "category_desc")
#cat2 <- CCS::CCSR_DX_categories%>%select(c('CCSR_category_code', 'CCSR_category_desc'))%>%rename("dx_group" = "CCSR_category_desc")

# Matching the corresponding CCS category
#covid_comorbidities <- left_join(covid_comorbidities, map, by=c("diagnosis_icd_code"="code"))
#covid_comorbidities <- left_join(covid_comorbidities, map2, by=c("diagnosis_icd_code"="code"))
#covid_comorbidities <- left_join(covid_comorbidities, cat, by=c("category_code"="category_code"))
#covid_comorbidities <- left_join(covid_comorbidities, cat2, by=c("CCSR_category_code"="CCSR_category_code"))

# 1) Comorbidities using the Comorbidity package
covid_comorbidities <- comorbidity::comorbidity(x = covid_comorbidities, id = "patient_site_uid", code = "diagnosis_icd_code", score = "charlson", icd = "icd10", assign0 = TRUE)
covid_comorbidities <- covid_comorbidities%>%select(-c("index", "wscore", "windex"))

# 2 ) Drugs


# covid_demographics <- read_csv('./csv/covid_demographics.csv')%>%select(-X1)

# Function that cadds count of each dx in the
# The script was changed count=n() to simply get 1 
get_counts <-function(dataset){       
  summary <- dataset %>% group_by(patient_site_uid,drug_class) %>% dplyr::summarise(count=1)%>% arrange(desc(count))%>%ungroup(patient_site_uid) 
  return(summary)
}
# Reading the dictionary
drug_dict <- read_csv('./drug_class_dict.csv')%>%select(-X1)


# Formatting all the drugs data
drugs_list = list("covid_drugs24h" = covid_drugs24h, "covid_drugs48h" = covid_drugs48h, "covid_drugs72h" = covid_drugs72h)
j = 1
for (i in drugs_list){
  tmp <- i%>%left_join(drug_dict, by=c('drug_name'='drug_name'))%>%select(-c('drug_name', 'drug_start_time'))
  narrowtmp <- get_counts(tmp)
  widecovid <- narrowtmp%>%spread(drug_class, count, fill=0)%>%select(-"0")
  assign(names(drugs_list)[j], widecovid)
  j = j+1
}



# 4) Cleaning datasets before merge
covid_stay <- covid_stay%>%select(patient_site_uid)
covid_deaths <- covid_deaths%>%mutate(death=1)%>%select(-death_time)
covid_icustay <- covid_icustay%>%mutate(icu=1)%>%select(c(patient_site_uid, icu))

# Demographics 1-hot & keeping age in the dataset
covid_demographics <- covid_demographics%>%mutate(patient_sex = ifelse(as.character(patient_sex) == 'unspecified', 'female', as.character(patient_sex)))
covid_age <- covid_demographics%>%select(c(patient_site_uid, patient_age))
#1 hot encoding
covid_demographics <- reshape2::dcast(data = covid_demographics, patient_site_uid ~ patient_sex, length)
covid_demographics <- covid_demographics%>%left_join(covid_age, by = "patient_site_uid")

covid_comorbidities <- covid_comorbidities #already wide

covid_drugs24h <- covid_drugs24h #already wide
covid_labs24h <- covid_labs24h #already wide
covid_vitals24h <- covid_vitals24h #already wide

# Adding appropriate info on mechanical ventilation
covid_mv24h <- covid_mv24h%>%mutate(mv=1)%>%select(c(patient_site_uid, mv))
covid_mv48h <- covid_mv48h%>%mutate(mv=1)%>%select(c(patient_site_uid, mv))
covid_mv72h <- covid_mv72h%>%mutate(mv=1)%>%select(c(patient_site_uid, mv))


## 5) Merging on covid_stay as the base ---------
# covid_24h <- plyr::join_all(tablelist, by='patient_site_uid', type='left') same script using plyr


tablelist_24h = list(covid_stay, covid_demographics, covid_deaths, covid_comorbidities, covid_drugs24h, covid_labs24h, covid_vitals24h, covid_mv24h, covid_icustay)
covid_24h <- tablelist_24h %>% purrr::reduce(left_join, by = "patient_site_uid", all.x=TRUE)

tablelist_48h = list(covid_stay, covid_demographics, covid_deaths, covid_comorbidities, covid_drugs48h, covid_labs48h, covid_vitals48h, covid_mv48h, covid_icustay)
covid_48h <- tablelist_48h %>% purrr::reduce(left_join, by = "patient_site_uid", all.x=TRUE)

tablelist_72h = list(covid_stay, covid_demographics, covid_deaths, covid_comorbidities, covid_drugs72h, covid_labs72h, covid_vitals72h, covid_mv72h, covid_icustay)
covid_72h <- tablelist_72h %>% purrr::reduce(left_join, by = "patient_site_uid", all.x=TRUE)

# Optimizing Dataset (Imputing Missing Data and Standardization) ----------


# Replacing NULL values by actual real values we know
covid_24h <- covid_24h%>%select(-c(`<NA>`, 'NA'))
covid_24h$death <- replace_na(covid_24h$death, 0) 
covid_24h$mv <- replace_na(covid_24h$mv, 0) 
covid_24h$icu <- replace_na(covid_24h$icu, 0) 

covid_48h <- covid_24h%>%select(-c(`<NA>`, 'NA'))
covid_48h$death <- replace_na(covid_48h$death, 0) 
covid_48h$mv<- replace_na(covid_48h$mv, 0) 
covid_48h$icu <- replace_na(covid_48h$icu, 0) 

covid_72h <- covid_72h%>%select(-c(`<NA>`, 'NA'))
covid_72h$death <- replace_na(covid_72h$death, 0) 
covid_72h$mv<- replace_na(covid_72h$mv, 0) 
covid_72h$icu <- replace_na(covid_72h$icu, 0) 

# Saving the non-imputed data
write_csv(covid_24h, file='covid24h_notimputed.csv')
write_csv(covid_48h, file='covid48h_notimputed.csv')
write_csv(covid_72h, file='covid72h_notimputed.csv')

# Creating another subset of data with ICU patients only
covid_72h <- read_csv("./data/notimputed/covid72h_notimputed.csv")
covid_72h_icu <- covid_72h%>%inner_join(covid_icustay, by = 'patient_site_uid')
covid_72h_icu <- covid_72h_icu%>%distinct(patient_site_uid, .keep_all = TRUE)

# Dropping columns with more than 35% missing values
covid_72h_icu1 <- covid_72h_icu %>% 
  purrr::discard(~sum(is.na(.x))/length(.x)*100 >=35)
# Dropping observations with more than 35% missing variables
covid_72h_icu2 <- covid_72h_icu1 %>% filter(rowSums(is.na(.)) < ncol(.)*0.35)
# Cleaning name
covid_72h_icu2 <- janitor::clean_names(covid_72h_icu2)  
covid_72h_icu3 <- covid_72h_icu2%>%select(-c('hospit_start_time', 'hospit_end_time', 'episode_start_time', 'episode_end_time', 'episode_unit_type', 'icu', 'patient_site_uid'))

# Imputing this dataset
# Getting predictorMatrix and modifying it to exclude 2 variables from the imputation set 
matrix_icu72h <- mice::mice(covid_72h_icu3, method = "cart", m=1, maxit = 0)
pred_matrixicu72h <- matrix_icu72h$predictorMatrix
pred_matrixicu72h[,'death'] <- 0

# Imputing
covidimputer <- mice::mice(covid_72h_icu3, pred = pred_matrixicu72h, method = "cart", m=1)
covidicu72h_imputed <- complete(covidimputer, 1)

# Saving the file

write_csv(covidicu72h_imputed, file='covidicu72h_imputed.csv')

# NB no vitals signs in the covidicu dataset
covidicu72h_imputed <- covidicu72h_imputed%>%select(c("patient_age", "hemoglobin_min", "plt_max", "wbc_max", "neutrophil_max", 
                                            "lymph_min", "mono_max", "eos_min", "sodium_min", "chloride_min", "albumin_min", "bicarbonate_min",
                                            "bun_max", "glucose_max", "anion_gap_mean", "ptt_max", "alt_max", "ast_max", "bili_tot_max", "tropot_max",
                                            "lipase_max", "ck_max", "weight_mean", "fio2_max","lactate_max", "svo2sat_min", "temp_max",
                                            "female", "male", "vasopressors", "glucocorticoids", "anti_bacterial_agents", "antifungal_agents",
                                            "immunosuppressive_agents", "diuretics", "platelet_aggregation_inhibitors", "sedation",
                                            "neuromuscular_blocking_agents", "bronchodilator_agents", "hiv_medication", "mv", "death"))

write_csv(covidicu72h_imputed, file='covidicu72h_imputed_filtered.csv')



# EDA ---------------------------------------------------------------------


# First EDA script here
remotes::install_github("XanderHorn/autoEDA")
library(DataExplorer)
library(skimr)
library(explore)
library(summarytools)
library(dataMaid)
library(autoEDA)

# Quick Look
skimmed <- skimr::skim(covid_24h)

# Simple EDA summary output as a df object
# summary <- summarytools::dfSummary(covid_24h)


# Vizual EDA options

# Complete Report of all variables from the dataset pre imputation
# Simple observation of the data, no hypothesis generation
dataMaid::makeDataReport(covid_72h,
                         render = FALSE,
                         file = 'coda19CHUMnotimputed_72h.rmd',
                         replace = TRUE)  


# Complete Report in HTML
# DataExplorer::create_report(covid_72h)




# Dropping columns with more than 35% missing values
covid_72h2 <- covid_72h %>% 
  purrr::discard(~sum(is.na(.x))/length(.x)*100 >=35)
# Dropping observations with more than 35% missing variables
covid_72h2 <- covid_72h2 %>% filter(rowSums(is.na(.)) < ncol(.)*0.35)
# Cleaning name
covid_72h2 <- janitor::clean_names(covid_72h2)  

# Getting predictorMatrix and modifying it to exclude 2 variables from the imputation set 
matrix_72h <- mice::mice(covid_72h2, method = "cart", m=1, maxit = 0)
pred_matrix72h <- matrix_72h$predictorMatrix
pred_matrix72h[,'patient_site_uid'] <- 0
pred_matrix72h[,'death'] <- 0

# Imputing
covidimputer <- mice::mice(covid_72h2, pred = pred_matrix72h, method = "cart", m=1)
covid72h_imputed <- complete(covidimputer, 1)

# Saving the file
write_csv(covid72h_imputed, file='covid72h_imputed.csv')

# EDA report from imputed data
dataMaid::makeDataReport(covid72h_imputed,
                         render = FALSE,
                         file = 'coda19CHUM72h_imputed.rmd',
                         replace = TRUE)  

# Correlation EDA part 1 = plots, part2 = summary stat
library(autoEDA)
library(cowplot)
library(svglite)
autoEDA_results <- autoEDA(covid72h_imputed, y = "death", returnPlotList = TRUE,
                           outcomeType = "automatic", removeConstant = TRUE, removeZeroSpread = TRUE, 
                           removeMajorityMissing = TRUE, imputeMissing = FALSE, clipOutliers = FALSE, 
                           minLevelPercentage = 0.025, predictivePower = TRUE, 
                           outlierMethod = "tukey", lowPercentile = 0.01, upPercentile = 0.99, 
                           plotCategorical = "groupedBar", plotContinuous = "histogram", bins = 30, #groupedBar
                           rotateLabels = TRUE, color = "#26A69A", verbose = TRUE) 

options(repr.plot.width = 20, repr.plot.height = 65)
p <- plot_grid(plotlist = autoEDA_results$plots, ncol = 3)
ggsave2("grid.svg", plot =p, width=20,height=84, limitsize = FALSE)

# Alternative output of the plots using the slickR package, outputting the results as an html widget
# library(htmlwidgets)
# library(slickR)
# plotsToSVG <- list()
# i <- 1
# for (v in autoEDA_results$plots) {
#   x <- xmlSVG({show(v)}, standalone=TRUE)
#   plotsToSVG[[i]] <- x
#   i <- i +1
# }
# hash_encode_url <- function(url){
#   gsub("#", "%23", url)
# }
# ## Pass list of figures to SlickR
# s.in <- sapply(plotsToSVG, function(sv){hash_encode_url(paste0("data:image/svg+xml;utf8,",as.character(sv)))})
# slickR::slickR(s.in, slideId = 'ex4', width = '70%')

# Summary statistics from correlation EDA
library(knitr)
library(kableExtra)

## Preview data
t <- kable(t(autoEDA_results$overview), colnames=NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover"))

library(ExPanDaR)
library(explore)
## Add mock time column
covid24h_imputed1$ts <- rep(1, nrow(covid24h_imputed1))

# NB ExPanDaR necessitates a row for timeseries, in our cas, ts = 1 because only looking at one point in time.
ExPanD(df = covid24h_imputed1, cs_id = "patient_site_uid", ts_id = "ts")
explore::explore_shiny(covid24h_imputed1) 


# ## Dropping final missing variables
# # Dropping if more than 25% missing variables post imputation
# covid24h_imputed1 <- covid24h_imputed1 %>% 
#   purrr::discard(~sum(is.na(.x))/length(.x)*100 >=25)
# 
# # Final check
# skimmed <- skimr::skim(covid24h_imputed1)
# 
# # Final output pre clustering
# covid24h_imputed1 <- covid24h_imputed1%>%select(-ts)
# write_csv(covid24h_imputed1, file='covid24h_precluster.csv')


