#!/bin/bash
APPLOC="/home/ccar788/"
sqlite3 "${APPLOC}BusHeadway/data/database/BhProd.db" < "${APPLOC}BusHeadway/code/database/BhCreateDatabase-Prod.sql"
