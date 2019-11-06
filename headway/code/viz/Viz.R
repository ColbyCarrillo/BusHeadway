##### This file is used to visualize the results #####

scriptStartTime <- Sys.time()
print("Starting Visualization Process")
print(scriptStartTime)

APPLOC="/home/ccar788/"

analysisDataDirectory <- paste(APPLOC,'headway/data/headwaySummary/',sep="")
outputDirectory <- paste(APPLOC,'headway/data/viz/',sep="")
curDate<-Sys.Date()

HeadwayRoutesLoc <- paste('HourlyHeadway',curDate,'.csv',sep="")
#currentStateRoutesLoc <- paste('CurrentState',curDate,'.csv',sep="")
#currentStateStopsLoc <- paste('StopCurrentState',curDate,'.csv',sep="")

HeadwayRoutes.df <- read.csv(paste(analysisDataDirectory, HeadwayRoutesLoc, sep = ''))
#currentStateRoutes.df <- read.csv(paste(analysisDataDirectory, currentStateRoutesLoc, sep = ''))
#currentStateStops.df <- read.csv(paste(analysisDataDirectory, currentStateStopsLoc, sep = ''), stringsAsFactors = FALSE)


library(plotly)
startTime <- as.POSIXct(paste(curDate, "07:00:00", sep = " "))
endTime <- as.POSIXct(paste(curDate, "23:00:00", sep = " "))


##########################################################################################################################
# Hourly headway Code Section
##########################################################################################################################

HeadwayRoutes.df$CalcTime <- as.POSIXct(HeadwayRoutes.df$CalcTime)
HeadwayRoutes.df$lateness<-round(HeadwayRoutes.df$AvgWaitTime-HeadwayRoutes.df$SchdWaitTime,2)

HeadwayRoutesObs.df <- subset(HeadwayRoutes.df,HeadwayRoutes.df$Estimator=="Observed")
HeadwayRoutesMix.df <- subset(HeadwayRoutes.df,HeadwayRoutes.df$Estimator=="Mixed")
HeadwayRoutesCur.df <- subset(HeadwayRoutes.df,HeadwayRoutes.df$Estimator=="Current")

axis_x_headway <- list(
        title = "Time",
        ticks = "outside",
        tick0 = startTime,
        range = c(startTime,endTime)
)

axis_y_headway <- list(
        showgrid=F,
        zeroline=T,
        title="Headway Lateness"
)

legend_headway <- list(
        yref='paper',
        xref="paper",
        y=1.04,
        x=1.14,
        text = "Routes",
        showarrow=F,
        font = list(
                size = 14
        )
)

routesHeadwayObsAct.plt <- plot_ly(data=HeadwayRoutesObs.df, 
                                x=~CalcTime,
                                y=~AvgWaitTime,
                                color = ~RouteName,
                                colors = rainbow(levels(HeadwayRoutesObs.df$RouteName)),
                                hoverinfo = "text",
                                text = ~paste("Avg. Wait Time: ", AvgWaitTime, '<br>Route:', RouteName, '<br>Time: ',format(CalcTime,"%H:%M")),
                                type='scatter',
                                mode='markers') %>%
        layout(title="Observed Average Wait Time", xaxis=axis_x_headway, yaxis=axis_y_headway, annotations = legend_headway) %>%
        add_segments(x = startTime, xend = endTime, y = 20, yend = 20, line = list(color = "red", dash="dot", width=1),opacity=.2, showlegend = FALSE)

routesHeadwayObs.plt <- plot_ly(data=HeadwayRoutesObs.df, 
                x=~CalcTime,
                y=~lateness,
                color = ~RouteName,
                colors = rainbow(levels(HeadwayRoutesObs.df$RouteName)),
                hoverinfo = "text",
                text = ~paste("Latness: ", lateness, '<br>Route:', RouteName, '<br>Time: ',format(CalcTime,"%H:%M")),
                type='scatter',
                mode='markers') %>%
        layout(title="Scheduled vs Observed Headway", xaxis=axis_x_headway, yaxis=axis_y_headway, annotations = legend_headway) %>%
        add_segments(x = startTime, xend = endTime, y = 10, yend = 10, line = list(color = "red", dash="dot", width=1),opacity=.2, showlegend = FALSE) %>%
        add_segments(x = startTime, xend = endTime, y = -10, yend = -10, line = list(color = "red", dash="dot", width=1), opacity=.2, showlegend = FALSE)


