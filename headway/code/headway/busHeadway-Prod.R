library(RSQLite)
library(dplyr)
library(stringr)


scriptStartTime <- Sys.time()
print("Starting Headway Calc/Comparison")
print(scriptStartTime)


####################################################################################################################
# Load in data from database and csv file pulled at start of day
# Database connection code 
databaseTimer <- Sys.time()

APPLOC="/home/ccar788/"

dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
dbCon <- dbConnect(SQLite(),dbLoc)


# Querying TripUpdates table for observed times

actualResults <- dbSendQuery(dbCon, "SELECT * FROM bus2")
#testResults <- dbSendQuery(dbCon, "SELECT * FROM TripUpdates")
busData.df <- dbFetch(actualResults)
testResults <-  dbSendQuery(dbCon, "SELECT tu.stop_id AS stop_id,
tu.route_id AS route_id,
r.route_short_name AS route_short_name,
tu.trip_id AS trip_id,
tu.start_time AS start_time,
tu.stop_sequence AS stop_sequence,
datetime(tu.timestamp, 'unixepoch', 'localtime') AS timestamp,
datetime(tu.api_timestamp, 'unixepoch', 'localtime') AS api_timestamp,
tu.delay AS delay,
tu.arrival,
tu.departure
FROM TripUpdates tu, Routes r
WHERE tu.route_id = r.route_id AND
date(tu.timestamp, 'unixepoch', 'localtime') = strftime('%Y-%m-%d', 'now', 'localtime')")
testBusData.df <- dbFetch(testResults)
dbDisconnect(dbCon)


# Removes duplicate entries for the same stop and takes the last one
testBusData.df$api_timestamp <- as.POSIXlt(testBusData.df$api_timestamp)
testBusData.df$timestamp <- as.POSIXlt(testBusData.df$timestamp)
testBusData.df<-testBusData.df[order(testBusData.df$trip_id,
                                     testBusData.df$stop_sequence,
                                     testBusData.df$timestamp),]

try(busData.df<-testBusData.df[!duplicated(testBusData.df[,c(1:6)],fromLast = T),])



# Troubleshooting process as ran into issue on 13-09-19 where the route was not in routes table #
if (nrow(busData.df)==0) { 
        dbConTrouble <- dbConnect(SQLite(),dbLoc)
        troubleResults <- dbSendQuery(dbConTrouble, "SELECT * FROM TRIPUPDATES WHERE arrival = '0'")
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

# Create column of Observed versions to reduce admin data
busData.df$version <- str_sub(busData.df$trip_id, start= -5)
observedVersionList <- unique(busData.df$version)

# Reduce desired stops (headway under X calculated earlier) to version observed currently
desiredBusRoutes.df <- subset(desiredBusRoutes.df, desiredBusRoutes.df$version %in% observedVersionList)
busTimeEstimates.df <- subset(busTimeEstimates.df, busTimeEstimates.df$version %in% observedVersionList)

### Scheduled Data ###
# Important columns in scheduled data
keepers <- c("trip_id", "arrival_time", "departure_time", 
             "stop_id", "stop_sequence", 
             "route_id", "Monday", "Tuesday", 
             "Wednesday", "Thursday", "Friday", 
             "Saturday", "Sunday", "start_date", 
             "end_date", "route_short_name")
scheduledBusStops.df <- scheduledBusStops.df[keepers]



# Reduce rows of scheduled dataframe by observed versions
scheduledBusStops.df$version <- str_sub(scheduledBusStops.df$trip_id, start= -5)
scheduledBusStops.df <- subset(scheduledBusStops.df, scheduledBusStops.df$version %in% desiredBusRoutes.df$version 
                               & scheduledBusStops.df$route_short_name %in% desiredBusRoutes.df$route_short_name)
scheduledBusStops.df <- scheduledBusStops.df[which(scheduledBusStops.df$departure_time >= "06:00:00" & 
                                                           scheduledBusStops.df$departure_time <= "23:00:00"),]

# Reformat scheduled data frame
scheduledBusStops.df$start_date <- as.Date(as.character(scheduledBusStops.df$start_date), "%Y%m%d")
scheduledBusStops.df$end_date <- as.Date(as.character(scheduledBusStops.df$end_date), "%Y%m%d")

# Receiving NA's as some of the times are over 24 hours..... NEED TO FIX
scheduledBusStops.df$altered_departure_time <- as.POSIXct(paste(currentDate,scheduledBusStops.df$departure_time,sep=' '),
                                                          tz=Sys.timezone(),"%Y-%m-%d %H:%M:%S")



print("Preprocessing Time")
print(Sys.time()-preprocessingTimer)





####################################################################################################################
##### Headway Calculations ########################################################################################
####################################################################################################################

overallHeadwayTimer <- Sys.time()

options(warn = 1)


calcObservedHeadway <- function(route,routeObsData,routeSchd) {
        #Variables to use as we loop over stops
        routeName <- vector()
        stopId <- vector()
        stopSequence <- vector()
        timeStampsDiff <- vector()
        lastTS <- vector()
        lastTSTripId <- vector()
        twoBeforeTS <- vector()
        twoBeforeTSTripId <- vector()
        obsSchdHeadway <- vector()
        
        ### Find all the stops on that unique route and scheduled route ###
        routeUniqStops <- unique(routeObsData[,c(1,6)])
        
        for(j in 1:nrow(routeUniqStops)) {
                timeStamps.df <- routeObsData[which(routeObsData$stop_id==routeUniqStops[j,1] & routeObsData$stop_sequence == routeUniqStops[j,2]), c(7,4,6)]
                timeStamps.df <- timeStamps.df[order(timeStamps.df$timestamp),]
                
                #For now we will not worry about the shared last and first stop, These headways will not be correct
                
                tempSchdTimes.df <- subset(routeSchd, routeSchd$stop_id==routeUniqStops[j,1] & routeSchd$stop_sequence == routeUniqStops[j,2])
                tempSchdTimes.df <- tempSchdTimes.df[order(tempSchdTimes.df$altered_departure_time),]
                
                if(nrow(timeStamps.df)==1) {
                        timeStampsDiff[j] <- NA
                        lastTS[j] <- as.character(timeStamps.df[nrow(timeStamps.df),1])
                        lastTSTripId[j] <- as.character(timeStamps.df[nrow(timeStamps.df),2])
                        twoBeforeTS[j] <- NA
                        twoBeforeTSTripId[j] <- NA
                        obsSchdHeadway[j] <- NA
                } else {
                        timeStampsDiff[j] <- round(as.numeric(difftime(timeStamps.df[nrow(timeStamps.df),1],timeStamps.df[(nrow(timeStamps.df)-1),1], units="mins")),2)
                        lastTS[j] <- as.character(timeStamps.df[nrow(timeStamps.df),1])
                        lastTSTripId[j] <- as.character(timeStamps.df[nrow(timeStamps.df),2])
                        twoBeforeTS[j] <- as.character(timeStamps.df[(nrow(timeStamps.df)-1),1])
                        twoBeforeTSTripId[j] <- as.character(timeStamps.df[(nrow(timeStamps.df)-1),2])
                        twoBeforeStopSeq<-timeStamps.df[(nrow(timeStamps.df)-1),3]
                        
                        obsSchdHeadway[j]<-calcObservedHeadwaySchedule(twoBeforeTSTripId[j],twoBeforeTS[j],tempSchdTimes.df)
                }
                stopId[j] <- routeUniqStops[j,1]
                stopSequence[j] <- routeUniqStops[j,2]
                #routeId[j] <- uniqRoutes[i,1]
                routeName[j] <- route
        }
        tempHeadway <- data.frame()
        tempHeadway <- data.frame(routeName,
                                  stopId,
                                  stopSequence,
                                  time_Difference=as.numeric(timeStampsDiff),
                                  lastTS,
                                  lastTSTripId,
                                  twoBeforeTS,
                                  twoBeforeTSTripId,
                                  obsSchdHeadway=as.numeric(obsSchdHeadway), stringsAsFactors = FALSE)
        #tempHeadway$routeId <- as.character(tempHeadway$routeId)
        tempHeadway$routeName <- as.character(tempHeadway$routeName)
        tempHeadway$stopId <- as.character(tempHeadway$stopId)
        
        
        # Return headway dataframe for route
        tempHeadway
}

calcObservedHeadwaySchedule <- function(tripId,tripTS,schdTimes) {
        schdAnchor <- subset(schdTimes, schdTimes$trip_id==tripId)
        if(nrow(schdAnchor)>1){schdAnchor<-schdAnchor[1,]}
        # If we do not find the observed trip in the scheduled data
        if(nrow(schdAnchor)<1) {
                differences <- abs(as.numeric(difftime(tripTS, schdTimes$altered_departure_time)))
                schdAnchor <- schdTimes[which(differences==min(differences)),][1,]
                nextSchd <- subset(schdTimes,schdTimes$altered_departure_time>schdAnchor$altered_departure_time)
                if(nrow(nextSchd)<1) {
                        schdHead <- NA
                } else {
                        nextSchd <- nextSchd[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)>180) {
                                schdHead <- NA
                        } else {
                                schdHead <- round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)
                        }
                }
        } else if (abs(as.numeric(difftime(tripTS,schdAnchor$altered_departure_time,units = "mins"))) > 180) {
                # If we find a trip value, but it is running at the incorrect time
                differences <- abs(as.numeric(difftime(tripTS, schdTimes$altered_departure_time)))
                schdAnchor <- schdTimes[which(differences==min(differences)),][1,]
                nextSchd <- subset(schdTimes,schdTimes$altered_departure_time>schdAnchor$altered_departure_time)
                if(nrow(nextSchd)<1) {
                        schdHead <- NA
                } else {
                        nextSchd <- nextSchd[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)>180) {
                                schdHead <- NA
                        } else {
                                schdHead <- round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)
                        }
                }
        } else {
                # If we find a trip value, and it is the right value
                nextSchd <- subset(schdTimes,schdTimes$altered_departure_time>schdAnchor$altered_departure_time)
                if(nrow(nextSchd)<1) {
                        schdHead <- NA
                } else {
                        nextSchd <- nextSchd[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)>180) {
                                schdHead <- NA
                        } else {
                                schdHead <- round(as.numeric(difftime(nextSchd$altered_departure_time,schdAnchor$altered_departure_time, units="mins")),2)
                        }
                }
        }
        schdHead
}

