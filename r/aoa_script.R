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
library(testthat) #testthat for tests
print("--> libraries imported")

#test working direktory
test_that('working direktory test', {
  expect_type(workingDir, "character")
  expect_equal(workingDir, "/app/jobs")
  print("--> working directory passed testing")
})

args = commandArgs(trailingOnly=TRUE) #read passed arguments 
job_name <- args[1] #name of the job
#job_name <- "test"
print(paste("--> Get job id from args:", job_name))


#Result JSON
result <- vector(mode="list", length=3) #initialize result JSON

#job_name <- "test" #for local tests
job_path <- paste(workingDir, job_name, sep="/") #path to the job folder

print(paste("--> Job path: ", job_path, sep=""))

#Parameters
parameters <- fromJSON(file = paste(job_path, "/", "job_param.json", sep="")) #read in job parameters

#test parameters
test_that('parameters readin test', {
  expect_type(parameters, "list")
  expect_equal(parameters$use_lookup == "true" ||parameters$use_lookup == "false", TRUE)
  expect_equal(parameters$use_pretrained_model == "true" || parameters$use_pretrained_model == "false", TRUE)
  expect_equal(parameters$cloud_cover >= 0 || parameters$cloud_cover <= 100, TRUE)
  expect_equal(parameters$resolution > 0, TRUE)
  expect_equal(parameters$sampling_strategy %in% c("regular", "stratified", "nonaligned", "clusterd", "Fibonacci"), TRUE)
  print("--> parameters passed testing")
})

print("--> parameters read")