routesHeadwayMix.plt <- plot_ly(data=HeadwayRoutesMix.df, 
                                x=~CalcTime,
                                y=~lateness,
                                color = ~RouteName,
                                colors = rainbow(levels(HeadwayRoutesMix.df$RouteName)),
                                hoverinfo = "text",
                                text = ~paste("Latness: ", lateness, '<br>Route:', RouteName, '<br>Time: ',format(CalcTime,"%H:%M")),
                                type='scatter',
                                mode='markers') %>%
        layout(title="Scheduled vs Mixed Estimator", xaxis=axis_x_headway, yaxis=axis_y_headway, annotations = legend_headway) %>%
        add_segments(x = startTime, xend = endTime, y = 10, yend = 10, line = list(color = "red", dash="dot", width=1),opacity=.2, showlegend = FALSE) %>%
        add_segments(x = startTime, xend = endTime, y = -10, yend = -10, line = list(color = "red", dash="dot", width=1), opacity=.2, showlegend = FALSE)


routesHeadwayCur.plt <- plot_ly(data=HeadwayRoutesCur.df, 
                                x=~CalcTime,
                                y=~lateness,
                                color = ~RouteName,
                                colors = rainbow(levels(HeadwayRoutesCur.df$RouteName)),
                                hoverinfo = "text",
                                text = ~paste("Latness: ", lateness, '<br>Route:', RouteName, '<br>Time: ',format(CalcTime,"%H:%M")),
                                type='scatter',
                                mode='markers') %>%
        layout(title="Scheduled vs Current Estimator", xaxis=axis_x_headway, yaxis=axis_y_headway, annotations = legend_headway) %>%
        add_segments(x = startTime, xend = endTime, y = 10, yend = 10, line = list(color = "red", dash="dot", width=1),opacity=.2, showlegend = FALSE) %>%
        add_segments(x = startTime, xend = endTime, y = -10, yend = -10, line = list(color = "red", dash="dot", width=1), opacity=.2, showlegend = FALSE)




##########################################################################################################################
# Hourly headway Code Section
##########################################################################################################################

#currentStateRoutes.df <- subset(currentStateRoutes.df,currentStateRoutes.df$Estimator=="Observed")
#currentStateRoutes.df$Quantile <- as.factor(currentStateRoutes.df$Quantile)
#currentStateRoutes.df <- subset(currentStateRoutes.df, (currentStateRoutes.df$Quantile=="50%" | currentStateRoutes.df$Quantile=="80%" | currentStateRoutes.df$Quantile=="90%"))
#currentStateRoutes.df$Time.Calculated <- as.POSIXct(currentStateRoutes.df$Time.Calculated)
#currentStateRoutes.df <- currentStateRoutes.df[order(currentStateRoutes.df$Time.Calculated,currentStateRoutes.df$Quantile),]
#currentStateRoutes.df$Observed.Average.Wait.Time <- round(currentStateRoutes.df$Observed.Average.Wait.Time,2)

#subCurrentStateRoutes.df <- currentState.df[,c("Quantile","Observed.Average.Wait.Time","Time.Calculated")]

#axis_x_curstate <- list(
#        #autotick = FALSE,
#        title = "Time",
#        ticks = "outside",
#        tick0 = startTime,
#        range = c(startTime,endTime)
#)

#axis_y_curstate <- list(
#        showgrid=F,
#        zeroline=T,
#        title="Average Wait Time (Mins)"
#)

#legend_headway <- list(
#        yref='paper',
#        xref="paper",
#        y=1.04,
#        x=1.14,
#        text = "Quantiles",
#        showarrow=F,
#        font = list(
#                size = 14
#        )
#)


