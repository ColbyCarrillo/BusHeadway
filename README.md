# BusHeadway

This project was for my Dissertation course in order to complete my Masters of Professional Studies in Data Science 
from University of Auckland, New Zealand.

The purpose of this application is to gather, in 20 second intervals from 06:00 to 23:00, the trip updates sent out
by Auckland Transport (AT). With this data we calculate three estimators of bus headway (observed, mixed, and current)
and have some visualizations that are created of the average waiting time for frequent routes.

By cloning this repo, it will provide all the required files and directories in order to run the Bus Headway application
that I created for AT in Auckland, New Zealand.

Required software:
-R (dplyr, stringr, RSQLite), Python 3.6 or greater, SQLite (Version 3.7 or greater)
		
		
		
	One is required to:
  	1.) Acquire a API key from AT (https://dev-portal.at.govt.nz/) 
		
  	2.) Alter the application location variables to where you are cloning the app on your system and your new application key provided by AT.
      	-This can be done by first CHANGING the variables to the respective locations and then altAppVariables.sh script which will replace all the app locations in the respective files
				
  	3.) Run the initialize application using the initApp.sh script, which will create the database tables and views
		
  	4.) Alter cron jobs to run daily (I choose 01:00): 
      		a.) startProg.sh
          		-example: 0 1 * * * PATH=/opt/anaconda3/bin:$PATH /home/ccar788/headway/code/masterScripts/startProg.sh >> /home/ccar788/headway/code/masterScripts/output/cron.txt 2>&1
     	 	b.) removeOldFiles.sh
          		-example: 0 1 * * * /home/ccar788/headway/code/masterScripts/removeOldFiles.sh

	5.) If you desire for the application to start right away, you can run 'nohup startProg.sh &' to start the program in the background, followed by disown %1 to have it run even after you logout (given that you only have one process running in background)      