calculateCurrentEstimator <- function(liveBusesDf,schdDf,nextTrips) {
        routeTravelInfo <- data.frame(matrix(ncol=10,nrow=0))
        colnames(routeTravelInfo) <- c("currentBusRoute","currentStopId","nextBusRoute","currentBusTrip","nextBusTrip","currentStopSeq","currentBusTimeStamp","nextBusLoc","estBusTravelTime","curSchdHeadway")
        
        for(k in 1:nrow(liveBusesDf)) {
                currentStopSeq <- liveBusesDf[k,"stop_sequence"]
                currentStopId <- liveBusesDf[k,paste(currentStopSeq,"_stop",sep="")]
                
                if(liveBusesDf[k,"stop_sequence"]>liveBusesDf[k,"maxStop"]){next}
                
                if(k==1){
                        j=0
                } else {
                        nextLiveBuses <- liveBusesDf[1:(k-1),]
                        recievedData<-FindQuickestNextLiveBus(nextLiveBuses,currentStopId,currentStopSeq)
                        
                        if(all(is.na(recievedData))==FALSE){
                                nextLiveBus<-recievedData[[1]]
                                nextBusGoesHereStopSeq<-recievedData[[2]]
                                travelTime<-recievedData[[3]]
                                
                                nextBusRoute <- nextLiveBus[1,"route_id"]
                                nextBusTrip <- nextLiveBus[1,"trip_id"]
                                nextBusLoc <- nextLiveBus[1,"stop_sequence"]
                                j = 1
                        } else {
                                j = 0
                        }
                }
                
                tempSchdTimesCur.df <- subset(schdDf, schdDf$stop_id==currentStopId & schdDf$stop_sequence==currentStopSeq)
                tempSchdTimesCur.df <- tempSchdTimesCur.df[order(tempSchdTimesCur.df$altered_departure_time),]
                
                # If this is earliest bus in its route, special logic (needs to look at scheduled)
                
                
                # We didn't find a bus currently running that is coming to this stop, find one in schedule
                if (j==0) {
                        #No bus coming to this stop currently running
                        currentBusRoute <- liveBusesDf[k,"route_id"] 
                        currentBusTrip <- liveBusesDf[k,"trip_id"]
                        currentBusSeq <- currentStopSeq
                        currentBusTimeStamp <- liveBusesDf[k,"timestamp"]
                        
                        
                        # CALL FUNCTION
                        returnTrips<-FindQuickestNextScheduledBus(nextTrips,currentStopId,currentStopSeq)
                        
                        if(all(is.na(returnTrips))==TRUE) {
                                nextBusRoute <- "None In Next Hour"
                                nextBusTrip <- "None In Next Hour"
                                nextBusLoc <- NA
                                estBusTravelTime <- NA
                                curSchdHeadway <- NA
                        } else {
                                nextBusComingHereSchd<-returnTrips[[1]]
                                desiredStopSeqCur<-returnTrips[[2]]
                                travelTime<-returnTrips[[3]]
                                nextBusRoute <- nextBusComingHereSchd[,"route_id"]
                                nextBusTrip <- nextBusComingHereSchd[,"trip_id"]
                                nextBusLoc <- nextBusComingHereSchd[,"stop_sequence"]
                                
                         
                                timeTillStart <- difftime(nextBusComingHereSchd[1,"altered_departure_time"],as.POSIXct(currentTime),units = "mins")
                                # We do one less because the stop before sums time to get to next stop, 5 holds time to get to 6
                                estBusTravelTime <- travelTime
                                estBusTravelTime <- estBusTravelTime + as.numeric(timeTillStart)
                                        
                                
                                curSchdHeadway<-calcCurrentEstimatorSchedule(tempSchdTimesCur.df,currentBusRoute,currentBusTrip,currentBusSeq,currentBusTimeStamp)
                        }

                } else {
                        #We found a bus coming to this stop that is currently running
                        currentBusRoute <- liveBusesDf[k,"route_id"]

                        currentBusTrip <- liveBusesDf[k,"trip_id"]

                        currentBusTimeStamp <- liveBusesDf[k,"timestamp"]
                        
                        returnTrips<-FindQuickestNextScheduledBus(nextTrips,currentStopId,currentStopSeq)
                        if(all(is.na(returnTrips))==FALSE){
                                if(travelTime>returnTrips[[3]]) {
                                        nextLiveBus<-returnTrips[[1]]
                                        nextBusGoesHereStopSeq<-returnTrips[[2]]
                                        travelTime<-returnTrips[[3]]
                                        
                                        nextBusRoute <- nextLiveBus[1,"route_id"]
                                        nextBusTrip <- nextLiveBus[1,"trip_id"]
                                        nextBusLoc <- nextLiveBus[1,"stop_sequence"]
                                        timeTillStart <- difftime(nextLiveBus[1,"altered_departure_time"],as.POSIXct(currentTime),units = "mins")
                                } else {
                                        timeTillStart<-0
                                }
                                
                        } else {
                                timeTillStart<-0
                        }
                        
                        
                        
                        #Estimated travel time from previous bus current stop to catch this bus (we do +10 because in stop i.e. 4 it is travel time from 4 to 5)
                        estBusTravelTime <- travelTime+timeTillStart
                        
                        
                        
                        
                        curSchdHeadway<-calcCurrentEstimatorSchedule(tempSchdTimesCur.df,currentBusRoute,currentBusTrip,currentBusSeq,currentBusTimeStamp)
                        
        
                }
                sub.df <- data.frame(currentBusRoute,currentStopId,currentBusTrip,currentStopSeq,currentBusTimeStamp,nextBusRoute,nextBusTrip,nextBusLoc,estBusTravelTime,curSchdHeadway)
                
                routeTravelInfo <- rbind(routeTravelInfo,sub.df)
        }
        routeTravelInfo
}

