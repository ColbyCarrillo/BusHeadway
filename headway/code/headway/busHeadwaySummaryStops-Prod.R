##### This file is used to import our headway measurements and output the findings of analysis #####

scriptStartTime <- Sys.time()
print("Starting Headway Analysis: Stop POV Wait Times")
print(scriptStartTime)

APPLOC="/home/ccar788/"

library(RSQLite)
dbLoc = paste(APPLOC,"headway/data/database/BhProd.db",sep="")
dbCon <- dbConnect(SQLite(),dbLoc)

# Querying Stops to get geo location
actualResults <- dbSendQuery(dbCon, "SELECT * FROM Stops")
stopsData.df <- dbFetch(actualResults)
dbDisconnect(dbCon)



headwayDataDriectory = paste(APPLOC,'headway/data/headwaySummary/',sep="")
curDate<-Sys.Date()
pureHistHeadwayFile = paste('pureSummary',curDate,'.csv',sep="")
mixEstimatorFile = paste('mixEstimateSummary',curDate,'.csv',sep="")
currentEstimaotrFile = paste('curEstimateSummary',curDate,'.csv',sep="")

pureHistHeadway <- read.csv(paste(headwayDataDriectory, pureHistHeadwayFile, sep = ''), stringsAsFactors = FALSE)
mixEstHeadway <- read.csv(paste(headwayDataDriectory, mixEstimatorFile, sep = ''), stringsAsFactors = FALSE)
curEstHeadway <- read.csv(paste(headwayDataDriectory, currentEstimaotrFile, sep = ''), stringsAsFactors = FALSE)

### Transform data frames variables
pureHistHeadway$lastTS <- as.POSIXct(as.character(pureHistHeadway$lastTS),tz=Sys.timezone())
pureHistHeadway$twoBeforeTS <- as.POSIXct(as.character(pureHistHeadway$twoBeforeTS),tz=Sys.timezone())
pureHistHeadway$currentTime <- as.POSIXct(as.character(pureHistHeadway$currentTime),tz=Sys.timezone())

#pureHistHeadway <- pureHistHeadway[!duplicated(pureHistHeadway[,c(1:8)],fromLast=T),]


#mixEstHeadway$nextBusLocMix <- as.numeric(mixEstHeadway$nextBusLocMix)
mixEstHeadway$currentTime <- as.POSIXct(as.character(mixEstHeadway$currentTime),tz=Sys.timezone())


curEstHeadway$currentTime <- as.POSIXct(as.character(curEstHeadway$currentTime),tz=Sys.timezone())
# Move calc time up to reduce number of observations before finding what routes to iterate over.
# Move lower if you want to output the routes that don't have any data in past hour with NA's
calcTimeIteration <- Sys.time()

###########################################################################################

observedHeadwayWithStops <- merge(x=pureHistHeadway,y=stopsData.df[,1:5],by.x=c("stopId"),by.y=c("stop_id"))
observedHeadwayWithStops <- observedHeadwayWithStops[order(observedHeadwayWithStops$lastTS),]

# Only looking at the last timestamp of information
times <- unique(observedHeadwayWithStops$currentTime)
observedHeadwayWithStops<-subset(observedHeadwayWithStops,observedHeadwayWithStops$currentTime==times[length(times)])

#mixedHeadwayWithStops <- merge(x=mixEstHeadway,y=stopsData.df[,1:5],by.x=c("thisStop"),by.y=c("stop_id"))
#mixedHeadwayWithStops <- mixedHeadwayWithStops[order(mixedHeadwayWithStops$lastTS),]

# Only looking at the last timestamp of information
#timesMixed <- unique(mixedHeadwayWithStops$currentTime)
#mixedHeadwayWithStops<-subset(mixedHeadwayWithStops,mixedHeadwayWithStops$currentTime==timesMixed[length(timesMixed)])

###########################################################################################
uniqueStopsPureMix <- unique(observedHeadwayWithStops[,c("stopId","stop_name","stop_lon","stop_lat")])
#uniqueStopsMixedEst <- unique(mixedHeadwayWithStops[,c("thisStop","stop_name","stop_lon","stop_lat")])

