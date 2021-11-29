#Packages
workingDir <- "/app/r"

setwd(workingDir) #needed for local tests
library(CAST) #CAST-Package for performing AOA
library(caret) #caret-Package for performing training of machine-learning models
library(sp) #sp-Package for handlig spatial datasets
library(rgdal) #rgdal-Packge for performing spatial operations
library(sf) #sf-package for performing spatial operation on spheroids
library(rstac) #rstac for accessing STAC-Catalogue 
library(rjson) #rjson for reading json input job file
library(mapview) #for testing
library(raster) #raster-Package for working with various raster formats
library(gdalcubes) #gdalcubes-Package for creating, handling and using spatio-temporal datacubes

#Parameters
parameters <- fromJSON(file = 'job_param.json') #read in job paramters

job_name <- parameters$name #name of the job

job_path <- paste(workingDir, "/", job_name, sep="") #path to the job folder
samplePolygons_path <- paste(job_path, "/", parameters$samples, sep ="") #path to the samples
samplePolygons <- read_sf(samplePolygons_path, crs = 4326) #sample Polygons (Dezimalgrad)
samplePolygon_bbox <- st_bbox(samplePolygons, crs = 4326) #(Dezimalgrad)

aoi_path <- paste(job_path, "/", parameters$aoi, sep ="") #path to the aoi
aoi <- read_sf(aoi_path, crs = 4326) #AOI (Dezimalgrad)
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI (Dezimalgrad)

#select resolution
if(parameters$use_lookup == "true") {
  resolution_aoi <- parameters$resolution #Resolutin of the Output-Image (Meter) 
  resolution_training <- parameters$resolution #Resolutin of the Output-Image (Meter) 
} else {
  area_aoi <- st_area(aoi_bbox)
  area_training <- st_area(samplePolygon_bbox)
}

cloud_cover <- parameters$cloud_cover #Threshold for Cloud-Cover in Sentinel-Images
t0 <- parameters$start_timestamp #start timestamp
t1 <- parameters$end_timestamp #end timestamp
timeframe <- paste(t0, '/', t1, sep ="") #timeframe
response <- parameters$response #Value to be used in classification
sampling_strategy <- parameters$sampling_strategy #regular, statified, nonaligned, clustered, hexagonal, Fibonacci
key <- parameters$obj_id #attribute to match samples with the response

assets = c("B01","B02","B03","B04","B05","B06", "B07","B08","B8A","B09","B11","SCL")
stac = stac("https://earth-search.aws.element84.com/v0") #initialize stac

#images_path <- paste("~/GitHub/web-aoa/r/", parameters$job_name, '_job/images/', sep ="") #needs fixing
#mapview(c(st_geometry(samplePolygons),st_geometry(aoi))) #plot aoi and sample Polygons

#############Get Image-Data for AOI
items_aoi <- stac %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
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
})


