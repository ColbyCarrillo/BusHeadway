#####           Colby Carrillo             #####
#####       Last Updated: 21/07/2019       #####
##### Check if webpage updated Admin Data  #####
##### https://www.crummy.com/software/BeautifulSoup/bs4/doc/
##### Tested and works                     #####

import urllib.request, sys, datetime, os, shutil
from bs4 import BeautifulSoup

APPLOC="/home/ccar788/"

codeDirectory = APPLOC+'BusHeadway/code/admin'
dataDirectory = APPLOC+'BusHeadway/data/admin'
databasePath = APPLOC+'BusHeadway/data/database/BhProd.db'

def downloadZip():
    import re, datetime, zipfile
    zips = ''

    for each in soup.find_all('p'):
        if ".zip" in str(each):
            zips = str(each)
    
    zips = re.findall('"([^"]*)"', zips)
    
    for each in zips:
        if ".zip" in str(each):
            zipUrl = each

    now = datetime.datetime.now()
    zipName = "gtfs-" + now.strftime("%Y-%m-%d")
    urllib.request.urlretrieve(zipUrl, dataDirectory + "/" + zipName + ".zip")

    os.chdir(dataDirectory)
    os.mkdir(zipName)

    zip_ref = zipfile.ZipFile(dataDirectory + "/" + zipName + ".zip", 'r')
    zip_ref.extractall(dataDirectory + "/" + zipName)
    zip_ref.close()

    os.remove(zipName + ".zip")

    #Calling file to parse text to sql, and then inserts into DB. Removing file if imports work correctly
    try:
        extractImportDB(zipName)
        print("extractImport function successful")
        try:
            shutil.rmtree(dataDirectory + "/" + zipName)
        except:
            print("Issue deleting directory")
    except:
        print("extractImport function failed")


