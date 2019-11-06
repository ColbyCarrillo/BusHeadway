library(RSQLite)
library(dplyr)
library(stringr)

scriptStartTime <- Sys.time()
print("Starting Headway Calc/Comparison")
print(scriptStartTime)

APPLOC="/home/ccar788/"


####################################################################################################################
# Load in data from database and csv file pulled at start of day
# Database connection code 
databaseTimer <- Sys.time()

dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
dbCon <- dbConnect(SQLite(),dbLoc)


# Querying TripUpdates table for observed times
actualResults <- dbSendQuery(dbCon, "SELECT * FROM bus2")
busData.df <- dbFetch(actualResults)
dbDisconnect(dbCon)

# Troubleshooting process as ran into issue on 13-09-19 where the route was not in routes table #
if (nrow(busData.df)==0) { 
        dbConTrouble <- dbConnect(SQLite(),dbLoc)
        troubleResults <- dbSendQuery(dbConTrouble, "SELECT * FROM TRIPUPDATES")
        troubleCheck.df <- dbFetch(troubleResults)
        if (nrow(troubleCheck.df)==0) {
                stop("No TripUpdates Data in Database, Please ensure all scripts are running")        
        }
                stop("Issue with Admin Data, please rerun admin script")
        }


# Pulling scheduled times from excel file pulled at start of day
schdCSVloc = paste(APPLOC,'headway/data/database/scheduledBuses',sep="")
desiredCSVLoc = paste(APPLOC,'headway/data/database/desiredRoutes',sep="")
estimateCSVLoc = paste(APPLOC,'headway/data/database/stopDiffEstimates',sep="")
currentDate = Sys.Date()
currentTime = strftime(Sys.time(),format="%Y-%m-%d %H:%M:%S",tz=Sys.timezone())
schdCSVFileName = paste(schdCSVloc,currentDate,'.csv',sep='')
desiredCSVFileName = paste(desiredCSVLoc,currentDate,'.csv',sep='')
estimatesCSVFileName = paste(estimateCSVLoc,currentDate,'.csv',sep='')

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
        desiredBusRoutes.df <- read.csv(desiredCSVFileName,stringsAsFactors = FALSE)
}
if (file.exists(estimatesCSVFileName) == FALSE) {
        stop("Bus Travel Time Estimates CSV not located. Please run pull script or check file location")
}else
{
        busTimeEstimates.df <- read.csv(estimatesCSVFileName,header = TRUE,stringsAsFactors = FALSE)
        colnames(busTimeEstimates.df) <- c("tripId","route_short_name","routeId","maxStop",as.character(seq(1,floor((length(busTimeEstimates.df)-3)/2),1)),paste(as.character(seq(1,floor((length(busTimeEstimates.df)-3)/2),1)),"_stop",sep=""))
        busTimeEstimates.df$version <- str_sub(busTimeEstimates.df$routeId, start= -5)
}

print("Database Time")
print(Sys.time()-databaseTimer)
####################################################################################################################

####################################################################################################################
# Preprocessing of dataframes

preprocessingTimer <- Sys.time()

### Observed Data ###
# Altering the timestamps from string into a R friendly timestamp
busData.df$timestamp <- as.POSIXlt(busData.df$timestamp)
busData.df$api_timestamp <- as.POSIXlt(busData.df$api_timestamp)

# Create column of Observed versions to reduce scheduled data
busData.df$version <- str_sub(busData.df$trip_id, start= -5)
observedVersionList <- unique(busData.df$version)

# Reduce desired stops (headway under X calculated earlier) to version observed currently
desiredBusRoutes.df <- subset(desiredBusRoutes.df, desiredBusRoutes.df$version %in% observedVersionList)
busTimeEstimates.df <- subset(busTimeEstimates.df, busTimeEstimates.df$version %in% observedVersionList)

### Scheduled Data ###
# Important columns in scheduled data
keepers <- c("trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence", "route_id", "Monday", "Tuesday", "Wednesday"
             , "Thursday", "Friday", "Saturday", "Sunday", "start_date", "end_date", "route_short_name")
