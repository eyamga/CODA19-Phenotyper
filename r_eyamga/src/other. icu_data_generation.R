## This file contains all the step for ICU data generation

# NB this script will run only if the icu_episodes view is well inserted in the database

# Library load
source("./pkg/library_load.R")


# Reading SQL script  ------------------------------------------------------------

# SQLPATH = '../../../../../output/covidb_full/sqlite/covidb_version-1.0.0.db'
SQLPATH = '../../../data/covidb_version-2.0.0new.db'
coda19 <- DBI::dbConnect(RSQLite::SQLite(), SQLPATH)
files_path <- list.files(path = "./sql_icu", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./sql_icu"), pattern =".sql", n=2))[[1]]
dflist = list()
for (i in seq_along(files_path)){
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <-  dbGetQuery(coda19, statement = read_file(files_path[i]))
  assign(files_names[i], tmp)
  dflist[[i]] = tmp
  write.csv(x = dflist[i], file = paste0("./data/icudata/raw/", files_names[i], ".csv"))
}


# #### Reading the CSV script ------------------
# files_path <- list.files(path = "./data/icudata/raw/", full.names=TRUE)
# files_names <- as_tibble(str_split_fixed(list.files(path = "./data/icudata/raw/"), pattern =".csv", n=2))[[1]]
# for (i in seq_along(files_path)){
#   print(paste0('Currently reading ...', files_names[i]))
#   #dbGetQuery(coda19, statement = read_file(files_path[i]))
#   tmp <- read_csv(files_path[i])
#   if ("X1"%in%colnames(tmp)){
#     tmp <- tmp%>%select(-X1)
#   }
#   assign(files_names[i], tmp)
# }


# Data wrangling --------------------------------------------------------

# Transforming narrow dataframe to wide - only 3 : comorbidities, dx and drugs


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
drug_dict <- read_csv('./pkg/drug_class_dict.csv')%>%select(-X1)


# Formatting all the drugs data
drugs_list = list("covid_drugs24h" = covid_drugs24h) # other time frames were not included in this task
j = 1
for (i in drugs_list){
  tmp <- i%>%left_join(drug_dict, by=c('drug_name'='drug_name'))%>%select(-c('drug_name', 'drug_start_time'))
  narrowtmp <- get_counts(tmp)
  widecovid <- narrowtmp%>%spread(drug_class, count, fill=0)%>%select(-"0")
  assign(names(drugs_list)[j], widecovid)
  j = j+1
}


# 3) Dx not worth widening - data of poor quality

# 4) Cleaning datasets before merge

# adding wave info 0 = first wave 1= second wave
covid_icustay <- covid_icustay%>%select(patient_site_uid, episode_start_time)
covid_icustay <- covid_icustay%>%mutate(
  wave = ifelse(lubridate::date(episode_start_time) < lubridate::date("2020-08-01"), 0, 1))%>%
  distinct(patient_site_uid, .keep_all = TRUE)%>%
  select(c("patient_site_uid", "wave"))

covid_deaths <- covid_deaths%>%mutate(death=1)%>%select(-death_time)

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

### Generating final COVID database at 24, 48 and 72h---------
# covid_24h <- plyr::join_all(tablelist, by='patient_site_uid', type='left') same script using plyr

tablelist_24h = list(covid_icustay, covid_demographics, covid_deaths, covid_comorbidities, covid_drugs24h, covid_labs24h, covid_vitals24h, covid_mv24h)
covid_24h.icu <- tablelist_24h %>% purrr::reduce(left_join, by = "patient_site_uid", all.x=TRUE)


# Replacing NULL values by actual real values we know
covid_24h.icu <- covid_24h.icu%>%select(-c(`<NA>`, 'NA'))
covid_24h.icu$death <- replace_na(covid_24h.icu$death, 0) 
covid_24h.icu$mv <- replace_na(covid_24h.icu$mv, 0) 
covid_24h.icu <- janitor::clean_names(covid_24h.icu)
covid_24h.icu <- covid_24h.icu[!duplicated(covid_24h.icu), ]

# Saving the non-imputed data
write_csv(covid_24h.icu, file='./data/icudata/processed/covid24h_notimputed.csv')



# ICU data EDA ---------------------------------------------------------------------

dataMaid::makeDataReport(covid_24h.icu,
                         render = FALSE,
                         replace = TRUE)  


#  Outliers correction and imputation -------------------------------------

# Loading not imputed data
# covid_24h.icu <- read_csv("./data/icudata/processed/covid24h_notimputed.csv")

tmp <- covid_24h.icu

# Outliers removal (removing n = 2)
# Age 
tmp <- tmp%>%filter(patient_age < 120 & patient_age > 18)
# Creatinine - All extremes seemed appropriate, no values changed
# FiO2
# Different correction for patients on MV
tmp <- tmp%>%mutate(
  fio2_min=
    case_when(
      is.na(fio2_min) ~ 21,
      TRUE ~ fio2_min),
  fio2_max=
    case_when(
      is.na(fio2_max) ~ 100,
      fio2_max >= 100 ~ 100,
      TRUE ~ fio2_max),
  fio2_mean=
    case_when(
      is.na(fio2_mean)  ~ 50,
      fio2_mean >= 100 ~ 100,
      TRUE ~ fio2_mean))
# SO2
tmp <- tmp%>%mutate(
  so2_min=
    case_when(
      so2_min < 40 ~ 60,
      TRUE ~ fio2_min),
  so2_max=
    case_when(
      so2_min >= 100 ~ 100,
      TRUE ~ fio2_max),
  so2_mean=
    case_when(
      is.na(fio2_mean) ~ 25,
      fio2_mean >= 100 ~ 100,
      TRUE ~ fio2_mean))
# WBC
tmp <- tmp%>%mutate(
  wbc_max=
    case_when(
      wbc_max > 100 ~ 50,
      TRUE ~ rr_min),
  wbc_mean=
    case_when(
      wbc_mean >= 50 ~ 40,
      TRUE ~ rr_max))
# Aniong gap
tmp <- tmp%>%mutate(
  anion_gap_calc =
    sodium_mean - chloride_mean - bicarbonate_mean
)

covid_24h.icu <- tmp



# Selecting candidata variables and observations  -------------------------------------------------------------

# NB : No duplicate PIDs in this cohort (latest admission 28/01/2021) might falsify death recording. 

# Dropping columns with more than 25% missing values
covid_24h.icu <- covid_24h.icu %>% 
  purrr::discard(~sum(is.na(.x))/length(.x)*100 >=25)

# Dropping observations with more than 25% missing variables
covid_24h.icu <- covid_24h.icu %>% filter(rowSums(is.na(.)) < ncol(.)*0.25)

# 165 to 147 observations and 264 to 159 variables

# Cleaning name

# Imputing this dataset
# Getting predictorMatrix and modifying it to exclude 2 variables from the imputation set 
matrix_icu24h <- mice::mice(covid_24h.icu, method = "cart", m=1, maxit = 0)
pred_matrixicu24h <- matrix_icu24h$predictorMatrix
pred_matrixicu24h[,'death'] <- 0

# Imputing
covidimputer <- mice::mice(covid_24h.icu, pred = pred_matrixicu24h, method = "cart", m=1)
covid_24h.icu_imputed <- complete(covidimputer, 1)

# Saving the file

write_csv(covid_24h.icu_imputed, file='./data/icudata/imputed/covidicu24h_imputed.csv')

# NB no vitals signs in the covidicu dataset
# covidicu72h_imputed <- covidicu72h_imputed%>%select(c("patient_age", "hemoglobin_min", "plt_max", "wbc_max", "neutrophil_max", 
#                                                       "lymph_min", "mono_max", "eos_min", "sodium_min", "chloride_min", "albumin_min", "bicarbonate_min",
#                                                       "bun_max", "glucose_max", "anion_gap_mean", "ptt_max", "alt_max", "ast_max", "bili_tot_max", "tropot_max",
#                                                       "lipase_max", "ck_max", "weight_mean", "fio2_max","lactate_max", "svo2sat_min", "temp_max",
#                                                       "female", "male", "vasopressors", "glucocorticoids", "anti_bacterial_agents", "antifungal_agents",
#                                                       "immunosuppressive_agents", "diuretics", "platelet_aggregation_inhibitors", "sedation",
#                                                       "neuromuscular_blocking_agents", "bronchodilator_agents", "hiv_medication", "mv", "death"))

# write_csv(covidicu72h_imputed, file='covidicu72h_imputed_filtered.csv')