stopHeadwayCalc <- data.frame()


#Full Day's Headway: observed and compared to scheduled
for (i in 1:nrow(uniqueStopsPureMix)) {
        # Formula Avg Wait Time: 1/2 ( (a^2+b^2+c^2)/(a+b+c) )
        # Formula Scheduled Wait Time: 1/2 * 1/n * (a+b+c...+n)
        
        ###########################################################################################
        # Temp Dataframes
        tempStopHeadway <- observedHeadwayWithStops[which(observedHeadwayWithStops$stopId==uniqueStopsPureMix[i,1]),]
        
        if (nrow(tempStopHeadway) == 0 ) {
                tempCalc <- data.frame(as.character(uniqueStopsPureMix[i,1]),
                                             as.character(uniqueStopsPureMix[i,2]),
                                             uniqueStopsPureMix[i,3],
                                             uniqueStopsPureMix[i,4],
                                             NA,
                                             NA,
                                             NA,
                                             NA,
                                             as.character(calcTimeIteration))
                colnames(tempCalc) <- c("StopId","StopName","StopLon","StopLat","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
                stopHeadwayCalc <- rbind(stopHeadwayCalc,tempCalc)
                next
        }
        
        # Remove duplicate observations seen if no bus update was made in the interval of headway calculation
        #tempStopHeadway <- tempStopHeadway[!duplicated(tempStopHeadway[,c(1:9)]),]
        
        tempUniqRoutes <- unique(tempStopHeadway[,"routeName"])
        
        # Remove Scheduled Headway if the observed headway isnt there. This was from a research paper****
        tempStopHeadwayNoNA <- tempStopHeadway[complete.cases(tempStopHeadway),]
        
        if(nrow(tempStopHeadwayNoNA)==0) {next}
        
        tempCalc<- data.frame()
        
        for(k in 1:length(tempUniqRoutes)) {
                routeTempHeadway <- tempStopHeadwayNoNA[which(tempStopHeadwayNoNA$routeName==tempUniqRoutes[k]),]
                
                
                if (nrow(routeTempHeadway) == 0 ) {
                        subsetRouteHolder <- data.frame(uniqueStopsPureMix[[i,1]],
                                                     uniqueStopsPureMix[[i,2]],
                                                     uniqueStopsPureMix[i,3],
                                                     uniqueStopsPureMix[i,4],
                                                     tempUniqRoutes[k],
                                                     NA,
                                                     NA,
                                                     NA,
                                                     as.character(calcTimeIteration))
                        colnames(subsetRouteHolder) <- c("StopId","StopName","StopLon","StopLat","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
                        tempCalc<-rbind(tempCalc,subsetRouteHolder)
                        next
                }
                
                
                avgWaitingTime<-vector()
                scheduledWaitingTime<-vector()
                percent<-vector()
                avgWaitingTime <- .5*(sum((routeTempHeadway$time_Difference)^2)/sum(routeTempHeadway$time_Difference))
                scheduledWaitingTime <- (.5*(sum(routeTempHeadway$obsSchdHeadway)/length(routeTempHeadway$obsSchdHeadway)))
                
                if(is.nan(scheduledWaitingTime)) {
                        scheduledWaitingTime<-NA
                        percent <- NA
                } else {
                        percent<-round((avgWaitingTime/scheduledWaitingTime),2)
                }
                
                
                subsetRouteHolder <- data.frame(as.character(uniqueStopsPureMix[i,1]),
                                                as.character(uniqueStopsPureMix[i,2]),
                                                uniqueStopsPureMix[i,3],
                                                uniqueStopsPureMix[i,4],
                                                tempUniqRoutes[k],
                                                round(avgWaitingTime,2),
                                                round(scheduledWaitingTime,2),
                                                percent,
                                                as.character(calcTimeIteration))
                colnames(subsetRouteHolder) <- c("StopId","StopName","StopLon","StopLat","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
                tempCalc<-rbind(tempCalc,subsetRouteHolder)
        }
        colnames(tempCalc)<-c("StopId","StopName","StopLon","StopLat","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
        stopHeadwayCalc <- rbind(stopHeadwayCalc,tempCalc)
        
        
        
        # Start of Mixed
        
      
}

colnames(stopHeadwayCalc) <- c("StopId","StopName","StopLon","StopLat","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")

#stopHeadwayHourlyCalcMix <- data.frame()

#for (k in 1:nrow(uniqueStopsMixedEst)) {
        
#        tempStopHourlyHeadwayMix <- mixedHeadwayWithStops[which(mixedHeadwayWithStops$thisStop==uniqueStopsPureMix[k,1]),]
        
#        if (nrow(tempStopHourlyHeadwayMix) == 0 ) {
#                tempHourlyCalcMix <- data.frame(as.character(uniqueStopsMixedEst[k,1]),
#                                             as.character(uniqueStopsMixedEst[k,2]),
#                                             uniqueStopsMixedEst[k,3],
#                                             uniqueStopsMixedEst[k,4],
#                                             NA,
#                                             NA,
#                                             NA,
#                                             NA,
#                                             as.character(calcTimeIteration))
#                colnames(tempHourlyCalcMix) <- c("StopId","StopName","StopLon","StopLat","HourlyRouteName","HourlyAvgWaitTime","HourlySchdWaitTime","HourlyPercent","HourlyCalcTime")
#                stopHeadwayHourlyCalcMix <- rbind(stopHeadwayHourlyCalcMix,tempHourlyCalc)
#                next
#        }
        
        # Remove duplicate observations seen if no bus update was made in the interval of headway calculation
#        tempStopHourlyHeadwayMix <- tempStopHourlyHeadwayMix[!duplicated(tempStopHourlyHeadwayMix[,c(1:12)]),]
        
#        tempUniqRoutesMix <- unique(tempStopHourlyHeadwayMix[,"route_short_name"])
        
        # Remove Scheduled Headway if the observed headway isnt there. This was from a research paper****
#        subsettempStopHourlyHeadwayMixNoNA <- subset(tempStopHourlyHeadwayMix, !is.na(tempStopHourlyHeadwayMix$estMixedHeadway) | !is.na(tempStopHourlyHeadwayMix$mixSchdHeadway))
        
        
#        tempHourlyCalcMix<- data.frame()
#        for(l in 1:length(tempUniqRoutesMix)) {
#                routeTempHourlyHeadwayMix <- subsettempStopHourlyHeadwayMixNoNA[which(subsettempStopHourlyHeadwayMixNoNA$route_short_name==tempUniqRoutesMix[l]),]
                
                
#                if (nrow(routeTempHourlyHeadwayMix) == 0 ) {
#                        subsetRouteHolderMix <- data.frame(uniqueStopsMixedEst[[k,1]],
#                                                        uniqueStopsMixedEst[[k,2]],
#                                                        uniqueStopsMixedEst[k,3],
#                                                        uniqueStopsMixedEst[k,4],
#                                                        tempUniqRoutesMix[l],
#                                                        NA,
#                                                        NA,
#                                                        NA,
#                                                        as.character(calcTimeIteration))
#                        colnames(subsetRouteHolderMix) <- c("StopId","StopName","StopLon","StopLat","HourlyRouteName","HourlyAvgWaitTime","HourlySchdWaitTime","HourlyPercent","HourlyCalcTime")
#                        tempHourlyCalcMix<-rbind(tempHourlyCalcMix,subsetRouteHolderMix)
#                        next
#                }
                
                
#                avgWaitingTimeHourlyMix<-vector()
#                scheduledWaitingTimeHourlyMix<-vector()
#                percentHourlyMix<-vector()
#                avgWaitingTimeHourlyMix <- .5*(sum((routeTempHourlyHeadwayMix$estMixedHeadway)^2,na.rm=TRUE)/sum(routeTempHourlyHeadwayMix$estMixedHeadway,na.rm=TRUE))
#                scheduledWaitingTimeHourlyMix <- (.5*(sum(routeTempHourlyHeadwayMix$mixSchdHeadway,na.rm=TRUE)/length(na.omit(routeTempHourlyHeadwayMix$mixSchdHeadway))))
                
#                if(is.nan(scheduledWaitingTimeHourly)) {
#                        scheduledWaitingTimeHourlyMix<-NA
#                        percentHourlyMix <- NA
#                }
#                else {
#                        percentHourlyMix<-(avgWaitingTimeHourlyMix/scheduledWaitingTimeHourlyMix)
#                }
                
                
#                subsetRouteHolderMix <- data.frame(as.character(uniqueStopsMixedEst[k,1]),
#                                                as.character(uniqueStopsMixedEst[k,2]),
#                                                uniqueStopsMixedEst[k,3],
#                                                uniqueStopsMixedEst[k,4],
#                                                tempUniqRoutesMix[l],
#                                                round(avgWaitingTimeHourlyMix,2),
#                                                round(scheduledWaitingTimeHourlyMix,2),
#                                                round((avgWaitingTimeHourlyMix/scheduledWaitingTimeHourlyMix),2),
#                                                as.character(calcTimeIteration))
#                colnames(subsetRouteHolderMix) <- c("StopId","StopName","StopLon","StopLat","HourlyRouteName","HourlyAvgWaitTime","HourlySchdWaitTime","HourlyPercent","HourlyCalcTime")
#                tempHourlyCalcMix<-rbind(tempHourlyCalcMix,subsetRouteHolderMix)
#        }
#        colnames(tempHourlyCalcMix)<-c("StopId","StopName","StopLon","StopLat","HourlyRouteName","HourlyAvgWaitTime","HourlySchdWaitTime","HourlyPercent","HourlyCalcTime")
#        stopHeadwayHourlyCalcMix <- rbind(stopHeadwayHourlyCalcMix,tempHourlyCalcMix)
        
        
        
#}

#colnames(stopHeadwayHourlyCalcMix) <- c("StopId","StopName","StopLon","StopLat","HourlyRouteName","HourlyAvgWaitTime","HourlySchdWaitTime","HourlyPercent","HourlyCalcTime")


######################################################################################################################################
# Calculating the current state of Auckland City

#probSeq <- seq(.1,.9,.1)
#currentStopStateOfAck <- data.frame(quantile(stopHeadwayHourlyCalc$HourlyAvgWaitTime, probs = probSeq, na.rm = TRUE),
#                                quantile(stopHeadwayHourlyCalc$HourlySchdWaitTime, probs = probSeq, na.rm = TRUE),
#                                quantile(stopHeadwayHourlyCalc$HourlyPercent, probs = probSeq, na.rm = TRUE),
#                                as.character(calcTimeIteration))

#colnames(currentStopStateOfAck) <- c("Observed Average Wait Time At Stops", "Scheduled Average Wait Time At Stops", "Stops Ratio Comparison", "Time Calculated")
#currentStopStateOfAck$Quantile <- rownames(currentStopStateOfAck) 
#currentStopStateOfAck <- currentStopStateOfAck[,c(5,1,2,3,4)]


finalStopHeadway <- paste(headwayDataDriectory,'stopHeadwayObserved',curDate,'.csv',sep="")
#finalStopHeadwayHourlyMixed <- paste(headwayDataDriectory,'StopHourlyHeadwayMixed',curDate,'.csv',sep="")
#finalStopCurrentState <- paste(headwayDataDriectory, 'StopCurrentState', curDate,'.csv',sep="")


if (file.exists(finalStopHeadway) == FALSE)
{
        write.table(stopHeadwayCalc, finalStopHeadway, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(stopHeadwayCalc, finalStopHeadway, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}

#if (file.exists(finalStopHeadwayHourlyMixed) == FALSE)
#{
#        write.table(stopHeadwayHourlyCalcMix, finalStopHeadwayHourlyMixed, col.names = TRUE, row.names = FALSE, sep=',')
#} else {
#        write.table(stopHeadwayHourlyCalcMix, finalStopHeadwayHourlyMixed, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
#}

#if (file.exists(finalStopCurrentState) == FALSE)
#{
#        write.table(currentStopStateOfAck, finalStopCurrentState, col.names = TRUE, row.names = FALSE, sep=',')
#} else {
#        write.table(currentStopStateOfAck, finalStopCurrentState, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
#}

print("Finished Headway Analysis (Stop POV Wait Times): Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())