#currentStateRoutes.plt <- plot_ly(data=currentStateRoutes.df, 
#                 x=~Time.Calculated,
#                 y=~Observed.Average.Wait.Time,
#                 color = ~Quantile,
#                 colors = rainbow(currentStateRoutes.df$Quantile),
#                 hoverinfo = "text",
#                 text = ~paste("Routes Avg. Wait Time (Mins): ", Observed.Average.Wait.Time, '<br>Time: ',format(Time.Calculated,"%H:%M")),
#                 type = 'scatter',
#                 mode='lines') %>%
#        layout(title = "Routes Average Wait Time (Quantiles)", xaxis = axis_x_curstate, yaxis = axis_y_curstate, annotations = legend_headway)



##########################################################################################################################
# Hourly headway Code Section
##########################################################################################################################

#currentStateStops.df$Quantile <- as.factor(currentStateStops.df$Quantile)
#currentStateStops.df <- subset(currentStateStops.df, ( currentStateStops.df$Quantile=="50%" | currentStateStops.df$Quantile=="80%" | currentStateStops.df$Quantile=="90%"))
#currentStateStops.df$Time.Calculated <- as.POSIXct(currentStateStops.df$Time.Calculated)
#currentStateStops.df <- currentStateStops.df[order(currentStateStops.df$Time.Calculated,currentStateStops.df$Quantile),]
#currentStateStops.df$Observed.Average.Wait.Time <- round(currentStateStops.df$Observed.Average.Wait.Time,2)


#axis_x_curstate_stop <- list(
#        #autotick = FALSE,
#        title = "Time",
#        ticks = "outside",
#        tick0 = startTime,
#        range = c(startTime,endTime)
#)

#axis_y_curstate_stop <- list(
#        showgrid=F,
#        zeroline=T,
#        title="Average Wait Time (Mins)"
#)

#legend_headway_stop <- list(
#        yref='paper',
#        xref="paper",
#        y=1.04,
#        x=1.14,
#        text = "Quantiles",
#        showarrow=F,
#        font = list(
#                size = 14
#        )
#)

#currentStateStops.plt <- plot_ly(data=currentStateStops.df, 
#                                  x=~Time.Calculated,
#                                  y=~Observed.Average.Wait.Time,
#                                  color = ~Quantile,
#                                  colors = rainbow(currentStateStops.df$Quantile),
#                                  hoverinfo = "text",
#                                  text = ~paste("Routes Avg. Wait Time (Mins): ", Observed.Average.Wait.Time, '<br>Time: ',format(Time.Calculated,"%H:%M")),
#                                  type = 'scatter',
#                                  mode='lines') %>%
#        layout(title = "Stops Average Wait Time (Quantiles)", xaxis = axis_x_curstate_stop, yaxis = axis_y_curstate_stop, annotations = legend_headway_stop)

##########################################################################################################################
# Output the HTML to location
##########################################################################################################################

htmlwidgets::saveWidget(as_widget(routesHeadwayObsAct.plt), paste(outputDirectory,"routesHeadwayObsAct.html",sep=""))
htmlwidgets::saveWidget(as_widget(routesHeadwayObs.plt), paste(outputDirectory,"routesHeadwayObs.html",sep=""))
htmlwidgets::saveWidget(as_widget(routesHeadwayMix.plt), paste(outputDirectory,"routesHeadwayMix.html",sep=""))
htmlwidgets::saveWidget(as_widget(routesHeadwayCur.plt), paste(outputDirectory,"routesHeadwayCur.html",sep=""))
#htmlwidgets::saveWidget(as_widget(currentStateRoutes.plt), paste(outputDirectory,"currentStateRoutes.html",sep=""))
#htmlwidgets::saveWidget(as_widget(currentStateStops.plt), paste(outputDirectory,"currentStateStops.html",sep=""))


print("Finished Visualization Process: Total Time")
print(Sys.time()-scriptStartTime)

