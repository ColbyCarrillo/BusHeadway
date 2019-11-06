DELETE FROM CALENDARS
WHERE end_date < strftime('%Y%m%d', 'now', 'localtime');