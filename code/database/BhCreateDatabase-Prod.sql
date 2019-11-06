CREATE TABLE Calendars(service_id TEXT PRIMARY KEY, 
Monday INTEGER NOT NULL, 
Tuesday INTEGER NOT NULL, 
Wednesday INTEGER NOT NULL, 
Thursday INTEGER NOT NULL, 
Friday INTEGER NOT NULL, 
Saturday INTEGER NOT NULL, 
Sunday INTEGER NOT NULL, 
start_date TEXT NOT NULL, 
end_date TEXT NOT NULL);

CREATE TABLE Routes(route_id TEXT PRIMARY KEY, 
agency_id TEXT NOT NULL, 
route_short_name TEXT, 
route_long_name TEXT,  
route_type INTEGER);

CREATE TABLE Stops(stop_id TEXT PRIMARY KEY, 
stop_name TEXT NOT NULL, 
stop_lat REAL NOT NULL, 
stop_lon REAL NOT NULL, 
stop_code INTEGER NOT NULL, 
the_geom TEXT);

CREATE TABLE StopTimes(trip_id TEXT NOT NULL,
arrival_time TEXT NOT NULL,
departure_time TEXT NOT NULL,
stop_id INTEGER NOT NULL, 
stop_sequence INTEGER NOT NULL,
PRIMARY KEY (trip_id, stop_sequence));

CREATE TABLE Trips(route_id TEXT NOT NULL, 
service_id TEXT NOT NULL, 
trip_id TEXT NOT NULL PRIMARY KEY, 
trip_headsign TEXT, 
direction_id INTEGER NOT NULL, 
shape_id TEXT,
FOREIGN KEY (route_id) REFERENCES Routes(route_id) 
    ON DELETE CASCADE ON UPDATE CASCADE
FOREIGN KEY (service_id) REFERENCES CALENDARS(service_id) 
    ON DELETE CASCADE ON UPDATE CASCADE);

CREATE TABLE TripUpdates(id TEXT NOT NULL,  
trip_id TEXT NOT NULL, 
route_id TEXT NOT NULL, 
start_time TEXT NOT NULL, 
vehicle_id TEXT NOT NULL, 
stop_sequence INTEGER NOT NULL, 
stop_id TEXT NOT NULL, 
delay INTEGER NOT NULL, 
arrival TEXT,
departure TEXT, 
timestamp TEXT NOT NULL,
api_timestamp TEXT NOT NULL,
PRIMARY KEY (trip_id, vehicle_id, timestamp),
FOREIGN KEY (trip_id) REFERENCES Trips(trip_id) 
    ON DELETE NO ACTION ON UPDATE NO ACTION,
FOREIGN KEY (route_id) REFERENCES Routes(route_id) 
    ON DELETE NO ACTION ON UPDATE NO ACTION,
FOREIGN KEY (stop_id) REFERENCES Stops(stop_id) 
    ON DELETE NO ACTION ON UPDATE NO ACTION);


CREATE INDEX idx_trip_id_trips ON Trips(trip_id);
CREATE INDEX idx_service_id_trips ON Trips(service_id);
CREATE INDEX idx_timestamp_trip_updates ON TripUpdates(timestamp);
CREATE INDEX idx_trip_id_stop_times ON StopTimes(trip_id);
CREATE INDEX idx_stop_id_stop_times ON StopTimes(stop_id);
CREATE UNIQUE INDEX idx_service_id_calendars ON Calendars(service_id);
CREATE INDEX idx_end_date_calendars ON Calendars(end_date);


CREATE VIEW bus AS 
SELECT tu.stop_id AS stop_id,
tu.route_id AS route_id,
r.route_short_name AS route_short_name,
tu.trip_id AS trip_id,
tu.start_time AS start_time,
tu.stop_sequence AS stop_sequence,
datetime(tu.timestamp, 'unixepoch', 'localtime') AS timestamp,
datetime(tu.api_timestamp, 'unixepoch', 'localtime') AS api_timestamp,
tu.delay AS delay,
tu.arrival,
tu.departure
FROM TripUpdates tu, Routes r
WHERE tu.route_id = r.route_id AND
date(tu.timestamp, 'unixepoch', 'localtime') = strftime('%Y-%m-%d', 'now', 'localtime');


CREATE VIEW schd AS 
SELECT st.*, t.*, c.*, r.route_short_name AS route_short_name
FROM StopTimes st, Trips t, Calendars c, Routes r
WHERE st.trip_id = t.trip_id AND
t.service_id = c.service_id AND
t.route_id = r.route_id AND
c.end_date > strftime('%Y%m%d',date('now', 'localtime')) AND
CASE strftime('%w','now', 'localtime')
        WHEN '1' THEN c.Monday
        WHEN '2' THEN c.Tuesday
        WHEN '3' THEN c.Wednesday
        WHEN '4' THEN c.Thursday
        WHEN '5' THEN c.Friday
        WHEN '6' THEN c.Saturday
        ELSE c.Sunday
        END = 1;


PRAGMA journal_mode=WAL;