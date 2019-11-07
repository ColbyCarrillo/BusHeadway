#!/bin/bash
APPLOC="/home/ccar788/"
find "${APPLOC}BusHeadway/data/headwaySummary/"* "${APPLOC}BusHeadway/code/masterScripts/output/masterOutput"* -type f -mtime +30 -delete
find "${APPLOC}BusHeadway/data/headwaySummary/"*Summary* -type f -mtime +30 -delete
truncate -s 1M "${APPLOC}BusHeadway/code/masterScripts/output/cron.txt"