def extractImportDB(str):
    import sqlite3
    subZipName = str
    os.chdir(dataDirectory + "/" + str)
    
    # Code for Calendar service_id, Monday, .. Sunday, start_date, end_date
    calData = []
    with open("calendar.txt", "r+") as f:
        for line in f:
            subLine = line.split(",")
            subLine[1] = subLine[1].strip('\n')
            subLine[2] = subLine[2].strip('\n')
            subLine[9] = subLine[9].strip('\n')
            if "service_id" in subLine:
                entry = "(" + subLine[0] + "," + subLine[3].capitalize() + "," + subLine[4].capitalize() + "," + subLine[5].capitalize() + "," + subLine[6].capitalize() + "," + subLine[7].capitalize() + "," + subLine[8].capitalize() + "," + subLine[9].capitalize() + "," + subLine[1] + "," + subLine[2] + ")"
            else:
                entry = "(" + "'" + subLine[0] + "'" + "," + subLine[3] + "," + subLine[4] + "," + subLine[5] + "," + subLine[6] + "," + subLine[7] + "," + subLine[8] + "," + subLine[9] + "," + subLine[1] + "," + subLine[2] + ")"
            calData.append(entry) 
    with open("calendar.sql", "w+") as f:
        f.write("INSERT OR IGNORE INTO Calendars" + calData[0] + "\n")
        f.write("VALUES" + "\n")
        for each in calData[1:]:
            if each == calData[len(calData)-1]:
                f.write(each + "\n")
            else:
                f.write(each + "," + "\n")

    # Code for Routes route_id, agency_id, route_short_name, route_long_name, route_type
    routeData = []
    with open("routes.txt", "r+") as f:
        for line in f:
            if '\"' in line:
                fSubLine = line.split("\"")
                subLine = line.split(",")
                subLine[7] = subLine[7].strip('\n')
                extra = len(subLine) - 7
                entry = "(" + "'" + subLine[4+extra] + "'" + "," + "'" + subLine[3+extra] + "'" + "," + "'" + subLine[6+extra] + "'" + "," + "'" + fSubLine[1].replace("\"", '') + "'" + "," + subLine[1+extra] + ")"
                routeData.append(entry) 
            else: 
                subLine = line.split(",")
                subLine[6] = subLine[6].strip('\n')
                if "route_long_name" in subLine:
                    entry = "(" + subLine[4] + "," + subLine[3] + "," + subLine[6] + "," + subLine[0] + "," + subLine[1] + ")"
                else: 
                    entry = "(" + "'" + subLine[4] + "'" + "," + "'" + subLine[3] + "'" + "," + "'" + subLine[6] + "'" + "," + "'" + subLine[0] + "'" + "," + subLine[1] + ")"
                routeData.append(entry) 
    with open("routes.sql", "w+") as f:
        f.write("INSERT OR IGNORE INTO Routes" + routeData[0] + "\n")
        f.write("VALUES" + "\n")
        for each in routeData[1:]:
            if each == routeData[len(routeData)-1]:
                f.write(each + "\n")
            else:
                f.write(each + "," + "\n")

    # Code for Stops stop_id 3*, stop_name 6*, stop_lat 0, stop_lon 2, stop_code 8, DROPPED the_geom
    stopData = []
    with open("stops.txt", "r+") as f:
        for line in f:
            subLine = line.split(",")
            subLine[8] = subLine[8].strip('\n')
            if "stop_id" in subLine:
                entry = "(" + subLine[3] + "," + subLine[6] + "," + subLine[0] + "," + subLine[2] + "," + subLine[8] + ")"
            else:
                entry = "(" + "'" + subLine[3] + "'" + "," + "\"" + subLine[6] + "\"" + "," + subLine[0] + "," + subLine[2] + "," + subLine[8] + ")"
            stopData.append(entry) 
    with open("stops.sql", "w+") as f:
        f.write("INSERT OR IGNORE INTO Stops" + stopData[0] + "\n")
        f.write("VALUES" + "\n")
        for each in stopData[1:]:
            if each == stopData[len(stopData)-1]:
                f.write(each + "\n")
            else:
                f.write(each + "," + "\n")
    
    # Code for Trips route_id 1*, service_id 5*, trip_id 6*, trip_headsign 3*, direction_id 2, shape_id 4*
    tripsData = []
    with open("trips.txt", "r+") as f:
        for line in f:
            subLine = line.split(",")
            subLine[6] = subLine[6].strip('\n')
            if "route_id" in subLine:
                entry = "(" + subLine[1] + "," + subLine[5] + "," + subLine[6] + "," + subLine[3] + "," + subLine[2] + "," + subLine[4] + ")"
            else:
                entry = "(" + "'" + subLine[1] + "'" + "," + "'" + subLine[5] + "'" + "," + "'" + subLine[6] + "'" + "," + "'" + subLine[3] + "'" + "," + subLine[2] + "," + "'" + subLine[4] + "'" + ")"
            tripsData.append(entry) 
    with open("trips.sql", "w+") as f:
        f.write("INSERT OR IGNORE INTO Trips" + tripsData[0] + "\n")
        f.write("VALUES" + "\n")
        for each in tripsData[1:]:
            if each == tripsData[len(tripsData)-1]:
                f.write(each + "\n")
            else:
                f.write(each + "," + "\n")
    
    # Code for Stop_times trip_id 0*, arrival_time 1*, departure_time 2*, stop_id 3*, stop_sequence 4
    stopTimesData = []
    with open("stop_times.txt", "r+") as f:
        for line in f:
            subLine = line.split(",")
            if "trip_id" in subLine:
                entry = "(" + subLine[0] + "," + subLine[1] + "," + subLine[2] + "," + subLine[3] + "," + subLine[4] + ")"
            else:
                entry = "(" + "'" + subLine[0] + "'" + "," + "'" + subLine[1] + "'" + "," + "'" + subLine[2] + "'" + "," + "'" + subLine[3] + "'" + "," + subLine[4] + ")"
            stopTimesData.append(entry)  
    with open("stop_times.sql", "w+") as f:
        f.write("INSERT OR IGNORE INTO StopTimes" + stopTimesData[0] + "\n")
        f.write("VALUES" + "\n")
        for each in stopTimesData[1:]:
            if each == stopTimesData[len(stopTimesData)-1]:
                f.write(each + "\n")
            else:
                f.write(each + "," + "\n")

    # Code for connecting and running SQL Scripts, in order of 
    conn = sqlite3.connect(databasePath)
    cursor = conn.cursor()
    fullFileLoc = dataDirectory + "/" + subZipName
    print(fullFileLoc)
    try:
        qry = open(fullFileLoc + "/" + "calendar.sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        print("calander successful")
    except:
        print("calendar failed")

    try:
        qry = open(fullFileLoc + "/" + "routes.sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        print("routes successful")
    except:
        print("routes failed")

    try:
        qry = open(fullFileLoc + "/" + "stops.sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        print("stops successful")
    except:
        print("stops failed")

    try:
        qry = open(fullFileLoc + "/" + "trips.sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        print("trips successful")
    except:
        print("trips failed")

    try:
        qry = open(fullFileLoc + "/" + "stop_times.sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        cursor.close()
        conn.close()
        print("stop_times successful")
    except:
        print("stop_times failed")
    
    # Need to add in code to delete the just uploaded zip file
    



# Main of the code, will call Download Zip with then calls import function, iif data was updates on AT page

url = 'https://at.govt.nz/about-us/at-data-sources/general-transit-feed-specification/'
urlsource = urllib.request.urlopen(url)
soup = BeautifulSoup(urlsource, 'html.parser')

data = ''

for each in soup.find_all('p'):
        if "update" in str(each):
            data = str(each)

data = data.replace("<p>", "")
data = data.replace("<strong>", "")
data = data.replace("</p>", "")
data = data.replace("</strong>", "")
data = data.replace("\xa0", " ")


os.chdir(codeDirectory)
fileList = os.listdir(codeDirectory)

fileCheck = None

for each in fileList:
    if "Last" in each:
        fileCheck = each

if fileCheck is None:
    open(data, "w+")
    downloadZip()
    sys.exit("No Update File, Update Complete")
elif fileCheck != data:
    os.remove(fileCheck)
    open(data, "w+")
    downloadZip()
    sys.exit("New Data Update Complete")
else:
    print("No new data to update")