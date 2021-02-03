# Library load
source("./pkg/library_load.R")

# This script transforms the raw dataset into an imputed set
# Must manually modify to generate appropriate hour time frame

# Loading raw dataset ---------------------------------------------------------------------
#
# ### Reading episodes data
stay <- read_csv('./data/raw/covid_stay.csv')%>%select(-X1)
# cut-off second wave as 08-2020
#first wave = 0, second wave = 1
stay <- stay%>%mutate(
  wave = ifelse(lubridate::date(episode_start_time) < lubridate::date("2020-08-01"), 0, 1)
  )%>%distinct(patient_site_uid, .keep_all = TRUE)%>%
  select(c("patient_site_uid", "wave"))

# ### Reading the CSV script
files_path <- list.files(path = "./data/processed", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./data/processed"), pattern =".csv", n=2))[[1]]
for (i in seq_along(files_path)){
  print(paste0('Currently reading ...', files_names[i]))
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <- read_csv(files_path[i])
  if ("X1"%in%colnames(tmp)){
    tmp <- tmp%>%select(-X1)
  }
  # Outliers removal (removing n = 2)
  # Age 
  tmp <- tmp%>%filter(patient_age < 120 & patient_age > 18)
  # Creatinine - All extremes seemed appropriate, no values changed
  # FiO2
  # Different correction for patients on MV
  tmp <- tmp%>%mutate(
    fio2_min=
      case_when(
        is.na(fio2_min) & mv == 1 ~ 21,
        TRUE ~ fio2_min),
    fio2_max=
      case_when(
        is.na(fio2_max) & mv == 1 ~ 100,
        fio2_max >= 100 ~ 100,
        TRUE ~ fio2_max),
    fio2_mean=
      case_when(
        is.na(fio2_mean) & mv == 1 ~ 50,
        fio2_mean >= 100 ~ 100,
        TRUE ~ fio2_mean))
  # Different correction for patients not on MV
  tmp <- tmp%>%mutate(
    fio2_min=
      case_when(
        is.na(fio2_min) & mv == 0 ~ 21,
        TRUE ~ fio2_min),
    fio2_max=
      case_when(
        is.na(fio2_max) & mv == 0 ~ 40,
        TRUE ~ fio2_max),
    fio2_mean=
      case_when(
        is.na(fio2_mean) & mv == 0 ~ 25,
        fio2_mean >= 100 ~ 100,
        TRUE ~ fio2_mean))
  # SO2
  tmp <- tmp%>%mutate(
    so2_min=
      case_when(
        so2_min < 40 ~ 60,
        TRUE ~ so2_min),
    so2_max=
      case_when(
        so2_max >= 100 ~ 100,
        TRUE ~ so2_max),
    so2_mean=
      case_when(
        is.na(so2_mean) ~ 25,
        so2_mean >= 100 ~ 100,
        TRUE ~ so2_mean))
  # RR
  tmp <- tmp%>%mutate(
    rr_min=
      case_when(
        rr_min < 8 ~ 8,
        TRUE ~ rr_min),
    rr_max=
      case_when(
        rr_max >= 50 ~ 50,
        TRUE ~ rr_max),
    rr_mean=
      case_when(
        rr_mean >= 40 ~ 40,
        TRUE ~ rr_mean))
  # Adding other variables
  # Adding anion_gap_calc
  # tmp <- tmp%>%mutate(
  #   anion_gap_calc = 
  #     sodium_mean - chloride_mean - bicarbonate_mean
  # )
  # Adding a categorical variables for NS3 (patients without labs on admission)
  tmp <- tmp%>%mutate(levelofcare= ifelse(
    is.na(hemoglobin_max), 0, 1))
  # Adding a categorical variable for first and second wave
  tmp <- tmp%>%left_join(stay, by = "patient_site_uid")
  # Removing duplicates (removing n = 36)
  tmp <- tmp%>%distinct(patient_site_uid, .keep_all = TRUE)
  #saving the dataframe
  assign(files_names[i], tmp)
}


f <- tmp%>%left_join(stay, by = 'patient_site_uid')

# Outliers removal --------------------------------------------------------------

# see above


# Imputation --------------------------------------------------------------

### NB must manually modify script to generate imputed set at 24, 48 and 72h

hours = c("24h", "48h", "72h")

for (i in hours){
  # Dropping columns with more than 25% missing values  
  # Dropping observations with more than 35% missing variables
  df_name = paste0("covid", i, "_notimputed")
  assign(df_name, tmp)
  tmp <- tmp %>% 
    purrr::discard(~sum(is.na(.x))/length(.x)*100 >=25)%>% 
    filter(rowSums(is.na(.)) < ncol(.)*0.25)
  # Getting predictor Matrix and modifying it to exclude 2 variables from the imputation set 
  matrix <- mice::mice(tmp, method = "cart", m=1, maxit = 0)
  pred_matrix <- matrix$predictorMatrix
  pred_matrix[,'patient_site_uid'] <- 0
  pred_matrix[,'death'] <- 0
  pred_matrix[,'wave'] <- 0
  
  # Imputing
  covidimputer <- mice::mice(tmp, pred = pred_matrix, method = "cart", m=1)
  imputed_df <- complete(covidimputer, 1)
  #Saving the file
  write_csv(imputed_df, file=paste0('./data/imputed/','covid',i,'_imputed.csv'))
}