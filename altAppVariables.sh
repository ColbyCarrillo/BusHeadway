#!/bin/bash
#Change this variable to where you cloned the repo
APPLOC="ccar788"
#
stringArray=("/home/${APPLOC}/BusHeadway/code/headway/busHeadway-Prod.R" "/home/${APPLOC}/BusHeadway/code/headway/busHeadwayEstimators-Prod.R" "/home/${APPLOC}/BusHeadway/code/headway/busHeadwaySummary-Prod.R" "/home/${APPLOC}/BusHeadway/code/headway/busHeadwaySummaryStops-Prod.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/adminDataMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/apiPullMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/databaseManageMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/databaseTripUpdatesMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/headwayAnalysisMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/headwayCalcMaster.R" "/home/${APPLOC}/BusHeadway/code/masterScripts/masterOfMasters.R" "/home/${APPLOC}/BusHeadway/code/viz/Viz.R" "/home/${APPLOC}/BusHeadway/code/admin/estimateTravelTime.R" "/home/${APPLOC}/BusHeadway/code/admin/pullScheduledTrips.R" "/home/${APPLOC}/BusHeadway/code/admin/checkAdminUpdate.py" "/home/${APPLOC}/BusHeadway/code/api/callTripUpdatesAPI.py" "/home/${APPLOC}/BusHeadway/code/api/pythonParse.py" "/home/${APPLOC}/BusHeadway/code/masterScripts/startProg.sh" "/home/${APPLOC}/BusHeadway/code/masterScripts/removeOldFiles.sh")
for i in ${stringArray[*]}
do
	sed -i s/ccar788/${APPLOC}/g $i
	chmod +x $i
done

#Change below * to your new API key provided by AT
NEWKEY="*"
#

sed -i "s/*/${NEWKEY}/g" /home/${APPLOC}/BusHeadway/code/api/callTripUpdatesAPI.py
