## Not run:
    library(sf)
    library(raster)
    library(caret)
    library(viridis)
    library(latticeExtra)
    library(CAST)
# prepare sample data:
dat <- get(load(system.file("extdata","Cookfarm.RData",package="CAST")))
dat <- aggregate(dat[,c("VW","Easting","Northing")],by=list(as.character(dat$SOURCEID)),mean)
pts <- st_as_sf(dat,coords=c("Easting","Northing"))
pts$ID <- 1:nrow(pts)
set.seed(100)
pts <- pts[1:30,]
studyArea <- stack(system.file("extdata","predictors_2012-03-25.grd",package="CAST"))[[1:8]]
trainDat <- extract(studyArea,pts,df=TRUE)
trainDat <- merge(trainDat,pts,by.x="ID",by.y="ID")
    # visualize data spatially:
    spplot(scale(studyArea))
    plot(studyArea$DEM)
    plot(pts[,1],add=TRUE,col="black")
    # train a model:
    set.seed(100)
    variables <- c("DEM","NDRE.Sd","TWI")
    model <- train(trainDat[,which(names(trainDat)%in%variables)],
    trainDat$VW, method="rf", importance=TRUE, tuneLength=1,
    trControl=trainControl(method="cv",number=5,savePredictions=T))
    print(model) #note that this is a quite poor prediction model
    prediction <- predict(studyArea,model)
    plot(varImp(model,scale=FALSE))
    #...then calculate the AOA of the trained model for the study area:
    AOA <- aoa(studyArea,model)
    spplot(AOA$DI, col.regions=viridis(100),main="Dissimilarity Index")
    #plot predictions for the AOA only:
    spplot(prediction, col.regions=viridis(100),main="prediction for the AOA")+
    spplot(AOA$AOA,col.regions=c("grey","transparent"))
    ####
    # Calculating the AOA might be time consuming. Consider running it in parallel:
    ####
    library(doParallel)
    library(parallel)
    cl <- makeCluster(4)
    registerDoParallel(cl)
    AOA <- aoa(studyArea,model,cl=cl)
    ####
    #The AOA can also be calculated without a trained model.


#All variables are weighted equally in this case:
####
AOA <- aoa(studyArea,train=trainDat,variables=variables)
spplot(AOA$DI, col.regions=viridis(100),main="Dissimilarity Index")
spplot(AOA$AOA,main="Area of Applicability")
## End(Not run)