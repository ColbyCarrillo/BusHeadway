##### This file is used to import our headway measurements and output the findings of analysis #####

scriptStartTime <- Sys.time()
print("Starting Headway Analysis: Wait Times")
print(scriptStartTime)

APPLOC="/home/ccar788/"

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



uniqueRoutesPureMix <- unique(pureHistHeadway[,"routeName"])
#uniqueRoutesMixEst <- unique(mixEstHeadway[,"route_short_name"])
#uniqueRoutesCurEst <- unique(curEstHeadway[,"route_short_name"])

uniqueCurrentTime <- unique(pureHistHeadway[,"currentTime"])

headwayHourlyCalc <- data.frame()
mixEstCalc <- data.frame()
curEstCalc <- data.frame()


#Full Day's Headway: observed and compared to scheduled
for (i in 1:length(uniqueRoutesPureMix)) {
        # Formula Avg Wait Time: 1/2 ( (a^2+b^2+c^2)/(a+b+c) )
        # Formula Scheduled Wait Time: 1/2 * 1/n * (a+b+c...+n)
        
        ###########################################################################################
        # Temp Dataframes
        tempHourlyHeadway <- pureHistHeadway[which(pureHistHeadway$currentTime==uniqueCurrentTime[length(uniqueCurrentTime)] & pureHistHeadway$routeName==uniqueRoutesPureMix[i]),]
        tempHourlyHeadway <- tempHourlyHeadway[complete.cases(tempHourlyHeadway),]
        if (nrow(tempHourlyHeadway) == 0 ) {
                tempHourlyCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             NA,
                                             NA,
                                             NA,
                                             as.character(calcTimeIteration))
                colnames(tempHourlyCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                headwayHourlyCalc <- rbind(headwayHourlyCalc,tempHourlyCalc)
        } else {
                # Remove duplicate observations seen if no bus update was made in the interval of headway calculation
                # tempHourlyHeadway <- tempHourlyHeadway[!duplicated(tempHourlyHeadway[,c(1:8,10:12)]),]
                
                ###########################################################################################
                # Calculations Hourly
                avgWaitingTimeHourly<-vector()
                scheduledWaitingTimeHourly<-vector()
                percentHourly<-vector()
                avgWaitingTimeHourly <- .5*(sum((tempHourlyHeadway$time_Difference)^2)/sum(tempHourlyHeadway$time_Difference))
                scheduledWaitingTimeHourly <- (.5*(sum(tempHourlyHeadway$obsSchdHeadway)/length(tempHourlyHeadway$obsSchdHeadway)))
                percentHourly<-(avgWaitingTimeHourly/scheduledWaitingTimeHourly)
                
                #Transformation Hourly
                if(is.nan(scheduledWaitingTimeHourly)) {scheduledWaitingTimeHourly<-NA}
                if(is.nan(avgWaitingTimeHourly)) {avgWaitingTimeHourly<-NA}
                
                ###########################################################################################
                # Output Hourly
                tempHourlyCalc<- data.frame()
                tempHourlyCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             round(avgWaitingTimeHourly,2),
                                             round(scheduledWaitingTimeHourly,2),
                                             round((avgWaitingTimeHourly/scheduledWaitingTimeHourly),2),
                                             as.character(calcTimeIteration))
                colnames(tempHourlyCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                
                headwayHourlyCalc <- rbind(headwayHourlyCalc,tempHourlyCalc)
        }
        
        
        
        tempMixEst<-mixEstHeadway[which(mixEstHeadway$currentTime==uniqueCurrentTime[length(uniqueCurrentTime)] & mixEstHeadway$route_short_name==uniqueRoutesPureMix[i]),]
        tempMixEst <- tempMixEst[complete.cases(tempMixEst),]
        if (nrow(tempMixEst) == 0 ) {
                tempMixEstCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             NA,
                                             NA,
                                             NA,
                                             as.character(calcTimeIteration))
                colnames(tempMixEstCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                mixEstCalc <- rbind(mixEstCalc,tempMixEstCalc)
                
        } else {
                avgWaitingTimeMixEst<-vector()
                scheduledWaitingTimeMixEst<-vector()
                percentHourlyMixEst<-vector()
                avgWaitingTimeMixEst <- .5*(sum((tempMixEst$estMixedHeadway)^2)/sum(tempMixEst$estMixedHeadway))
                scheduledWaitingTimeMixEst <- (.5*(sum(tempMixEst$mixSchdHeadway)/length((tempMixEst$mixSchdHeadway))))
                percentHourlyMixEst<-(avgWaitingTimeMixEst/scheduledWaitingTimeMixEst)
                
                
                if(is.nan(avgWaitingTimeMixEst)) {avgWaitingTimeMixEst<-NA}
                if(is.nan(scheduledWaitingTimeMixEst)) {scheduledWaitingTimeMixEst<-NA}
                
                tempMixEstCalc<- data.frame()
                tempMixEstCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             round(avgWaitingTimeMixEst,2),
                                             round(scheduledWaitingTimeMixEst,2),
                                             round((avgWaitingTimeMixEst/scheduledWaitingTimeMixEst),2),
                                             as.character(calcTimeIteration))
                colnames(tempMixEstCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                
                mixEstCalc <- rbind(mixEstCalc,tempMixEstCalc)
        }
        
        tempCurEst <- curEstHeadway[which(curEstHeadway$currentTime==uniqueCurrentTime[length(uniqueCurrentTime)] & curEstHeadway$route_short_name==uniqueRoutesPureMix[i]),]
        tempCurEst <- tempCurEst[complete.cases(tempCurEst),]
        if (nrow(tempMixEst) == 0 ) {
                tempCurEstCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             NA,
                                             NA,
                                             NA,
                                             as.character(calcTimeIteration))
                colnames(tempCurEstCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                curEstCalc <- rbind(curEstCalc,tempCurEstCalc)
        } else {
                avgWaitingTimeCurEst<-vector()
                scheduledWaitingTimeCurEst<-vector()
                percentHourlyCurEst<-vector()
                avgWaitingTimeCurEst <- .5*(sum((tempCurEst$estBusTravelTime)^2)/sum(tempCurEst$estBusTravelTime))
                scheduledWaitingTimeCurEs <- (.5*(sum(tempCurEst$curSchdHeadway)/length(tempCurEst$curSchdHeadway)))
                percentHourlyCurEs<-(avgWaitingTimeCurEst/scheduledWaitingTimeCurEs)
                
                if(is.nan(avgWaitingTimeCurEst)) {avgWaitingTimeCurEst<-NA}
                if(is.nan(scheduledWaitingTimeCurEs)) {scheduledWaitingTimeCurEs<-NA}
                
                tempCurEstCalc<- data.frame()
                tempCurEstCalc <- data.frame(as.character(uniqueRoutesPureMix[i]),
                                             round(avgWaitingTimeCurEst,2),
                                             round(scheduledWaitingTimeCurEs,2),
                                             round((avgWaitingTimeCurEst/scheduledWaitingTimeCurEs),2),
                                             as.character(calcTimeIteration))
                colnames(tempCurEstCalc) <- c("RouteName","AvgWaitTime","SchdWaitTime","Percent",
                                              "CalcTime")
                
                curEstCalc <- rbind(curEstCalc,tempCurEstCalc)
        }
      
}

