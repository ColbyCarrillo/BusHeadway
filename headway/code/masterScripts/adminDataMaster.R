
##### R script file to call scheduled files and admin data #####

scriptStartTime <- Sys.time()

print("Starting Admin Update")
print(scriptStartTime)

APPLOC="/home/ccar788/"


##### Call admin data script #####

adminScriptLocation <- paste(APPLOC,"headway/code/admin/checkAdminUpdate.py",sep="")
adminCallFull <- sprintf("python3 %s", adminScriptLocation)
system(adminCallFull)


print("Finished Pulling Admin Data: Total Script Time")
print(Sys.time()-scriptStartTime)

##### Area for pulling scheduled buses for the day #####

schdBusScripLocation <- paste(APPLOC,"headway/code/admin/pullScheduledTrips.R",sep="")
schdCallFull <- sprintf("Rscript %s", schdBusScripLocation)
system(schdCallFull)

print("Finished Pulling Scheduled Trips: Time")
print(Sys.time()-scriptStartTime)


####

##### Area for estimating travel time of scheduled buses for the day #####

busEstScripLocation <- paste(APPLOC,"headway/code/admin/estimateTravelTime.R",sep="")
busEstCallFull <- sprintf("Rscript %s", busEstScripLocation)
system(busEstCallFull)

print("Finished Pulling Estimated Scheduled Trips: Time")
print(Sys.time()-scriptStartTime)


####