calcCurrentEstimatorSchedule <- function(schdTSDf,curRoute,curTrip,curSeq,curTs) {
        
        # Find Scheduled Headway
        # Set our anchor to the scheduled data
        schdAnchorCur <- subset(schdTSDf,schdTSDf$trip_id==curTrip & schdTSDf$stop_sequence==curSeq & schdTSDf$route_id==curRoute)
        if(nrow(schdAnchorCur)>1){schdAnchorCur<-schdAnchorCur[1,]}
        # If we do not find the observed trip in the scheduled data
        
        if(nrow(schdAnchorCur)<1) {
                schdTSDf<-subset(schdTSDf,schdTSDf$route_id==curRoute & schdTSDf$stop_sequence)
                differences <- abs(as.numeric(difftime(curTs, schdTSDf$altered_departure_time)))
                schdAnchorCur <- schdTSDf[which(differences==min(differences)),][1,]
                if(nrow(schdAnchorCur)>1){schdAnchorCur<-schdAnchorCur[1,]}
                nextSchdCur <- subset(schdTSDf, schdTSDf$altered_departure_time > schdAnchorCur$altered_departure_time)
                if(nrow(nextSchdCur)<1){
                        curSchdHeadway <- NA
                } else {
                        nextSchdCur <- nextSchdCur[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if(round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)>180) {
                                curSchdHeadway <- NA
                        } else {
                                curSchdHeadway <- round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)
                        }
                        
                }
                
        } else if (abs(as.numeric(difftime(curTs,schdAnchorCur$altered_departure_time,units = "mins")))>180) {
                
                schdTSDf<-subset(schdTSDf,schdTSDf$route_id==curRoute & schdTSDf$stop_sequence)
                # If we find a trip value, but it is running at the incorrect time
                differences <- abs(as.numeric(difftime(curTs, schdTSDf$altered_departure_time)))
                schdAnchorCur <- schdTSDf[which(differences==min(differences)),][1,]
                if(nrow(schdAnchorCur)>1){schdAnchorCur<-schdAnchorCur[1,]}
                nextSchdCur <- subset(schdTSDf,schdTSDf$altered_departure_time>schdAnchorCur$altered_departure_time)
                if(nrow(nextSchdCur)<1){
                        curSchdHeadway <- NA
                } else {
                        nextSchdCur <- nextSchdCur[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if(round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)>180) {
                                curSchdHeadway <- NA
                        } else {
                                curSchdHeadway <- round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)
                        }
                }
        } else {
                # If we find a trip value, and it is the right value
                nextSchdCur <- subset(schdTSDf,schdTSDf$altered_departure_time>schdAnchorCur$altered_departure_time)
                if(nrow(nextSchdCur)<1){
                        curSchdHeadway <- NA
                } else {
                        nextSchdCur <- nextSchdCur[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if(round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)>180) {
                                curSchdHeadway <- NA
                        } else {
                                curSchdHeadway <- round(as.numeric(difftime(nextSchdCur$altered_departure_time,schdAnchorCur$altered_departure_time, units="mins")),2)
                        }
                }
        }
        curSchdHeadway
}

