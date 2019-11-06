DELETE FROM STOPS
WHERE stop_id NOT IN
    (SELECT s.stop_id 
    FROM STOPS s JOIN STOPTIMES st ON s.stop_id = st.stop_id);