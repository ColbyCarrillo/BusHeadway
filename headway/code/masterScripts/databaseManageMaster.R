library(RSQLite)

##### R script file to call scheduled files and admin data #####
scriptStartTime <- Sys.time()

print("Running database admin cleanup")
print(scriptStartTime)

### Call admin data script ###

APPLOC="/home/ccar788/"

databaseLocation <- paste(APPLOC,"headway/data/database/",sep="")
database <- "BhProd.db"
dbLoc <- paste(databaseLocation,database,sep="")

databaseDeleteScriptLocation <- paste(APPLOC,"headway/code/database/deletion/",sep="")

# Order of deletion required by Table
# Tier 1: Calendars
# Tier 2: Trips
# Tier 3: Routes, Stop Times
# Tier 4: Stops

calendarScript <- "DeleteOldCalendars.sql"
tripsScript <- "DeleteOldTrips.sql"
routesScript <- "DeleteOldRoutes.sql"
stopTimesScript <- "DeleteOldStopTimes.sql"
stopsScript <- "DeleteOldStops.sql"


calendarScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,calendarScript)),collapse=" ")
tripsScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,tripsScript)),collapse=" ")
routesScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,routesScript)),collapse=" ")
stopTimesScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,stopTimesScript)),collapse=" ")
stopsScriptText <- paste(readLines(sprintf("%s%s",databaseDeleteScriptLocation,stopsScript)),collapse=" ")

fileVector <- c(calendarScriptText, tripsScriptText, routesScriptText, stopTimesScriptText, stopsScriptText)


for (i in fileVector) {
        dbCon <- dbConnect(SQLite(),dbLoc)
        
        dbExecute(dbCon, i)
        
        dbDisconnect(dbCon)
}

print("Finishing database admin cleanup: Run Time")
print(Sys.time()-scriptStartTime)