calculateMixedEstimator <- function(route,obsDf,liveBusesDf,schdDf,nextStartDf) {
        routeMixTravelInfo <- data.frame(matrix(ncol=13, nrow=0))
        colnames(routeMixTravelInfo) <- c("curStop","currentBusRouteMix","nextBusRouteMix","currentBusTripMix","mixCurrentTimestamp","nextBusTripMix","currentStopMix","nextBusLocMix","timeSinceHere","timeTillStartNext","estBusTravelTimeMix","estMixedHeadway","mixSchdHeadway")
        
        routeUniqStops <- unique(obsDf[,c(1,6)])
        
        for(y in 1:nrow(routeUniqStops)) {
                curStop <- routeUniqStops[y,1]
                curStopSeq <- routeUniqStops[y,2]
                
                # Find most recent bus here
                timeStampsMix.df <- obsDf[which(obsDf$stop_id==routeUniqStops[y,1] & obsDf$stop_sequence==routeUniqStops[y,2]), c(7,4,2,6)]
                timeStampsMix.df <- timeStampsMix.df[order(timeStampsMix.df$timestamp),]
                
                lastBusHere <- timeStampsMix.df[nrow(timeStampsMix.df),]
                currentBusRouteMix <- lastBusHere[1,"route_id"]
                currentBusTripMix <- lastBusHere[1,"trip_id"]
                currentStopMix <- lastBusHere[1,"stop_sequence"]
                mixCurrentTimestamp <- lastBusHere[1,"timestamp"]
                timeSinceHere <- as.numeric(difftime(as.POSIXct(currentTime),lastBusHere[,"timestamp"],units = "mins"))
        
                
                # Find the next buses running
                # Order it by timestamp and then by stop sequence
                nextBusHere <- liveBusesDf[which(liveBusesDf$stop_sequence<=currentStopMix & liveBusesDf$trip_id!=currentBusTripMix),]
                nextBusHere <- nextBusHere[rev(order(nextBusHere$timestamp)),]
                nextBusHere <- nextBusHere[order(-nextBusHere$stop_sequence),]
                
                # Set Scheduled to only ones we care about
                tempSchdTimesMix.df <- subset(schdDf, schdDf$stop_id==curStop & schdDf$stop_sequence==curStopSeq)
                tempSchdTimesMix.df <- tempSchdTimesMix.df[order(tempSchdTimesMix.df$altered_departure_time),]
                
                if(nrow(nextBusHere)==0) {
                        
                        # Find next starting bus coming here
                        recievedData<-FindQuickestNextScheduledBus(nextStartDf,curStop,curStopSeq)
                        
                        if(all(is.na(recievedData))==TRUE) {
                                nextBusRouteMix <- "None In Next Hour"
                                nextBusTripMix <- "None In Next Hour"
                                nextBusLocMix <- "None In Next Hour"
                                
                                timeTillStartNext <- NA
                                estBusTravelTimeMix <- NA
                                estMixedHeadway <- NA
                                mixSchdHeadway <- NA
                        } else {
                                nextBusComingHereSchd<-recievedData[[1]]
                                desiredStopSeq<-recievedData[[2]]
                                nextBusRouteMix <- nextBusComingHereSchd[,"route_id"]
                                nextBusTripMix <- nextBusComingHereSchd[,"trip_id"]
                                nextBusLocMix <- nextBusComingHereSchd[,"stop_sequence"]
                                
                                if(nextBusLocMix!=1) {
                                        stop("ERROR GRABBING NEXT SCHEDULED START MIX LINE 577")
                                }
                                
                                # Combine the time unitl it starts and the estimated time to travel to here
                                # We have logic to find the stop amongst the trips stops, need to calculate to that desired stop sequence
                                timeTillStartNext <- as.numeric(difftime(nextBusComingHereSchd[,"altered_departure_time"],as.POSIXct(currentTime),"mins"))
                                # Time since the last bus has been at this stop
                                
                                if(currentStopMix==1){
                                        estBusTravelTimeMix <- 0
                                } else {
                                        estBusTravelTimeMix <- sum(nextBusComingHereSchd[,(nextBusLocMix+19):(desiredStopSeq+18)])
                                }
                                
                                estMixedHeadway <- estBusTravelTimeMix + timeTillStartNext + timeSinceHere
                                mixSchdHeadway<-calcMixedEstimatorSchedule(tempSchdTimesMix.df,currentBusTripMix,curStopSeq,currentBusRouteMix,mixCurrentTimestamp)
                        }
                        
                        
                        subMix.df <- data.frame(curStop,currentBusRouteMix,currentBusTripMix,currentStopMix,mixCurrentTimestamp,nextBusRouteMix,nextBusTripMix,nextBusLocMix,timeSinceHere,timeTillStartNext,estBusTravelTimeMix,estMixedHeadway,mixSchdHeadway,stringsAsFactors = FALSE)
                        routeMixTravelInfo <- rbind(routeMixTravelInfo,subMix.df)
                        next
                
                } else {
                                liveBusReturn<-FindQuickestNextLiveBus(nextBusHere,curStop,curStopSeq)
                                schdBusReturn<-FindQuickestNextScheduledBus(nextStartDf,curStop,curStopSeq)
                                
                                if(all(is.na(liveBusReturn))==TRUE&all(is.na(schdBusReturn))==TRUE) {
                                        quickestBus<-NA
                                } else if(all(is.na(liveBusReturn))==TRUE) {
                                        quickestBus<-schdBusReturn
                                } else if (all(is.na(schdBusReturn))==TRUE) {
                                        quickestBus<-liveBusReturn
                                } else if(liveBusReturn[[3]]<schdBusReturn[[3]]){
                                        quickestBus<-liveBusReturn
                                } else {
                                        quickestBus <- schdBusReturn
                                }
                                
                                
                                
                                if(all(is.na(liveBusReturn))==TRUE) {
                                        # If the live buses don't go here
                                        recievedData<-quickestBus
                                        
                                        if(all(is.na(recievedData))==TRUE) {
                                                nextBusRouteMix <- "None In Next Hour"
                                                nextBusTripMix <- "None In Next Hour"
                                                nextBusLocMix <- "None In Next Hour"
                                                
                                                timeTillStartNext <- NA
                                                estBusTravelTimeMix <- NA
                                                estMixedHeadway <- NA
                                                mixSchdHeadway <- NA
                                        } else {
                                                nextBusComingHereSchd<-recievedData[[1]]
                                                desiredStopSeq<-recievedData[[2]]
                                                travelTime<-recievedData[[3]]
                                                nextBusRouteMix <- nextBusComingHereSchd[,"route_id"]
                                                nextBusTripMix <- nextBusComingHereSchd[,"trip_id"]
                                                nextBusLocMix <- nextBusComingHereSchd[,"stop_sequence"]
                                                if(nextBusLocMix!=1) {
                                                        stop("ERROR GRABBING NEXT SCHEDULED START MIX LINE 577")
                                                }
                                                
                                                # Combine the time unitl it starts and the estimated time to travel to here
                                                # We have logic to find the stop amongst the trips stops, need to calculate to that desired stop sequence
                                                timeTillStartNext <- as.numeric(difftime(nextBusComingHereSchd[,"altered_departure_time"],as.POSIXct(currentTime),"mins"))
                                                # Time since the last bus has been at this stop
                                                
                                                
                                                estBusTravelTimeMix <- travelTime
 
                                                
                                                estMixedHeadway <- estBusTravelTimeMix + timeTillStartNext + timeSinceHere
                                                mixSchdHeadway<-calcMixedEstimatorSchedule(tempSchdTimesMix.df,currentBusTripMix,curStopSeq,currentBusRouteMix,mixCurrentTimestamp)
                                        }
                                        subMix.df <- data.frame(curStop,currentBusRouteMix,currentBusTripMix,currentStopMix,mixCurrentTimestamp,nextBusRouteMix,nextBusTripMix,nextBusLocMix,timeSinceHere,timeTillStartNext,estBusTravelTimeMix,estMixedHeadway,mixSchdHeadway,stringsAsFactors = FALSE)
                                        routeMixTravelInfo <- rbind(routeMixTravelInfo,subMix.df)
                                } else {
                                        # If the livebuses do go here
                                        nextLiveBus<-quickestBus[[1]]
                                        nextBusGoesHereStopSeq<-quickestBus[[2]]
                                        travelTime<-quickestBus[[3]]
                                        
                                        nextBusRouteMix <- nextLiveBus[1,"route_id"]
                                        nextBusTripMix <- nextLiveBus[1,"trip_id"]
                                        nextBusLocMix <- nextLiveBus[1,"stop_sequence"]
                                        
                                        if(nextBusLocMix==currentStopMix) {
                                                estBusTravelTimeMix<-0
                                        } else {
                                                estBusTravelTimeMix <- travelTime      
                                        }
                                        
                                        estMixedHeadway <- sum(estBusTravelTimeMix,timeSinceHere)
                                        
                                        mixSchdHeadway<-calcMixedEstimatorSchedule(tempSchdTimesMix.df,currentBusTripMix,curStopSeq,currentBusRouteMix,mixCurrentTimestamp)
                                        
                                        timeTillStartNext<-NA
                                        subMix.df <- data.frame(curStop,currentBusRouteMix,currentBusTripMix,currentStopMix,mixCurrentTimestamp,nextBusRouteMix,nextBusTripMix,nextBusLocMix,timeSinceHere,timeTillStartNext,estBusTravelTimeMix,estMixedHeadway,mixSchdHeadway,stringsAsFactors = FALSE)
                                        routeMixTravelInfo <- rbind(routeMixTravelInfo,subMix.df)
                                }
                        
                        }
                        
                
        }
        routeMixTravelInfo
}

