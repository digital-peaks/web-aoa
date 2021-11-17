#Packages
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
library(gdalcubes) #for creating data cubes (Mean over many Images to reduce cloud related noise)

#install.packages("rjson")
library(rjson)

#install.packages("ggplot2")
library(ggplot2)
##############################################################################################
samplePolygons <- read_sf('samplePolygons.geojson')
plot(st_geometry(samplePolygons))

aoi <- read_sf('aoi.geojson')
plot(st_geometry(aoi))



sentinal2aImage <- #Sentinel2A Image for the Region the Polygons are in
trainigData <- extract(sentinal2aImage, samplePolygons, df=TRUE) #Extract Training Samples

aoibbox <- #BBox of the Area of Interest
stac <- stac("https://earth-search.aws.element84.com/v0") #link to STAC

#Retrieve Images in BBox
items = s |> #(may need to bee transformed?)
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(bbox_wgs84["xmin"],bbox_wgs84["ymin"],
                       bbox_wgs84["xmax"],bbox_wgs84["ymax"]), 
              datetime = "2018-06-01/2018-06-30",
              limit = 500) |>
  post_request() 

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