scheduledBusStops.df <- scheduledBusStops.df[keepers]



# Reduce rows of scheduled dataframe by observed versions
scheduledBusStops.df$version <- str_sub(scheduledBusStops.df$trip_id, start= -5)
scheduledBusStops.df <- subset(scheduledBusStops.df, scheduledBusStops.df$version %in% desiredBusRoutes.df$version & scheduledBusStops.df$route_short_name %in% desiredBusRoutes.df$route_short_name)
scheduledBusStops.df <- scheduledBusStops.df[which(scheduledBusStops.df$departure_time >= "06:00:00" & scheduledBusStops.df$departure_time <= "23:00:00"),]

# Reformat scheduled data frame
scheduledBusStops.df$start_date <- as.Date(as.character(scheduledBusStops.df$start_date), "%Y%m%d")
scheduledBusStops.df$end_date <- as.Date(as.character(scheduledBusStops.df$end_date), "%Y%m%d")

# Receiving NA's as some of the times are over 24 hours..... NEED TO FIX
scheduledBusStops.df$altered_departure_time <- as.POSIXct(paste(currentDate,scheduledBusStops.df$departure_time,sep=' '),tz=Sys.timezone(),"%Y-%m-%d %H:%M:%S")

print("Preprocessing Time")
print(Sys.time()-preprocessingTimer)





####################################################################################################################
##### Headway Calculations ########################################################################################
####################################################################################################################

overallHeadwayTimer <- Sys.time()

# Finding unique routes for the day to iterate over #
uniqRoutes <- unique(busData.df[,"route_short_name"])
# Reducing number of routes to ones with headway under 15 minutes
uniqRoutes <- subset(uniqRoutes, uniqRoutes %in% desiredBusRoutes.df[,1])


# Preallocating data frame for headway #


currentEstimate <- data.frame(matrix(ncol=9,nrow = 0))
colnames(currentEstimate) <- c("route_short_name","currentBusRoute","nextBusRoute","currentBusTrip","nextBusTrip","currentStop","nextBusLoc","estBusTravelTime", "currentTime")

