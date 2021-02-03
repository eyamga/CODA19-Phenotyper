# Library load
source("./pkg/library_load.R")

# To execute this script simply change the corresponding dataframe at the end of the file : 24, 48 and 72h
# Loading raw dataset ---------------------------------------------------------------------
#
# ### Reading the CSV script
files_path <- list.files(path = "./data/processed/", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./data/processed/"), pattern =".csv", n=2))[[1]]
for (i in seq_along(files_path)){
  print(paste0('Currently reading ...', files_names[i]))
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <- read_csv(files_path[i])
  if ("X1"%in%colnames(tmp)){
    tmp <- tmp%>%select(-X1)
  }
  assign(files_names[i], tmp)
}


# EDA on raw dataset ---------------------------------------------------------------------

# First EDA script here
# remotes::install_github("XanderHorn/autoEDA")
#library(DataExplorer)
# library(skimr)
# library(explore)
# library(summarytools)
library(dataMaid)
# library(autoEDA)

# Quick Look
# skimmed <- skimr::skim(covid_24h)

# Simple EDA summary output as a df object
# summary <- summarytools::dfSummary(covid_24h)

# Vizual EDA options

# Complete Report of all variables from the dataset pre imputation
# Simple observation of the data, no hypothesis generation
dataMaid::makeDataReport(covid72h_notimputed,
                         render = FALSE,
                         replace = TRUE)  



# exploring missing data --------------------------------------------------

missing_med <- covid_24h%>%filter(is.na(acetaminophene))%>%select(patient_site_uid)
missing_labs <- covid_24h%>%filter(is.na(hemoglobin_min))%>%select(patient_site_uid)
missing_vs <- covid_24h%>%filter(is.na(sbp_max))%>%select(patient_site_uid)
missing_comorbidities <- covid_24h%>%filter(is.na(chf))%>%select(patient_site_uid)

old_missing_labs <- read_csv("old_missing_labs.csv")

comparing <- inner_join(old_missing_labs, missing_labs, by='patient_site_uid')

new_missing_labs <- missing_labs%>%filter(!patient_site_uid%in%comparing$patient_site_uid)
new_missing_labs <- new_missing_labs%>%left_join(covid_stay, by = 'patient_site_uid')
