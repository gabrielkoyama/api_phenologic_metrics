library(plumber)
library(yaml)
library(Rwtss)
library(rstac)
library(httr)
library(CropPhenology)
library(jsonlite)
library(magrittr)
# options(warn=-1)

SOURCE  = "https://brazildatacube.dpi.inpe.br/wtss"
SERVICE = "Rwtss"
VERSION = as.character(packageVersion('Rwtss'))

URL <- "http://127.0.0.1:8080/get-image?f="

single_phenology <- function(annualTS, percentage, smoothing) {
  # Savitzky-Golay option
  # NA interpolating 
  metrics <- SinglePhenology(AnnualTS=annualTS, Percentage=percentage, Smoothing=smoothing)
  # 15 Metrics ::
  # ("OnsetV, OnsetT, OffsetV, OffsetT, MAxV, MaxT, TINDVI, TINDVIBeforeMax, TINDVIAfeterMax, Assymetry, GreenUpSlope, BrownDownSlope, LengthGS, BeforeMaxT, AfterMaxT")
  return(metrics)
}

pheno_metrics <- function(IVStack, roi) {
  raster_metrics <- PhenoMetrics(IVStack, roi)

  print("saving PhenoMetrics results at ./PhenoMetrics_results")

  writeRaster(raster_metrics, "/PhenoMetrics_results") # save in grd

  print("saving single metrics..")
  idx<-1

  enpoints <- list()
  for (name in names(raster_metrics)){
      dst_name <- paste0("PhenoMetrics_results_", name, ".tif")
      enpoints <- append(enpoints, paste0(URL, "PhenoMetrics_results_", name, ".tif"))
      aux_tif  <- subset(raster_metrics,subset=idx)
      idx<-idx+1
      writeRaster(aux_tif, dst_name)
      print(paste0("saved file: ", dst_name))
  }

  # list single metrics
  # single_files_metrics <- list.files("./", pattern = glob2rx("*PhenoMetrics_results_*.tif$"), full.names = TRUE)

  return(enpoints)
}

# Coverages 
#* @get /coverages-wtss
function(){
  wtss_inpe <- "https://brazildatacube.dpi.inpe.br/wtss"
  coverages <- Rwtss::list_coverages(wtss_inpe)
  list(coverages = coverages)
}

# Coverages 
#* @get /coverages-stac
function(){
  wtss_inpe <- "https://brazildatacube.dpi.inpe.br/wtss"
  coverages <- Rwtss::list_coverages(wtss_inpe)
  list(coverages = coverages)
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


#* @get /test2
#* @serializer contentType list(type='image/png')
function(){
    # p = data.frame(x=1,y= 1) %>% ggplot(aes(x=x,y=y)) + geom_point()
    file = './file.png'
    # ggsave(file,p)
    readBin(file,'raw',n = file.info(file)$size)
}

#* @get /get-image
#* @serializer contentType list(type='image/tiff')
function(f){
  print(paste0("Downloading ", f))
  readBin(paste0("./", f),'raw',n = file.info(f)$size)
}

#* @get /testtiff
#* @serializer contentType list(type='image/tiff')
function(){
  file = './Max_Time_pm_stack_ndvi2.tif'
  readBin(file,'raw',n = file.info(file)$size)
}

# pheno-metrics
#* @get /pheno-metrics
function(roi, period="", token="", datacube=""){

  if(datacube == "") datacube = "S2-SEN2COR_10_16D_STK-1"
  if(token    == "") token    = "ZcuMgQjFvNxzKUr1WvRgzioztBK0ZxFa2AqJSxuUS8"
  if(period   == "") period   = "2019-01-01/2020-01-01"

  # Searching..
  print("Searching..")
  s_obj <- stac("https://brazildatacube.dpi.inpe.br/stac/")
  it_obj <- s_obj %>%
      stac_search(collections = datacube,
                  bbox = c(-46.118120, -9.130727,-46.101009, -9.119429), limit=2) %>%
      get_request(add_headers("x-api-key" = token))
  
  tam <- it_obj %>% items_length()

  print(paste0("Found: ", tam))

  # Download..
  print("Downloading..")
  download_items <- it_obj %>% 
    assets_download(assets_name = "NDVI")

  # Listing
  files_ndvi <- list.files("./", pattern = glob2rx("*NDVI*.tif$"), full.names = TRUE)
  print(files_ndvi)

  # read shapefile
  print("Reading shapefile")
  crop_extent <- readOGR("./field1.shp")

  # Crop rasters by shapefile and save at current directory
  root <- "./"
  for (file in files_ndvi){
      
      print(paste0("Reading raster:", file))
      raster_ndvi <- raster(file)
      
      print("Transform projection..")
      crop_extent <- spTransform(crop_extent, CRS(proj4string(raster_ndvi)))
                                                              
      print("Cropping...")
      raster_ndvi_crop <- crop(raster_ndvi, crop_extent)
      
      dst_name <- paste0(root, names(raster_ndvi), "_crop", ".tif")
      print(paste0("saving file in", dst_name))
      writeRaster(raster_ndvi_crop, dst_name)
  }

  # list crop files
  ndvi_cropped <- list.files("./", pattern = glob2rx("*crop*.tif$"), full.names = TRUE)
  ndvi_cropped

  # Stack tif files..
  print("Stacking tif files..")
  IVStack <- stack(ndvi_cropped)

  # extract metrics rasters from stack
  files_metrics <- pheno_metrics(IVStack, crop_extent)

  # mount link...
  

  return(list(
    metrics=files_metrics, # link...
    phenometric="./PhenoMetrics_results.gdr" # link...
  ))
}

#* @plumber
function(pr){
  pr %>% 
    pr_set_api_spec(yaml::read_yaml("openapi.yaml"))
}