targetSystem <- toString(items_aoi$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
aoi_transformed <- st_transform(aoi, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
aoi_bbox_tranformed <- st_bbox(aoi_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI

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

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

classification_image_name <- paste(job_name, '_classification_image_', sep ="") 
cube_raster_aoi = raster_cube(collection_aoi, cube_view_aoi, mask = S2.mask) %>%
  select_bands(c("B02", "B03", "B04", "B08", "B11")) %>% #B, G, R, NIR, SWIR
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>% #NDVI - Normalized Difference Vegetation Index
  apply_pixel("(B11+B04)-(B08+B02)/(B11+B04)+(B08+B02)", "BSI", keep_bands = TRUE) %>% #Bare Soil Index
  apply_pixel("(B04 + 0.3)/(B03+B11)", "BAEI", keep_bands = TRUE) %>% # Built-up Area Extraction Index
  reduce_time(c("median(B02)", "median(B03)", "median(B04)", "median(B08)", "median(NDVI)", "median(B11)", "median(BSI)", "median(BAEI)")) %>% 
  write_tif(
    dir = job_path,
    prefix = basename(classification_image_name),
    overviews = FALSE,
    COG = TRUE,
    rsmpl_overview = "nearest"
  )

#############Get Image-Data for sample Polygons
items_poly <- stac %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(samplePolygon_bbox[1], samplePolygon_bbox[2], samplePolygon_bbox[3], samplePolygon_bbox[4]),
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
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
})

targetSystem <- toString(items_poly$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
samplePolygons_transformed <- st_transform(samplePolygons, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
samplePolygons_bbox_tranformed <- st_bbox(samplePolygons_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI

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

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

training_image_name <- paste(job_name, '_training_image_', sep ="") 
cube_raster_poly = raster_cube(collection_poly, cube_view_poly, mask = S2.mask) %>%
  select_bands(c("B02", "B03", "B04", "B08", "B11")) %>% #B, G, R, NIR, SWIR
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>% #NDVI - Normalized Difference Vegetation Index
  apply_pixel("(B11+B04)-(B08+B02)/(B11+B04)+(B08+B02)", "BSI", keep_bands = TRUE) %>% #Bare Soil Index
  apply_pixel("(B04 + 0.3)/(B03+B11)", "BAEI", keep_bands = TRUE) %>% # Built-up Area Extraction Index
  reduce_time(c("median(B02)", "median(B03)", "median(B04)", "median(B08)", "median(NDVI)", "median(B11)", "median(BSI)", "median(BAEI)")) %>% 
  write_tif(
    dir = job_path,
    prefix = basename(training_image_name),
    overviews = FALSE,
    COG = TRUE,
    rsmpl_overview = "nearest"
  )

#############Training
training_stack_path <- paste(job_path, "/", training_image_name, t0, ".tif", sep="")
training_stack <- stack(training_stack_path) #load training image as stack
names(training_stack)<-c("b", "g", "r", "nir", "ndvi", "swir", "bsi", "baei") #rename bands
training_stack 

classification_stack_path <- paste(job_path, "/", classification_image_name, t0, ".tif", sep="")
classification_stack <-stack(classification_stack_path) #load classification image 
names(classification_stack)<-c("b", "g", "r", "nir", "ndvi", "swir", "bsi", "baei") #rename bands
classification_stack 

training_data <- extract(training_stack, samplePolygons, df='TRUE') #extract training data from image via polygons
training_data <- merge(training_data, samplePolygons, by.x="ID", by.y=key) #enrich traing data with corresponding classes

predictors <- names(training_stack) #set predictor variables
response <- response #set response value
#indices <- CreateSpacetimeFolds(training_data, spacevar = "ID", k=3, class="class") #for ffs 
#control <- trainControl(method="cv", index = indices$index, savePredictions = 'TRUE') #for ffs

model <- train(training_data[,predictors], training_data$class, #train model
               method="rf", tuneGrid=data.frame("mtry"= 8), #with random forrest
               importance=TRUE,
               ntree=100, #max number of trees
               trControl=trainControl(method="cv", number=5)) #perform cross validation to assess model
model
#plot(varImp(model)) #insights into what predictors are how important

prediction <- predict(classification_stack, model) #predict LU/LC
prediction


aoa<- aoa(classification_stack, model) #calculate aoa
aoa

#############Raster Export
#plotRGB(classification_stack, r=3, g=2, b=1, stretch="lin") #plot classification image as rgb
#plot(prediction, col = topo.colors(4), main="Precition") #prediction
#plot(aoa$AOA) #plot area of applicability
#plot(aoa$DI) #plot dissimilarity index

aoa_path <- paste(job_path, "/", "aoa_aoa", sep="")
di_path <- paste(job_path, "/", "aoa_di", sep="")
prediction_path <- paste(job_path, "/", "pred", sep="")
writeRaster(aoa$AOA, aoa_path, format = 'GTiff', options=c('TFW=YES')) #export aoa
writeRaster(aoa$DI, di_path, format = 'GTiff',  options=c('TFW=YES')) #export dissimilarity index
writeRaster(prediction, prediction_path, format = 'GTiff', options=c('TFW=YES')) #export prediction

#############Sampling
aoa_raster <- stack("test_job/images/aoa_aoa.tif") #load training image as stack
mask <- mask(aoa_raster, aoa_raster, maskvalue=0)
points <- spsample(rasterToPolygons(mask), n = 50, sampling_strategy) 
