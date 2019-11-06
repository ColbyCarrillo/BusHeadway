DELETE FROM TRIPUPDATES
WHERE datetime(timestamp, 'unixepoch', 'localtime') < datetime('now','localtime', '-1.5 hours');