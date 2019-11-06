
##### R script file to call headway and output #####
library(RSQLite)
scriptStartTime <- Sys.time()
print("Starting Headway Script")
print(scriptStartTime)

APPLOC="/home/ccar788/"

### Note: need to add in sleep logic for if it tries to run to early or too late ###

startTime = "07:00:00"
endTime = "22:00:00"

currentTime = Sys.time()
fullStartTime = as.POSIXlt(paste(Sys.Date(),startTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())
fullEndTime = as.POSIXlt(paste(Sys.Date(),endTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())

minutesBetweenCall = 10
#Used for sleep
secondsBetweenCall = minutesBetweenCall*60

headwayScriptLocation = paste(APPLOC,'headway/code/headway/busHeadway-Prod.R',sep="")

headwayFull = sprintf("Rscript %s", headwayScriptLocation)



# If currentTime is before the start time
if ((currentTime < fullStartTime)==TRUE) {
        
        timeToWait <- as.integer(floor(difftime(fullStartTime,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        # Want to check that we dont have issue with our admin data
        
        dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
        dbCon <- dbConnect(SQLite(),dbLoc)
        actualResultsTest <- dbSendQuery(dbCon, "SELECT * FROM TripUpdates WHERE arrival ='0'")
        busDataTest.df <- dbFetch(actualResultsTest)
        actualResults <- dbSendQuery(dbCon, "SELECT * FROM bus")
        busData.df <- dbFetch(actualResults)
        
        if (nrow(busDataTest.df)==nrow(busData.df)) {
                
        }else {
                if(abs(nrow(busData.df)-nrow(busDataTest.df))>1000) {
                        
                } else {
                        print("Ran into issues with admin data, rerunning all admin collection")
                        adminLoc = paste(APPLOC,"headway/code/admin/",sep="")
                        currentFiles <- list.files(adminLoc)
                        removeFile<-currentFiles[currentFiles %in% grep("Last",currentFiles, value=T)]
                        file.remove(paste(adminLoc,removeFile,sep=""))
                        
                        adminScriptLocation <- paste(APPLOC,"headway/code/admin/checkAdminUpdate.py",sep="") 
                        adminCallFull <- sprintf("python3 %s", adminScriptLocation)
                        system(adminCallFull)
                        schdBusScripLocation <- paste(APPLOC,"headway/code/admin/pullScheduledTrips.R",sep="")
                        schdCallFull <- sprintf("Rscript %s", schdBusScripLocation)
                        system(schdCallFull)
                        busEstScripLocation <- paste(APPLOC,"headway/code/admin/estimateTravelTime.R",sep="")
                        busEstCallFull <- sprintf("Rscript %s", busEstScripLocation)
                        system(busEstCallFull) 
                }
        }
        
        
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv file
                y<-tryCatch(system(headwayFull))#,
                            #error=function(e){print(e)})
                #print(y)
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                # Calls output generation, still working on
                #system(outputFull)
                Sys.sleep(secondsBetweenCall-timeTookToRun)
        }
        break
        # If current TIme is before the end time
} else if ((currentTime < fullEndTime)==TRUE) {
        
        # Want to check that we dont have issue with our admin data
        
        dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
        dbCon <- dbConnect(SQLite(),dbLoc)
        actualResultsTest <- dbSendQuery(dbCon, "SELECT * FROM TripUpdates WHERE arrival ='0'")
        busDataTest.df <- dbFetch(actualResultsTest)
        actualResults <- dbSendQuery(dbCon, "SELECT * FROM bus")
        busData.df <- dbFetch(actualResults)
        if (nrow(busDataTest.df)==nrow(busData.df)) {
                
        }else {
                if(abs(nrow(busData.df)-nrow(busDataTest.df))>1000) {
                        
                } else {
                        print("Ran into issues with admin data, rerunning all admin collection")
                        adminLoc = paste(APPLOC,"headway/code/admin/",sep="")
                        currentFiles <- list.files(adminLoc)
                        removeFile<-currentFiles[currentFiles %in% grep("Last",currentFiles, value=T)]
                        file.remove(paste(adminLoc,removeFile,sep=""))
                        
                        adminScriptLocation <- paste(APPLOC,"headway/code/admin/checkAdminUpdate.py",sep="") 
                        adminCallFull <- sprintf("python3 %s", adminScriptLocation)
                        system(adminCallFull)
                        schdBusScripLocation <- paste(APPLOC,"headway/code/admin/pullScheduledTrips.R",sep="")
                        schdCallFull <- sprintf("Rscript %s", schdBusScripLocation)
                        system(schdCallFull)
                        busEstScripLocation <- paste(APPLOC,"headway/code/admin/estimateTravelTime.R",sep="")
                        busEstCallFull <- sprintf("Rscript %s", busEstScripLocation)
                        system(busEstCallFull) 
                }
        }
        
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv file
                y<-tryCatch(system(headwayFull))
                #error=function(e){print(e)})
                #print(y)
         
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                # Calls output generation, still working on
                #system(outputFull)
                Sys.sleep(secondsBetweenCall-timeTookToRun)
        }
        
        break
        # If current time is after the end time
} else if ((currentTIme > fullEndTime)==TRUE) {
        timeToWait <- as.integer(floor(difftime(fullStartTime+86400,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        # Want to check that we dont have issue with our admin data
        
        dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
        dbCon <- dbConnect(SQLite(),dbLoc)
        actualResultsTest <- dbSendQuery(dbCon, "SELECT * FROM TripUpdates WHERE arrival ='0'")
        busDataTest.df <- dbFetch(actualResultsTest)
        actualResults <- dbSendQuery(dbCon, "SELECT * FROM bus")
        busData.df <- dbFetch(actualResults)
        if (nrow(busDataTest.df)==nrow(busData.df)) {
                
        }else {
                if(abs(nrow(busData.df)-nrow(busDataTest.df))>1000) {
                        
                } else {
                        print("Ran into issues with admin data, rerunning all admin collection")
                        adminLoc = paste(APPLOC,"headway/code/admin/",sep="")
                        currentFiles <- list.files(adminLoc)
                        removeFile<-currentFiles[currentFiles %in% grep("Last",currentFiles, value=T)]
                        file.remove(paste(adminLoc,removeFile,sep=""))
                        
                        adminScriptLocation <- paste(APPLOC,"headway/code/admin/checkAdminUpdate.py",sep="") 
                        adminCallFull <- sprintf("python3 %s", adminScriptLocation)
                        system(adminCallFull)
                        schdBusScripLocation <- paste(APPLOC,"headway/code/admin/pullScheduledTrips.R",sep="")
                        schdCallFull <- sprintf("Rscript %s", schdBusScripLocation)
                        system(schdCallFull)
                        busEstScripLocation <- paste(APPLOC,"headway/code/admin/estimateTravelTime.R",sep="")
                        busEstCallFull <- sprintf("Rscript %s", busEstScripLocation)
                        system(busEstCallFull) 
                }
        }
        
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv file
                y<-tryCatch(system(headwayFull))
                #error=function(e){print(e)})
                #print(y)

                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                # Calls output generation, still working on 
                #system(outputFull)
                Sys.sleep(secondsBetweenCall-timeTookToRun)
        }
        break
        
        
        # Something is wrong space    
} else {
        stop("Time has surpassed human reality....")
}



print("Finished Headway and Output for the day: Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())
        
