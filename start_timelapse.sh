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
 echo "Can't see configuration file: Timelapse_Config.txt. Exiting." >> last_mesg.txt 
 exit 
fi

#>--------------------------------------------------------------------
cd $TOPDIR

# Cleanup pause flag from previous run:
if [ -f "pause_timelapse.txt" ]; then
 echo "Starting timelapse: found pause flag, - removing" >> last_mesg.txt
 rm pause_timelapse.txt
fi

#>--------------------------------------------------------------------
# Recording start date:
STARTDATE=`date +%Y-%m-%d`
DATE=$STARTDATE
TIME=`date +%H:%M`

# Record to log file:
echo $(printf "Date: %s Time: %s Location: %s Interval: %s  " "$DATE" "$TIME" "$LOCATION" "$INTERVAL" ) >>logfile.txt 

# Take initial alignment reference image if not present:
if [ -f "Ref_image.jpg" ]; then
 echo "-reference image present" 
else 
 echo "-taking intial reference image for alignments" 
 raspistill -p 10,10,640,480 -vf -hf -ev -4 -o  Ref_image.jpg 
fi

# Take series of timelapse images until told to stop:
#>--------------------------------------------------------------------
COUNTER=0
while : 
do
  let COUNTER=COUNTER+1  # a counter for file labelling.
  DATE=`date +%Y-%m-%d`
  time1=`date +%s`       # take time to figure out image processing time

# Capture images for processing including HDR (High Dynamic Range): 
# (set in Timelapse_config file)  
  echo "-grabbing images for HDR" 
  $Capture1
  $Capture2
  $Capture3 
  $Capture4
  $Capture5

# Align image batch (uses reference image as first image):
 if [ "$ALIGN" -eq "1" ]; then
  echo "-aligning images" >> last_mesg.txt
  align_image_stack -i -a ALIGN_  Ref_image.jpg temp_image*
  # remove aligned reference image: (not to be included in the averaging) 
  rm ALIGN_0000.tif
  enfuse --output aligned.tif ALIGN_*
 fi

# Make HDR image from images:
 echo "-making HDR image out of aligned images" 
 if [ "$ALIGN" -eq "0" ]; then
  enfuse --output aligned.tif temp_*.jpg
 fi  

# Label HDR image with timestamp, move to Working directory & cleanup old files.
 TIMENOW=`date +%Y-%m-%d_%H.%M`
 filename=$(printf "%s/%s_%s_%04d.jpg" "$WRKDIR" "$LOCATION" "$TIMENOW" "$COUNTER" )

# Check light levels from gray-scaled image:
 L=$(convert aligned.tif -colorspace gray -resize 1x1 -format '%[pixel:p{0,0}]' info: |sed "s/[^0-9,]//g" | awk -F',' '{print $1}') 
 echo $(printf "Light level of image: %s %s" "$L" "$TIMENOW") >> last_mesg.txt

 if [ "$L" -ge "$LIGHT_LOWER" ] && [ "$L" -le "$LIGHT_UPPER" ] || [ "$LIGHT_CUTOFF" -eq "0" ]; then
  convert aligned.tif -quality 100 $filename
  echo "-saving image to stack"
 fi 

# Clean up files:
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

# Sanity check: -stop if too many images gathered without processing.
 if [ $COUNTER -gt "5000" ]; then 
   echo "Warning: over 5000 images captured without image averaging: Are you sure you set thing up right?"
   echo $(printf "5000 images generated without processing: stopping time lapse at %s" "$TIMENOW" ) >>logfile.txt
   exit
 fi 

done

