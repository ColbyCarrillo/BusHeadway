##### Runs once daily to pull scheduled buses and save to csv file for headway #####

scriptStartTime <- Sys.time()
print("Computing Travel Time")
print(scriptStartTime)

APPLOC="/home/ccar788/"


library(RSQLite)
library(stringr)
library(dplyr)

# Pulling scheduled times from excel file pulled at start of day
schdCSVloc = paste(APPLOC,'headway/data/database/scheduledBuses',sep="")
desiredCSVLoc = paste(APPLOC,'headway/data/database/desiredRoutes',sep="")
currentDate = Sys.Date()
currentTime = strftime(Sys.time(),format="%Y-%m-%d %H:%M:%S",tz=Sys.timezone())
schdCSVFileName = paste(schdCSVloc,currentDate,'.csv',sep='')
desiredCSVFileName = paste(desiredCSVLoc,currentDate,'.csv',sep='')

if (file.exists(schdCSVFileName) == FALSE) {
        stop("Scheduled Buses CSV not located. Please run pull script or check file location")
}else
{
        scheduledBusStops.df <- read.csv(schdCSVFileName,stringsAsFactors = FALSE)
}
if (file.exists(desiredCSVFileName) == FALSE) {
        stop("Desired Buses CSV not located. Please run pull script or check file location")
}else
{
        desiredBusStops.df <- read.csv(desiredCSVFileName,stringsAsFactors = FALSE)
}


scheduledBusStops.df <- subset(scheduledBusStops.df, scheduledBusStops.df$route_short_name %in% desiredBusStops.df$route_short_name)
scheduledBusStops.df <- scheduledBusStops.df[which(scheduledBusStops.df$departure_time >= "06:00:00" & scheduledBusStops.df$departure_time <= "23:00:00"),]
scheduledBusStops.df$altered_departure_time <- as.POSIXct(paste(Sys.Date(),scheduledBusStops.df$departure_time,sep=' '),tz=Sys.timezone(),"%Y-%m-%d %H:%M:%S")


# Start of logic ***
# Start of logic ***
# Start of logic ***

uniqTrips <- scheduledBusStops.df %>% distinct(route_short_name, route_id, trip_id)
#uniqRoutes <- scheduledBusStops.df %>% distinct(route_short_name, route_id)

# Gather all stop infromation for every routes (first trip), and calculate the difference in stops, last stop will have NA value
detailedData<-lapply(uniqTrips[,3],function(a) {
        #tempTrips <- unique(uniqTrips[which(uniqTrips$route_id==a),c(2,3)])[2]
        
        #pickRightTrip <- scheduledBusStops.df[which(scheduledBusStops.df$route_id==a),] #& scheduledBusStops.df$trip_id %in% tempTrips),]
        
        #rightTrip <- pickRightTrip %>% group_by(trip_id) %>% summarise(highTrip = max(stop_sequence))
        #rightTrip <- rightTrip[order(rightTrip$highTrip),]
        
        temp <- scheduledBusStops.df[which(scheduledBusStops.df$trip_id==a),] #& scheduledBusStops.df$trip_id %in% rightTrip[nrow(rightTrip),1]),]
        #temp <- pickRightTrip[which(scheduledBusStops.df$trip_id %in% rightTrip[nrow(rightTrip),1]),]
        
        tripTime <- temp[,c(5,4,23)]
        tripTime$diff <- sapply(tripTime[,1],function(d) { 
                                                difftime(tripTime[d+1,3],tripTime[(d),3],units = "mins")
                                                } )
        cbind(rep(a,nrow(tripTime)),tripTime[,c(1,2,4)])
} )

# Find the max stops so we can create that as the length of data frame
sumData <- lapply(detailedData,function(a) {
        if(nrow(a)>0) {
                tempMax <- max(a[,2])
                c(as.character(a[1,1]),as.numeric(tempMax))  
        } else { c(NA,NA) }
        
})

#Flatten into a data frame to find the max number of routes
flat <- do.call(rbind, sumData)
flat <- data.frame(flat)
colnames(flat) <- c("tripId","maxStop")
flat$maxStop <- as.character(flat$maxStop)
flat$maxStop <- as.integer(flat$maxStop)
flat$tripId <- as.character(flat$tripId)
#biggest <- (max(flat$maxStop,na.rm = TRUE)*2)+2
biggest<-max(flat$maxStop,na.rm=TRUE)

# Create base data frame
finalMatrix <- data.frame(matrix(data=NA , nrow=1,ncol=((biggest*2)+2)))

for(i in 1:nrow(flat)) {
        if(is.na(flat[i,1])) {next}
        
        lenObs<-length(detailedData[[i]]$diff)
        lenStops<-length(detailedData[[i]]$stop_id)
        maxi<-biggest
        
        trip<-flat[[i,1]]
        maxSt<-flat[[i,2]]
        obs<-detailedData[[i]]$diff
        stops<-detailedData[[i]]$stop_id

        tailerObs<-rep(NA,(maxi-lenObs))
        trailerStops<-rep(NA,(maxi-lenStops))
        
        finalMatrix <- rbind(finalMatrix,c(trip,maxSt,obs,tailerObs,stops,trailerStops))
}

# Remove first row of NA's
finalMatrix<-finalMatrix[-1,]
colnames(finalMatrix) <- c("tripId","maxStop",as.character(seq(1,(biggest),1)),paste(seq(1,(biggest),1),"_stop",sep=""))

# Alter columns from character to numeric
finalMatrix[,2:(biggest+2)] <- lapply(finalMatrix[,2:(biggest+2)], as.numeric)

finalMatrix <- merge(uniqTrips, finalMatrix, by.x="trip_id", by.y = "tripId")


### Save text file for routes + version over minimum ###
stopEstFileName <- "stopDiffEstimates"
stopEstFileLoc <- paste(APPLOC,'headway/data/database/',sep="")

stopEstFullFileName <- paste(stopEstFileName,Sys.Date(),".csv",sep = "")

currentFilesR <- list.files(stopEstFileLoc)

oldFilesR <- currentFilesR[currentFilesR %in% grep(stopEstFileName,currentFilesR, value=T)]
if (length(oldFilesR) > 0) {
        for(i in oldFilesR) {
                file.remove(paste(stopEstFileLoc,i,sep=""))
        }
        write.table(finalMatrix, paste(stopEstFileLoc,stopEstFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
} else {
        write.table(finalMatrix, paste(stopEstFileLoc,stopEstFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
}




print("Finished Computing Scheduled Data")
print(Sys.time()-scriptStartTime)
print(Sys.time())