##### Runs once daily to pull scheduled buses and save to csv file for headway #####

scriptStartTime <- Sys.time()
print("Pulling/Computing Scheduled Data")
print(scriptStartTime)

APPLOC="/home/ccar788/"


library(RSQLite)
library(stringr)
library(dplyr)


dbLoc <- paste(APPLOC,"headway/data/database/BhProd.db",sep="")
dbCon <- dbConnect(SQLite(),dbLoc)


### Querying Stop_Times table for Schedued Trips  ###
actualResults <- dbSendQuery(dbCon, "SELECT * FROM schd")
scheduledBusData.df <- dbFetch(actualResults)

routeResults <- dbSendQuery(dbCon, "SELECT * FROM Routes")
routes.df <- dbFetch(routeResults)

dbDisconnect(dbCon)

# Code to remove schools from the list of route_short_names
schoolKeyWords <- c("Intermediate","College", "Schools", "Primary", "School", "Grammar","Boys","Girls", "High", "Sacred Heart")
pattern <- paste(schoolKeyWords, collapse="|")
goodRoutes <- routes.df[which(grepl(pattern, routes.df$route_long_name)==FALSE),"route_short_name"] 


### Calculate relevant trips ###

headwayCutOff <- 16


scheduledBusStops.df <- scheduledBusData.df
keepers <- c("trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence", "route_id", "Monday", "Tuesday", "Wednesday"
             , "Thursday", "Friday", "Saturday", "Sunday", "start_date", "end_date", "route_short_name")
scheduledBusStops.df <- scheduledBusStops.df[keepers]

# Removes stops which are outside the desired time
scheduledBusStops.df <- scheduledBusStops.df[which(scheduledBusStops.df$departure_time >= "06:00:00" & scheduledBusStops.df$departure_time <= "23:00:00"),]



# Reduce rows of scheduled dataframe by observed versions
scheduledBusStops.df$version <- str_sub(scheduledBusStops.df$trip_id, start= -5)

# Reformat scheduled data frame
scheduledBusStops.df$trip_id <- as.character(scheduledBusStops.df$trip_id)
scheduledBusStops.df$stop_id <- as.character(scheduledBusStops.df$stop_id)
scheduledBusStops.df$route_id <- as.character(scheduledBusStops.df$route_id)
scheduledBusStops.df$start_date <- as.Date(as.character(scheduledBusStops.df$start_date), "%Y%m%d")
scheduledBusStops.df$end_date <- as.Date(as.character(scheduledBusStops.df$end_date), "%Y%m%d")

# Receiving NA's as some of the times are over 24 hours..... NEED TO FIX
scheduledBusStops.df$altered_departure_time <- as.POSIXct(paste(Sys.Date(),scheduledBusStops.df$departure_time,sep=' '),tz=Sys.timezone(),"%Y-%m-%d %H:%M:%S")



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
uniqScheduledRoutesSN <- data.frame(unique(scheduledBusStops.df[,c(16,17)]),0)
uniqScheduledRoutesSN <- subset(uniqScheduledRoutesSN, uniqScheduledRoutesSN$route_short_name %in% goodRoutes)
colnames(uniqScheduledRoutesSN) <- c("route_short_name","version","avgHeadway")