for(i in 1:length(uniqRoutes)) {
        
        #Finding Records Of Interest#
        #############################
        
        
        # This process will give us all the unique trip timestamps in past 30 minutes (1800 sec)
        temp.df <- busData.df[which(busData.df$route_short_name==uniqRoutes[i]),]
        # Look at the largest timestamp and take ones form last 30 minutes
        apiTimestamps <- sort(unique(temp.df$api_timestamp))
        maxAPI <- max(apiTimestamps)
        reasonableTime <- maxAPI-1800
        apiTimestamps<-apiTimestamps[which(apiTimestamps>reasonableTime)]
        temp.df <- subset(temp.df,temp.df$api_timestamp %in% apiTimestamps)
        temp.df<-temp.df[order(temp.df$stop_sequence),]
        
        # Find only the trips that are the latest
        temp.df<-temp.df[!duplicated(temp.df[,c(2,3,4)],fromLast = TRUE),]
        temp.df<-temp.df[which(temp.df$stop_sequence!=1),]
        
        # Introduce the estimates and stops into observed data
        tripsAndEstimates.df <- merge(temp.df,busTimeEstimates.df,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
        
        # Remove trips that reached thelast stop
        tripsAndEstimates.df <- tripsAndEstimates.df[which(tripsAndEstimates.df$maxStop!=tripsAndEstimates.df$stop_sequence),]
        tripsAndEstimates.df <- tripsAndEstimates.df[order(tripsAndEstimates.df$stop_sequence,tripsAndEstimates.df$timestamp),]
        
        # Logic for next scheduled Bus within the next hour
        nextStart <- scheduledBusStops.df[which(scheduledBusStops.df$route_short_name==uniqRoutes[i] & scheduledBusStops.df$altered_departure_time > as.POSIXct(currentTime) & scheduledBusStops.df$stop_sequence == 1),]
        nextStart <- nextStart[order(nextStart$altered_departure_time),]
        nextStart <- subset(nextStart, nextStart$altered_departure_time < as.POSIXct(currentTime)+3600)
        nextStartAndEstimates.df <- merge(nextStart,busTimeEstimates.df,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
        
        
        routeTravelInfo <- data.frame(matrix(ncol=7,nrow=0))
        colnames(routeTravelInfo) <- c("currentBusRoute","nextBusRoute","currentBusTrip","nextBusTrip","currentStop","nextBusLoc","estBusTravelTime")
        
        
        
        if(nrow(tripsAndEstimates.df)<=1){next}
        
        ######################
        #Caltulating Estimate#
        ######################
        # Now look through all buses running to find estimated distance between them
        
        for(k in 1:nrow(tripsAndEstimates.df)) {
                currentStop <- tripsAndEstimates.df[k,"stop_sequence"]
                currentStopId <- tripsAndEstimates.df[k,paste(currentStop,"_stop",sep="")]
                
                # If this is earliest bus in its route, special logic (needs to look at scheduled)
                if(k == 1) {
                        nextBusLoc<-"None"
                        nextBusGoesToCurrent<-"None"
                } else {
                        nextBusLoc <- tripsAndEstimates.df[k-1,"stop_sequence"]
                        nextBusGoesToCurrent <- tripsAndEstimates.df[k-1,paste(currentStop,"_stop",sep="")]    
                }
                
                
                
                # Check if this bus comes to this stop, if it doesn't, look into previous buses, or scheduled bus
                if (is.na(nextBusGoesToCurrent)==FALSE & (currentStopId==nextBusGoesToCurrent)==TRUE) {
                        j = k-1
                } else {
                        #Check if the bus ever goes to this stop
                        busInQuestion <- tripsAndEstimates.df[k-1,]
                        stopInBusTrip <- currentStopId %in% busInQuestion
                        
                        if (stopInBusTrip==FALSE) {
                                j = k-2
                                # Set j and loop through j until it is 0
                                # Check all previous buses until you find one that stops here
                                while(j>0) {
                                        nextBusInQuestion <- tripsAndEstimates.df[j,]
                                        nextInBusTrip <- currentStopId %in% nextBusInQuestion
                                        if(nextInBusTrip==FALSE) {
                                                j=j-1
                                        } else {
                                                break
                                        }
                                }
                                
                                if(j<0){j=0}
                                
                        } else {
                                #For now, I am just going to assume that this bus is the next one to arrive even if the
                                #stop sequence of it is not the same
                                j = k-1
                        }
                }
                
                
                # We didn't find a bus currently running that is coming to this stop
                if (j==0) {
                        #No bus coming to this stop currently running
                        currentBusRoute <- tripsAndEstimates.df[k,"route_id"] 
                        currentBusTrip <- tripsAndEstimates.df[k,"trip_id"]
                        currentStop <- tripsAndEstimates.df[k,"stop_sequence"]
                        
                        
                        #nextBusRoute <- "Unknown"
                        #nextBusTrip <- "Unknown"
                        #nextBusLoc <- NA
                        #estBusTravelTime <- NA
                        
                        # Find the next scheduled bus
                        if (nrow(nextStartAndEstimates.df)==0) {
                                m = 0
                        } else {
                                m = 1 
                        }
                        
                        while(m!=nrow(nextStartAndEstimates.df)) {
                        
                        
                        nextStartInQuestion <- nextStartAndEstimates.df[m,]
                        nextStartLoc <- 1
                        nextStartGoesToCurrent <- nextStartInQuestion[1,paste(currentStop,"_stop",sep="")]
                        
                        if (is.na(nextStartGoesToCurrent)==FALSE & (currentStopId==nextStartGoesToCurrent)==TRUE) {
                                nextBusRoute <- nextStartInQuestion[1,"route_id"]
                                nextBusTrip <- nextStartInQuestion[1,"trip_id"]
                                nextBusLoc <- 1
                                timeTillStart <- difftime(nextStartInQuestion[1,"altered_departure_time"],as.POSIXct(currentTime),"mins")
                                # We do one less because the stop before sums time to get to next stop, 5 holds time to get to 6
                                estBusTravelTime <- sum(nextStartInQuestion[1,(nextStartLoc+19):(currentStop+18)])
                                estBusTravelTime <- as.numeric(estBusTravelTime) + as.numeric(timeTillStart)
                                break
                        } else {
                                     m=m+1   
                                }
                        }
                        
                        if(m==nrow(nextStartAndEstimates.df)) {
                                nextBusRoute <- "None In Next Hour"
                                nextBusTrip <- "None In Next Hour"
                                nextBusLoc <- NA
                                estBusTravelTime <- NA
                        }
                        
                } else {
                        #We found a bus coming to this stop that is currently running
                        currentBusRoute <- tripsAndEstimates.df[k,"route_id"]
                        nextBusRoute <- tripsAndEstimates.df[j,"route_id"]
                        currentBusTrip <- tripsAndEstimates.df[k,"trip_id"]
                        nextBusTrip <- tripsAndEstimates.df[j,"trip_id"]
                        currentStop <- tripsAndEstimates.df[k,"stop_sequence"]
                        nextBusLoc <- tripsAndEstimates.df[j,"stop_sequence"]
                        
                        #Estimated travel time from previous bus current stop to catch this bus (we do +10 because in stop i.e. 4 it is travel time from 4 to 5)
                        if(currentStop==nextBusLoc) {
                                estBusTravelTime<-0
                        } else if((currentStop-nextBusLoc)==1) {
                                estBusTravelTime <- tripsAndEstimates.df[j,(nextBusLoc+11)]
                        } else {
                                estBusTravelTime <- sum(tripsAndEstimates.df[j,(nextBusLoc+11):(currentStop+10)])
                        }
                        
                }
                
                
                sub.df <- data.frame(currentBusRoute,currentBusTrip,currentStop,nextBusRoute,nextBusTrip,nextBusLoc,estBusTravelTime)
                
                routeTravelInfo <- rbind(routeTravelInfo,sub.df)
        }
        
        route_short_name <- uniqRoutes[i]
        routeTravelInfo <- cbind(route_short_name,routeTravelInfo,currentTime)
        
        currentEstimate <- rbind(currentEstimate,routeTravelInfo)
}




mixEstimate <- data.frame(matrix(ncol=12,nrow = 0))
colnames(mixEstimate) <- c("route_short_name","stop","currentBusRoute","nextBusRoute","currentBusTrip","nextBusTrip","currentStop","nextBusLoc","timeSinceHere","estBusTravelTimeMix","estMixedHeadway", "currentTime")


for(i in 1:length(uniqRoutes)) {
        
        # This process will give us all the unique trip timestamps in past 30 minutes (1800 sec)
        temp.df <- busData.df[which(busData.df$route_short_name==uniqRoutes[i]),]
        apiTimestamps <- sort(unique(temp.df$api_timestamp))
        maxAPI <- max(apiTimestamps)
        reasonableTime <- maxAPI-1800
        apiTimestamps<-apiTimestamps[which(apiTimestamps>reasonableTime)]
        temp.df <- subset(temp.df,temp.df$api_timestamp %in% apiTimestamps)
        temp.df<-temp.df[order(temp.df$stop_sequence),]
        #Find latest trip update for each trip
        temp.df<-temp.df[!duplicated(temp.df[,c(2,3,4)],fromLast = TRUE),]
        temp.df<-temp.df[which(temp.df$stop_sequence!=1),]
        
        # Introduce the estimates and stops into observed data
        tripsAndEstimates.df <- merge(temp.df,busTimeEstimates.df,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
        
        # Remove trips that finished
        tripsAndEstimates.df <- tripsAndEstimates.df[which(tripsAndEstimates.df$maxStop!=tripsAndEstimates.df$stop_sequence),]
        tripsAndEstimates.df <- tripsAndEstimates.df[order(tripsAndEstimates.df$stop_sequence,tripsAndEstimates.df$timestamp),]
        
        #Logic for next scheduled Buses within the next hour
        nextStart <- scheduledBusStops.df[which(scheduledBusStops.df$route_short_name==uniqRoutes[i] & scheduledBusStops.df$altered_departure_time > as.POSIXct(currentTime) & scheduledBusStops.df$stop_sequence == 1),]
        nextStart <- nextStart[order(nextStart$altered_departure_time),]
        nextStart <- subset(nextStart, nextStart$altered_departure_time < as.POSIXct(currentTime)+3600)
        nextStartAndEstimates.df <- merge(nextStart,busTimeEstimates.df,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
        
        
        routeMixTravelInfo <- data.frame(matrix(ncol=10,nrow=0))
        colnames(routeMixTravelInfo) <- c("stop_id","currentBusRouteMix","nextBusRouteMix","currentBusTripMix","nextBusTripMix","currentStopMix","nextBusLocMix","timeSinceHere","estBusTravelTimeMix","estMixedHeadway")
        
        
        # Find all stops observed today
        routeUniqStops <- unique(busData.df[which(busData.df$route_short_name==uniqRoutes[i]),c(1,6)])
        
        for(m in 1:nrow(routeUniqStops)) {
                
                # Find all buses that have visted this stop
                timeStamps.df <- busData.df[which(busData.df$stop_id==routeUniqStops[m,1] & busData.df$route_short_name==uniqRoutes[i]), c(7,4,2,6)]
                timeStamps.df <- timeStamps.df[order(timeStamps.df$timestamp),]
                lastBusHere <- timeStamps.df[nrow(timeStamps.df),]
                
                # Set this stop id and sequence
                thisStop<-routeUniqStops[m,1]
                thisStopSeq <- lastBusHere[1,4]
                
                # Time since the last bus has been at this stop
                timeSinceHere <- difftime(currentTime,lastBusHere[,1],units = "mins")
                
                # Find the next bus running
                nextBusHere <- tripsAndEstimates.df[which(tripsAndEstimates.df$stop_sequence<lastBusHere[,4]),]
                
                
                # If there are no buses running that are coming here
                if(nrow(nextBusHere)==0) {
                        currentBusRouteMix <- lastBusHere[1,"route_id"]
                        currentBusTripMix <- lastBusHere[1,"trip_id"]
                        currentStopMix <- lastBusHere[1,"stop_sequence"]
                        
                        # Entering logic for finding next scheduled bus
                        if (nrow(nextStartAndEstimates.df)==0) {
                                l = 0
                        } else {
                                l = 1 
                        }
                        
                        # Loop through the schedule to make sure the bus comes to this stop
                        while(l!=nrow(nextStartAndEstimates.df)) {
                                nextStartInQuestion <- nextStartAndEstimates.df[l,]
                                nextStartLoc <- 1
                                
                                # Make sure this stop is in the next schedueled
                                if(thisStop %in% nextStartInQuestion) {} else {
                                        l = l+1 
                                        next
                                }
                                # Make sure that it is the same stop sequence?
                                if(nextStartInQuestion[1,paste(thisStopSeq,"_stop",sep="")] == thisStop) {
                                        nextStartGoesToCurrent <- nextStartInQuestion[1,paste(thisStopSeq,"_stop",sep="")]
                                } else {
                                        a <- nextStartInQuestion %in% thisStop
                                        nextStartGoesToCurrent <- nextStartInQuestion[a]
                                        nextStartGoesToCurrent <- nextStartGoesToCurrent[1]
                                        # if it is the first stop, there will be multiple entries of the stop b/c of dataframe
                                        #if(thisStopSeq==1) {
                                                
                                        #}
                                }
                                
                                
                                # Check that the next bust comes to this stop, if it doesn't go next
                                if (is.na(nextStartGoesToCurrent)==FALSE & (thisStop==nextStartGoesToCurrent)==TRUE) {
                                        nextBusRouteMix <- nextStartInQuestion[1,"route_id"]
                                        nextBusTripMix <- nextStartInQuestion[1,"trip_id"]
                                        nextBusLocMix <- 1
                                        
                                        # Combine the time unitl it starts and the estimated time to travel to here
                                        timeTillStart <- difftime(nextStartInQuestion[1,"altered_departure_time"],as.POSIXct(currentTime),"mins")
                                        estMixedHeadway <- sum(nextStartInQuestion[1,(nextBusLocMix+19):(thisStopSeq+18)])
                                        estMixedHeadway <- as.numeric(estMixedHeadway) + as.numeric(timeTillStart)
                                        break
                                } else {
                                        l=l+1   
                                }
                        }
                        
                        # If none of the buses in past hour dataframe come here, let them know
                        if(l==nrow(nextStartAndEstimates.df)) {
                                nextBusRouteMix <- "None In Next Hour"
                                nextBusTripMix <- "None In Next Hour"
                                nextBusLocMix <- "None In Next Hour"
                                
                                estBusTravelTimeMix <- NA
                                estMixedHeadway <- NA
                        }
                        
                        
                } else {
                        
                        # Do not need to check if the next bus comes to this stop because we are working with 
                        # data that only comes to this stop
                        
                        nextBusHere <- nextBusHere[which(nextBusHere$stop_sequence==max(nextBusHere$stop_sequence)),]
                        currentBusRouteMix <- lastBusHere[1,"route_id"]
                        nextBusRouteMix <- nextBusHere[1,"route_id"]
                        currentBusTripMix <- lastBusHere[1,"trip_id"]
                        nextBusTripMix <- nextBusHere[1,"trip_id"]
                        currentStopMix <- lastBusHere[1,"stop_sequence"]
                        nextBusLocMix <- nextBusHere[1,"stop_sequence"]
                        
                        estBusTravelTimeMix <- sum(nextBusHere[1,(nextBusLocMix+11):(currentStopMix+10)],na.rm = TRUE)
                        estMixedHeadway <- sum(estBusTravelTimeMix,timeSinceHere)
                }
        subMix.df <- data.frame(thisStop,currentBusRouteMix,currentBusTripMix,currentStopMix,nextBusRouteMix,nextBusTripMix,nextBusLocMix,timeSinceHere,estBusTravelTimeMix,estMixedHeadway,stringsAsFactors = FALSE)
        routeMixTravelInfo <- rbind(routeMixTravelInfo,subMix.df)
        }
        
        route_short_name <- uniqRoutes[i]
        routeMixTravelInfo <- cbind(route_short_name,routeMixTravelInfo,currentTime)
        
        mixEstimate <- rbind(mixEstimate,routeMixTravelInfo)
}









##################################
##################################
##### Output of Calculations #####
##################################
##################################
csvSaveTime <- Sys.time()

summaryOutFileLoc = paste(APPLOC,'headway/data/headwaySummary/',sep="")

mixOutFile <- paste(summaryOutFileLoc, 'mixEstimateSummary', currentDate, '.csv', sep = '')
currentOutFile <- paste(summaryOutFileLoc, 'curEstimateSummary', currentDate, '.csv', sep = '')

        ### Mixed Estimator ###
if (file.exists(mixOutFile) == FALSE)
{
        write.table(mixEstimate, mixOutFile, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(mixEstimate, mixOutFile, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}
        
        ### Current Estimator ###
if (file.exists(currentOutFile) == FALSE)
{
        write.table(currentEstimate, currentOutFile, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(currentEstimate, currentOutFile, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}

print("CSV Save Time")
print(Sys.time()-csvSaveTime)

################################################################################################################

print("Finished Headway Calc/Comparison: Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())
