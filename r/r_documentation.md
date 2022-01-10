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
  "name": "test",
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


# Data Aquisition
# Pre-Processing
# Model Training and Applicatiion
# Area of Applicability and Dissimilarity Index
# Output
# Final Notes 