calcMixedEstimatorSchedule<-function(schdTSDf,curTrip,curSeq,curRoute,curTs) {
        # Find the scheduled headway
        # Set our anchor to the scheduled data
        #options(warn=2)
        if(nrow(schdTSDf)==0) {return(NA)}
        schdAnchorMix <- subset(schdTSDf,schdTSDf$trip_id==curTrip & schdTSDf$route_id==curRoute)
        if(nrow(schdAnchorMix)>1){schdAnchorMix<-schdAnchorMix[1,]}
        # If we do not find the observed trip in the scheduled data
        if(nrow(schdAnchorMix)<1) {
                differencesMix <- abs(as.numeric(difftime(curTs, schdTSDf$altered_departure_time)))
                schdAnchorMix <- schdTSDf[which(differencesMix==min(differencesMix) & schdTSDf$route_id==curRoute),][1,]
                nextSchdMix <- subset(schdTSDf,schdTSDf$altered_departure_time>schdAnchorMix$altered_departure_time)
                
                if(nrow(nextSchdMix)<1){
                        mixSchdHeadway<-NA
                } else {
                        nextSchdMix<-nextSchdMix[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)>180) {
                                mixSchdHeadway<-NA
                        } else {
                                mixSchdHeadway <- round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)
                        }
                        
                }
                
        } else if(abs(as.numeric(difftime(schdAnchorMix$altered_departure_time,curTs,units = "mins")))>180) {
                # If we find a trip value, but it is running at the incorrect time
                differencesMix <- abs(as.numeric(difftime(curTs, schdTSDf$altered_departure_time)))
                schdAnchorMix <- schdTSDf[which(differencesMix==min(differencesMix) & schdTSDf$route_id==curRoute),][1,]
                nextSchdMix <- subset(schdTSDf,schdTSDf$altered_departure_time>schdAnchorMix$altered_departure_time)
                
                if(nrow(nextSchdMix)<1){
                        mixSchdHeadway<-NA
                } else {
                        nextSchdMix<-nextSchdMix[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)>180) {
                                mixSchdHeadway<-NA
                        } else {
                                mixSchdHeadway <- round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)
                        }
                }
        } else {
                # If we find a trip value, and it is the right value
                nextSchdMix <- subset(schdTSDf,schdTSDf$altered_departure_time>schdAnchorMix$altered_departure_time)
                
                if(nrow(nextSchdMix)<1){
                        mixSchdHeadway<-NA
                } else {
                        nextSchdMix<-nextSchdMix[1,]
                        # If scheduled headway greater than 2 hours then set to NA, gets rid of large gap between morning and night segments
                        if (round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)>180) {
                                mixSchdHeadway<-NA
                        } else {
                                mixSchdHeadway <- round(as.numeric(difftime(nextSchdMix$altered_departure_time,schdAnchorMix$altered_departure_time, units="mins")),2)
                        }
                }
        }
        mixSchdHeadway
}



