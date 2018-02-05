#!/bin/bash
# A script to do the average processing of images in the working directory.

source TimelapseFunctions.sh

read_timelapse_config

DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M`
time1=`date +%s`

echo $(printf "Start image averaging: %s  %s"  "$DATE" "$TIME") >>logfile.txt
echo "-making daily average image"

#>---------------------------------------------------------------------

AVEIMG=$(printf "%s_%s.jpg" "$LOCATION" "$DATE" )
echo "$AVEIMG"

convert working_average_image.tif -quality 100 $AVEIMG
cp $AVEIMG $ARCHIVE

# email daily result
mpack -s "timelapse image: $LOCATION $DATE" $AVEIMG  $EMAIL

cleanup_files

record_finish


