# Basics
The aim of the software is to allow users to easiely perform land-use / land-cover classifications based on Sentinel-2A EO-data using machine learning procedures and acess the precision and quality of the results. The assessment can be performed using the Area of Applicability (AoA) (link to paper) and the dissimilarity index (DI). The AOA allows allows for some statements to be made as to the applicability of the trained model to the area of interest. The DI describes how similar the area of interest and the area (its feratures) used for the training of the applyed model are. The implementtation of the processing compinend of the software is implemnted using the language R. The user can decide if a preexisting model should be used or train a new model. 

# Dependencies
1. CAST (https://cran.r-project.org/web/packages/CAST/index.html)
2. caret (httpscran sp://cran.r-project.org/web/packages/caret/index.html)
3. sp (https://cran.r-project.org/web/packages/sp/index.html)
4. rgdal (https://cran.r-project.org/web/packages/rgdal/index.html)
5. sf (https://cran.uni-muenster.de/web/packages/sf/index.html)
6. rstac (https://cran.r-project.org/web/packages/rstac/index.htmlrjson)
7. rjson (https://mran.microsoft.com/snapshot/2021-04-12/web/packages/rjson/index.html)
8. raster (https://mran.microsoft.com/web/packages/raster/index.html)
9. gdalcubes (https://cran.r-project.org/web/packages/gdalcubes/index.html)
10. kernlab (https://cran.r-project.org/web/packages/kernlab/index.html)

# Input
The frontend of the software delivers a set of input informations and stores the in a dedicated job folder. The folder contains: 
-> a job_param.json which contains a multitude of parameters for the processing
-> an area of interest in .geojson format which defines the geographic area for which the classifation will be performed
-> a set of training data if a new model will be trained or the pretrained model. 
The job_param.json is structures as follows:

```
{
  "name": "job_id",
  "use_lookup": "true",
  "resolution": 10,
  "cloud_cover": 15,
  "start_timestamp": "2020-01-01",
  "end_timestamp": "2020-12-01",
  "response": "class",
  "samples": "samplePolygons.gpkg",
  "aoi": "aoi.gpkg",
  "sampling_strategy": "regular",
  "obj_id": "PID",
  "use_pretrained_model": "false",
  "model": "model.rds",
  "procedure":  {
	"selected": "rf",
	"random_forrest": {
		"n_tree": 800,
		"cross_validation_folds": 5
	}
  }
}
```
A job gets a unique id assigned to it which is stored in the ```name``` parameter. 

The boolean parameter ```use_lookup``` controlls the usage of a lookup-table for the resolution of the output raster datasets. If it is set to  ```false``` the user defined value of the parameter  ```resolution``` will be used. If it is set to  ```true``` the resolution is set by the script itself based on the following formula:

![foxdemo](https://github.com/digital-peaks/web-aoa/blob/r-documentation/r/documentation_gfx/resolution_formula.PNG)

If the resolution is determined by the script the resolution will be set to a value that each image contains approximatly 10000pixels to ensure fast processing. 

The parameter ```cloud_cover``` determines which percentage of the Sentinal-2A images is allowed to be coverd by clouds. The paramter is user defines.

The parameter-pair ```start_timestamp``` and ```end_timestamp``` define the timeframe form which Sentinel-2A images are retrieved and is also user defined.

The paramter ```response``` is only needed when a new model is to be trained. It defines the attribute in the training data which describes the classes into which the Sentinel-2A images will be segmented (the land-use / land-cover classes)

The parameter ```samples``` is only need when a new model is to be trained. It contains the name of the .geojson or .gpkg
file with the training datsets. These are commonly polygonal but points could be used as well. 

The parameter ```aoi``` contains the name of the .geojson or .gpkg
file with the area of interest. 

The parameter ```sampling_strategy``` defines which sampling strategy should be used to make suggestions for potential locations for which additional traing datsets could be retreived in order to optimize the results. Possible value are: ```random```, ```regular```, ```stratified```, ```nonaligned```, ```hexogonal```, ```clustered```, ```Fibonacci```

The parameter ```obj_id``` defines the primary key of the attribute table of the training dataset.

The boolean parameter ```use_pretrained_model``` is set to ```true``` if the user provides a pretrained model or to ```false``` if the user decides to train a new model based on user provided training datasets.

The parameter ```model``` defines the name of the user provided model in .rds format. The parameter is only neccesarry if a pretrained model is used.

The ```procedure``` block defines the machine learning precedure. The model cam be traind using a random forrest or an support vector machine. The parameter ```selected``` can either be set to ```rf``` foor random forrest or ```svmradial``` for support vectoc machine.

Parameters for the random forrest are ```n_tree``` which defines the size of the random forrest and ```cross_validation_folds``` which defines the ammount of cross validation folds to be performed to access the precision and accurcy of the trained model. 

```
"random_forrest": {
		"n_tree": 800,
		"cross_validation_folds": 5
	}
```

Paramters for the support vector machine are ```sigma```, ```c``` and ```cross_validation_folds``` which defines the ammount of cross validation folds to be performed to access the precision and accurcy of the trained model. 

```
"support_vector_machine": {
		"sigma": 0.004385965,
		"c": 1,
		"cross_validation_folds": 5
	}
```

# Data Aquisition
# Pre-Processing
# Model Training and Applicatiion
# Area of Applicability and Dissimilarity Index
# Output
# Final Notes 