FindQuickestNextScheduledBus <- function(nextStartData,curBusStop,curBusStopSeq) {
        # Entering logic for finding next scheduled bus
        if (nrow(nextStartData)==0) {
                returnData<-NA
                return(returnData)
        } else {
                l = 1
        }
        
        totalTravelTime<-matrix(ncol=4,nrow = nrow(nextStartData))
        colnames(totalTravelTime)<-c("Bus","TimeTillStart","EstTravelTime","StopSequence")
        
        # Loop through the schedule to make sure the bus comes to this stop
        while(l!=nrow(nextStartData)+1) {
                nextStartInQuestionMix <- nextStartData[l,]
                nextStartLocMix <- 1
                
                # Make sure this stop is in the next schedueled
                if(curBusStop %in% nextStartInQuestionMix) {
                        a <- which(nextStartInQuestionMix %in% curBusStop)
                        if (length(a)>2) {
                                if(curBusStopSeq==1) {
                                        a<-a[2]
                                        nextStartGoesToCurrentMix <- nextStartInQuestionMix[a]
                                } else {
                                        a<-a[3]
                                        nextStartGoesToCurrentMix <- nextStartInQuestionMix[a]
                                }
                        } else if (length(a)>1) {
                                a<-a[2]
                                nextStartGoesToCurrentMix <- nextStartInQuestionMix[a]
                        } else {
                                nextStartGoesToCurrentMix <- nextStartInQuestionMix[a]
                        }
                        
                        
                        # Need to get to the side of the dataframe that hold est times not stop id
                        desiredStopSeq <- (a-19)-((length(nextStartData)-19)/2)
                        
                        totalTravelTime[l,1]<-l
                        totalTravelTime[l,2]<-as.numeric(difftime(nextStartInQuestionMix[,"altered_departure_time"],as.POSIXct(currentTime),"mins"))
                        totalTravelTime[l,3]<-sum(nextStartInQuestionMix[,(20):(desiredStopSeq+18)])
                        totalTravelTime[l,4]<-desiredStopSeq
                        l=l+1
                        next
                        
                } else {
                        totalTravelTime[l,1]<-l
                        totalTravelTime[l,2]<-NA
                        totalTravelTime[l,3]<-NA
                        totalTravelTime[l,4]<-NA
                        l = l+1 
                        next
                }
                
        }
        
        if(all(is.na(totalTravelTime[,c(2,3)]))==TRUE) {
                returnData<-NA
                return(returnData)
        } else if (nrow(totalTravelTime)==1) {
                sums<-sum(totalTravelTime[,c(2,3)])
                sums[which(sums==0)]<-NA
        } else {
                sums <- rowSums(totalTravelTime[,c(2,3)],na.rm = T)
                sums[which(sums==0)]<-NA   
        }
        
        
        if(all(is.na(sums))) {
                returnData<-NA
        } else {
                busNumber<-which(sums==min(sums,na.rm = T))[1]
                returnData <- list(nextStartData[busNumber,],totalTravelTime[busNumber,4],totalTravelTime[busNumber,3])
        }
        
        
        return(returnData)
        
}

