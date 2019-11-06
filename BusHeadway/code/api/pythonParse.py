import json, os, datetime, sqlite3

APPLOC="/home/ccar788/"

now = datetime.datetime.now()
fileLocation = APPLOC+"headway/data/api/"
databasePath = APPLOC+"headway/data/database/BhProd.db"

os.chdir(fileLocation)
fileList = os.listdir(fileLocation)
fileList = [a for a in fileList if 'tripUpdatesData' in a]

for fi in fileList:
    with open(fileLocation+fi, 'r') as myfile:
        jsonData = json.load(myfile)

        # Start to write the sql insert files as was having issues inserting with R
        writesVector = []
        writesVector.append('INSERT OR IGNORE INTO TripUpdates(id,trip_id,route_id,start_time,vehicle_id,stop_sequence,stop_id,delay,arrival,departure,timestamp,api_timestamp)')
        writesVector.append('VALUES')

        for j in range(len(jsonData["response"]["entity"])):
            # Alter id, trip_id, route_id, start_time, vehicle_id, stop_id, timestamp to strings
            jsonData["response"]["entity"][j]["trip_update"]["trip"]["start_time"] = "'" + jsonData["response"]["entity"][j]["trip_update"]["trip"]["start_time"] + "'"
            try:
                jsonData["response"]["entity"][j]["trip_update"]["vehicle"]["id"] = "'" + jsonData["response"]["entity"][j]["trip_update"]["vehicle"]["id"] + "'"
            except:
                jsonData["response"]["entity"][j]["trip_update"]["vehicle"]["id"] = "'NA'"


            # Variable assignmnet
            try:
                id = "'"+jsonData["response"]["entity"][j]["id"]+"'"
            except:
                id = '"NA"'
            try:
                trip_id = "'"+jsonData["response"]["entity"][j]["trip_update"]["trip"]["trip_id"]+"'"
            except:
                trip_id = '"NA"'
            try:
                route_id = "'"+jsonData["response"]["entity"][j]["trip_update"]["trip"]["route_id"]+"'"
            except:
                route_id = "'NA'"

            try:
                start_time = jsonData["response"]["entity"][j]["trip_update"]["trip"]["start_time"]
            except:
                start_time = "'NA'"
            
            try:
                vehicle_id = jsonData["response"]["entity"][j]["trip_update"]["vehicle"]["id"]
            except:
                vehicle_id = "'NA'"
            
            try:
                stop_sequence = jsonData["response"]["entity"][j]["trip_update"]["stop_time_update"]["stop_sequence"]
            except:
                stop_sequence = "'NA'"
            
            try:
                stop_id = "'"+jsonData["response"]["entity"][j]["trip_update"]["stop_time_update"]["stop_id"]+"'"
            except:
                stop_id = "'NA'"
            
            try:
                timestamp = jsonData["response"]["entity"][j]["trip_update"]["timestamp"]
            except:
                timestamp = "'NA'"
            
            try:
                apiTimestamp = jsonData["response"]["header"]["timestamp"]
            except:
                apiTimestamp = "'NA'"

            
            try:
                delay = jsonData["response"]["entity"][j]["trip_update"]["stop_time_update"]["departure"]["delay"]
                writesVector.append("(" + str(id) + "," + str(trip_id) + "," + str(route_id) + "," + str(start_time) + "," + str(vehicle_id) + "," + str(stop_sequence) + "," + str(stop_id) + "," + str(delay) + "," + str(0) + "," + str(1) + "," + str(timestamp) + "," + str(apiTimestamp) + ")")
            except:
                try:
                    delay = jsonData["response"]["entity"][j]["trip_update"]["stop_time_update"]["arrival"]["delay"]
                    writesVector.append("(" + str(id) + "," + str(trip_id) + "," + str(route_id) + "," + str(start_time) + "," + str(vehicle_id) + "," + str(stop_sequence) + "," + str(stop_id) + "," + str(delay) + "," + str(1) + "," + str(0) + "," + str(timestamp) + "," + str(apiTimestamp) + ")")
                except:
                    delay = '"NA"'
                
            
   
        with open("TripUpdatesInsert"+fi[15:31]+".sql", "w+") as f:
            f.write(writesVector[0] + "\n")
            f.write(writesVector[1] + "\n")
            for each in writesVector[2:]:
                if each == writesVector[len(writesVector)-1]:
                    f.write(each + "\n")
                else:
                    f.write(each + "," + "\n")
        

    # Code for connecting and running SQL Scripts, in order of 
    conn = sqlite3.connect(databasePath)
    cursor = conn.cursor()
    try:
        qry = open(fileLocation + "/" + "TripUpdatesInsert"+fi[15:31]+".sql", 'r').read()
        cursor.execute(qry)
        conn.commit()
        print("TripUpdate Updated")
        try:
            os.remove(fileLocation+"/" + "TripUpdatesInsert" + fi[15:31] + ".sql")
            print("TripUpdate File Deleted")
        except:
            os.rename(fileLocation+"TripUpdatesInsert"+fi[15:31]+".sql",fileLocation + "archive/" + "TripUpdatesInsert" + fi[15:31] + "arch"+ ".sql")
            print("File archived, check what is wrong")
    except:
        print("TripUpdate Failed")

    # Altered to delete file not archive as I was on local box
    print(fi)
    os.remove(fileLocation+fi)

        
        


