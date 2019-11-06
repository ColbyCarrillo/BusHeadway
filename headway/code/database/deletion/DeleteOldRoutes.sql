DELETE FROM ROUTES
WHERE route_id NOT IN 
        (SELECT route_id 
        FROM TRIPS); 

