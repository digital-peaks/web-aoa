#Packages
setwd("~/GitHub/web-aoa/r") #needed for loacal tests
library(CAST) #CAST-Package for performing AOA
library(caret) #caret-Package for performing training
library(sp) #sp-Package for handlig spatial datasets
library(rgdal) #rgdal-Packge for performing spatial operations
library(sf) #sf-package for performing spatial operation on spheroids
library(rstac) #rstac for accessing STAC-Catalogue 
library(rjson)
library(ggplot2)
library(mapview)
library(raster)
library(gdalcubes)

#Parameters
job_name <- 'test'

samplePolygons <- read_sf('test_job/geojson/samplePolygons.geojson', crs = 4326) #sample Polygons (Dezimalgrad)
samplePolygon_bbox <- st_bbox(samplePolygons, crs = 4326) #(Dezimalgrad)

aoi <- read_sf('test_job/geojson/aoi.geojson', crs = 4326) #AOI (Dezimalgrad)
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI (Dezimalgrad)

resolution <- 10 #Resolutin of the Output-Image (Meter) #Look-Up-Table?
cloud_cover <- 95 #Threshold for Cloud-Cover in Sentinel-Images
t0 <- "2020-01-01" #start timestamp
t1 <- "2020-12-20" #end timestamp
timeframe <- paste(t0, '/', t1, sep ="") #timeframe
assets = c("B01","B02","B03","B04","B05","B06", "B07","B08","B8A","B09","B11","SCL")
stac = stac("https://earth-search.aws.element84.com/v0") #initialize stac
response <- "class" #Value to be used in classification

#mapview(c(st_geometry(samplePolygons),st_geometry(aoi))) #plot aoi and sample Polygons

#############Get Image-Data for AOI
items_aoi <- stac %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
items_aoi

collection_aoi = tryCatch({
  stac_image_collection(items_aoi$features, asset_names = assets, 
                        property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
  }, warning = function(w) {
    print("Warning!")
    #print(w)
  }, error = function(e) {
    print("Error!")
    #print(e)
  }, finally = {
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
                                                 dx = resolution, 
                                                 dy = resolution, 
                                                 dt = "P1D", #intervall in which images are taken from each time slice
                                                 aggregation = "median", 
                                                 resampling = "average")

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

classication_image_name <- paste(job_name, '_classication_image_', sep ="") 
cube_raster_aoi = raster_cube(collection_aoi, cube_view_aoi, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04", "B08")) %>%
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)", "median(B08)", "median(NDVI)")) %>%
  write_tif(
    dir = "~/GitHub/web-aoa/r/images",
    prefix = basename(classication_image_name),
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

collection_poly = stac_image_collection(items_poly$features, asset_names = assets, 
                                       property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
collection_poly

targetSystem <- toString(items_poly$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
samplePolygons_transformed <- st_transform(samplePolygons, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
samplePolygons_bbox_tranformed <- st_bbox(samplePolygons_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI

cube_view_poly = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                             left = samplePolygons_bbox_tranformed[1], 
                                                             right = samplePolygons_bbox_tranformed[3],  
                                                             top = samplePolygons_bbox_tranformed[4], 
                                                             bottom = samplePolygons_bbox_tranformed[2]),
                                                             dx = resolution, 
                                                             dy = resolution, 
                                                             dt = "P1D", 
                                                             aggregation = "median", 
                                                             resampling = "average")

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

training_image_name <- paste(job_name, '_training_image_', sep ="") 
cube_raster_poly = raster_cube(collection_poly, cube_view_poly, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04", "B08")) %>%
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)", "median(B08)", "median(NDVI)")) %>%
  write_tif(
    dir = "~/GitHub/web-aoa/r/images",
    prefix = basename(training_image_name),
    overviews = FALSE,
    COG = TRUE,
    rsmpl_overview = "nearest"
  )

#############Training
training_stack <- stack("test_job/images/test_training_image_2020-01-01.tif") #load training image as stack
names(training_stack)<-c("b", "g", "r", "nir", "ndvi") #rename bands
training_stack 

classification_stack <-stack("test_job/images/test_classication_image_2020-01-01.tif") #load classification image 
names(classification_stack)<-c("b", "g", "r", "nir", "ndvi") #rename bands
classification_stack 

training_data <- extract(training_stack, samplePolygons, df='TRUE') #extract training data from image via polygons
training_data <- merge(training_data, samplePolygons, by.x="ID", by.y="PID") #enrich traing data with corresponding classes

predictors <- names(training_stack) #set predictor variables
response <- response #set response value
#indices <- CreateSpacetimeFolds(training_data, spacevar = "ID", k=3, class="class") #for ffs
#control <- trainControl(method="cv", index = indices$index, savePredictions = 'TRUE') #for ffs

set.seed(10) #?
model <- train(training_data[,predictors], training_data$class, #train model
               method="rf", tuneGrid=data.frame("mtry"= 5), #with random forrest
               importance=TRUE,
               ntree=100, #max number of trees
               trControl=trainControl(method="cv", number=5)) #perform cross validation to assess model
model

prediction <- predict(classification_stack, model) #predict LU/LC
prediction

#############AOA
aoa<- aoa(classification_stack, model) #calculate aoa
aoa

#output <- stack(classification_stack, prediction, aoa$AOA, aoa$DI) #generate compound output
plotRGB(classification_stack, r=3, g=2, b=1, stretch="lin") #plot classification image as rgb
plot(prediction, col = topo.colors(4), main="Precition") #prediction
plot(aoa$AOA) #plot area of applicability
plot(aoa$DI) #plot dissimilarity index

writeRaster(aoa$AOA,'test_job/images/aoa_aoa',options=c('TFW=YES')) #export aoa
writeRaster(aoa$DI,'test_job/images/aoa_di',options=c('TFW=YES')) #export dissimilarity index
writeRaster(prediction,'test_job/images/classication',options=c('TFW=YES')) #export prediction

#############Sampling
