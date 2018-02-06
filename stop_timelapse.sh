#!/bin/bash
# A simple bash script to stop the timelapse. 

# Read in configuration variables.  
 source TimelapseFunctions.sh
 read_timelapse_config
 cd $TOPDIR
 DATE=`date +%Y-%m-%d`
 TIME=`date +%H:%M`


# turn on HDMI? 
 touch pause_timelapse.txt   # create pause flag
 echo $(printf "stopping timelapse at %s %s" "$DATE $TIME" ) 
 echo $(printf "stopping timelapse at %s %s" "$DATE $TIME" ) >>log_file.txt