headwayHourlyCalc <- cbind("Observed",headwayHourlyCalc)
mixEstCalc <- cbind("Mixed", mixEstCalc)
curEstCalc <- cbind("Current", curEstCalc)

colnames(headwayHourlyCalc) <- c("Estimator","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
colnames(mixEstCalc) <- c("Estimator","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")
colnames(curEstCalc) <- c("Estimator","RouteName","AvgWaitTime","SchdWaitTime","Percent","CalcTime")

estimatorSummary <- rbind(headwayHourlyCalc,mixEstCalc,curEstCalc)


######################################################################################################################################
# Calculating the current state of Auckland City

probSeq <- seq(.1,.9,.1)
currentStateOfAckObs <- data.frame("Observed",
                                quantile(headwayHourlyCalc$AvgWaitTime, probs = probSeq, na.rm = TRUE),
                                quantile(headwayHourlyCalc$SchdWaitTime, probs = probSeq, na.rm = TRUE),
                                quantile(headwayHourlyCalc$Percent, probs = probSeq, na.rm = TRUE),
                                as.character(calcTimeIteration))

currentStateOfAckMix <- data.frame("Mixed",
                                   quantile(mixEstCalc$AvgWaitTime, probs = probSeq, na.rm = TRUE),
                                   quantile(mixEstCalc$SchdWaitTime, probs = probSeq, na.rm = TRUE),
                                   quantile(mixEstCalc$Percent, probs = probSeq, na.rm = TRUE),
                                   as.character(calcTimeIteration))

currentStateOfAckCur <- data.frame("Current",
                                   quantile(curEstCalc$AvgWaitTime, probs = probSeq, na.rm = TRUE),
                                   quantile(curEstCalc$SchdWaitTime, probs = probSeq, na.rm = TRUE),
                                   quantile(curEstCalc$Percent, probs = probSeq, na.rm = TRUE),
                                   as.character(calcTimeIteration))

library(dplyr)
currentStateOfAckObs <- tibble::rownames_to_column(currentStateOfAckObs, "Quantile")
currentStateOfAckMix <- tibble::rownames_to_column(currentStateOfAckMix, "Quantile")
currentStateOfAckCur <- tibble::rownames_to_column(currentStateOfAckCur, "Quantile")

colnames(currentStateOfAckObs) <- c("Quantile","Estimator","Average Wait Time", "Scheduled Average Wait Time", "Comparison", "Time Calculated")
colnames(currentStateOfAckMix) <- c("Quantile","Estimator","Average Wait Time", "Scheduled Average Wait Time", "Comparison", "Time Calculated")
colnames(currentStateOfAckCur) <- c("Quantile","Estimator","Average Wait Time", "Scheduled Average Wait Time", "Comparison", "Time Calculated")

currentStateOfAck <- rbind(currentStateOfAckObs,currentStateOfAckMix,currentStateOfAckCur)


finalHeadwayHourly <- paste(headwayDataDriectory,'HourlyHeadway',curDate,'.csv',sep="")
finalCurrentState <- paste(headwayDataDriectory, 'CurrentState', curDate,'.csv',sep="")


if (file.exists(finalHeadwayHourly) == FALSE)
{
        write.table(estimatorSummary, finalHeadwayHourly, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(estimatorSummary, finalHeadwayHourly, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}

if (file.exists(finalCurrentState) == FALSE)
{
        write.table(currentStateOfAck, finalCurrentState, col.names = TRUE, row.names = FALSE, sep=',')
} else {
        write.table(currentStateOfAck, finalCurrentState, col.names = FALSE, row.names = FALSE, append = TRUE, sep=',')
}

print("Finished Headway Analysis (Wait Times): Total Time")
print(Sys.time()-scriptStartTime)
print(Sys.time())

