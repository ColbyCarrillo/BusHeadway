
##### R script file to call API and headway #####

### Note: need to add in sleep logic for if it tries to run to early or too late

startTime = "06:00:00"
endTime = "22:00:00"

APPLOC="/home/ccar788/"

currentTime = Sys.time()
fullStartTime = as.POSIXlt(paste(Sys.Date(),startTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())
fullEndTime = as.POSIXlt(paste(Sys.Date(),endTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())

callsPerMinute = 3

APICallLocation = paste(APPLOC,"BusHeadway/code/api/callTripUpdatesAPI.py",sep="")
APICallFull = sprintf("python3 %s", APICallLocation)
APIParseLocation = paste(APPLOC,"BusHeadway/code/api/pythonParse.py",sep="")
APIParseFull = sprintf("python3 %s", APIParseLocation)


# If currentTime is before the start time
if ((currentTime < fullStartTime)==TRUE) {
        timeToWait <- as.integer(floor(difftime(fullStartTime,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        timeToRunSecs <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="secs")))
        loopsLeft = as.integer(ceiling(timeToRunSecs/ (60/callsPerMinute)))
        
        
        # Run API R code every 20 seconds between 6:00 AM and 10:00 PM - 180 per hour x 16 hours - 2880 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call API and save it to a JSON file
                system(APICallFull)
                
                # Call parser to parse JSON to SQL and insert into database. Archives the file**** Need to remove
                system(APIParseFull)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                timeToSleep <- ifelse(((60/callsPerMinute)-timeTookToRun)<0,0,((60/callsPerMinute)-timeTookToRun))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                Sys.sleep(timeToSleep)
        }
        
        
        break
        # If current TIme is before the end time
} else if ((currentTime < fullEndTime)==TRUE) {
        timeToRunSecs <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="secs")))
        loopsLeft = as.integer(ceiling(timeToRunSecs/ (60/callsPerMinute)))
        
        
        # Run API R code every 20 seconds between 6:00 AM and 10:00 PM - 180 per hour x 16 hours - 2880 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call API and save it to a JSON file
                system(APICallFull)
                
                # Call parser to parse JSON to SQL and insert into database. Archives the file**** Need to remove
                system(APIParseFull)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                timeToSleep <- ifelse(((60/callsPerMinute)-timeTookToRun)<0,0,((60/callsPerMinute)-timeTookToRun))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                Sys.sleep(timeToSleep)
        }
       
        break
        # If current time is after the end time      
} else if ((currentTIme > fullEndTime)==TRUE) {
        
        timeToWait <- as.integer(floor(difftime(fullStartTime+86400,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        timeToRunSecs <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="secs")))
        loopsLeft = as.integer(ceiling(timeToRunSecs/ (60/callsPerMinute)))
        
        
        # Run API R code every 20 seconds between 6:00 AM and 10:00 PM - 180 per hour x 16 hours - 2880 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call API and save it to a JSON file
                system(APICallFull)
                
                # Call parser to parse JSON to SQL and insert into database. Archives the file**** Need to remove
                system(APIParseFull)
                
                timeTookToRun <- as.numeric(difftime(Sys.time(),subScriptStartTime,units="secs"))
                timeToSleep <- ifelse(((60/callsPerMinute)-timeTookToRun)<0,0,((60/callsPerMinute)-timeTookToRun))
                
                print("Loops Left")
                print(loopsLeft-i)
                
                Sys.sleep(timeToSleep)
        }
        break
        
        
        # Something is wrong space    
} else {
        stop("Time has surpassed human reality....")
}


print("Finished Pulling Trip Updates Output for the day: Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())
        
