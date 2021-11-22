#Packages
setwd("~/GitHub/web-aoa/r")
# setwd("~/Desktop/WS21:22/Geosoft_2/Github/web-aoa/r") # Josi 
library(CAST) #CAST-Package for performing AOA
library(caret) #caret-Package for performing training
library(sp) #sp-Package for handlig spatial datasets
library(rgdal) #rgdal-Packge for performing spatial operations
library(sf) #sf-package for performing spatial operation on spheroids
library(rstac) #rstac for accessing STAC-Catalogue 
#install devtools and gdalUtils
#install.packages("devtools")
#devtools:::install_github("gearslaboratory/gdalUtils")
library(gdalUtils) #gdalUtil-Package for tranforming images
#install gdalcubes 
#install.packages("gdalcubes")
#install.packages(c("sf", "stars", "magick", "rmarkdown", "ncdf4", "Rcpp", "jsonlite", "RcppProgress", "rstac", "tmap"))
library(gdalcubes) #for creating data cubes (Mean over many Images to reduce cloud related noise)
#install.packages("rjson")
library(rjson)
#install.packages("ggplot2")
library(ggplot2)
#install.packages("mapview")
library(mapview)

#Parameters
job_name <- 'test'

samplePolygons <- read_sf('samplePolygons.geojson', crs = 4326) #sample Polygons (Dezimalgrad)
samplePolygon_bbox <- st_bbox(samplePolygons, crs = 4326) #(Dezimalgrad)

aoi <- read_sf('aoi.geojson', crs = 4326) #AOI (Dezimalgrad)
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI (Dezimalgrad)

resolution <- 50 #Resolutin of the Output-Image (Meter)
cloud_cover <- 15 #Threshold for Cloud-Cover in Sentinel-Images
t0 <- "2020-01-01"
t1 <- "2020-03-01"
timeframe <- paste(t0, '/', t1, sep ="")
assets = c("B01","B02","B03","B04","B05","B06", "B07","B08","B8A","B09","B11","SCL")
stac = stac("https://earth-search.aws.element84.com/v0")

#mapview(st_geometry(samplePolygons)) 
#mapview(st_geometry(aoi))
mapview(st_bbox(aoi))
mapview(st_bbox(samplePolygons))

####################Get Image-Data for AOI
items_aoi <- stac %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
items_aoi

collection_aoi = stac_image_collection(items_aoi$features, asset_names = assets, 
                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
collection_aoi

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
                                                 dt = "P1D", 
                                                 aggregation = "median", 
                                                 resampling = "average")

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

classication_image_name <- paste(job_name, '_classication_image', sep ="") 
cube_raster_aoi = raster_cube(collection_aoi, cube_view_aoi, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04")) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)")) %>%
  #plot(rgb = 3:1, zlim=c(0,1800))
  write_tif(
    dir = "~/GitHub/web-aoa/r/images",
    prefix = basename(tempfile(pattern = classication_image_name)),
    overviews = FALSE,
    COG = FALSE,
    rsmpl_overview = "nearest",
    creation_options = NULL,
    write_json_descr = FALSE,
    pack = NULL
  )

####################Get Image-Data for sample Polygons
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

training_image_name <- paste(job_name, '_training_image', sep ="") 
cube_raster_poly = raster_cube(collection_poly, cube_view_poly, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04")) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)")) %>%
  #plot(rgb = 3:1, zlim=c(0,1800)) 
  write_tif(
    dir = "~/GitHub/web-aoa/r/images",
    prefix = basename(tempfile(pattern = training_image_name)),
    overviews = FALSE,
    COG = FALSE,
    rsmpl_overview = "nearest",
    creation_options = NULL,
    write_json_descr = FALSE,
    pack = NULL
  )
##########################################non working part##################################################################
predictor <- #raster data

trainData <- extract(predictors,samplePolygons,df=TRUE)

model <- train(trainigData[,predictors], #extracted RGB-Values?
               trainigData$classes, #? Classes for LU/LC?
               method="rf", #Random Forrest
               importance=FALSE, #we do not need the most important predictors since we only have "one"
               ntree = 50, #Number of Trees
               trControl = trainControl(method="cv", number=3)) #Cross Validation (here 3-fold)

newPredictionData <-  #Sentinel2A Image the Area of Interest covers
classification <- predict(newPredictionData, model)
aoa <- aoa(newPredictionData, model)
aoaArea <- #Spatial extend of the Region in which the Model is not applicable
newSamples <- points(spsample(aoaArea, n = 1000, "regular"), pch = 3) #create sample points inside the area of the aoa (here regular but other methods are possible)


