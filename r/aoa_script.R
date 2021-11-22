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

# Auch ganz nice
#install.packages("mapview")
library(mapview)

#aoi and polygons
samplePolygons <- read_sf('samplePolygons.geojson') #sample Polygons
aoi <- read_sf('aoi.geojson', crs = 4326) #AOI
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI
resolution <- 50 #Resolutin of the Output-Image
cloud_cover <- 15 #Threshold for Cloud-Cover in Sentinel-Images
t0 <- "2020-01-01"
t1 <- "2020-12-31"
timeframe <- paste(t0, '/', t1, sep ="")

#mapview(st_geometry(samplePolygons)) 
#mapview(st_geometry(aoi))
#mapview(st_bbox(aoi))

#gdalcubes
stac = stac("https://earth-search.aws.element84.com/v0")

items <- stac %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe,
              limit = 100) %>%
  post_request() 
items

assets = c("B01","B02","B03","B04","B05","B06", "B07","B08","B8A","B09","B11","SCL")
collection = stac_image_collection(items$features, asset_names = assets, 
                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
collection

#Transformation of the BBOX
targetSystem <- toString(items$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
aoi_transformed <- st_transform(aoi, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
aoi_bbox_tranformed <- st_bbox(aoi_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI


cube_view = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                 left = aoi_bbox_tranformed[1], 
                                                 right = aoi_bbox_tranformed[3],  
                                                 top = aoi_bbox_tranformed[4], 
                                                 bottom = aoi_bbox_tranformed[2]),
                                                 dx = resolution, 
                                                 dy = resolution, 
                                                 dt = "P1D", 
                                                 aggregation = "median", 
                                                 resampling = "average")

S2.mask = image_mask("SCL", values=c(3,8,9)) # clouds and cloud shadows

gdalcubes_options(threads = 8) #set Threads for raster cube 

cube_raster = raster_cube(collection, cube_view, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04")) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)")) 
  
(cube_raster %>%
  plot(rgb = 3:1, zlim=c(0,1800)) ) %>% system.time()


############################################################################################################
#///////
sentinal2aImage <- #Sentinel2A Image for the Region the Polygons are in
trainigData <- extract(sentinal2aImage, samplePolygons, df=TRUE) #Extract Training Samples
#////////

aoibbox <- st_bbox(aoi)
s <- stac("https://earth-search.aws.element84.com/v0") #link to STAC

q <- s %>% # same like below but withou "post_request()"
    stac_search(collections = "sentinel-s2-l2a-cogs",
                bbox = c(aoibbox["xmin"],aoibbox["ymin"],
                         aoibbox["xmax"],aoibbox["ymax"]),
                datetime = "2021-06-01/2021-06-30",
                limit = 500) 

q$params$query = "{\"eo:cloud_cover\": {\"lt\": 10}}" # limitates the cloud coverage 

items <- q %>% post_request()

col <- stac_image_collection(items$features, property_filter = function(x) {x[["eo:cloud_cover"]] < 20}) # limitates the cloud coverage 
S2.mask = image_mask("SCL", values=c(3,8,9)) # clouds and cloud shadows (?)

v = cube_view(srs = "EPSG:3857",  
              extent = list(t0 = "2021-06-01", t1 = "2021-06-30", 
                            left = aoibbox["xmin"]-1000, right = aoibbox["xmax"]+1000,  
                            top = aoibbox["ymax"]+1000, bottom = aoibbox["ymin"]-1000), 
                            dx = 20, dy = 20, dt = "P1D", aggregation = "mean", resampling = "near") #dt = temporal extend

c = raster_cube(col, v) %>%
            select_bands(c("B02","B03","B04")) %>%
            reduce_time(c("median(B02)", "median(B03)", "median(B04)")) %>%
            plot(rgb = 3:1, zlim=c(0,1500)) %>% system.time() # Funktioniert noch nicht 

#Retrieve Images in BBox
# items = s %>% #(may need to bee transformed?)
  # stac_search(collections = "sentinel-s2-l2a-cogs",
    #           bbox = c(aoibbox["xmin"],aoibbox["ymin"],
    #                    aoibbox["xmax"],aoibbox["ymax"]), 
    #           datetime = "2021-06-01/2021-06-30",
    #           limit = 500) %>%
  # post_request() 

#Build Collection
collection = stac_image_collection(items$features)

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


