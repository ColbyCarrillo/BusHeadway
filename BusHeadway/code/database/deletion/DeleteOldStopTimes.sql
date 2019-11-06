DELETE FROM STOPTIMES
WHERE trip_id NOT IN
    (SELECT st.trip_id 
    FROM TRIPS t JOIN STOPTIMES st ON t.trip_id = st.trip_id); 
