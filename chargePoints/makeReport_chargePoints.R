# Packages ----
library(here)
library(rmarkdown)

# Functions ----
source(here::here("R", "functions.R"))

# rmarkdown::render(input = here::here("rmd", f),
#                   output_format ="all", # output all formats specified in the rmd
#                   output_dir= here::here("docs")
# )

makeReport <- function(county){
  # default = whatever is set in yaml
  rmarkdown::render(input = here::here("chargePoints","chargePoints.Rmd"),
                    params = list(county = county),
                    #output_format ="all", # output all formats specified in the rmd
                    output_file = paste0(here::here("docs/evChargePoints_"), county, "_", version)
  )
}

# names MUST EXACTLY match the parish name in the CSE data files
strList <- c("Suffolk", "Hampshire")

message("Filters: ", strList)

version <- "v1"

# get the data once (this takes time)
# good case for targets - if it can check data not updated since last time?

source(here::here("chargePoints", "getChargePointData.R"))

for(s in strList){
  # set params
  county <- s
  message("Running report on: ", county)
  makeReport(county)
}