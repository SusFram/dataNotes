# EV charging points

# https://data.openenergy.org.uk/dataset/national-chargepoint-registry

library(data.table)
library(sf)
library(leaflet)

url <- "https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv"

dt <- data.table::fread(url)

# Map suffolk

suffolk <- dt[county %like% "Suffolk"]

# basic charger site location map
# this is just sites, there may be multiple chargers per site (connector1 -> connector8)
#map <- leaflet(suffolk) %>% addCircles(lng = ~longitude, lat = ~latitude)
#map %>% addTiles()

# how do we calculate the mean of the connector1RatedOutputKW columns?

head(suffolk[, .(chargeDeviceID, reference, name)])

nrow(suffolk$reference)
uniqueN(suffolk$reference)
uniqueN(suffolk$name)
uniqueN(suffolk$latitude)

kw_cols <- suffolk[, .(chargeDeviceID, 
          connector1RatedOutputKW,
          connector2RatedOutputKW,
          connector3RatedOutputKW,
          connector4RatedOutputKW,
          connector5RatedOutputKW,
          connector6RatedOutputKW,
          connector7RatedOutputKW,
          connector8RatedOutputKW
          )]

kw_cols_long <- melt(kw_cols, id.vars = "chargeDeviceID")
kw_cols_long[, connector := as.numeric(stringr::str_remove(stringr::str_remove(variable, "connector"), "RatedOutputKW"))]
kw_cols_long[, .(nObs = .N, 
                 minkW = min(value, na.rm = TRUE),
                 maxkW = max(value, na.rm = TRUE)
                 ), keyby = .(connector)]
kw_cols_long[!is.na(value), valid := 1]
summaryStats <- kw_cols_long[, .(nChargers = sum(valid, na.rm = TRUE),
                                 minkW = min(value, na.rm = TRUE),
                                 meankW = mean(value, na.rm = TRUE),
                                 maxkW = max(value, na.rm = TRUE)), keyby = .(chargeDeviceID)]

setkey(suffolk, chargeDeviceID)
setkey(summaryStats, chargeDeviceID)

suffolk <- suffolk[summaryStats]

pal <- colorNumeric(
  palette = "Reds",
  domain = suffolk$meankW)

map <- leaflet(suffolk) %>% addCircles(lng = ~longitude, lat = ~latitude, 
                                       color = ~pal(meankW),
                                       popup = ~paste0("Location: ", town," (",name,")","<br>",
                                                       "N chargers: ", nChargers, "<br>",
                                                       "Power: ", minkW, " - ", maxkW, " kW" )
                                       )
map %>% addTiles() %>%
  addLegend("bottomright", pal = pal, values = ~meankW,
            title = "Mean kW at site",
            opacity = 1
  ) %>% addMiniMap("topright")
