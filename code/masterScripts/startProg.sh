#!/bin/bash
APPLOC="/home/ccar788/"
Rscript "${APPLOC}BusHeadway/code/masterScripts/masterOfMasters.R" >> "${APPLOC}BusHeadway/code/masterScripts/output/masterOutput.$(date +"%d-%m-%Y")" &

