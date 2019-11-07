#!/bin/bash
#Change variable below before running
APPLOC="ccar788"
#
sqlite3 "/home/${APPLOC}/BusHeadway/data/database/BhProd.db" < "/home/${APPLOC}/BusHeadway/code/database/BhCreateDatabase-Prod.sql"