FindQuickestNextLiveBus <- function(nextBusHere,curStop,curStopSeq) {
        
        totalTravelTime<-matrix(ncol=3,nrow = nrow(nextBusHere))
        colnames(totalTravelTime)<-c("Bus","EstTravelTime","StopSequenceItComesHere")
        
        z=1
        # Check the live buses to see if any of them come to this location
        while(z!=nrow(nextBusHere)+1) {
                liveBusesCheck <- nextBusHere[z,]
                
                # Make sure this stop is in the next schedueled
                if(curStop %in% liveBusesCheck) {
                        a <- which(liveBusesCheck %in% curStop)
                        if (length(a)>2) {
                                if(curStopSeq==1) {
                                        a<-a[2]
                                        nextStartGoesToCurrentMix <- liveBusesCheck[a]
                                } else {
                                        a<-a[3]
                                        nextStartGoesToCurrentMix <- liveBusesCheck[a]
                                }
                        }else if (length(a)>1) {
                                a<-a[2]
                                nextStartGoesToCurrentMix <- liveBusesCheck[a]
                        } else {
                                nextStartGoesToCurrentMix <- liveBusesCheck[a]
                        }
                        
                        # Need to get to the side of the dataframe that hold est times not stop id
                        desiredStopSeq <- (a-13)-((length(liveBusesCheck)-13)/2)
                        
                        totalTravelTime[z,1]<- z
                        totalTravelTime[z,2]<- sum(liveBusesCheck[,(liveBusesCheck[,"stop_sequence"]+13):(desiredStopSeq+12)])
                        totalTravelTime[z,3]<- desiredStopSeq
                        z=z+1
                        
                } else {
                        totalTravelTime[z,1]<-z
                        totalTravelTime[z,2]<-NA
                        totalTravelTime[z,3]<-NA
                        z=z+1 
                        
                }
        }
        
        if(all(is.na(totalTravelTime[,2]))==TRUE){
                returnData <- NA
        } else {
                busNumber<-which(totalTravelTime[,2]==min(totalTravelTime[,2],na.rm = T))[1]
                returnData <- list(nextBusHere[busNumber,],totalTravelTime[busNumber,3],totalTravelTime[busNumber,2]) 
        }
        return(returnData)
}


