#!/bin/bash
#Change this variable to where you cloned the repo
APPLOC="/home/ccar788/"
#
stringArray=("${APPLOC}BusHeadway/code/headway/busHeadway-Prod.R" "${APPLOC}BusHeadway/code/headway/busHeadwayEstimators-Prod.R" "${APPLOC}BusHeadway/code/headway/busHeadwaySummary-Prod.R" "${APPLOC}BusHeadway/code/headway/busHeadwaySummaryStop-Prod.R" "${APPLOC}BusHeadway/code/masterScripts/adminDataMaster.R" "${APPLOC}BusHeadway/code/masterScripts/apiPullMaster.R" "${APPLOC}BusHeadway/code/masterScripts/databaseManageMaster.R" "${APPLOC}BusHeadway/code/masterScripts/databaseTripUpdatesMaster.R" "${APPLOC}BusHeadway/code/masterScripts/headwayAnalysisMaster.R" "${APPLOC}BusHeadway/code/masterScripts/headwayCalcMaster.R" "${APPLOC}BusHeadway/code/masterScripts/masterOfMasters.R" "${APPLOC}BusHeadway/code/viz/Viz.R" "${APPLOC}BusHeadway/code/admin/estimateTravelTime.R" "${APPLOC}BusHeadway/code/admin/pullScheduledTrips.R" "${APPLOC}BusHeadway/code/admin/checkAdminUpdate.py" "${APPLOC}BusHeadway/code/api/callTripUpdatesAPI.py" "${APPLOC}BusHeadway/code/api/pythonParse.py")
for i in ${stringArray[*]}
do
    sed -i "s/APPLOC='/home/ccar788/'/APPLOC='newAppLocation'/g" $i
done

#Change below * to your new API key provided by AT
NEWKEY="'Ocp-Apim-Subscription-Key': '*'"
#

sed -i "s/"'Ocp-Apim-Subscription-Key': '*'"/'${NEWKEY}'/g" "${APPLOC}/code/api/callTripUpdatesAPI.py"
