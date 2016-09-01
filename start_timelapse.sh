#!/bin/bash
# A simple bash script to collect and process HDR images as a timelapse
# to be averaged on a daily basis.
# Note: this script stops at midnight. Ensure to commit a proper schedule
# in the crontab. Make sure to read the Job_scheduling.README

# You should only have to edit the Timelapse_Config.txt file. 

cd /home/pi/Desktop/AveragePhotography/


# Read in configuration variables.  
if [ -f "Timelapse_Config.txt" ]; then
 source "Timelapse_Config.txt"
else 
 echo " Can't see configuration file: Timelapse_Config.txt. Exiting." 
 exit 
fi
#>--------------------------------------------------------------------
cd $TOPDIR

# Cleanup pause flag from previous run:
if [ -f "pause_timelapse.txt" ]; then
 echo "Starting timelapse: found pause flag, - removing "
 rm pause_timelapse.txt
fi

#>--------------------------------------------------------------------
# Recording start date:
STARTDATE=`date +%Y-%m-%d`
DATE=$STARTDATE
TIME=`date +%H:%M`

echo $(printf "Starting timelapse on %s at %s " "$DATE" "$TIME" ) >>logfile.txt 
echo $(printf "Location: %s    Time interval between shots: %s seconds " "$LOCATION" "$INTERVAL" ) >>logfile.txt

# Take initial reference image
echo "-taking intial reference image for alignments. "
raspistill -p 10,10,640,480 -ev -4 -o  Ref_image.jpg

# Checks for new day; (timelapse needs to be restarted daily in crontab).
COUNTER=0
while [ "$DATE" == "$STARTDATE" ]
 do
  let COUNTER=COUNTER+1  # a counter for file labelling.
  DATE=`date +%Y-%m-%d`
  time1=`date +%s`       # take time to figure out image processing time

# Take photos for HDR:
  echo "-grabbing images for HDR"
  raspistill -p 10,10,320,240 -ISO 100 -ev  0  -q 100  -o temp_image1.jpg
  raspistill -p 10,10,320,240 -ISO 100 -ev  24 -q 100  -o temp_image2.jpg
  raspistill -p 10,10,320,240 -ISO 100 -ev -24 -q 100  -o temp_image3.jpg

# Align image batch (uses reference image as first image):
  echo "-aligning images"
  align_image_stack -i -a ALIGN_ Ref_image.* temp_image*
  # remove aligned reference image:
  rm ALIGN_0000.tif

# Make HDR image from aligned images:
  echo "-making HDR image out of aligned images"
  enfuse --output aligned.tif ALIGN_*

# Label HDR image with timestamp, move to Working directory & cleanup old files.
  TIMENOW=`date +%Y-%m-%d_%H.%M`
  filename=$(printf "%s/%s_%s_%04d.jpg" "$WRKDIR" "$LOCATION" "$TIMENOW" "$COUNTER" )
# convert to jpg and cleanup:
  convert aligned.tif -quality 100 $filename
  rm temp_image* ALIGN_* aligned.tif

# A conditional test to stop the timelapse (checks for presence of flag file).
  if [ -f "pause_timelapse.txt" ]; then
   echo "-pause flag present > exiting "
   echo $(printf "Pause flag present: stopping time lapse at %s" "$TIMENOW" ) >>logfile.txt
   exit
  fi

# Deduce processing time from interval time. Sleep if necessary.
  time2=`date +%s`
  let time3=" $time2 - $time1 "

 if [ $INTERVAL -ge $time3 ]
  then
   let delay=" $INTERVAL - $time3 "
   echo $(printf "Processing time: %s Sleeping for %s seconds" "$time3" "$delay")
   sleep $delay
   else
   echo "Warning: HDR Image processing takes longer than defined timelapse interval."
   echo $(printf "Interval time: %s   processing time: %s" "$INTERVAL" "$time3")
  fi

 done

# Stopping timelapse: Make sure to set up job schedule in crontab.
# -this makes it easier to schedule jobs during daylight hours, so
#  not to waste space and processing on overly dark images.

 echo "It is a new day! Timelaspe stopping. Make sure to set schedule in crontab."
 echo $(printf "Finishing daily timelapse on %s \n" "$DATE") >>logfile.txt
