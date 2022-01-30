# Basics
The aim of the software is to allow users to easily perform land-use/land-cover classifications based on Sentinel-2A EO-data using machine learning procedures and assess the precision and quality of the results. The assessment can be performed using the Area of Applicability (AoA) (link to paper) and the dissimilarity index (DI). The AOA allows for some statements to be made as to the applicability of the trained model to the area of interest. The DI describes how similar the area of interest and the area (its features) used for the training of the applied model are. The implementation of the processing compinend of the software is implemented using the language R. The user can decide if a preexisting model should be used or train a new model.

# Dependencies
1. CAST (https://cran.r-project.org/web/packages/CAST/index.html) / License: GPL-2, GPL-3
2. caret (https://mran.microsoft.com/snapshot/2017-02-04/web/packages/caret/index.html) / License: GPL-2, GPL-3
3. sp (https://cran.r-project.org/web/packages/sp/index.html) / License: GPL-2, GPL-3
4. rgdal (https://cran.r-project.org/web/packages/rgdal/index.html) / License: GPL-2, GPL-3
5. sf (https://cran.uni-muenster.de/web/packages/sf/index.html) / License: GPL-2, MIT
6. rstac (https://cran.r-project.org/web/packages/rstac/index.html) / License: MIT
7. rjson (https://mran.microsoft.com/snapshot/2021-04-12/web/packages/rjson/index.html) / License: GPL-2
8. raster (https://mran.microsoft.com/web/packages/raster/index.html) / License: GPL-3
9. gdalcubes (https://cran.r-project.org/web/packages/gdalcubes/index.html) / License: MIT
10. kernlab (https://cran.r-project.org/web/packages/kernlab/index.html) / License: GPL-2
11. testthat (https://mran.microsoft.com/web/packages/testthat/index.html) / License: MIT

# Input
The frontend of the software delivers a set of input informations and stores the in a dedicated job folder. The folder contains:
-> a job_param.json which contains a multitude of parameters for the processing
-> an area of interest in .geojson format which defines the geographic area for which the classification will be performed
-> a set of training data if a new model is trained or a pretrained model
The job_param.json is structures as follows:

```
{
  "name": "job_id",
  "use_lookup": "true",
  "resolution": 10,
  "cloud_cover": 15,
  "start_timestamp": "2020-01-01",
  "end_timestamp": "2020-12-01",
  "samples_class": "class",
  "samples": "samplePolygons.gpkg",
  "aoi": "aoi.gpkg",
  "sampling_strategy": "regular",
  "obj_id": "PID",
  "use_pretrained_model": "false",
  "model": "model.rds",
  "random_forrest": {
      "n_tree": 800,
      "cross_validation_folds": 5
  }
}
```
A job gets a unique id assigned to it which is stored in the ```name``` parameter.

The boolean parameter ```use_lookup``` controlls the usage of a lookup-table for the resolution of the output raster datasets. If it is set to ```false``` the user defined value of the parameter ```resolution``` is used. If it is set to ```true``` the resolution is set by the script itself based on the following formula:

![foxdemo](https://github.com/digital-peaks/web-aoa/blob/main/docs/documentation_gfx/resolution_formula.PNG)

If the resolution is determined by the script, the resolution is set to a value that each image contains approximately 10000 pixels to ensure fast processing.

The parameter ```cloud_cover``` determines which percentage of the Sentinal-2A images is allowed to be covered by clouds. The parameter is user defines.

The parameter-pair ```start_timestamp``` and ```end_timestamp``` define the timeframe form which Sentinel-2A images are retrieved and is also user defined.

The parameter ```response``` is only needed when a new model is to be trained. It defines the attribute in the training data which describes the classes into which the Sentinel-2A images is segmented (the land-use / land-cover classes).

The parameter ```samples``` is only need when a new model is to be trained. It contains the name of the .geojson or .gpkg
file with the training datasets. These are commonly polygonal but points could be used as well. Sample datasets must conform to the WGS coordinate system (EPSG 4326).

The parameter ```aoi``` contains the name of the .geojson or .gpkg
file with the area of interest. AOI dataset must conform to the WGS coordinate system (EPSG 4326).

The parameter ```sampling_strategy``` defines which sampling strategy should be used to make suggestions for potential locations for which additional training datasets could be retrieved in order to optimize the results. Possible value are: ```random```, ```regular```, ```stratified```, ```nonaligned```, ```hexogonal```, ```clustered```, ```Fibonacci```

The parameter ```obj_id``` defines the primary key of the attribute table of the training dataset.

The boolean parameter ```use_pretrained_model``` is set to ```true``` if the user provides a pretrained model or to ```false``` if the user decides to train a new model based on the user provided training datasets.

The parameter ```model``` defines the name of the user provided model in .rds format. The parameter is only nescesarry if a pretrained model is used.

The model cam be trained using a random forest or a support vector machine. 
Parameters for the random forest are ```n_tree``` which defines the size of the random forest and ```cross_validation_folds``` which defines the amount of cross-validation folds to be performed to access the precision and accuracy of the trained model.

```
"random_forrest": {
  "n_tree": 800,
  "cross_validation_folds": 5
}
```

Parameters for the support vector machine are ```sigma```, ```c``` and ```cross_validation_folds``` which defines the amount of cross-validation folds to be performed to access the precision and accuracy of the trained model.

```
"support_vector_machine": {
  "sigma": 0.004385965,
  "c": 1,
  "cross_validation_folds": 5
}
```

If a pretrained model is provided it get validated. It is checked if it only uses the bands provided by Sentinel-2A imagery as predictors.
If all parameters are valid and all nessesary files are present in the corresponding job folder the script beginns retrieveing the Sentinel-2A imagery.

# Data acquisition
The retrieval of Sentinel-2A imagery is performed using a spatio temporal asset catalog (STAC) and its API. The script retrieves the Sentinel-2A imagery from https://earth-search.aws.element84.com/v0. Images are retrieved from the ```sentinel-s2-l2a-cogs``` collection which contains Sentinel-2A images in a cloud optimized form. If datasets are found which comply to the criteria set in the job_param.json (timeframe, area of interest, cloud cover, etc.) a collection of these items is created.

# Pre-processing
Spatio-temporal datacubes are used to preprocess the Sentel-2A imagery. A cube view object defines the spatial and temporal extends, sets the output resolution and the output crs. From this cube view object a raster cube can be created. All images in the collection are processed in this datacube. Bands ```B01```, ```B02```, ```B03```, ```B04```, ```B05```, ```B06```, ```B07```, ```B08```, ```B08A```, ```B09```, ```B11``` and ```B12``` are selected from each Sentinel-2A image in the time series. Additionally some Indices are calculated with the aim to enhance the land-use/land-cover classification. The indices chosen are: the Normalized Difference Vegetation Index (NDVI), the Bare SOil Index (BSI) and the Build-up Area Extraction Index (BAEI) given by:

![foxdemo](https://github.com/digital-peaks/web-aoa/blob/main/docs/documentation_gfx/indices.PNG)

The model can employ the Sentinal-2A bands and the mentioned indices as predictors. 
The time series now needs to be reduces to only one image. The median method is chosen to reduce the time series since the median is robust toward outliers. This is done in order to reduce the effect of remaining cloud coverage. Finally, the resulting, cloud-free image is written as a cloud-optimized .tif to the job folder. This workflow is always performed for the area of interest. If a new model is trained the process of image retrieval and preprocessing is repeated for the area in which the training datasets are located.

# Model training
The next step is to train a new model with the retrieved data and apply it or to apply the provided pretrained model. If a new model is to be trained the values for each band of the image corresponding to the training dataset are extracted if the pixel is inside a polygon or corresponds to a point of the training dataset. Each of the extracted pixels get the class of corresponding training dataset object assigned to it. The predictors for the model are set to the bands and indices present in the image. The model is then trained using a random forest or a support vector machine depending on the users choice. The resulting model is stored as a .rds in the job folder.

# Model application
The prediction (land-use/land-cover classification) is applied using the newly trained or pretrained model on the Sentinel-2A image corresponding to the area of interest. The resulting prediction is stored as a .tif in the job folder.
With the model and the resulting prediction, the AOA and the DI can be derived. Both are stored as .tif in the job folder. In order to give the user some suggestions on how he/she can enhance the model performance some possible locations for additional training datasets are derived as well. These are created in areas where the model does not perform in a way which is viewed as acceptable (outside the AOA). This is done according to the chosen sampling method. The resulting points are stored a .geojson in the job folder.

# Output
The result of the script are various files:
1. Sentinel-2A image of the area of interest in the chosen resolution as a .tif (if no pretrained model is provided an additional image for the area of the training datasets is stored as well)
2. newly trained or pretrained model as .rds
3. prediction (land-use/land-cover classification) as a .tif
4. Area of Applicability as a .tif
5. Dissimilarity Index as a .tif
6. suggested additional sampling locations as .geojson
7. result .json containing the accuracy and kappa index of the model and the descriptive names of the land-use/land-cover classes

