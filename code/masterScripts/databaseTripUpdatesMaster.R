library(RSQLite)

##### Script to ensure TripUpdates is not over X hours old ######

scriptStartTime <- Sys.time()
print("Starting TripUpdates Cleaning Script")
print(scriptStartTime)

APPLOC="/home/ccar788/"



# Connection information
databaseLocation <- paste(APPLOC,"BusHeadway/data/database/",sep="")
database <- "BhProd.db"
dbLoc <- paste(databaseLocation,database,sep="")
databaseDeleteScriptLocation <- paste(APPLOC,"BusHeadway/code/database/deletion/",sep="")
tripUpdatesScript <- "DeleteOldTripUpdates.sql"
tripUpdatesScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,tripUpdatesScript)),collapse=" ")


# Variables for how long I want to run

currentTime <- Sys.time()

startTime <- "05:00:00"
startTimeText <- paste(Sys.Date(), startTime, sep = " ")
startTimeFull <- as.POSIXlt(startTimeText, format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())

stopTime <- "23:00:00"
stopTimeText <- paste(Sys.Date(), stopTime, sep = " ")
stopTimeFull <- as.POSIXlt(stopTimeText, format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())


# If currentTime is before the start time
if ((currentTime < startTimeFull)==TRUE) {
        timeToWait <- as.integer(floor(difftime(startTimeFull,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        timeToRunSecs <- as.integer(floor(difftime(stopTimeFull, Sys.time(),units="secs")))
        
        #hours to run
        timeToRun <- ceiling(timeToRunSecs/60/60)+1
        
        for(i in 1:timeToRun) {
                subScriptStartTime <- Sys.time()
                print("Deleting Old Trip Updates via hourly script: databaseTripUpdatesMaster.R")
                print(subScriptStartTime)
                
                dbCon <- dbConnect(SQLite(),dbLoc)
                dbExecute(dbCon, tripUpdatesScriptText)
                
                dbDisconnect(dbCon)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                #sleep one hour, delete past 3 hours
                Sys.sleep(3600-timeTookToRun)
        }
        
        break
# If current TIme is before the end time
} else if ((currentTime < stopTimeFull)==TRUE) {
        
        timeToRunSecs <- as.integer(floor(difftime(stopTimeFull, Sys.time(),units="secs")))
        
        #hours to run
        timeToRun <- ceiling(timeToRunSecs/60/60)+1
        
        for(i in 1:timeToRun) {
                subScriptStartTime <- Sys.time()
                print("Deleting Old Trip Updates via hourly script: databaseTripUpdatesMaster.R")
                print(subScriptStartTime)
                
                dbCon <- dbConnect(SQLite(),dbLoc)
                dbExecute(dbCon, tripUpdatesScriptText)
                
                dbDisconnect(dbCon)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                #sleep one hour, delete past 3 hours
                Sys.sleep(3600-timeTookToRun)
        }
        
        break
        
        
# If current time is after the end time      
} else if ((currentTIme > stopTimeFull)==TRUE) {
        timeToWait <- as.integer(floor(difftime(startTimeFull+86400,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        
        timeToRunSecs <- as.integer(floor(difftime(stopTimeFull+86400, Sys.time(),units="secs")))
        
        #hours to run
        timeToRun <- ceiling(timeToRunSecs/60/60)+1
        
        for(i in 1:timeToRun) {
                subScriptStartTime <- Sys.time()
                print("Deleting Old Trip Updates via hourly script: databaseTripUpdatesMaster.R")
                print(subScriptStartTime)
                
                dbCon <- dbConnect(SQLite(),dbLoc)
                dbExecute(dbCon, tripUpdatesScriptText)
                
                dbDisconnect(dbCon)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                #sleep one hour, delete past 3 hours
                Sys.sleep(3600-timeTookToRun)
        }
        
        break
        
        
# Something is wrong space    
} else {
        stop("Time has surpassed human reality....")
}


print("Finished Removing TripUpdates For the Day: Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())



