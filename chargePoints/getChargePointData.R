# EV charging points

# https://data.openenergy.org.uk/dataset/national-chargepoint-registry

library(data.table)

url <- "https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv"

dt <- data.table::fread(url)


kw_cols <- dt[, .(chargeDeviceID, 
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

setkey(dt, chargeDeviceID)
setkey(summaryStats, chargeDeviceID)

dt <- dt[summaryStats]