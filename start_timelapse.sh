#!/bin/bash
# A simple bash script to collect and process HDR images as a timelapse
# to be averaged on a daily/weekly/monthly basis. Ensure to commit a proper schedule in 
# the crontab. Make sure to read the Job_scheduling.README

##
# You should only have to edit the Timelapse_Config.txt file. 
##

 source TimelapseFunctions.sh

 read_timelapse_config
 cd $TOPDIR
 initialize_timelapse
 log_date_and_location

# Take series of timelapse images until told to stop:
COUNTER=0
while : 
do
  time1=`date +%s`       # take time to figure out image processing time

  capture_images
  make_HDR_image
  echo "-made HDR image"
 
  check_light_levels      # process images if light levels within boundaries
  if $Light ;  
    then 
    let COUNTER=COUNTER+1  # counter for working out blending %
    make_average_image current_hdr_image.tif working_average_image.tif $COUNTER
    echo "Image count: $PICTURENO" >>last_mesg.txt
  fi 

  cleanup_files 
  sanity_check
  check_sleeptime
done

