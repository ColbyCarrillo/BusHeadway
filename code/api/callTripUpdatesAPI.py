#! /opt/anaconda3/bin/python python

###########    Python 3.2    ################
##### Trip Updates API - Colby Carrillo #####
#####     Last Updated: 19/02/2019      #####

import http.client, urllib.request, urllib.parse, urllib.error, base64, os, datetime

APPLOC="/home/ccar788/"
dataDirectory = APPLOC+"BusHeadway/data/api"

headers = {
    # Request headers
    'Ocp-Apim-Subscription-Key': '*',
}

try:
    conn = http.client.HTTPSConnection('api.at.govt.nz')
    conn.request("GET", "/v2/public/realtime/tripupdates?%s", "{body}", headers)
    response = conn.getresponse()
    data = response.read()

    # Data is in bytes, had to change to string to write to file
    dataString = data.decode("utf-8")

    # Remove the beginning text of the file
    #dataString = dataString[44:]

    # Open file, remove any contents, and then write and close
    os.chdir(dataDirectory)
    now = datetime.datetime.now()
    
    
    file = open("tripUpdatesData" + now.strftime("%Y-%m-%d-%H%M%S") + ".json","w")
    file.truncate(0)
    for lines in dataString:
        file.write(lines)
    file.close()

    conn.close()
except Exception as e:
    print("[Errno {0}] {1}".format(e.errno, e.strerror))

####################################
