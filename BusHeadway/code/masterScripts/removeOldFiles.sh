#!/bin/bash
APPLOC="/home/ccar788/"
find "${APPLOC}headway/data/headwaySummary/"* "${APPLOC}headway/code/masterScripts/output/masterOutput"* -type f -mtime +30 -delete
find "${APPLOC}headway/data/headwaySummary/"*Summary* -type f -mtime +30 -delete
truncate -s 1M "${APPLOC}headway/code/masterScripts/output/cron.txt"
