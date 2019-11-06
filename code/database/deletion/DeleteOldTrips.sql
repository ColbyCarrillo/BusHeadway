DELETE FROM TRIPS
WHERE trip_id NOT IN
        (SELECT t.trip_id 
        FROM TRIPS t JOIN CALENDARS c ON t.service_id = c.service_id); 


