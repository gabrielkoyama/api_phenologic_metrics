library(plumber)
library(yaml)
library(Rwtss)
library(httr)
library(CropPhenology)
library(jsonlite)
# options(warn=-1)

SOURCE  = "https://brazildatacube.dpi.inpe.br/wtss"
SERVICE = "Rwtss"
VERSION = as.character(packageVersion('Rwtss'))

# Coverages 
#* @get /coverages
function(){
  wtss_inpe <- "https://brazildatacube.dpi.inpe.br/wtss"
  coverages <- Rwtss::list_coverages(wtss_inpe)
  list(coverages = coverages)
}

single_phenology <- function(annualTS, percentage, smoothing) {
  # Savitzky-Golay option
  # NA interpolating 

  metrics <- SinglePhenology(AnnualTS=annualTS, Percentage=percentage, Smoothing=smoothing)
  # 15 Metrics ::
  # ("OnsetV, OnsetT, OffsetV, OffsetT, MAxV, MaxT, TINDVI, TINDVIBeforeMax, TINDVIAfeterMax, Assymetry, GreenUpSlope, BrownDownSlope, LengthGS, BeforeMaxT, AfterMaxT")
  return(metrics)
}

# single-phenology
#* @get /single-phenology
function(roi, period="", token="", datacube=""){

  if(datacube=="") datacube="S2-SEN2COR_10_16D_STK-1"
  if(token=="")    token="ZcuMgQjFvNxzKUr1WvRgzioztBK0ZxFa2AqJSxuUS8"
  if(period=="")   period="2019-01-01/2020-01-01"

  # requisicao para a api em python
  print("sending request to extract ts...")
  url <- "http://192.168.15.7:8081/extract-ts"
  res <- VERB("GET", url=url, query=list(roi=roi, period=period, datacube=datacube, token=token))

  # list(timeline = content(res)$timeline, values=content(res)$values, satellite=content(res)$satellite)

  annualTS   <- unlist(content(res)$values)
  percentage <- 20
  smoothing  <- FALSE

  m_labels <- c("OnsetV", "OnsetT", "OffsetV", "OffsetT", "MAxV", "MaxT", "TINDVI", "TINDVIBeforeMax", "TINDVIAfeterMax", "Assymetry", "GreenUpSlope", "BrownDownSlope", "LengthGS", "BeforeMaxT", "AfterMaxT")
  m_values <- single_phenology(annualTS, percentage, smoothing)

  list(

  )

  # mounting response
  return(list(
    area=jsonlite::unbox(roi),
    datacube=jsonlite::unbox(datacube),
    period=jsonlite::unbox(period),
    source=jsonlite::unbox(SOURCE),
    service=jsonlite::unbox(SERVICE),
    version=jsonlite::unbox(VERSION),
    time_series=annualTS,
    # phenologic_metrics=list(labels=m_labels, values=m_values),
    phenologic_metrics = list("OnsetV"          = jsonlite::unbox(m_values[1]),
                              "OnsetT"          = jsonlite::unbox(m_values[2]),
                              "OffsetV"         = jsonlite::unbox(m_values[3]),
                              "OffsetT"         = jsonlite::unbox(m_values[4]),
                              "MAxV"            = jsonlite::unbox(m_values[5]),
                              "MaxT"            = jsonlite::unbox(m_values[6]),
                              "TINDVI"          = jsonlite::unbox(m_values[7]),
                              "TINDVIBeforeMax" = jsonlite::unbox(m_values[8]),
                              "TINDVIAfeterMax" = jsonlite::unbox(m_values[9]),
                              "Assymetry"       = jsonlite::unbox(m_values[10]),
                              "GreenUpSlope"    = jsonlite::unbox(m_values[11]),
                              "BrownDownSlope"  = jsonlite::unbox(m_values[12]),
                              "LengthGS"        = jsonlite::unbox(m_values[13]),
                              "BeforeMaxT"      = jsonlite::unbox(m_values[14]),
                              "AfterMaxT"       = jsonlite::unbox(m_values[15])),
    statistics=list(
        maximum   = jsonlite::unbox(max(annualTS)),
        minimin   = jsonlite::unbox(min(annualTS)),
        average   = jsonlite::unbox(mean(annualTS)),
        deviation = jsonlite::unbox(sd(annualTS))
    )
  ))
}

# single-phenology
#* @get /pheno-metrics
function(){
  list(ok=200)
}

#* @plumber
function(pr){
  pr %>% 
    pr_set_api_spec(yaml::read_yaml("openapi.yaml"))
}