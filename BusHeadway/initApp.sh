#!/bin/bash
APPLOC="/home/ccar788/"
sqlite3 "${APPLOC}headway/data/database/BhProd.db" < "${APPLOC}headway/code/database/BhCreateDatabase-Prod.sql"
