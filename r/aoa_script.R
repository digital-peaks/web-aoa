#Packages
start_time <- Sys.time() #set start time 

#workingDir <- "~/GitHub/web-aoa/r" #set working directory 
workingDir <- "/app/jobs" #set working directory 
setwd(workingDir) #needed for local tests

print("--> working directory set")

library(CAST) #CAST-Package for performing AOA
library(caret) #caret-Package for performing training of machine-learning models
library(sp) #sp-Package for handlig spatial datasets
library(rgdal) #rgdal-Packge for performing spatial operations
library(sf) #sf-package for performing spatial operation on spheroids
library(rstac) #rstac for accessing STAC-Catalogue 
library(rjson) #rjson for reading json input job file
library(raster) #raster-Package for working with various raster formats
library(gdalcubes) #gdalcubes-Package for creating, handling and using spatio-temporal datacubes
library(kernlab) #kernlab for training kernel based support vector machines
print("--> libraries imported")

args = commandArgs(trailingOnly=TRUE)
job_name <- args[1] #name of the job
print(paste("--> Get job id from args:", job_name))

#job_name <- "test" #for local tests
job_path <- paste(workingDir, job_name, sep="/") #path to the job folder

print(paste("--> Job path: ", job_path, sep=""))

#Parameters
parameters <- fromJSON(file = paste(job_path, "/", "job_param.json", sep="")) #read in job paramters
print("--> parameters read")

if(parameters$use_pretrained_model == "false") { #checks if a pretrained model should be used
  samplePolygons_path <- paste(job_path, "/", parameters$samples, sep ="") #path to the samples
  samplePolygons <- read_sf(samplePolygons_path, crs = 4326) #sample Polygons (Dezimalgrad)
  samplePolygon_bbox <- st_bbox(samplePolygons, crs = 4326) #(Dezimalgrad)
  print("--> new model will be trained")
} else {
  tryCatch({
    model_path <- paste(job_path, "/", parameters$model, sep ="") #path to the samples
    model <- readRDS(model_path) 
    model_bands <- 	colnames(model$ptype) #retrieve predictors from pretrained model
    available_bands = c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL", "NDVI", "BSI", "BAEI") #avaiable predictors
    if(length(model$ptype) > length(available_bands)) { #if pretrained model employs too many predictors
      stop()
    }
    for(i in 1:length(model_bands)){ #if pretrained model employs predictors not available in Sentinel-2A imagery
      if(model_bands[i]%in%available_bands == FALSE) {
        stop()
      }
    }
    print("--> pretrained model valid")
  }, warning = function(w) {
    print("Warning!")
  }, error = function(e) {
    print("Error!")
    print("--> given model employs non-available predictor")
    print("--> a valid model could employ the following bands from Sentinel-2A imagery:")
    print("--> B01, B02, B03, B04, B05, B06, B07, B08, B8A, B09, B11, B12, SCL, NDVI, BSI, BAEI")
  }, finally = {
  })
}

aoi_path <- paste(job_path, "/", parameters$aoi, sep ="") #path to the aoi
aoi <- read_sf(aoi_path, crs = 4326) #AOI (Dezimalgrad)
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI (Dezimalgrad)
print("--> AOI and AFT set")

#select resolution
if(parameters$use_lookup == "true") {
  aoi_area <- st_area(aoi)
  if(parameters$use_pretrained_model == "false") {
    sample_area <- sum(st_area(samplePolygons))
    optimal_resolution <- as.numeric(sqrt(((aoi_area+sample_area)/2)/10000))
  } else {
    optimal_resolution <- sqrt(aoi_area/10000) #Function for calculating the optimal resolution for a 10000 pixel image
  }
  
  if(optimal_resolution <= 10) {
    resolution_aoi <- 10
    resolution_training <- 10
  }
  if(optimal_resolution <= 20 && optimal_resolution > 10) {
    resolution_aoi <- 20
    resolution_training <- 20
  }
  if(optimal_resolution <= 50 && optimal_resolution > 20) {
    resolution_aoi <- 50
    resolution_training <- 50
  }
  if(optimal_resolution <= 100 && optimal_resolution > 50) {
    resolution_aoi <- 100
    resolution_training <- 100
  }
  if(optimal_resolution <= 200 && optimal_resolution > 100) {
    resolution_aoi <- 200
    resolution_training <- 200
  }
  if(optimal_resolution <= 400 && optimal_resolution > 200) {
    resolution_aoi <- 400
    resolution_training <- 400
  }
} else {
  resolution_aoi <- parameters$resolution #Resolutin of the Output-Image (Meter) 
  resolution_training <- parameters$resolution #Resolutin of the Output-Image (Meter)
  print("--> custom resolution will be used")
}
print("--> output resolution set to ")
print(resolution_aoi)

