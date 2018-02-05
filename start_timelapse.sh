#!/bin/bash
# A simple bash script to collect and process HDR images as a timelapse
# to be averaged on a daily basis. Ensure to commit a proper schedule in 
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
PICTURENO=0
while : 
do
  let COUNTER=COUNTER+1  # a counter for file labelling.
  time1=`date +%s`       # take time to figure out image processing time

 capture_images

 make_HDR_image

 echo "made HDR image"
 check_light_levels

 if $Light ; 
  then 
  let PICTURENO=PICTURENO+1  # counter for working out blending %
  make_average_image $PICTURENO
  echo "Image count: $PICTURENO" >>last_mesg.txt
 fi 

 cleanup_files 

 sanity_check

 check_sleeptime

done