findLiveAndNextTrips <- function(obsDf,busEstimates,schdDf) {
        # Look at the largest timestamp and take ones form last 10 minutes
        apiTimestamps <- sort(unique(obsDf$api_timestamp))
        maxAPI <- max(apiTimestamps)
        reasonableTime <- maxAPI-600
        
        apiTimestamps<-apiTimestamps[which(apiTimestamps>reasonableTime)]
        obsDf <- subset(obsDf,obsDf$api_timestamp %in% apiTimestamps)
        obsDf<-obsDf[order(obsDf$stop_sequence),]
        
        # Find only the trips that are the latest and remove trips at stop 1
        obsDf<-obsDf[!duplicated(obsDf[,c(2,3,4)],fromLast = TRUE),]
        obsDf<-obsDf[which(obsDf$stop_sequence!=1),]
        
        # Introduce the estimates and stops into observed data
        liveAndEst <- merge(obsDf,busEstimates,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
        
        # Remove trips that reached the last stop
        liveAndEst <- liveAndEst[which(liveAndEst$maxStop!=liveAndEst$stop_sequence),]
        liveAndEst <- liveAndEst[order(liveAndEst$stop_sequence,liveAndEst$timestamp),]
        
        if(nrow(liveAndEst)<=1){return(NA)}
        
        # Logic for next scheduled Bus within the next hour
        nextBuses <- schdDf[which(schdDf$route_short_name==uniqRoutes[i] & schdDf$altered_departure_time > as.POSIXct(currentTime) & schdDf$stop_sequence == 1),]
        nextBuses <- nextBuses[order(nextBuses$altered_departure_time),]
        nextBuses <- subset(nextBuses, nextBuses$altered_departure_time < as.POSIXct(currentTime)+3600)
        nextBusesAndEst <- merge(nextBuses,busEstimates,by.x=c("trip_id","route_id","route_short_name","version"),by.y=c("tripId","routeId","route_short_name","version"))
       
        return(list(liveAndEst,nextBusesAndEst)) 
}

# Finding unique routes for the day to iterate over #
uniqRoutes <- unique(busData.df[,"route_short_name"])

# Reducing number of routes to ones with headway under 15 minutes
uniqRoutes <- subset(uniqRoutes, uniqRoutes %in% desiredBusRoutes.df[,1])

# Preallocating data frame for headway #
headway <- data.frame()

currentEstimate <- data.frame(matrix(ncol=12,nrow = 0))
colnames(currentEstimate) <- c("route_short_name","currentStopId","currentBusRoute","nextBusRoute","currentBusTrip","nextBusTrip","currentStopSeq","nextBusLoc","estBusTravelTime","curSchdHeadway", "currentTime")

mixEstimate <- data.frame(matrix(ncol=15,nrow = 0))
colnames(mixEstimate) <- c("route_short_name","stop","currentBusRoute","nextBusRoute","currentBusTrip","mixCurrentTimestamp","nextBusTrip","currentStop","nextBusLoc","timeSinceHere","timeTillStartNext","estBusTravelTimeMix","estMixedHeadway","mixSchdHeadway", "currentTime")
        

####################################################################################################################
### Looping through all the routes for the day to calc THREE headways for each stop on the route ###
### Need to keep the loop as numeric as we create vectors of values, if we use the variable itself we get issues ###
####################################################################################################################
for(i in 1:length(uniqRoutes)) {
        
        routeSchdTimes.df <- subset(scheduledBusStops.df, scheduledBusStops.df$route_short_name==uniqRoutes[i])
        routeBusEstimates.df <- subset(busTimeEstimates.df, busTimeEstimates.df$route_short_name==uniqRoutes[i])
        collectedBusDataThisRoute.df <- busData.df[which(busData.df$route_short_name==uniqRoutes[i]),]
        route_short_name <- uniqRoutes[i]
        #####################################
        # HEADWAY Estimator Observed: 1     #     
        #####################################
        
        tempHeadway<-calcObservedHeadway(route_short_name,collectedBusDataThisRoute.df,routeSchdTimes.df)
        
        headway <- rbind(headway,tempHeadway)
        ##################################################################################################################################
        
        # Since mixed looks at every stop it will look at stop sequence 1
        
        
        # Find all Live Trips and Next Trips
        prepDataReturn <- findLiveAndNextTrips(collectedBusDataThisRoute.df,routeBusEstimates.df,routeSchdTimes.df)
        
        if(length(prepDataReturn)<2) {
                next
        }
        
        liveBusesAndEstTimes.df <- prepDataReturn[[1]]
        nextStartAndEstTimes.df <- prepDataReturn[[2]]
        
        
        #####################################
        # HEADWAY Estimator Current         #     
        #####################################
        
        routeTravelInfo <- calculateCurrentEstimator(liveBusesAndEstTimes.df,routeSchdTimes.df,nextStartAndEstTimes.df)
        routeTravelInfo <- cbind(route_short_name,routeTravelInfo,currentTime)
        currentEstimate <- rbind(currentEstimate,routeTravelInfo)

        
        
        #####################################
        # HEADWAY Estimator Mixed           #     
        #####################################
        
        mixOutput<-calculateMixedEstimator(route_short_name, collectedBusDataThisRoute.df, liveBusesAndEstTimes.df, routeSchdTimes.df, nextStartAndEstTimes.df)
        mixOutput <- cbind(route_short_name,mixOutput,currentTime)
        mixEstimate <- rbind(mixEstimate,mixOutput)
        
        
}

# Appending the headway for each route to a larger external headway 
headway<-cbind(headway,currentTime)



print("Overall Headway Timer")
print(Sys.time()-overallHeadwayTimer)
print("Numebr of loops")
print(length(uniqRoutes))
####################################################################################################################################




##################################
##################################
##### Output of Calculations #####
##################################
##################################
csvSaveTime <- Sys.time()

summaryOutFileLoc = paste(APPLOC,'headway/data/headwaySummary/',sep="")

pureOutFile <- paste(summaryOutFileLoc, 'pureSummary', currentDate, '.csv', sep = '')
mixOutFile <- paste(summaryOutFileLoc, 'mixEstimateSummary', currentDate, '.csv', sep = '')
currentOutFile <- paste(summaryOutFileLoc, 'curEstimateSummary', currentDate, '.csv', sep = '')

        ### Pure history ###
if (file.exists(pureOutFile) == FALSE)
{
        write.table(headway, pureOutFile, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(headway, pureOutFile, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}


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

print("CSV Save Time")
print(Sys.time()-csvSaveTime)


flush(stderr())
################################################################################################################

print("Finished Headway Calc/Comparison: Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())
