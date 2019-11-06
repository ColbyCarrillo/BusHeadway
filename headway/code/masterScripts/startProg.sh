#!/bin/bash
APPLOC="/home/ccar788/"
Rscript "${APPLOC}headway/code/masterScripts/masterOfMasters.R" >> "${APPLOC}headway/code/masterScripts/output/masterOutput.$(date +"%d-%m-%Y")" &