for (i in 1:length(uniqScheduledRoutesSN[,1]))
{
        # Load in all values with that route name and version
        temp <- scheduledBusStops.df[which(scheduledBusStops.df$route_short_name == uniqScheduledRoutesSN[i,1] & scheduledBusStops.df$version == uniqScheduledRoutesSN[i,2]),]
        
        # Find all unique stops on that route
        uniqStopsOnRoutes <- unique(temp[,"stop_id"])
        stopMeanHeadway <- data.frame(uniqStopsOnRoutes,0,0)
        colnames(stopMeanHeadway) <- c("stop_id","numOfTrips","meanHeadway")
        
        for (stops in 1:length(uniqStopsOnRoutes)) {
                # Grab the subsection for this unique stop and order
                subTemp <- temp[which(temp$stop_id == uniqStopsOnRoutes[stops]),]
                subTemp <- subTemp[order(subTemp$altered_departure_time),]
                subTemp$headway <- NA
                
                if(nrow(subTemp)==0 | nrow(subTemp)==1){
                        stopMeanHeadway[stops,2] <- NA
                        stopMeanHeadway[stops,3] <- nrow(subTemp)
                        next
                }
                
                # Find the headway between each bus at this stop
                for (k in 2:nrow(subTemp)) {
                        subTemp$headway[k] <- as.numeric(difftime(subTemp$altered_departure_time[k],subTemp$altered_departure_time[k-1],units = "mins"))   
                }

                stopMeanHeadway[stops,2] <- nrow(subTemp)
                stopMeanHeadway[stops,3] <- mean(subTemp$headway, na.rm = TRUE)
        }
        
        # Use the number of trips to minus off the first one which would have a headway of 0, does not add to the equation and shouldnt be used        
        stopMeanHeadway$TotalContribution <- stopMeanHeadway$meanHeadway * (stopMeanHeadway$numOfTrips-1)/sum(stopMeanHeadway$numOfTrips-1,na.rm = TRUE)
        
        uniqScheduledRoutesSN[i,3] <- sum(stopMeanHeadway$TotalContribution, na.rm=TRUE)
        
}

totalUniqScheduledRoutesSN <- uniqScheduledRoutesSN
uniqScheduledRoutesSN <- uniqScheduledRoutesSN[which(uniqScheduledRoutesSN$avgHeadway < headwayCutOff & uniqScheduledRoutesSN$avgHeadway!=0),]


### Save text file for routes + version over minimum ###
routeFileName <- "desiredRoutes"
routeFileLoc <- paste(APPLOC,'headway/data/database/',sep="")
routeFullFileName <- paste(routeFileName,Sys.Date(),".csv",sep = "")

currentFilesR <- list.files(routeFileLoc)

oldFilesR <- currentFilesR[currentFilesR %in% grep(routeFileName,currentFilesR, value=T)]
if (length(oldFilesR) > 0) {
        for(i in oldFilesR) {
                file.remove(paste(routeFileLoc,i,sep=""))
        }
        write.table(uniqScheduledRoutesSN, paste(routeFileLoc,routeFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
} else {
        write.table(uniqScheduledRoutesSN, paste(routeFileLoc,routeFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
}


totalRouteFileName <- "totalRoutesHeadway"
totalRouteFileLoc <- paste(APPLOC,'headway/data/database/',sep="")

totalRouteFullFileName <- paste(totalRouteFileName,Sys.Date(),".csv",sep = "")

currentFilesTR <- list.files(totalRouteFileLoc)

oldFilesTR <- currentFilesTR[currentFilesTR %in% grep(totalRouteFileName,currentFilesTR, value=T)]
if (length(oldFilesTR) > 0) {
        for(i in oldFilesTR) {
                file.remove(paste(totalRouteFileLoc,i,sep=""))
        }
        write.table(totalUniqScheduledRoutesSN , paste(totalRouteFileLoc,totalRouteFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
} else {
        write.table(totalUniqScheduledRoutesSN , paste(totalRouteFileLoc,totalRouteFullFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
}


### Save csv file for headway to pull ###

fileName <- "scheduledBuses"
scheduleFileLoc <- paste(APPLOC,'headway/data/database/',sep="")
scheduleFileName <- paste(fileName,Sys.Date(),".csv",sep = "")

currentFiles <- list.files(scheduleFileLoc)

oldFiles <- currentFiles[currentFiles %in% grep(fileName,currentFiles, value=T)]

if (length(oldFiles) > 0) {
        for(i in oldFiles) {
                file.remove(paste(scheduleFileLoc,i,sep=""))
        }
        write.table(scheduledBusData.df, paste(scheduleFileLoc,scheduleFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
} else {
        write.table(scheduledBusData.df, paste(scheduleFileLoc,scheduleFileName,sep = ""), col.names = TRUE, row.names = FALSE, sep = ",")
}


print("Finished Computing Scheduled Data")
print(Sys.time()-scriptStartTime)
print(Sys.time())