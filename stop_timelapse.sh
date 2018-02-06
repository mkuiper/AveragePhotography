#!/bin/bash
# A simple bash script to stop the timelapse. 

# Read in configuration variables.  
 source TimelapseFunctions.sh
 read_timelapse_config
 cd $TOPDIR
# turn on HDMI? 
 touch pause_timelapse.txt   # create pause flag
 echo $(printf "stopping timelapse at %s" "$TIMENOW" ) >>logfile.txt
