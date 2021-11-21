#install.packages(c("sf", "stars", "magick", "rmarkdown", "ncdf4", "Rcpp", "jsonlite", "RcppProgress", "rstac", "tmap"))
library(rstac) 
s = stac("https://earth-search.aws.element84.com/v0")

items <- s %>%
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = c(7.55,52.0,7.70,51.92), #wgs 84 lat lon in dezimal grad
              datetime = "2020-01-01/2020-12-31",
              limit = 100) %>%
  post_request() 
items


q <- s %>% stac_search(collections = "sentinel-s2-l2a-cogs",
                       bbox = c(7.55,52.0,7.70,51.92), #wgs 84 lat lon
                       datetime = "2020-01-01/2020-12-31",
                       limit = 100)
q$params$query = "{\"eo:cloud_cover\": {\"lt\": 10}}" # JSON property filter
q %>% post_request() 

library(gdalcubes)
system.time(col <- stac_image_collection(items$features, property_filter = function(x) {x[["eo:cloud_cover"]] < 20}))
col

assets = c("B01","B02","B03","B04","B05","B06", "B07","B08","B8A","B09","B11","SCL")
col = stac_image_collection(items$features, asset_names = assets, 
                            property_filter = function(x) {x[["eo:cloud_cover"]] < 20})
col
v = cube_view(srs = "EPSG:32632",  extent = list(t0 = "2020-01-01", t1 = "2020-12-31",
                                                left = 400459.27, right = 410597.12,  top = 5762030.85, bottom = 5752938.87),
              dx = 20, dy = 20, dt = "P1D", aggregation = "median", resampling = "average")
#hier werden die Coords der Eingaemaske in dem gegebene EPSG benoetigt


S2.mask = image_mask("SCL", values=c(3,8,9)) # clouds and cloud shadows
gdalcubes_options(threads = 8) 
cube = raster_cube(col, v, mask = S2.mask) %>%
  select_bands(c("B02","B03","B04")) %>%
  reduce_time(c("median(B02)", "median(B03)", "median(B04)")) %>%
  plot(rgb = 3:1, zlim=c(0,1800)) %>% system.time()
