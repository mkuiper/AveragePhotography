#!/bin/bash
# A simple bash script to collect and process HDR images as a timelapse
# to be averaged on a daily basis.
# Note: this script stops at midnight. Ensure to commit a proper schedule
# in the crontab. Make sure to read the Job_scheduling.README

# You should only have to edit the Timelapse_Config.txt file. 

# Read in configuration variables.  
if [ -f "Timelapse_Config.txt" ]; then
 source "Timelapse_Config.txt"
else 
 echo " Can't see configuration file: Timelapse_Config.txt. Exiting." 
 exit 
fi
#>--------------------------------------------------------------------
cd $TOPDIR

# turn on HDMI 
# tvservice -p

touch pause_timelapse.txt


