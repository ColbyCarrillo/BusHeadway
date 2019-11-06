
##### R script file to call all other master script #####
##### Each individual script manages there own time, this script is responsible for the inital daily kick off #####
##### All scripts will be started once at the beginning of the day in order: databaseManage, adminData, apiPull, and then Headway #####

print("Start of Master of Masters Script")
print(Sys.time())

APPLOC="/home/ccar788/"

masterScriptsLocation <- paste(APPLOC,"BusHeadway/code/masterScripts/",sep="")

databaseManage <- "databaseManageMaster.R"        
adminData <- "adminDataMaster.R"
databaseTripUpdates <- "databaseTripUpdatesMaster.R"
headwayCalc <- "headwayCalcMaster.R"
headwayAnalaysis <- "headwayAnalysisMaster.R"
apiPull <- "apiPullMaster.R"

# Cleans Database Admin Data (once)
databaseCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, databaseManage, sep=""))
# Retrieves Database Admin Data If Updates  (once)
adminCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, adminData, sep=""))
# Deletes old TripUpdates (hourly)
databaseTripUpdatesCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, databaseTripUpdates, sep=""))
# Runs Headway Calculations (15 min)
headwayCalcCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, headwayCalc, sep=""))
# Runs Headway Calculations (15 min)
headwayAnalysisCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, headwayAnalaysis, sep=""))
# Pulls TripUpdates Data (20s)
apiCommandFull <- sprintf("Rscript %s", paste(masterScriptsLocation, apiPull, sep=""))

currentTimeDay <- Sys.time()
currentTime <- format(currentTimeDay, format="%H:%M:%S")
# Adding an hour so admin scripts can run from 6 AM
startOfDay <- "05:00:00"
endOfDay <- "22:00:00"




# If current time is less than start of day
if ((currentTime <= startOfDay) == TRUE) {
        # Run database cleanse and application scripts
        system(databaseCommandFull)
        system(adminCommandFull)
        #system(databaseTripUpdatesCommandFull, wait = FALSE)
        system(headwayCalcCommandFull, wait = FALSE)
        system(headwayAnalysisCommandFull, wait = FALSE)
        system(apiCommandFull)
        
        break
        
} else if ((currentTime < endOfDay) == TRUE) {
        # If current time is less than end of day
        
        # Run application scripts
        system(adminCommandFull)
        #system(databaseTripUpdatesCommandFull, wait = FALSE)
        system(headwayCalcCommandFull, wait = FALSE)
        system(headwayAnalysisCommandFull, wait = FALSE)
        system(apiCommandFull)
        
        break
        
} else if ((currentTime > endOfDay) == TRUE) {
        # If current time is greater than end of day
        
        nextStartTime <- "01:00:00"
        nextStartTimeText <- paste(Sys.Date()+1, nextStartTime, sep = " ")
        nextStartTimeFull <- as.POSIXct(nextStartTimeText, format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())
        
        waitTime <- floor(difftime(nextStartTimeFull,currentTimeDay,units = "secs"))
        Sys.sleep(waitTime)
        
        # Run database cleanse and application scripts
        system(databaseCommandFull)
        system(adminCommandFull)
        #system(databaseTripUpdatesCommandFull, wait = FALSE)
        system(headwayCalcCommandFull, wait = FALSE)
        system(headwayAnalysisCommandFull, wait = FALSE)
        system(apiCommandFull)
        
        break
        
} else {
        # Something is wrong space 
        stop("Time has surpassed human reality....")
}




print("End of Master of Masters Script: Cya Tomorrow")
print(Sys.time())
