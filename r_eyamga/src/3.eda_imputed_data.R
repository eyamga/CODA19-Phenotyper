# NB in this file must manually generate reports

#Loading raw dataset ---------------------------------------------------------------------
#
# ### Reading the CSV script
files_path <- list.files(path = "./data/imputed", full.names=TRUE)
files_names <- as_tibble(str_split_fixed(list.files(path = "./data/imputed"), pattern =".csv", n=2))[[1]]
for (i in seq_along(files_path)){
  print(paste0('Currently reading ...', files_names[i]))
  #dbGetQuery(coda19, statement = read_file(files_path[i]))
  tmp <- read_csv(files_path[i])
  if ("X1"%in%colnames(tmp)){
    tmp <- tmp%>%select(-X1)
  }
  assign(files_names[i], tmp)
}

# EDA on imputed dataset --------------------------------------------------


# EDA report from imputed data
dataMaid::makeDataReport(covid24h_imputed,
                         render = FALSE,
                         file = 'coda19CHUM24h_imputed.rmd',
                         replace = TRUE)  


# Correlation EDA ---------------------------------------------------------

# EDA taking potential outcomes into consideration


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
