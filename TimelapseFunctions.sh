#!/bin/bash

# Bash functions for Raspberry Pi Timelapse. 

#-----------------------------------------------------------------------
function read_timelapse_config() {
## Simple function to read configuration file

if [ -f "Timelapse_Config.txt" ] ; then
 source "Timelapse_Config.txt"
 echo "reading config file"
else
 echo "Can't see configuration file: Timelapse_Config.txt. Exiting." \
  > last_mesg.txt
 exit
fi
}

#-----------------------------------------------------------------------
function initialize_timelapse() {
## Cleanup pause flag from previous run if present

echo "Starting timelapse." > last_mesg.txt
if [ -f "pause_timelapse.txt" ] ; then
 rm pause_timelapse.txt
fi

## Option to turn off hdmi to save power while taking photos
if [ "$HDMI" == true ] ; then
 tvservice -o
 echo "Turning off HDMI." > last_mesg.txt
fi
}

#-----------------------------------------------------------------------
function log_date_and_location() {
## function to log date and location

STARTDATE=`date +%Y-%m-%d`
DATE=$STARTDATE
TIME=`date +%H:%M`
echo $(printf "Date: %s Time: %s Location: %s Interval: %s  " \
     "$DATE" "$TIME" "$LOCATION" "$INTERVAL" ) >>logfile.txt
}

#-----------------------------------------------------------------------
function capture_images() {
## Capture images for processing including HDR (High Dynamic Range):
## (set in Timelapse_config file, up to 10 capture commands)

echo "-grabbing images for HDR"
for i in {1..10}
 do
  cmd="\$Capture$i"
  eval $cmd
 done
}

#-----------------------------------------------------------------------
function make_HDR_image() {
# Make HDR image from captured images:

echo "-making HDR image out of captured images"
enfuse --output current_hdr_image.tif temp_*.jpg

# Fill in working average images if absent:
if [ ! -f "working_average_image.tif" ] ; then
 cp current_hdr_image.tif working_average_image.tif 
 echo "copied current_hdr_image.tif to working_average_image.tif" >>  last_mesg.txt
fi

if [ ! -f "running_7day_average_image.tif" ] ; then
 cp current_hdr_image.tif running_7day_average_image.tif 
 echo "copied current_hdr_image.tif to running_7day_average_image.tif" >>  last_mesg.txt
fi

if [ ! -f "running_30day_average_image.tif" ] ; then
 cp current_hdr_image.tif running_7day_average_image.tif 
 echo "copied current_hdr_image.tif to running_30day_average_image.tif" >>  last_mesg.txt
fi
}

#-----------------------------------------------------------------------
function check_light_levels() {
# Check light levels from gray-scaled image:

L=$(convert current_hdr_image.tif -colorspace gray -resize 1x1 -format '%[pixel:p{0,0}]' \
  info: |sed "s/[^0-9,]//g" | awk -F',' '{print $1}')

echo $(printf "Light level of image: %s %s" "$L" "$TIMENOW") > last_mesg.txt

if [ "$L" -ge "$LIGHT_LOWER" ] && [ "$L" -le "$LIGHT_UPPER" ]; then
 Light=true 
else 
 Light=false
fi
}

#-----------------------------------------------------------------------
function make_average_image() {
# function to average working image. 
# needs 3 arguments: current_image  average_image  blend_ratio(integer)
# (modified from www.imagemagick.org/discorse-server/viewtopic.php?t=21279)


convert $2 tmp.mpc

i=$3
j=$((i+1)) 
# calculate blending percentages
new=`convert xc: -format "%[fx:100/$j]" info:`
old=`convert xc: -format "%[fx:100-$new]" info:`

echo $i $j $new $old
composite -blend $old%x$new% tmp.mpc $1 tmp.mpc

convert tmp.mpc $2 

rm tmp.mpc

}

#-----------------------------------------------------------------------
function cleanup_files() {
# cleanup temporary files:

rm temp_image*
}

#-----------------------------------------------------------------------
function sanity_check() {
## check to see things are running as expected. 
# A conditional test to stop the timelapse (checks for presence of flag file).

if [ -f "pause_timelapse.txt" ]; then
 echo "-pause flag present > exiting "
 echo $(printf "Pause flag present: stopping time lapse at %s" "$TIMENOW" ) >>logfile.txt
 exit
fi

# Sanity check: -stop if too many images gathered without processing.
if [ $COUNTER -gt "5000" ]; then
 echo "Warning: over 5000 images captured without daily reset: Are you sure you set thing up right?"
 echo $(printf "5000 images generated without processing: stopping time lapse at %s" "$TIMENOW" ) >>logfile.txt
 exit
fi
}

#-----------------------------------------------------------------------
function check_sleeptime() {
## Deduce processing time from interval time. Sleep if necessary.

time2=`date +%s`
let time3=" $time2 - $time1 "

if [ $INTERVAL -ge $time3 ]; then
 let delay=" $INTERVAL - $time3 "
 echo $(printf "Processing time: %s Sleeping for %s seconds" "$time3" "$delay")
 sleep $delay
else
 echo "Warning: HDR Image processing takes longer than defined timelapse interval."
 echo $(printf "Interval time: %s   processing time: %s" "$INTERVAL" "$time3")
fi
}

#-----------------------------------------------------------------------
function cleanup_files() {
# simple cleanup commands
rm tmp.cache
rm *.jpg

}
#-----------------------------------------------------------------------
function record_finish() {
# record the details to the logfile

cd $TOPDIR
FINISH=`date +%Y-%m-%d_%H:%M`
time2=`date +%s`
let time3=" $time2 - $time1 "

echo $(printf "Finished daily processing: %s     %s images \n"  "$FINISH" "$PICTURENO") >> logfile.txt

} 


