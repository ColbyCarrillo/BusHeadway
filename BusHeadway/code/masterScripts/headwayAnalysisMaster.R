
##### R script file to call headway and output #####

scriptStartTime <- Sys.time()
print("Starting Headway Script")
print(scriptStartTime)

APPLOC="/home/ccar788/"

### Note: need to add in sleep logic for if it tries to run to early or too late ###

startTime = "07:05:00"
endTime = "22:00:00"

currentTime = Sys.time()
fullStartTime = as.POSIXlt(paste(Sys.Date(),startTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())
fullEndTime = as.POSIXlt(paste(Sys.Date(),endTime), format = "%Y-%m-%d %H:%M:%S", tz=Sys.timezone())

minutesBetweenCall = 10
#Used for sleep
secondsBetweenCall = minutesBetweenCall*60

headwaySummaryScriptLocation = paste(APPLOC,'headway/code/headway/busHeadwaySummary-Prod.R',sep="")
stopHeadwaySummaryScriptLocation = paste(APPLOC,'headway/code/headway/busHeadwaySummaryStops-Prod.R',sep="")
headwaySummaryFull = sprintf("Rscript %s", headwaySummaryScriptLocation)
stopHeadwaySummaryFull = sprintf("Rscript %s", stopHeadwaySummaryScriptLocation)


# If currentTime is before the start time
if ((currentTime < fullStartTime)==TRUE) {
        
        timeToWait <- as.integer(floor(difftime(fullStartTime,Sys.time(),units = "secs")))
        Sys.sleep(timeToWait)
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv fiel
                system(headwaySummaryFull)
                system(stopHeadwaySummaryFull)
                
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
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv fiel
                system(headwaySummaryFull)
                system(stopHeadwaySummaryFull)
                
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
        
        timeToRunMins <- as.integer(floor(difftime(fullEndTime, Sys.time(),units="min")))
        loopsLeft = as.integer(ceiling(timeToRunMins/minutesBetweenCall))
        
        # Run headway calculations and output every 15 minutes from 6:00 AM and 10:00 PM - 4 per hour x 16 hours - 64 times total
        for (i in 1:loopsLeft) {
                subScriptStartTime <- Sys.time()
                
                # Call headway, saved to csv fiel
                system(headwaySummaryFull)
                system(stopHeadwaySummaryFull)
                
                
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

        
