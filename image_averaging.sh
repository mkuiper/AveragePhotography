#!/bin/bash
# A script to do the average processing of images in the working directory.

 source TimelapseFunctions.sh
 read_timelapse_config

 DATE=`date +%Y-%m-%d`
 TIME=`date +%H:%M`
 time1=`date +%s`

 echo $(printf "Start image averaging: %s  %s"  "$DATE" "$TIME") >> logfile.txt
 echo "-making daily average image"

#>---------------------------------------------------------------------
 AVEIMG=$(printf "%s_%s.jpg" "$LOCATION" "$DATE" )
 echo "$AVEIMG"
 convert working_average_image.tif -quality 100 $AVEIMG
 cp $AVEIMG $ARCHIVE

#>---------------------------------------------------------------------
# make running weekly and monthly (30 day) averages:  
 make_average_image working_average_image.tif running_7day_average_image.tif 6 
 make_average_image working_average_image.tif running_30day_average_image.tif 29 

 AVEIMG_7=$(printf "%s_%s_7day.jpg" "$LOCATION" "$DATE" )
 AVEIMG_30=$(printf "%s_%s_30day.jpg" "$LOCATION" "$DATE" )
 convert running_7day_average_image.tif  -quality 100 $AVEIMG_7
 convert running_30day_average_image.tif -quality 100 $AVEIMG_30
 cp $AVEIMG_7  $ARCHIVE7
 cp $AVEIMG_30 $ARCHIVE30

# email daily result
 mpack -s "timelapse image: $LOCATION $DATE" $AVEIMG  $EMAIL

 cleanup_files
 record_finish

