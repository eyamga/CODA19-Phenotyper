# Set Working Directory
setwd("/data8/projets/Mila_covid19/code/eyamga/phenotyper/code/r_eyamga")

# Library load
source("./library_load.R")
library(comorbidity)
library(DBI)
library(RSQLite)


### Loading db and querying the info and saving as CSV files

SQLPATH = '../../../../../output/covidb_full/sqlite/covidb_version-1.0.0.db'
coda19 <- DBI::dbConnect(RSQLite::SQLite(), SQLPATH)
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