if(parameters$use_pretrained_model == "false") { #checks if a pretrained model should be used
  
  #test sample file
  test_that('samples file test', {
    expect_equal(file.exists(paste(job_path, "/", parameters$samples, sep="")), TRUE)
    print("--> sample file passed testing")
  })
  
  samplePolygons_path <- paste(job_path, "/", parameters$samples, sep ="") #path to the samples
  samplePolygons <- read_sf(samplePolygons_path, crs = 4326) #sample Polygons (Dezimalgrad)
  samplePolygon_bbox <- st_bbox(samplePolygons, crs = 4326) #(Dezimalgrad)
  
  #test samples
  test_that('samples readin test', {
    expect_equal(parameters$response %in% 	colnames(samplePolygons), TRUE)
    expect_equal(parameters$obj_id %in% 	colnames(samplePolygons), TRUE)
    print("--> samples passed testing")
  })
  
  print("--> new model will be trained")
} else {
  tryCatch({ 
    test_that('model file test', {
      expect_equal(file.exists(paste(job_path, "/", parameters$model, sep="")), TRUE)
      print("--> model file passed testing")
    })
    
    model_path <- paste(job_path, "/", parameters$model, sep ="") #path to the model
    model <- readRDS(model_path) #ingest .rds file
    
    #test model
    test_that('pretrained model readin test', {
      expect_type(model, "list")
      expect_equal()
    })
    
    model_bands <- 	colnames(model$ptype) #retrieve predictors from pretrained model
    available_bands = c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL", "NDVI", "BSI", "BAEI") #avaiable predictors
    if(length(model$ptype) > length(available_bands)) { #if pretrained model employs too many predictors
      stop()
    }
    for(i in 1:length(model_bands)){ #if pretrained model employs predictors not available in Sentinel-2A imagery
      if(model_bands[i]%in%available_bands == FALSE) { #if model contains predictors not present in the Sentinel-2A imagery
        stop() #stop processing
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

#test aoi file
test_that('aoi file test', {
  expect_equal(file.exists(paste(job_path, "/", parameters$aoi, sep="")), TRUE)
  print("--> aoi file passed testing")
})

aoi_path <- paste(job_path, "/", parameters$aoi, sep ="") #path to the aoi
aoi <- read_sf(aoi_path, crs = 4326) #AOI (Dezimalgrad)
aoi_bbox <- st_bbox(aoi, crs = 4326) #BBox of AOI (Dezimalgrad)
print("--> AOI and AFT set")

#select resolution
if(parameters$use_lookup == "true") { #if look-table should be used to find optimal resolution
  aoi_area <- st_area(aoi) #calculate area of the aoi
  if(parameters$use_pretrained_model == "false") { #if samples are ingestable
    sample_area <- sum(st_area(samplePolygons)) #calculate area of the samples
    optimal_resolution <- as.numeric(sqrt(((aoi_area+sample_area)/2)/10000)) #calculate optimal resolution for image with 10000 pixels
  } else { 
    optimal_resolution <- sqrt(aoi_area/10000) #function for calculating the optimal resolution for a 10000 pixel image
  }
  
  #test optimal resolution
  test_that('optimal resolution test', {
    expect_equal(optimal_resolution > 0, TRUE)
    print("--> optimal resolution passed testing")
  })
  
  #resolution lookup table
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

#Test stac
test_that('stac init test', {
  expect_type(stac, "list")
  expect_equal(stac$base_url == "https://earth-search.aws.element84.com/v0", TRUE)
})

print("--> stac initialized")
print("--> basic processing setup done")

#############Get Image-Data for AOI
items_aoi <- stac %>% #retrieve sentinel bands for area of interest
  stac_search(collections = "sentinel-s2-l2a-cogs", #search for cloud optimized images
              bbox = c(aoi_bbox[1],aoi_bbox[2],aoi_bbox[3],aoi_bbox[4]), #Anfrage mit AOI-BBox
              datetime = timeframe, #set timeframe
              limit = 100) %>% #limit results to 100 datasets
  post_request() #post the request
print("--> stac items for AOI retrieved")
items_aoi

#Test items
test_that('items for aoi test', {
  expect_type(items_aoi, "list")
  expect_equal(items_aoi$numberMatched > 0, TRUE)
  expect_equal(items_aoi$numberReturned > 0, TRUE)
  expect_equal(items_aoi$type, "FeatureCollection")
})

tryCatch({ #try to build a collection from items
  collection_aoi =  stac_image_collection(items_aoi$features, asset_names = assets, 
                                          property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
}, warning = function(w) {
  print("Warning!")
}, error = function(e) {
  print("Error!")
}, finally = {
  collection_aoi =  stac_image_collection(items_aoi$features, asset_names = assets, #try to build a collection from items
                                          property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
  print("--> image collection for AOI created")
})

#Test collection
test_that('collection for aoi test', {
  expect_type(collection_aoi, "externalptr")
})

targetSystem <- toString(items_aoi$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images

#Test target crs
test_that('target crs test', {
  expect_type(targetSystem, "character")
  expect_equal(nchar(targetSystem) == 4 || nchar(targetSystem) == 5, TRUE)
})

print("--> target crs retrieved")
targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
aoi_transformed <- st_transform(aoi, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
print("--> AOI tranformed to target crs")
aoi_bbox_tranformed <- st_bbox(aoi_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI
print("--> AOI bbox tranformed to target crs")

#build a cube view object
cube_view_aoi = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                             left = aoi_bbox_tranformed[1], #set b-box
                                                             right = aoi_bbox_tranformed[3],  
                                                             top = aoi_bbox_tranformed[4], 
                                                             bottom = aoi_bbox_tranformed[2]),
                                                             dx = resolution_aoi, #set resolution
                                                             dy = resolution_aoi, #set resolution
                                                             dt = "P1D", #intervall in which images are taken from each time slice
                                                             aggregation = "median", #set aggregation method
                                                             resampling = "average") #set resampling

#Test cube view
test_that('cube view test', {
  expect_type(cube_view_aoi, "list")
  expect_equal(cube_view_aoi$aggregation == "median", TRUE)
  expect_equal(cube_view_aoi$resampling == "average", TRUE)
  expect_equal(cube_view_aoi$time$t0 == t0 && cube_view_aoi$time$t1 == t1, TRUE)
})

("--> AOI cube view created")

S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows
print("--> cloud mask created")

gdalcubes_options(threads = 4) #set Threads for raster cube
print("--> gdalcubes threads set to 4")
classification_image_name <- paste('classification_image', sep ="")  #set classifiication image name
#build a raster_cube object
cube_raster_aoi = raster_cube(collection_aoi, cube_view_aoi, mask = S2.mask) %>%
  select_bands(c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","SCL")) %>% #B, G, R, NIR, SWIR
  apply_pixel("(B08-B04)/(B08+B04)", "NDVI", keep_bands = TRUE) %>% #NDVI - Normalized Difference Vegetation Index
  apply_pixel("(B11+B04)-(B08+B02)/(B11+B04)+(B08+B02)", "BSI", keep_bands = TRUE) %>% #Bare Soil Index
  apply_pixel("(B04 + 0.3)/(B03+B11)", "BAEI", keep_bands = TRUE) %>% #Built-up Area Extraction Index
  reduce_time(c("median(B01)", #reduce timeseries
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
  write_tif( #write result as .tif
    dir = job_path, #to the job folder
    prefix = basename(classification_image_name), #set filename
    overviews = FALSE, #build no overviews
    COG = TRUE, #write a cloud optimzed image
    rsmpl_overview = "nearest" #set resamplling method
  )
filename <- paste(job_path, "/", "classification_image", t0, ".tif", sep="") #set filename
file <- filename #find written file
file.rename(filename, paste(job_path, "/", "classification_image.tif", sep="")) #rename written file

#test classification image
test_that('classification image test', {
  expect_equal(file.exists(paste(job_path, "/", "classification_image", ".tif", sep="")), TRUE)
})

print("--> AOI raster cube created")
print("--> classification image written")

#############Get Image-Data for sample Polygons
if(parameters$use_pretrained_model == "false") { #if a pretrained model is used to trainig data must be retrieved
  items_poly <- stac %>% #retrieve sentinel bands for area for training
    stac_search(collections = "sentinel-s2-l2a-cogs", #search for cloud optimized images
                bbox = c(samplePolygon_bbox[1], samplePolygon_bbox[2], samplePolygon_bbox[3], samplePolygon_bbox[4]),
                datetime = timeframe, #set timeframe
                limit = 100) %>% #set max results to 100 items
    post_request() #post request
  print("--> stac items for AFT retrieved")
  items_poly
  
  #Test items
  test_that('items for training test', {
    expect_type(items_poly, "list")
    expect_equal(items_poly$numberMatched > 0, TRUE)
    expect_equal(items_poly$numberReturned > 0, TRUE)
    expect_equal(items_poly$type, "FeatureCollection")
  })
  
  tryCatch({ #try to build a collection from items
    collection_poly = stac_image_collection(items_poly$features, asset_names = assets, 
                                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
  }, warning = function(w) {
    print("Warning!")
  }, error = function(e) {
    print("Error!")
  }, finally = {
    collection_poly = stac_image_collection(items_poly$features, asset_names = assets, 
                                            property_filter = function(x) {x[["eo:cloud_cover"]] < cloud_cover})
    
    #Test collection
    test_that('collection for training test', {
      expect_type(collection_poly, "externalptr")
    })
    
    print("--> image collection for AFT created")
  })
  
  targetSystem <- toString(items_poly$features[[1]]$properties$`proj:epsg`) #read EPSG-Code of Sentinel-Images
  print("--> target crs retrieved")
  targetString <- paste('EPSG:', targetSystem) #transform EPSG-Code to String
  
  #Test target crs
  test_that('target crs test', {
    expect_type(targetSystem, "character")
    expect_equal(nchar(targetSystem) == 4 || nchar(targetSystem) == 5, TRUE)
  })
  
  samplePolygons_transformed <- st_transform(samplePolygons, as.numeric(targetSystem)) #transform AOI to Sentinel-Image EPSG
  print("--> AFT tranformed to target crs")
  samplePolygons_bbox_tranformed <- st_bbox(samplePolygons_transformed, crs = as.numeric(targetSystem)) #derive BBox of transformed AOI
  print("--> AFT bbox tranformed to target crs")
  
  cube_view_poly = cube_view(srs = targetString,  extent = list(t0 = t0, t1 = t1,
                                                                left = samplePolygons_bbox_tranformed[1], #set b-box
                                                                right = samplePolygons_bbox_tranformed[3],  
                                                                top = samplePolygons_bbox_tranformed[4], 
                                                                bottom = samplePolygons_bbox_tranformed[2]),
                                                                dx = resolution_training, #set resolution
                                                                dy = resolution_training, #set resolution
                                                                dt = "P1D", #intervall in which images are taken from each time slice
                                                                aggregation = "median", #set aggregation method
                                                                resampling = "average") #set resampling 
  print("--> AFT cube view created")
  
  #Test cube view
  test_that('cube view test', {
    expect_type(cube_view_poly, "list")
    expect_equal(cube_view_poly$aggregation == "median", TRUE)
    expect_equal(cube_view_poly$resampling == "average", TRUE)
    expect_equal(cube_view_poly$time$t0 == t0 && cube_view_aoi$time$t1 == t1, TRUE)
  })
  
  S2.mask = image_mask("SCL", values=c(3,8,9)) #clouds and cloud shadows
  print("--> cloud mask created")
  
  gdalcubes_options(threads = 4) #set Threads for raster cube 
  print("--> gdalcubes threads set to 4")
  
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
    write_tif( #write result as .tif
      dir = job_path, #to jon folder
      prefix = basename(training_image_name), #set filename
      overviews = FALSE, #build no overviews
      COG = TRUE, #write a cloud optimzed image
      rsmpl_overview = "nearest" #set seasmpling method
    )
  filename <- paste(job_path, "/", "training_image", t0, ".tif", sep="") #set filename
  file <- filename #find written file
  file.rename(filename, paste(job_path, "/", "training_image.tif", sep="")) #rename written file
  
  #test training image
  test_that('classification image test', {
    expect_equal(file.exists(paste(job_path, "/", "training_image", ".tif", sep="")), TRUE)
  })
  
  print("--> AFT raster cube created")
  print("--> training image written")
  print("--> raster data retrieval done")
}

#############Training
if(parameters$use_pretrained_model == "false") { #if a pretrained model is used no training stack must be created
  training_stack_path <- paste(job_path, "/", training_image_name, ".tif", sep="") #set path to training datasets
  training_stack <- stack(training_stack_path) #load training image as stack
  print("--> training stac created")
  names(training_stack)<-c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","NDVI", "BSI", "BAEI") #rename bands
  print("--> band names assigned")
  training_stack 
  
  #test training stac
  test_that('training stac test', {
    expect_type(training_stack, "S4")
    expect_equal(training_stack@layers[[1]]@data@names, "B01")
    expect_equal(training_stack@layers[[2]]@data@names, "B02")
    expect_equal(training_stack@layers[[3]]@data@names, "B03")
    expect_equal(training_stack@layers[[4]]@data@names, "B04")
    expect_equal(training_stack@layers[[5]]@data@names, "B05")
    expect_equal(training_stack@layers[[6]]@data@names, "B06")
    expect_equal(training_stack@layers[[7]]@data@names, "B07")
    expect_equal(training_stack@layers[[8]]@data@names, "B08")
    expect_equal(training_stack@layers[[9]]@data@names, "B8A")
    expect_equal(training_stack@layers[[10]]@data@names, "B09")
    expect_equal(training_stack@layers[[11]]@data@names, "B11")
    expect_equal(training_stack@layers[[12]]@data@names, "B12")
  })
}

classification_stack_path <- paste(job_path, "/", classification_image_name, ".tif", sep="") #set path to classification datasets
classification_stack <- stack(classification_stack_path) #load classification image 
print("--> classification stac created")
names(classification_stack)<-c("B01","B02","B03","B04","B05","B06","B07","B08","B8A","B09","B11","B12","NDVI", "BSI", "BAEI") #rename bands
print("--> band names assigned")
classification_stack 

#test classification stac
test_that('classification stac test', {
  expect_type(classification_stack , "S4")
  expect_equal(classification_stack@layers[[1]]@data@names, "B01")
  expect_equal(classification_stack@layers[[2]]@data@names, "B02")
  expect_equal(classification_stack@layers[[3]]@data@names, "B03")
  expect_equal(classification_stack@layers[[4]]@data@names, "B04")
  expect_equal(classification_stack@layers[[5]]@data@names, "B05")
  expect_equal(classification_stack@layers[[6]]@data@names, "B06")
  expect_equal(classification_stack@layers[[7]]@data@names, "B07")
  expect_equal(classification_stack@layers[[8]]@data@names, "B08")
  expect_equal(classification_stack@layers[[9]]@data@names, "B8A")
  expect_equal(classification_stack@layers[[10]]@data@names, "B09")
  expect_equal(classification_stack@layers[[11]]@data@names, "B11")
  expect_equal(classification_stack@layers[[12]]@data@names, "B12")
})

if(parameters$use_pretrained_model == "false") { #train model ig no pretrained model is provided
  training_data <- extract(training_stack, samplePolygons, df='TRUE') #extract training data from image via polygons
  print("--> training data extracted from raster")
  training_data <- merge(training_data, samplePolygons, by.x="ID", by.y=key) #enrich traing data with corresponding classes
  print("--> response assigned to training data")
  
  #test training data
  test_that('training data test', {
    expect_type(training_data , "list")
    expect_equal("ID" %in% colnames(training_data), TRUE)
    expect_equal(response %in% colnames(training_data), TRUE)
    expect_equal(nrow(training_data) > 0, TRUE)
  })

  predictors <- names(training_stack) #set predictor variables
  
  print("--> predictors set")
  response <- response #set response value
  print("--> response set")
  if("random_forrest" %in% names(parameters)) { #if random forrest is selected
    print("--> random forrest will be trained")
    model <- train(training_data[,predictors], training_data$class, #train model
                    method="rf", tuneGrid=data.frame("mtry"= length(predictors)/2), #with random forrest 
                    importance=TRUE, #store importance of predictors
                    ntree=parameters$random_forrest$n_tree, #max number of trees
                    trControl=trainControl(method="cv", number=parameters$random_forrest$cross_validation_folds)) #perform cross validation to assess model
    print("--> model trained")
    model
  } else if("support_vector_machine" %in% names(parameters)) { #if support vector machine is selected
    print("--> support vector machine will be trained")
    model <- train(training_data[,predictors], training_data$class, #train model
                   method="svmRadial", tuneGrid=expand.grid(.C = parameters$support_vector_machine$c,.sigma= parameters$support_vector_machine$sigma), #with support vector machine
                   importance=TRUE, #store importance of predictors
                   trControl=trainControl(method="cv", number=parameters$support_vector_machine$cross_validation_folds)) #perform cross validation to assess model
    print("--> model trained")
    model
  } else {
    print("--> No machine learning procedure was provided")
    stop() # Stop script
  }
  model_path <- paste(job_path, "/", "model.rds", sep="") #set model path
  saveRDS(model, model_path) #store model as .rds
  
  #test model
  test_that('model test', {
    expect_equal(file.exists(paste(job_path, "/", "model", ".rds", sep="")), TRUE)
  })
  
  print("--> model exported")
  } else { #use pretrained model if one is provided
    model_path <- paste(job_path, "/", parameters$model, sep ="") #path to the samples
    model <- readRDS(model_path) #read .rds from model path
    print("--> model imported")
}

prediction <- predict(classification_stack, model) #predict LU/LC
print("--> classification done")
prediction

#test prediction
test_that('prediction test', {
  expect_type(prediction , "S4")
  expect_equal(setequal(c(prediction@data@attributes[[1]]$value), training_data$class) , TRUE)
})

aoa<- aoa(classification_stack, model) #calculate aoa
print("--> AOA calculation done done")
aoa

#test aoa
test_that('aoa test', {
  expect_type(aoa , "S4")
  expect_equal(aoa@layers[[1]]@data@names == "DI", TRUE)
  expect_equal(aoa@layers[[2]]@data@names == "AOA", TRUE)
})

print("--> geostatistical processing done")

#############Export
aoa_path <- paste(job_path, "/", "aoa_aoa", sep="") #set area of applicability path
di_path <- paste(job_path, "/", "aoa_di", sep="") #set dissimilarity index path
prediction_path <- paste(job_path, "/", "pred", sep="") #set prediction path
geojson_path <- paste(job_path, "/", "suggestion.geojson", sep="") #set geojon path for suggested sampling locations
result_path <- paste(job_path, "/", "result.json", sep="") #set result path for result JSON
writeRaster(aoa$AOA, aoa_path, format = 'GTiff', options=c('TFW=YES')) #export aoa
print("--> aoa image written")
writeRaster(aoa$DI, di_path, format = 'GTiff',  options=c('TFW=YES')) #export dissimilarity index
print("--> di image written")
writeRaster(prediction, prediction_path, format = 'GTiff', options=c('TFW=YES')) #export prediction
print("--> prediction image written")
result[[1]] <- model$levels #store classes
result[[2]] <- model$results$Accuracy #store accuracy
result[[3]] <- model$results$Kappa #store kappa
exportJson <- toJSON(result) #covert to JSON
write(exportJson, result_path) #export result JSON

#test output
test_that('output test', {
  expect_equal(file.exists(paste(job_path, "/", "aoa_aoa", ".tif", sep="")), TRUE) 
  expect_equal(file.exists(paste(job_path, "/", "aoa_di", ".tif", sep="")), TRUE)  
  expect_equal(file.exists(paste(job_path, "/", "pred", ".tif", sep="")), TRUE)
  expect_equal(file.exists(paste(job_path, "/", "result", ".json", sep="")), TRUE)  
  print("--> outputs passed testing")
})

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

#test sampling locations
test_that('sampling locations test', {
  expect_equal(file.exists(paste(job_path, "/", "suggestion", ".geojson", sep="")), TRUE) 
})

print("--> processing done")
end_time <- Sys.time() #set end time 
overall_time <- paste("--> processing time: ", (end_time - start_time), " Minutes", sep="") #culculate overall processing time
print(overall_time)