cloud_cover <- parameters$cloud_cover #Threshold for Cloud-Cover in Sentinel-Images
print("--> cloudcover set")
t0 <- parameters$start_timestamp #start timestamp
t1 <- parameters$end_timestamp #end timestamp
timeframe <- paste(t0, '/', t1, sep ="") #timeframe
print("--> timeframe set")
response <- parameters$response #Value to be used in classification
print("--> response set")
sampling_strategy <- parameters$sampling_strategy #regular, statified, nonaligned, clustered, hexagonal, Fibonacci
print("--> sampling strategy set")
key <- parameters$obj_id #attribute to match samples with the response
print("--> key attribute set")

assets = c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL") #bands to be retrieved via stac
print("--> assets set")
stac = stac("https://earth-search.aws.element84.com/v0") #initialize stac
print("--> stac initialized")
print("--> basic processing setup done")

#############Get Image-Data for AOI
items_aoi <- stac %>% #retrieve sentinel bands for area of interest
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
print("--> stac items for AOI retrieved")
items_aoi

tryCatch({
  collection_aoi =  stac_image_collection(items_aoi$features, asset_names = assets, 
                                          property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
}, warning = function(w) {
  print("Warning!")
}, error = function(e) {
  print("Error!")
}, finally = {
  collection_aoi =  stac_image_collection(items_aoi$features, asset_names = assets, 
                                          property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
  print("--> image collection for AOI created")
})

targetSystem <- toString(items_aoi$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
print("--> target crs retrieved")
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
aoi_transformed <- st_transform(aoi, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
print("--> AOI tranformed to target crs")
aoi_bbox_tranformed <- st_bbox(aoi_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI
print("--> AOI bbox tranformed to target crs")

cube_view_aoi = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                             left = aoi_bbox_tranformed[1], 
                                                             right = aoi_bbox_tranformed[3],  
                                                             top = aoi_bbox_tranformed[4], 
                                                             bottom = aoi_bbox_tranformed[2]),
                                                             dx = resolution_aoi, 
                                                             dy = resolution_aoi, 
                                                             dt = "P1D", #intervall in which images are taken from each time slice
                                                             aggregation = "median", 
                                                             resampling = "average")
print("--> AOI cube view created")

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows
print("--> cloud mask created")

gdalcubes_options(threads = 8) #set Threads for raster cube
print("--> gdalcubes threads set to 8")
classification_image_name <- paste('classification_image', sep ="") 
cube_raster_aoi = raster_cube(collection_aoi, cube_view_aoi, mask = S2.mask) %>%
  select_bands(c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL")) %>% #B, G, R, NIR, SWIR
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>% #NDVI - Normalized Difference Vegetation Index
  apply_pixel("(B11+B04)-(B08+B02)/(B11+B04)+(B08+B02)", "BSI", keep_bands = TRUE) %>% #Bare Soil Index
  apply_pixel("(B04 + 0.3)/(B03+B11)", "BAEI", keep_bands = TRUE) %>% #Built-up Area Extraction Index
  reduce_time(c("median(B01)", 
                "median(B02)", 
                "median(B03)", 
                "median(B04)", 
                "median(B05)", 
                "median(B06)",
                "median(B07)",
                "median(B08)",
                "median(B8A)",
                "median(B09)",
                "median(B11)",
                "median(B12)",
                "median(NDVI)", 
                "median(BSI)", 
                "median(BAEI)")) %>%  
  write_tif(
    dir = job_path,
    prefix = basename(classification_image_name),
    overviews = FALSE,
    COG = TRUE,
    rsmpl_overview = "nearest"
  )
filename <- paste(job_path, "/", "classification_image", t0, ".tif", sep="")
file <- filename
file.rename(filename, paste(job_path, "/", "classification_image.tif", sep=""))

print("--> AOI raster cube created")
print("--> classification image written")

#############Get Image-Data for sample Polygons
if(parameters$use_pretrained_model == "false") { #if a pretrained model is used to trainig data must be retrieved
  items_poly <- stac %>% #retrieve sentinel bands for area for training
    stac_search(collections = "sentinel-s2-l2a-cogs",
                bbox = c(samplePolygon_bbox[1], samplePolygon_bbox[2], samplePolygon_bbox[3], samplePolygon_bbox[4]),
                datetime = timeframe,
                limit = 100) %>%
    post_request() 
  print("--> stac items for AFT retrieved")
  items_poly
  
  tryCatch({
    collection_poly = stac_image_collection(items_poly$features, asset_names = assets, 
                                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
  }, warning = function(w) {
    print("Warning!")
  }, error = function(e) {
    print("Error!")
  }, finally = {
    collection_poly = stac_image_collection(items_poly$features, asset_names = assets, 
                                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
    print("--> image collection for AFT created")
  })
  
  targetSystem <- toString(items_poly$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
  print("--> target crs retrieved")
  targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
  samplePolygons_transformed <- st_transform(samplePolygons, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
  print("--> AFT tranformed to target crs")
  samplePolygons_bbox_tranformed <- st_bbox(samplePolygons_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI
  print("--> AFT bbox tranformed to target crs")
  
  cube_view_poly = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                                left = samplePolygons_bbox_tranformed[1], 
                                                                right = samplePolygons_bbox_tranformed[3],  
                                                                top = samplePolygons_bbox_tranformed[4], 
                                                                bottom = samplePolygons_bbox_tranformed[2]),
                                                                dx = resolution_training, 
                                                                dy = resolution_training, 
                                                                dt = "P1D", 
                                                                aggregation = "median", 
                                                                resampling = "average")
  print("--> AFT cube view created")
  
  S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows
  print("--> cloud mask created")
  
  gdalcubes_options(threads = 8) #set Threads for raster cube 
  print("--> gdalcubes threads set to 8")
  
  training_image_name <- paste('training_image', sep ="") 
  cube_raster_poly = raster_cube(collection_poly, cube_view_poly, mask = S2.mask) %>%
    select_bands(c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL")) %>% #B, G, R, NIR, SWIR
    apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>% #NDVI - Normalized Difference Vegetation Index
    apply_pixel("(B11+B04)-(B08+B02)/(B11+B04)+(B08+B02)", "BSI", keep_bands = TRUE) %>% #Bare Soil Index
    apply_pixel("(B04 + 0.3)/(B03+B11)", "BAEI", keep_bands = TRUE) %>% #Built-up Area Extraction Index
    reduce_time(c("median(B01)", 
                  "median(B02)", 
                  "median(B03)", 
                  "median(B04)", 
                  "median(B05)", 
                  "median(B06)",
                  "median(B07)",
                  "median(B08)",
                  "median(B8A)",
                  "median(B09)",
                  "median(B11)",
                  "median(B12)",
                  "median(NDVI)", 
                  "median(BSI)", 
                  "median(BAEI)")) %>% 
    write_tif(
      dir = job_path,
      prefix = basename(training_image_name),
      overviews = FALSE,
      COG = TRUE,
      rsmpl_overview = "nearest"
    )
  filename <- paste(job_path, "/", "training_image", t0, ".tif", sep="")
  file <- filename
  file.rename(filename, paste(job_path, "/", "training_image.tif", sep=""))
  
  print("--> AFT raster cube created")
  print("--> training image written")
  print("--> raster data retrieval done")
}

#############Training
if(parameters$use_pretrained_model == "false") { #if a pretrained model is used no training stack must be created
  training_stack_path <- paste(job_path, "/", training_image_name, ".tif", sep="")
  training_stack <- stack(training_stack_path) #load training image as stack
  print("--> training stac created")
  names(training_stack)<-c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","NDVI", "BSI", "BAEI") #rename bands
  print("--> band names assigned")
  training_stack 
}

classification_stack_path <- paste(job_path, "/", classification_image_name, ".tif", sep="")
classification_stack <- stack(classification_stack_path) #load classification image 
print("--> classification stac created")
names(classification_stack)<-c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","NDVI", "BSI", "BAEI") #rename bands
print("--> band names assigned")
classification_stack 

if(parameters$use_pretrained_model == "false") { #train model ig no pretrained model is provided
  training_data <- extract(training_stack, samplePolygons, df='TRUE') #extract training data from image via polygons
  print("--> training data extracted from raster")
  training_data <- merge(training_data, samplePolygons, by.x="ID", by.y=key) #enrich traing data with corresponding classes
  print("--> response assigned to training data")

  predictors <- names(training_stack) #set predictor variables
  print("--> predictors set")
  response <- response #set response value
  print("--> response set")
  if(parameters$procedure$selected == "rf") {
    print("--> random forrest will be trained")
    model <- train(training_data[,predictors], training_data$class, #train model
                    method="rf", tuneGrid=data.frame("mtry"= length(predictors)/2), #with random forrest 
                    importance=TRUE,
                    ntree=parameters$procedure$random_forrest$n_tree, #max number of trees
                    trControl=trainControl(method="cv", number=parameters$procedure$random_forrest$cross_validation_folds)) #perform cross validation to assess model
    print("--> model trained")
    model
  }
  if(parameters$procedure$selected == "svmradial") {
    print("--> support vector machine will be trained")
    
    model <- train(training_data[,predictors], training_data$class, #train model
                   method="svmRadial", tuneGrid=expand.grid(.C = parameters$procedure$support_vector_machine$c,.sigma=parameters$procedure$support_vector_machine$sigma), #with random forrest 
                   importance=TRUE,
                   ntree=parameters$procedure$random_forrest$n_tree, #max number of trees
                   trControl=trainControl(method="cv", number=parameters$procedure$support_vector_machine$cross_validation_folds)) #perform cross validation to assess model
    print("--> model trained")
    model
  }
  model_path <- paste(job_path, "/", "model.rds", sep="")
  saveRDS(model, model_path)
  print("--> model exported")
  } else { #use pretrained model if one is provided
    model_path <- paste(job_path, "/", parameters$model, sep ="") #path to the samples
    model <- readRDS(model_path)
    print("--> model imported")
}

prediction <- predict(classification_stack, model) #predict LU/LC
print("--> classification done")
prediction

aoa<- aoa(classification_stack, model) #calculate aoa
print("--> AOA calculation done done")
aoa
print("--> geostatistical processing done")

#############Raster Export
aoa_path <- paste(job_path, "/", "aoa_aoa", sep="")
di_path <- paste(job_path, "/", "aoa_di", sep="")
prediction_path <- paste(job_path, "/", "pred", sep="")
geojson_path <- paste(job_path, "/", "suggestion.geojson", sep="")
writeRaster(aoa$AOA, aoa_path, format = 'GTiff', options=c('TFW=YES')) #export aoa
print("--> AOA image written")
writeRaster(aoa$DI, di_path, format = 'GTiff',  options=c('TFW=YES')) #export dissimilarity index
print("--> DI image written")
writeRaster(prediction, prediction_path, format = 'GTiff', options=c('TFW=YES')) #export prediction
print("--> prediction image written")

#############Sampling
aoa_source_path <- paste(job_path, "/aoa_aoa.tif", sep="") #path to aoa raster
aoa_raster <- stack(aoa_source_path) #load training image as stack
mask <- mask(aoa_raster, aoa_raster, maskvalue=1) #create mask from aoa where model is not applicable
print("--> AOA mask created")
points <- spsample(rasterToPolygons(mask), n = 50, sampling_strategy) #create sample points on mask
print("--> suggested locations for extra training polygons created")

proj_string <- raster::crs(aoa_raster) #retrieve CRS

points_dataframe <- points@coords #extract coords
points_dataframe_source <- as.data.frame(points_dataframe) #convert coords to dataframe
xy <- points_dataframe[,c(1,2)] #get fields

spatial_points_dataframe <- SpatialPointsDataFrame(coords = xy, data = points_dataframe_source, #create spatial_points_dataframe
                               proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))

spatial_points_dataframe_converted <- st_as_sf(spatial_points_dataframe) #convert spatial_points_dataframe
st_crs(spatial_points_dataframe_converted) = as.numeric(targetSystem) #set target system as crs
spatial_points_dataframe_transformed <- st_transform(spatial_points_dataframe_converted, as.numeric("4326")) #transform AOI to Sentinel-Image EPSG
st_write(spatial_points_dataframe_transformed, geojson_path, driver = "GeoJSON") #export as GeoJSON
print("--> suggested locations for extra training polygons written")
print("--> processing done")
end_time <- Sys.time() #set end time 
overall_time <- paste("--> processing time: ", (end_time - start_time)/60, " Minutes", sep="")
print(overall_time)

